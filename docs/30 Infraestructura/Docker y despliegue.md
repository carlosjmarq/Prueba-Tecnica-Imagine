---
tags: [infra, docker, despliegue]
status: vigente
date: 2026-09-08
---

# Docker y despliegue

> Contenerización del proyecto y estrategia de despliegue (local → CI → AWS).

## Docker Compose (desarrollo)

Archivo base en `infra/docker-compose.base.yml` (o en `infra/docker-compose.yml`):

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: imagine_delivery
      POSTGRES_PASSWORD: imagine_delivery_dev
      POSTGRES_DB: imagine_delivery
    ports: ["5434:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    ports: ["9000:9000", "9001:9001"]
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin

  api:
    build: ../backend
    ports: ["8000:8000"]
    environment:
      DATABASE_URL: postgresql+asyncpg://imagine_delivery:imagine_delivery_dev@postgres:5432/imagine_delivery
      STORAGE_BACKEND: s3          # apunta a MinIO
      S3_ENDPOINT_URL: http://minio:9000
    depends_on: [postgres, minio]
```

## Dockerfile del backend (multi-stage)

```dockerfile
FROM python:3.12-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY app/ alembic/ ./
EXPOSE 8000
CMD [".venv/bin/uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Despliegue

### CI (GitHub Actions)

| Repo           | Pipeline                                   |
| -------------- | ------------------------------------------ |
| delivery-api   | lint+test → build imagen → push ECR → deploy (SSM/CodeDeploy o ECS) |
| mobile         | 2 pipelines (customer_app y driver_app): analyze+test → build APK/AppBundle → artifact |
| infra          | `terraform validate/plan` en PR → `apply` en main (OIDC) |

### AWS

1. Imagen → **ECR**.
2. EC2 con user-data que tira el contenedor (o ECS Fargate si se prefiere; en la prueba se justifica EC2+ALB para WebSocket directo).
3. Migraciones: paso explícito en el pipeline (con backup previo, ver [[RDS PostgreSQL]]).
4. Variables/secretos en **SSM Parameter Store / Secrets Manager**, inyectados como env del contenedor.
5. Rollback: desplegar la imagen anterior en el target group.

> **Implementación (Fase 4, 2026-09-10):** compose full en `infra/docker-compose.yml`
> (postgres 5434 + MinIO + API en 8000, con `build: ../backend`). Módulo
> `infra/terraform/modules/compute/`: ECR `delivery-api`, launch template
> Amazon Linux 2023 con user-data (instala Docker, `ecr get-login-password`, lee
> SSM y arranca el contenedor con `--restart unless-stopped` y logs `awslogs`),
> ASG 1–2 en subnets privadas, ALB internet-facing con target group :8000 y health
> check `/health`. CI en `.github/workflows/ci.yml` (fmt + validate) y CD en
> `.github/workflows/deploy.yml` (build/push a ECR + `tofu apply` con OIDC).

## Estado real (deploy 2026-09-10)

- ECR `delivery-api`, ALB **`delivery-dev-alb`** (HTTP:80 → target group :8000) y ASG `t3.micro` 1–2 con user-data Docker (login ECR + SSM + uvicorn); health `/health` OK.
- **Endpoint público API**: http://delivery-dev-alb-290184693.eu-west-1.elb.amazonaws.com (Swagger en `/docs`). Flujo completo probado: registro → login → pedido `PENDING`.
- Correcciones durante el deploy: `Dockerfile` con rutas `./app/` y `./alembic/` + `COPY README.md`; rol EC2 con `AmazonSSMManagedInstanceCore` para leer SSM.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Arquitectura AWS]], [[RDS PostgreSQL]], [[Testing y calidad]]
- **Repo:** `infra` (CI/CD en `.github/workflows/`)
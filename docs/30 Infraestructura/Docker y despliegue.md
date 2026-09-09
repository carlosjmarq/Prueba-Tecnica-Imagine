---
tags: [infra, docker, despliegue]
status: borrador
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
      POSTGRES_USER: delivery
      POSTGRES_PASSWORD: delivery_dev
      POSTGRES_DB: delivery
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    ports: ["9000:9000", "9001:9001"]
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin

  api:
    build: ../../backend
    ports: ["8000:8000"]
    environment:
      DATABASE_URL: postgresql+asyncpg://delivery:delivery_dev@postgres:5432/delivery
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

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Arquitectura AWS]], [[RDS PostgreSQL]], [[Testing y calidad]]
- **Repo:** `infra` (CI/CD en `.github/workflows/`)
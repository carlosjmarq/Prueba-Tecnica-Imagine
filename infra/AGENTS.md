# infra — Infraestructura

Terraform/OpenTofu, Docker, diagramas y CI/CD de la plataforma de delivery.

> Parte del monorepo `imagine-delivery` (ADR-008): ver `AGENTS.md` raíz y `docs/` (vault Obsidian).

## Stack

- OpenTofu (fork de Terraform, HCL compatible) — ver nota de bloqueo regional en `docs/40 Proceso/Setup y herramientas`
- AWS: VPC, RDS, S3, EC2/ALB, CloudFront, CloudWatch, Lambda
- GitHub Actions (CI + CD)
- Docker Compose base (PostgreSQL + MinIO)

## Estructura

```
docker-compose.base.yml   # servicios de dev (postgres, minio)
terraform/
  modules/
    rds/                  # RDS PostgreSQL multi-AZ + backups
    s3_cloudfront/        # bucket + CDN
    compute/              # EC2 + ALB (REST + WebSocket)
    observability/        # CloudWatch logs, métricas, alarmas
    lambda/               # order-timeout-canceller
  envs/
    dev/  staging/  prod/
functions/                # código de las funciones Lambda
.github/workflows/        # CI/CD
```

## Comandos (dev)

```powershell
# levantar infra local (Postgres + MinIO)
docker compose -f docker-compose.base.yml up -d

# terraform/tofu
tofu init
tofu validate
tofu plan
tofu apply
```

## Documentación

- Diagrama de arquitectura: `docs/30 Infraestructura/Arquitectura AWS`
- RDS: `docs/30 Infraestructura/RDS PostgreSQL`
- S3 + CloudFront: `docs/30 Infraestructura/S3 y CloudFront`
- CloudWatch: `docs/30 Infraestructura/CloudWatch y logging`
- Lambda: `docs/30 Infraestructura/Lambda`

## Convenciones

- Nunca credenciales reales en el repo: variables/SSM/Secrets Manager.
- Todo cambio toca el vault: revisar `docs/` antes, actualizar después.
- Commits Conventional Commits.
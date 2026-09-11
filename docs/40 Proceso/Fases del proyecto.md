---
tags: [proceso, fases, workflow]
status: permanente
date: 2026-09-08
---

# Fases del proyecto

> Orden de ejecución del workflow de IA. Cada fase termina con tests verdes y vault actualizado.

## Estado de fases

| Fase | Nombre          | Comando opencode      | Estado |
| ---- | --------------- | --------------------- | ------ |
| 0    | Setup           | `/setup`              | ✅     |
| 1    | Fundaciones     | `/foundations`        | ✅     |
| 2    | Backend         | `/backend`            | ✅     |
| 3    | Apps móviles    | `/apps`               | ✅     |
| 4    | Infraestructura | `/infra`              | ✅     |
| 5    | Entrega         | `/deliver`            | ✅ (salvo video opcional) |

## Fase 0 — Setup

Instalar y verificar el toolchain ([[Setup y herramientas]]). Salida: tabla de herramientas OK + servicios locales (Postgres/MinIO) levantados.

## Fase 1 — Fundaciones

- Monorepo único inicializado ([[ADR-008 Monorepo unico]]) con `git init` y commit base.
- `AGENTS.md` por carpeta, CI vacío, docker-compose base (`infra/docker-compose.base.yml`).
- ADRs iniciales en el vault ([[ADR-001 Eleccion de stack]], [[ADR-002 Estructura multi-repositorio]], [[ADR-003 Vault Obsidian como fuente de verdad]], [[ADR-007 Monorepo de apps moviles]], [[ADR-008 Monorepo unico]]).
- **Esqueletos de código completados**:
  - Backend: `pyproject.toml` (uv), `app/` (main con `/health`), `tests/`, `Dockerfile` multi-stage, `alembic.ini`, `.env.example`. Validado: ruff, format, mypy y pytest verdes.
  - Apps: `flutter create` de `customer_app` y `driver_app` (org `com.imagine`), paquete `packages/shared` inicial, patrón feature-first (`core/` + `features/`), Riverpod conectado, `shared` referenciado por path. Validado: `flutter analyze` y `flutter test` verdes en ambas.
  - CI: `.github/workflows/ci.yml` con jobs por path filter (backend, mobile, infra).
  - Infra local: Postgres 16 + MinIO levantados vía `docker-compose.base.yml`.

## Fase 2 — Backend

- Auth JWT + refresh con rotación y revocación ([[API Autenticacion]]).
- Pedidos y máquina de estados ([[API Pedidos y estados]], [[Modelo de datos]]).
- Realtime WebSocket con ConnectionManager y rooms ([[Realtime]], [[ADR-005 Realtime WebSocket vs SSE]] Aceptado).
- StorageService S3 siempre (MinIO en dev) ([[StorageService]]).
- Rate limiting (slowapi), logging JSON (structlog), Alembic aplicado, Swagger `/docs`, tests ([[Testing y calidad]]).
- Estado real: [[API Implementada]]. ADR-004 Aceptado.

## Fase 3 — Apps móviles

- Customer App y Driver App (login, registro, pedidos, realtime), en `mobile/` ([[ADR-007 Monorepo de apps moviles]]) dentro del monorepo único ([[ADR-008 Monorepo unico]]).
- Estado Riverpod ([[ADR-004 Estado de las apps]] Aceptado); UI con el [[Design System de las apps]] (ui-ux-pro-max).
- Estado real: [[Apps moviles implementadas]].

## Fase 4 — Infraestructura ✅

**Deploy real completado el 2026-09-10** en AWS `eu-west-1`, cuenta `646364595364`.

- Diagrama de arquitectura ([[Arquitectura AWS]]).
- Terraform (OpenTofu) con 6 módulos (`vpc`, `rds`, `s3_cloudfront`, `compute`, `observability`, `lambda`) instanciados desde `envs/dev`; state remoto en S3 `imagine-delivery-tfstate-646364595364` + lock DynamoDB.
- **Red**: VPC `10.0.0.0/16`, 2 AZs, 1 NAT; SGs con mínimo privilegio (ALB 80/443 desde internet, API 8000 desde ALB, RDS 5432 desde API+Lambda, Lambda con egress).
- **RDS** ([[RDS PostgreSQL]]): PostgreSQL **16.13**, `db.t3.small` gp3 20 GB, Multi-AZ, backups 7 días con PITR y deletion protection; migraciones Alembic aplicadas (initial schema + add delivery proof key).
- **S3 + CloudFront** ([[S3 y CloudFront]]): bucket privado `delivery-media-dev` (versioning, SSE-S3 AES256, CORS presign, lifecycle IA 30d / Glacier 90d) con distribución CloudFront OAC `d3b1xgzyfgomor.cloudfront.net`.
- **Compute** ([[Docker y despliegue]]): ECR `delivery-api`, ALB `delivery-dev-alb` (HTTP:80 → TG 8000) y ASG `t3.micro` 1–2 con user-data Docker (login ECR + SSM + uvicorn). Health `/health` OK y flujo completo probado (registro → login → pedido `PENDING`).
- **Observabilidad** ([[CloudWatch y logging]]): log groups `/aws/ec2/delivery-api`, `/aws/alb/delivery`, `/aws/lambda/delivery-order-timeout`; SNS `delivery-alerts` (email); alarmas ALB 5xx, RDS CPU y RDS free storage; dashboard.
- **Lambda** ([[Lambda]]): `delivery-order-timeout-canceller` (python3.12, pg8000, VPC, cron cada 5 min) verificada — retorna `{"cancelled": 0}`.
- GitHub Actions + dockerizado ([[Docker y despliegue]]).
- **Endpoint público API**: http://delivery-dev-alb-290184693.eu-west-1.elb.amazonaws.com (Swagger en `/docs`).
- **CI/CD verificado verde (2026-09-11)**: CI (backend tests con Postgres+MinIO, mobile analyze+test, infra validate) y CD completo (build/push ECR + `tofu apply` vía OIDC) pasan. Detalles en [[Deploy AWS automatizado]].

## Fase 5 — Entrega ✅

- READMEs finales (raíz, backend, apps), checklist completado ([[Checklist de la prueba]]).
- **Pendiente opcional**: guion de video ([[Guion video]]) — no requerido para la entrega.

## Reglas

- No saltar fases: la Fase N+1 asume la N completada.
- Cada fase y cada feature aplica el ciclo **RPI (Research → Plan → Implement)** — ver [[RPI Research Plan Implement]].
- Cada fase actualiza su estado en esta tabla y el [[00 Inbox/MOC]].
- Si una fase descubre un cambio de diseño → nuevo ADR.

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Setup y herramientas]], [[ADR-002 Estructura multi-repositorio]]
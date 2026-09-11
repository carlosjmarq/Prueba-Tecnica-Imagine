# delivery-api

Backend de la plataforma de delivery: **FastAPI + PostgreSQL + SQLAlchemy 2.0 async + Alembic + JWT**.

Parte del monorepo `imagine-delivery` (ver `AGENTS.md` raíz y el vault `docs/`). Swagger en `/docs`.

## Stack

- Python 3.12, FastAPI, uvicorn
- SQLAlchemy 2.0 (async) + Alembic + PostgreSQL 16
- JWT access + refresh (pyjwt) con rotación y revocación; bcrypt
- Rate limiting (slowapi), logging estructurado JSON (structlog)
- WebSocket para realtime (ConnectionManager + rooms)
- StorageService S3 (MinIO en dev, AWS S3 en prod) con presigned URLs

## Estructura

```
app/
  api/          # routers REST + WebSocket
  core/         # config, security, logging, database
  models/       # SQLAlchemy ORM
  schemas/      # Pydantic v2
  services/     # dominio: pedidos, storage, realtime
alembic/        # migraciones (incluye seed de datos)
tests/          # pytest (TestClient + httpx)
```

## Desarrollo

```powershell
# 1. Infra local (Postgres :5434 + MinIO :9000)
docker compose -f ../infra/docker-compose.base.yml up -d

# 2. Config y deps
Copy-Item .env.example .env      # ajustar si hace falta
uv sync --group dev

# 3. Migraciones (aplica esquema + seed de mock data) y arranque
alembic upgrade head
uv run uvicorn app.main:app --reload
```

Swagger en `http://localhost:8000/docs`. O levantar todo con `scripts/dev.ps1` desde la raíz.

## Mock data

La migración `alembic/versions/9f8e7d6c5b4a_seed_mock_data.py` siembra usuarios y pedidos de demo
(usuarios `customer1@`/`customer2@`/`driver1@`/`driver2@example.com`, password `password123`).
Aplicar/refrescar con `scripts/seed.ps1 -Env dev|prod` (ver `docs/20 Tecnico/Seed de datos`).

## Endpoints principales

| Método | Ruta | Uso |
| ------ | ---- | --- |
| POST | `/api/v1/auth/register` / `/login` / `/refresh` / `/logout` | Autenticación JWT |
| GET | `/api/v1/auth/me` | Perfil del usuario autenticado |
| POST | `/api/v1/orders` | Crear pedido (customer) |
| GET | `/api/v1/orders` | Listar pedidos propios |
| GET | `/api/v1/orders/{id}` | Detalle |
| POST | `/api/v1/orders/{id}/accept` | Aceptar (driver) |
| POST | `/api/v1/orders/{id}/status` | Actualizar estado (driver) |
| POST | `/api/v1/orders/{id}/cancel` | Cancelar (customer, solo PENDING) |
| POST | `/api/v1/uploads/presign` | Presigned URL para subida directa |
| GET | `/api/v1/uploads/images/{key}` | Proxy de lectura de imágenes autenticado |
| WS | `/ws/orders` | Notificaciones realtime por estado |
| GET | `/health` | Health check |

## Calidad

```powershell
uv run ruff check .
uv run ruff format .
uv run mypy app
uv run pytest
```

## Producción

- Deploy infraestructura: `scripts/deploy-aws.ps1 deploy` (ver `docs/40 Proceso/Deploy AWS automatizado`).
- CI/CD: `.github/workflows/ci.yml` (lint + test) y `deploy.yml` (ECR + `tofu apply` vía OIDC).
- Endpoint público de ejemplo: http://delivery-dev-alb-290184693.eu-west-1.elb.amazonaws.com (Swagger en `/docs`).

## Documentación

- `docs/20 Tecnico/API Implementada`, `API Autenticacion`, `API Pedidos y estados`, `Modelo de datos`, `Realtime`, `StorageService`
- `docs/10 Diseno/ADR-001 Eleccion de stack` y ADRs numerados
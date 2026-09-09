# backend — FastAPI

Backend de la plataforma de delivery: FastAPI + PostgreSQL + SQLAlchemy 2.0 async + Alembic + JWT.

> Parte del monorepo `imagine-delivery` (ADR-008): ver `AGENTS.md` raíz y `docs/` (vault Obsidian).

## Stack

- Python 3.12, FastAPI, uvicorn
- SQLAlchemy 2.0 (async) + Alembic
- PostgreSQL 16 (Docker en dev)
- JWT access + refresh (pyjwt), bcrypt
- WebSocket para realtime (ver ADR-005)
- StorageService S3-ready (MinIO en dev, S3 en prod)
- Pytest + httpx, ruff + mypy

## Estructura

```
app/
  api/          # routers REST + WS
  core/         # config, security, logging
  models/       # SQLAlchemy ORM
  schemas/      # Pydantic v2
  services/     # dominio: pedidos, storage, realtime
alembic/        # migraciones
tests/          # pytest
```

## Comandos (dev)

```powershell
# instalar deps
uv sync

# levantar infra (Postgres + MinIO)
docker compose -f ../infra/docker-compose.base.yml up -d

# migrar y correr
alembic upgrade head
uv run uvicorn app.main:app --reload

# calidad
uv run ruff check .
uv run ruff format .
uv run mypy app
uv run pytest
```

## Entregables

- Swagger en `/docs`
- Auth JWT + refresh + rate limiting
- Pedidos con máquina de estados (Pending → Accepted → Picked Up → Delivered / Cancelled)
- Notificaciones realtime por WebSocket
- Logging estructurado JSON
- Dockerfile multi-stage

## Convenciones

- Todo cambio toca el vault: revisar `docs/` antes, actualizar después.
- Commits Conventional Commits (ver `docs/40 Proceso/Convenciones git y commits`).
# delivery-api

Backend de la plataforma de delivery: FastAPI + PostgreSQL + SQLAlchemy 2.0 async + Alembic + JWT.

Parte del monorepo `imagine-delivery`. Ver `AGENTS.md` y el vault `docs/` para contexto y decisiones.

## Desarrollo

```powershell
# levantar infra (Postgres + MinIO)
docker compose -f ../infra/docker-compose.base.yml up -d

# instalar deps
uv sync --group dev

# migrar y correr
alembic upgrade head
uv run uvicorn app.main:app --reload

# calidad
uv run ruff check .
uv run ruff format .
uv run mypy app
uv run pytest
```

Swagger en `http://localhost:8000/docs`.
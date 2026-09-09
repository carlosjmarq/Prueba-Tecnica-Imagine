import os

TEST_DB = "imagine_delivery_test"

# Windows: ProactorEventLoop rompe TestClient + WebSocket; usar SelectorEventLoop.
if os.name == "nt":
    import asyncio

    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

# Definir la BD de test ANTES de importar la app: pydantic-settings lee env vars
# con prioridad sobre defaults, y get_settings() esta cacheado al import.
DEV_DB_URL = (
    "postgresql+asyncpg://imagine_delivery:imagine_delivery_dev@localhost:5434/imagine_delivery"
)
os.environ.setdefault("DATABASE_URL", DEV_DB_URL.rsplit("/", 1)[0] + f"/{TEST_DB}")

import asyncio  # noqa: E402
from collections.abc import AsyncIterator  # noqa: E402

import asyncpg  # noqa: E402
import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import text  # noqa: E402
from sqlalchemy.ext.asyncio import (  # noqa: E402
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.pool import NullPool  # noqa: E402

from app.core.config import get_settings  # noqa: E402
from app.core.database import get_session  # noqa: E402
from app.main import app  # noqa: E402


def _admin_dsn() -> str:
    return DEV_DB_URL.replace("postgresql+asyncpg://", "postgresql://")


async def _create_test_db() -> None:
    admin_conn = await asyncpg.connect(_admin_dsn())
    exists = await admin_conn.fetchval("SELECT 1 FROM pg_database WHERE datname = $1", TEST_DB)
    if not exists:
        await admin_conn.execute(f'CREATE DATABASE "{TEST_DB}"')
    await admin_conn.close()


async def _drop_test_db() -> None:
    admin_conn = await asyncpg.connect(_admin_dsn())
    await admin_conn.execute(f'DROP DATABASE IF EXISTS "{TEST_DB}" WITH (FORCE)')
    await admin_conn.close()


@pytest.fixture(scope="session", autouse=True)
def _prepare_db() -> AsyncIterator[None]:
    async def setup() -> None:
        await _create_test_db()

    async def teardown() -> None:
        await _drop_test_db()

    asyncio.run(setup())
    yield
    asyncio.run(teardown())


@pytest.fixture(scope="session", autouse=True)
def _prepare_storage() -> None:
    """Crea el bucket en MinIO si no existe (tests usan MinIO local)."""
    from app.services.storage import get_storage

    storage = get_storage()
    try:
        storage._client.head_bucket(Bucket=storage._bucket)
    except Exception:
        storage.ensure_bucket()
    yield


@pytest.fixture(scope="session")
def engine(_prepare_db):
    engine = create_async_engine(get_settings().database_url, poolclass=NullPool)
    yield engine
    asyncio.run(engine.dispose())


async def _migrate() -> None:
    from alembic import command
    from alembic.config import Config

    cfg = Config("alembic.ini")
    cfg.set_main_option("sqlalchemy.url", get_settings().database_url)
    await asyncio.to_thread(command.upgrade, cfg, "head")


@pytest.fixture(scope="session")
async def migrated(engine) -> None:
    await _migrate()


@pytest.fixture(autouse=True)
async def _clean_tables(session_factory) -> AsyncIterator[None]:
    """Limpia las tablas antes de cada test para aislamiento total."""
    async with session_factory() as session:
        await session.execute(
            text(
                "TRUNCATE TABLE refresh_tokens, order_status_history, order_items, "
                "orders, users RESTART IDENTITY CASCADE"
            )
        )
        await session.commit()
    yield


@pytest.fixture(autouse=True)
def _clean_websocket_manager() -> None:
    """Reinicia el ConnectionManager global entre tests (sockets muertos)."""
    from app.services.realtime import manager

    manager._rooms.clear()
    yield
    manager._rooms.clear()


@pytest.fixture
async def session_factory(engine, migrated) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(engine, expire_on_commit=False)


@pytest.fixture
async def db_session(session_factory) -> AsyncIterator[AsyncSession]:
    async with session_factory() as session:
        yield session


@pytest.fixture
def client(session_factory) -> AsyncIterator[TestClient]:
    async def _override_get_session() -> AsyncIterator[AsyncSession]:
        async with session_factory() as session:
            yield session

    app.dependency_overrides[get_session] = _override_get_session
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def auth_headers(client: TestClient) -> dict[str, dict[str, str]]:
    """Registra customer y driver y devuelve headers Bearer para cada uno."""

    def _register(role: str, email_suffix: str) -> dict[str, str]:
        email = f"user{email_suffix}@example.com"
        resp = client.post(
            "/api/v1/auth/register",
            json={
                "email": email,
                "full_name": f"User {role}",
                "password": "password123",
                "role": role,
            },
        )
        assert resp.status_code == 201, resp.text
        login = client.post("/api/v1/auth/login", json={"email": email, "password": "password123"})
        assert login.status_code == 200, login.text
        token = login.json()["access_token"]
        return {"Authorization": f"Bearer {token}"}

    return {
        "customer": _register("CUSTOMER", "1"),
        "driver": _register("DRIVER", "2"),
    }

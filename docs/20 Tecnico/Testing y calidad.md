---
tags: [tecnico, testing, calidad]
status: borrador
date: 2026-09-08
---

# Testing y calidad

> Estrategia de pruebas y herramientas de calidad del proyecto.

## Backend (pytest + httpx)

| Capa                | Qué se prueba                                   | Herramientas                    |
| ------------------- | ----------------------------------------------- | ------------------------------- |
| Unit               | Servicios de dominio (transiciones de estado, cálculo total) | pytest, `pytest-asyncio` |
| API (integration)  | Endpoints con DB real (Postgres en Docker)      | `httpx.AsyncClient` + ASGITransport, fixture de sesión |
| Auth               | Registro/login/refresh/logout, roles, rate limit| pytest + freeze_time            |
| Realtime           | Conexión WS, auth en handshake, eventos por room, heartbeat y regresión "N WS no bloquean el REST"; **el customer recibe `order.updated` cuando el driver actúa** | `fastapi.testclient` con WS |
| Storage            | S3Service contra MinIO en tests (upload/get), presign + round-trip PUT→GET | MinIO en runner / mocks |

Setup: DB de test dedicada, migraciones Alembic aplicadas al inicio, `pytest.ini` con `asyncio_mode=auto`, cobertura objetivo ≥ 80% en dominio.

## Apps Flutter

| Capa                | Qué se prueba                                   |
| ------------------- | ----------------------------------------------- |
| Widget tests        | Pantallas con providers sobrescritos (fake repos) |
| Unit tests          | Estados/notifiers, máquinas de estado           |
| Integration (opcional) | Flujo login → crear pedido contra backend real |

Comando: `flutter test`. Análisis: `flutter analyze`. Formato: `dart format`.

## Herramientas de calidad

| Herramienta | Uso                                    | Comando             |
| ----------- | -------------------------------------- | ------------------- |
| ruff        | Lint + formato Python                  | `ruff check .` / `ruff format .` |
| mypy        | Type checking                          | `mypy app`          |
| pytest      | Tests backend                          | `pytest`            |
| alembic     | Migraciones revisadas                  | `alembic upgrade head` |
| dart/flutter| Lint + tests apps                      | `flutter analyze` / `flutter test` |
| pre-commit  | Hooks (ruff, mypy, format)             | `pre-commit run --all-files` |

## CI (GitHub Actions)

- Backend: job con uv → `ruff` → `mypy` → `pytest` (Postgres service container) → build imagen Docker.
- Apps: `flutter analyze` + `flutter test`.
- Infra: `terraform validate` (+ `plan` con OIDC si hay credenciales), docker build.
- Ver [[Docker y despliegue]] y [[Arquitectura AWS]].

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Setup y herramientas]], [[Convenciones git y commits]], [[API Autenticacion]], [[API Pedidos y estados]]
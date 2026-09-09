---
tags: [tecnico, api, backend, implementacion]
status: implementado
date: 2026-09-09
---

# API Implementada (Fase 2)

> Estado real del backend tras la Fase 2. Se apoya en los ADRs [[ADR-005 Realtime WebSocket vs SSE]], [[ADR-004 Estado de las apps]] y las notas de diseño.

## Endpoints

### Auth (`/api/v1/auth`)
| Método | Ruta | Descripción |
| ------ | ---- | ----------- |
| POST | `/register` | Crea usuario (CUSTOMER/DRIVER) |
| POST | `/login` | Access + refresh tokens |
| POST | `/refresh` | Rota refresh token (one-time, revoca el anterior) |
| POST | `/logout` | Revoca el refresh token |
| GET | `/me` | Perfil del usuario autenticado |

### Pedidos (`/api/v1/orders`)
| Método | Ruta | Rol |
| ------ | ---- | --- |
| POST | `/` | Customer: crear pedido |
| GET | `/` | Customer/Driver: listar los míos |
| GET | `/available` | Driver: pedidos PENDING |
| GET | `/mine` | Driver: mis asignados |
| GET | `/{id}` | Detalle (con items + historial) |
| POST | `/{id}/cancel` | Customer: cancelar si PENDING |
| POST | `/{id}/accept` | Driver: aceptar |
| POST | `/{id}/status` | Driver asignado: PICKED_UP/DELIVERED |

### Uploads (`/api/v1/uploads`)
| Método | Ruta | Descripción |
| ------ | ---- | ----------- |
| POST | `/images` | Sube imagen a S3/MinIO (máx 5 MB, jpeg/png/webp) |

### Realtime
| Ruta | Descripción |
| ---- | ----------- |
| `WS /ws/orders?token=<jwt>` | Rooms `user:{id}` y `orders:available` (drivers) |

## Decisiones implementadas

- **Refresh tokens**: se guarda hash **SHA-256** del token (determinista, permite búsqueda/rotación), no bcrypt. Ver [[Modelo de datos]] y [[API Autenticacion]].
- **Máquina de estados**: validada en el servicio de dominio (`VALID_TRANSITIONS`), con historial en `order_status_history`.
- **WebSocket**: `ConnectionManager` con rooms; eventos `order.created` y `order.updated`. Ver [[Realtime]].
- **StorageService**: única implementación S3 (boto3); MinIO en dev, AWS S3 en prod vía `S3_ENDPOINT_URL`. Ver [[StorageService]].
- **Rate limiting**: slowapi con límite por IP (configurable `RATE_LIMIT_PER_MINUTE`).
- **Logging**: structlog con renderer JSON.

## Calidad

- `pytest`: 22 tests verdes (auth, pedidos, WS, uploads).
- `ruff check`, `ruff format --check`, `mypy app`: sin errores.
- Swagger disponible en `/docs`.

## Notas de entorno (dev)

- PostgreSQL del contenedor en **puerto 5434** (5432 y 5433 los ocupa un Postgres local de Windows — ver [[Setup y herramientas]]).
- MinIO en `localhost:9000` (consola `:9001`, minioadmin).
- Migración inicial: `alembic upgrade head` (5 tablas).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[API Autenticacion]], [[API Pedidos y estados]], [[Realtime]], [[StorageService]], [[Modelo de datos]], [[Testing y calidad]]
- **Repo:** `backend/`
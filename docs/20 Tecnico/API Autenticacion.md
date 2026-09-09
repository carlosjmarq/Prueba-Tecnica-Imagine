---
tags: [tecnico, api, auth, jwt]
status: borrador
date: 2026-09-08
---

# API Autenticacion

> Autenticación JWT para Customer y Driver: access tokens cortos + refresh tokens rotativos + rate limiting.

## Flujo

```
POST /api/v1/auth/register   → crea usuario (role CUSTOMER | DRIVER)
POST /api/v1/auth/login      → { access_token, refresh_token, user }
POST /api/v1/auth/refresh    → rota refresh token → { access_token, refresh_token }
POST /api/v1/auth/logout     → revoca refresh token
GET  /api/v1/users/me        → perfil del usuario autenticado
```

## JWT

- **Access token**: TTL 15 min, claims `sub` (user id), `role`, `type=access`, `jti`.
- **Refresh token**: TTL 7 días, opaco (UUID aleatorio); en BD se guarda solo su **hash** (ver [[Modelo de datos]] → `refresh_tokens`). Rotación en cada uso (one-time use), revocable en logout.
- Firma: HS256 con `SECRET_KEY` de `.env` (en AWS: Secrets Manager/SSM, ver [[Arquitectura AWS]]).
- Dependencias: `pyjwt` o `python-jose` + `bcrypt` para hash de contraseñas.

## Endpoints públicos vs protegidos

| Endpoint                       | Auth          |
| ------------------------------ | ------------- |
| `POST /auth/register`          | Público       |
| `POST /auth/login`             | Público       |
| `POST /auth/refresh`           | Refresh token |
| `/orders/**` (customer)        | Access JWT + rol `CUSTOMER` |
| `/orders/available` / aceptar / estado (driver) | Access JWT + rol `DRIVER` |

La dependencia FastAPI `get_current_user` valida firma, expiración y rol; devuelve 401/403.

## Rate limiting

- SlowAPI (en memoria) o Redis para producción.
- Límites: login/register 5–10 req/min por IP; API general 60–120 req/min.
- Headers `X-RateLimit-*`; respuesta 429 con `Retry-After`.

## Seguridad

- Contraseñas: bcrypt con salt (cost 12+).
- No guardar tokens en claro en BD (solo hash del refresh).
- CORS restringido; HTTPS obligatorio en producción (ALB).
- Logging estructurado de eventos de auth (login fallido, refresh rechazado) → [[CloudWatch y logging]].

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Modelo de datos]], [[API Pedidos y estados]]
- **ADR:** [[ADR-001 Eleccion de stack]]
- **Repo:** `backend` (`app/api/routes/auth.py`, `app/core/security.py`)
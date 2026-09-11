---
tags: [tecnico, datos, seed, mock]
status: vigente
date: 2026-09-11
---

# Seed de datos (mock data)

> Datos de demostración para desarrollo y pruebas, sembrados como **migración Alembic de datos** (`backend/alembic/versions/9f8e7d6c5b4a_seed_mock_data.py`). Es una migración de DATOS (no de esquema) e **idempotente**.

## Qué siembra

| Entidad | Contenido |
| ------- | --------- |
| Usuarios | `customer1@example.com`, `customer2@example.com`, `driver1@example.com`, `driver2@example.com` |
| Password | `password123` (hash bcrypt determinista embebido) |
| Pedidos | 6 pedidos que cubren todos los estados: `PENDING`×2 (disponibles), `ACCEPTED`, `PICKED_UP`, `DELIVERED` (con `delivery_proof_key`), `CANCELLED` |
| Ítems | 12 `order_items` (nombres, precios, cantidades; `image_key` en `NULL`) |
| Historial | 13 `order_status_history` coherentes con `VALID_TRANSITIONS` (último `to_status` = `orders.status`, actores correctos) |

Los UUIDs son fijos, así `downgrade()` borra solo lo sembrado (por emails/IDs) sin tocar datos reales.

## Cómo ejecutarlo

### Bajo demanda (script)

```powershell
# Desarrollo: BD local (backend/.env -> :5434)
powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env dev

# Producción (entorno AWS desplegado): pide confirmación
powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env prod
powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env prod -Force

# Refrescar los datos (downgrade + upgrade): útil para reponer pedidos PENDING
powershell -ExecutionPolicy Bypass -File scripts/seed.ps1 -Env prod -Reseed -Force
```

En prod se ejecuta vía SSM (`docker exec api alembic upgrade head`) sobre la instancia del ASG, igual que las migraciones de esquema. **Requiere la imagen desplegada que incluya la migración** (el CD reconstruye la imagen al tocar `backend/**`); si la instancia aún corre la imagen vieja, ejecutar antes `deploy-aws.ps1 refresh`.

### Como parte del deploy (`scripts/deploy-aws.ps1`)

- `deploy` incluye la etapa **`seed`** por defecto (después de `migrate`).
- **`-NoSeed`** la deshabilita: además, `migrate` sube solo hasta el head de esquema (`a1b2c3d4e5f6`, el `down_revision` del seed) → no se siembra mock data.
- `seed` como comando independiente: `pwsh -File scripts/deploy-aws.ps1 seed`.

## Comportamiento

- **Idempotente**: `alembic upgrade head` solo aplica la migración una vez (queda en `alembic_version`); si se re-ejecuta no duplica datos.
- **Dev y CI se siembran solos**: `dev.ps1` y `conftest.py` ejecutan `alembic upgrade head`; los tests truncan las tablas entre test (sin conflictos).
- **Downgrade**: `alembic downgrade a1b2c3d4e5f6` limpia únicamente las filas de seed.
- **Pedidos PENDING y la Lambda de timeout**: los pedidos `PENDING` del seed nacen con timestamp **actual** para que estén disponibles; aun así, la Lambda `order-timeout-canceller` (timeout 15 min, ver [[Lambda]]) los cancela pasados ~15 min. Para reponerlos, re-sembrar con `-Reseed`.

## Verificado en producción (2026-09-11)

- `seed.ps1 -Env prod` aplicado vía SSM; login de `customer1@example.com`/`customer2@example.com` (`password123`) OK.
- Pedidos por cliente: customer1 → `PENDING`, `ACCEPTED`, `PICKED_UP`; customer2 → `PENDING`, `CANCELLED`, `DELIVERED`.
- `deploy-aws.ps1 check` sin drift tras refrescar el baseline con `state`.

## Baseline de `check`

Tras sembrar el entorno AWS, `alembic_version` pasa a incluir `9f8e7d6c5b4a`. Refrescar el baseline con `deploy-aws.ps1 state`. Un deploy `-NoSeed` mostrará drift esperado en `check` (falta la revisión de seed).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Modelo de datos]], [[API Autenticacion]], [[Deploy AWS automatizado]], [[Testing y calidad]]
- **Repo:** `backend/alembic/versions/9f8e7d6c5b4a_seed_mock_data.py`, `scripts/seed.ps1`, `scripts/deploy-aws.ps1`
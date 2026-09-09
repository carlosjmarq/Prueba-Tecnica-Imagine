---
tags: [tecnico, api, pedidos, estados]
status: borrador
date: 2026-09-08
---

# API Pedidos y estados

> Ciclo de vida de pedidos: máquina de estados, endpoints por rol y eventos realtime.

## Máquina de estados

```
PENDING ──acepta driver──▶ ACCEPTED ──recoge──▶ PICKED_UP ──entrega──▶ DELIVERED
   │
   └──cancela customer──▶ CANCELLED
```

- `PENDING`: visible para todos los drivers disponibles.
- `ACCEPTED`: asignado a un driver (`driver_id` set). Deja de ser "disponible".
- `PICKED_UP` → `DELIVERED`: solo el driver asignado puede transicionar.
- `CANCELLED`: solo desde `PENDING` y por el customer o admin.
- Cada transición se persiste en `order_status_history` y **emite un evento realtime** ([[Realtime]]).

## Endpoints

### Customer (rol `CUSTOMER`)

| Método | Ruta                         | Descripción                            |
| ------ | ---------------------------- | -------------------------------------- |
| POST   | `/api/v1/orders`             | Crear pedido (items, direcciones)      |
| GET    | `/api/v1/orders`             | Listar mis pedidos (paginado)          |
| GET    | `/api/v1/orders/{id}`        | Detalle de pedido (con historial)      |
| POST   | `/api/v1/orders/{id}/cancel` | Cancelar si `PENDING`                  |

### Driver (rol `DRIVER`)

| Método | Ruta                            | Descripción                           |
| ------ | ------------------------------- | ------------------------------------- |
| GET    | `/api/v1/orders/available`      | Pedidos `PENDING` disponibles         |
| POST   | `/api/v1/orders/{id}/accept`    | Aceptar pedido (→ `ACCEPTED`)         |
| POST   | `/api/v1/orders/{id}/status`    | Actualizar estado (`PICKED_UP`, `DELIVERED`) |
| GET    | `/api/v1/orders/mine`           | Pedidos asignados a mí                |

## Esquemas Pydantic (resumen)

```python
class OrderCreate(BaseModel):
    pickup_address: str
    delivery_address: str
    notes: str | None = None
    items: list[OrderItemCreate]  # name, price, quantity, image_id?

class OrderRead(BaseModel):
    id: UUID
    status: OrderStatus
    customer_id: UUID
    driver_id: UUID | None
    total_amount: Decimal
    items: list[OrderItemRead]
    history: list[StatusHistoryRead]  # en detalle
    created_at: datetime
```

## Concurrencia

- Aceptar un pedido es una operación atómica: `UPDATE ... WHERE status='PENDING'` (optimistic lock por estado) o `SELECT FOR UPDATE`. Dos drivers no pueden aceptar el mismo pedido.
- Reintentos de WebSocket tras reconexión (ver [[Realtime]]).

## Relaciones

- **MOC:** [[00 Inbox/MOC]]
- **Relacionada con:** [[Modelo de datos]], [[API Autenticacion]], [[Realtime]]
- **Repo:** `backend` (`app/api/routes/orders.py`, `app/services/orders.py`)
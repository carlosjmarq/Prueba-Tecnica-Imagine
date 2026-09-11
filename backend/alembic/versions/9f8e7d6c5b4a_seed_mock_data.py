"""seed mock data

Siembra datos de demostracion (usuarios, pedidos, items e historial) en
desarrollo y produccion bajo demanda.

Revision ID: 9f8e7d6c5b4a
Revises: a1b2c3d4e5f6
Create Date: 2026-09-11

Nota: es una migracion de DATOS, no de esquema. Es idempotente: si ya existen
los emails de seed, no hace nada (no falla por unique constraints). Los UUIDs
son fijos para que downgrade() pueda limpiar solo lo sembrado.

Credenciales de los usuarios de demo: password "password123" (hash bcrypt
determinista embebido).
"""

from collections.abc import Sequence
from datetime import UTC, datetime

import sqlalchemy as sa
from alembic import op

revision: str = "9f8e7d6c5b4a"
down_revision: str | None = "a1b2c3d4e5f6"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

PASSWORD_HASH = "$2b$12$1FKyTbl8krMFwfTQx56RjeNBE.xrNK8pDjsMxu6.iXaRjT.ZOcjPK"  # password123

SEED_EMAILS = (
    "customer1@example.com",
    "customer2@example.com",
    "driver1@example.com",
    "driver2@example.com",
)

# ---------------------------------------------------------------------------
# Datos
# ---------------------------------------------------------------------------

USERS = [
    {
        "id": "11111111-1111-1111-1111-111111111111",
        "email": "customer1@example.com",
        "full_name": "Ana Garcia",
        "role": "CUSTOMER",
        "created_at": "2026-09-08T10:00:00+00:00",
    },
    {
        "id": "22222222-2222-2222-2222-222222222222",
        "email": "customer2@example.com",
        "full_name": "Luis Perez",
        "role": "CUSTOMER",
        "created_at": "2026-09-08T10:00:00+00:00",
    },
    {
        "id": "33333333-3333-3333-3333-333333333333",
        "email": "driver1@example.com",
        "full_name": "Marta Ruiz",
        "role": "DRIVER",
        "created_at": "2026-09-08T10:00:00+00:00",
    },
    {
        "id": "44444444-4444-4444-4444-444444444444",
        "email": "driver2@example.com",
        "full_name": "Jorge Diaz",
        "role": "DRIVER",
        "created_at": "2026-09-08T10:00:00+00:00",
    },
]

ORDERS = [
    {
        "id": "55000000-0000-0000-0000-000000000001",
        "customer_id": "11111111-1111-1111-1111-111111111111",
        "driver_id": None,
        "status": "PENDING",
        "pickup_address": "Calle Mayor 10, Madrid",
        "delivery_address": "Av. de la Constitucion 45, Sevilla",
        "total_amount": "11.50",
        "notes": "Entregar en porteria",
        "created_at": "2026-09-09T10:00:00+00:00",
    },
    {
        "id": "55000000-0000-0000-0000-000000000002",
        "customer_id": "11111111-1111-1111-1111-111111111111",
        "driver_id": "33333333-3333-3333-3333-333333333333",
        "status": "ACCEPTED",
        "pickup_address": "Mercado Central, Valencia",
        "delivery_address": "Calle Serrano 22, Madrid",
        "total_amount": "12.00",
        "notes": None,
        "created_at": "2026-09-09T11:00:00+00:00",
    },
    {
        "id": "55000000-0000-0000-0000-000000000003",
        "customer_id": "11111111-1111-1111-1111-111111111111",
        "driver_id": "33333333-3333-3333-3333-333333333333",
        "status": "PICKED_UP",
        "pickup_address": "La Pampa 88, Buenos Aires",
        "delivery_address": "Av. Corrientes 1200, Buenos Aires",
        "total_amount": "21.75",
        "notes": "Llamar al llegar",
        "created_at": "2026-09-09T12:00:00+00:00",
    },
    {
        "id": "55000000-0000-0000-0000-000000000004",
        "customer_id": "22222222-2222-2222-2222-222222222222",
        "driver_id": "44444444-4444-4444-4444-444444444444",
        "status": "DELIVERED",
        "pickup_address": "Av. Amazonas N36-45, Quito",
        "delivery_address": "Calle de las Flores 3, Quito",
        "total_amount": "23.00",
        "notes": "Comprobante adjunto",
        "delivery_proof_key": "orders/55000000-0000-0000-0000-000000000004/proof.webp",
        "created_at": "2026-09-09T13:00:00+00:00",
    },
    {
        "id": "55000000-0000-0000-0000-000000000005",
        "customer_id": "22222222-2222-2222-2222-222222222222",
        "driver_id": None,
        "status": "CANCELLED",
        "pickup_address": "Plaza del Sol 1, Madrid",
        "delivery_address": "Gran Via 55, Madrid",
        "total_amount": "6.90",
        "notes": "Cancelado por el cliente",
        "created_at": "2026-09-09T14:00:00+00:00",
    },
    {
        "id": "55000000-0000-0000-0000-000000000006",
        "customer_id": "22222222-2222-2222-2222-222222222222",
        "driver_id": None,
        "status": "PENDING",
        "pickup_address": "Restaurante La Rueda, Bogota",
        "delivery_address": "Cra 7 # 24-89, Bogota",
        "total_amount": "16.40",
        "notes": None,
        "created_at": "2026-09-09T15:00:00+00:00",
    },
]

ITEMS = [
    # Orden 1
    {
        "id": "66000000-0000-0000-0000-000000000001",
        "order_id": "55000000-0000-0000-0000-000000000001",
        "name": "Ensalada Cesar",
        "price": "8.50",
        "quantity": 1,
    },
    {
        "id": "66000000-0000-0000-0000-000000000002",
        "order_id": "55000000-0000-0000-0000-000000000001",
        "name": "Agua mineral",
        "price": "1.50",
        "quantity": 2,
    },
    # Orden 2
    {
        "id": "66000000-0000-0000-0000-000000000003",
        "order_id": "55000000-0000-0000-0000-000000000002",
        "name": "Pizza margarita",
        "price": "12.00",
        "quantity": 1,
    },
    # Orden 3
    {
        "id": "66000000-0000-0000-0000-000000000004",
        "order_id": "55000000-0000-0000-0000-000000000003",
        "name": "Hamburguesa doble",
        "price": "10.75",
        "quantity": 1,
    },
    {
        "id": "66000000-0000-0000-0000-000000000005",
        "order_id": "55000000-0000-0000-0000-000000000003",
        "name": "Papas fritas",
        "price": "3.50",
        "quantity": 2,
    },
    {
        "id": "66000000-0000-0000-0000-000000000006",
        "order_id": "55000000-0000-0000-0000-000000000003",
        "name": "Refresco",
        "price": "2.00",
        "quantity": 2,
    },
    # Orden 4
    {
        "id": "66000000-0000-0000-0000-000000000007",
        "order_id": "55000000-0000-0000-0000-000000000004",
        "name": "Sushi mixto",
        "price": "18.00",
        "quantity": 1,
    },
    {
        "id": "66000000-0000-0000-0000-000000000008",
        "order_id": "55000000-0000-0000-0000-000000000004",
        "name": "Te verde",
        "price": "2.50",
        "quantity": 2,
    },
    # Orden 5
    {
        "id": "66000000-0000-0000-0000-000000000009",
        "order_id": "55000000-0000-0000-0000-000000000005",
        "name": "Cafe americano",
        "price": "2.90",
        "quantity": 1,
    },
    {
        "id": "66000000-0000-0000-0000-000000000010",
        "order_id": "55000000-0000-0000-0000-000000000005",
        "name": "Croissant",
        "price": "2.00",
        "quantity": 2,
    },
    # Orden 6
    {
        "id": "66000000-0000-0000-0000-000000000011",
        "order_id": "55000000-0000-0000-0000-000000000006",
        "name": "Arepa de queso",
        "price": "4.20",
        "quantity": 2,
    },
    {
        "id": "66000000-0000-0000-0000-000000000012",
        "order_id": "55000000-0000-0000-0000-000000000006",
        "name": "Jugo natural",
        "price": "4.00",
        "quantity": 2,
    },
]

# Historial consistente: el ultimo to_status coincide con orders.status.
HISTORY = [
    # Orden 1 -> PENDING
    {
        "id": "77000000-0000-0000-0000-000000000001",
        "order_id": "55000000-0000-0000-0000-000000000001",
        "from_status": None,
        "to_status": "PENDING",
        "actor_id": "11111111-1111-1111-1111-111111111111",
        "changed_at": "2026-09-09T10:00:00+00:00",
    },
    # Orden 2 -> PENDING -> ACCEPTED
    {
        "id": "77000000-0000-0000-0000-000000000002",
        "order_id": "55000000-0000-0000-0000-000000000002",
        "from_status": None,
        "to_status": "PENDING",
        "actor_id": "11111111-1111-1111-1111-111111111111",
        "changed_at": "2026-09-09T11:00:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000003",
        "order_id": "55000000-0000-0000-0000-000000000002",
        "from_status": "PENDING",
        "to_status": "ACCEPTED",
        "actor_id": "33333333-3333-3333-3333-333333333333",
        "changed_at": "2026-09-09T11:15:00+00:00",
    },
    # Orden 3 -> PENDING -> ACCEPTED -> PICKED_UP
    {
        "id": "77000000-0000-0000-0000-000000000004",
        "order_id": "55000000-0000-0000-0000-000000000003",
        "from_status": None,
        "to_status": "PENDING",
        "actor_id": "11111111-1111-1111-1111-111111111111",
        "changed_at": "2026-09-09T12:00:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000005",
        "order_id": "55000000-0000-0000-0000-000000000003",
        "from_status": "PENDING",
        "to_status": "ACCEPTED",
        "actor_id": "33333333-3333-3333-3333-333333333333",
        "changed_at": "2026-09-09T12:10:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000006",
        "order_id": "55000000-0000-0000-0000-000000000003",
        "from_status": "ACCEPTED",
        "to_status": "PICKED_UP",
        "actor_id": "33333333-3333-3333-3333-333333333333",
        "changed_at": "2026-09-09T12:30:00+00:00",
    },
    # Orden 4 -> PENDING -> ACCEPTED -> PICKED_UP -> DELIVERED
    {
        "id": "77000000-0000-0000-0000-000000000007",
        "order_id": "55000000-0000-0000-0000-000000000004",
        "from_status": None,
        "to_status": "PENDING",
        "actor_id": "22222222-2222-2222-2222-222222222222",
        "changed_at": "2026-09-09T13:00:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000008",
        "order_id": "55000000-0000-0000-0000-000000000004",
        "from_status": "PENDING",
        "to_status": "ACCEPTED",
        "actor_id": "44444444-4444-4444-4444-444444444444",
        "changed_at": "2026-09-09T13:05:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000009",
        "order_id": "55000000-0000-0000-0000-000000000004",
        "from_status": "ACCEPTED",
        "to_status": "PICKED_UP",
        "actor_id": "44444444-4444-4444-4444-444444444444",
        "changed_at": "2026-09-09T13:20:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000010",
        "order_id": "55000000-0000-0000-0000-000000000004",
        "from_status": "PICKED_UP",
        "to_status": "DELIVERED",
        "actor_id": "44444444-4444-4444-4444-444444444444",
        "changed_at": "2026-09-09T13:45:00+00:00",
    },
    # Orden 5 -> PENDING -> CANCELLED
    {
        "id": "77000000-0000-0000-0000-000000000011",
        "order_id": "55000000-0000-0000-0000-000000000005",
        "from_status": None,
        "to_status": "PENDING",
        "actor_id": "22222222-2222-2222-2222-222222222222",
        "changed_at": "2026-09-09T14:00:00+00:00",
    },
    {
        "id": "77000000-0000-0000-0000-000000000012",
        "order_id": "55000000-0000-0000-0000-000000000005",
        "from_status": "PENDING",
        "to_status": "CANCELLED",
        "actor_id": "22222222-2222-2222-2222-222222222222",
        "changed_at": "2026-09-09T14:10:00+00:00",
    },
    # Orden 6 -> PENDING
    {
        "id": "77000000-0000-0000-0000-000000000013",
        "order_id": "55000000-0000-0000-0000-000000000006",
        "from_status": None,
        "to_status": "PENDING",
        "actor_id": "22222222-2222-2222-2222-222222222222",
        "changed_at": "2026-09-09T15:00:00+00:00",
    },
]

SEED_ORDER_IDS = [o["id"] for o in ORDERS]
SEED_USER_IDS = [u["id"] for u in USERS]


def _dt(value: str) -> datetime:
    return datetime.fromisoformat(value).astimezone(UTC)


def _users_table() -> sa.Table:
    return sa.table(
        "users",
        sa.column("id", sa.Uuid()),
        sa.column("email", sa.String()),
        sa.column("full_name", sa.String()),
        sa.column("password_hash", sa.String()),
        sa.column("role", sa.Enum("CUSTOMER", "DRIVER", name="user_role")),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
    )


def _orders_table() -> sa.Table:
    return sa.table(
        "orders",
        sa.column("id", sa.Uuid()),
        sa.column("customer_id", sa.Uuid()),
        sa.column("driver_id", sa.Uuid()),
        sa.column(
            "status",
            sa.Enum(
                "PENDING", "ACCEPTED", "PICKED_UP", "DELIVERED", "CANCELLED", name="order_status"
            ),
        ),
        sa.column("pickup_address", sa.Text()),
        sa.column("delivery_address", sa.Text()),
        sa.column("total_amount", sa.Numeric(12, 2)),
        sa.column("notes", sa.Text()),
        sa.column("delivery_proof_key", sa.String()),
        sa.column("created_at", sa.DateTime(timezone=True)),
        sa.column("updated_at", sa.DateTime(timezone=True)),
    )


def _items_table() -> sa.Table:
    return sa.table(
        "order_items",
        sa.column("id", sa.Uuid()),
        sa.column("order_id", sa.Uuid()),
        sa.column("name", sa.String()),
        sa.column("price", sa.Numeric(12, 2)),
        sa.column("quantity", sa.Integer()),
        sa.column("image_key", sa.String()),
    )


def _history_table() -> sa.Table:
    return sa.table(
        "order_status_history",
        sa.column("id", sa.Uuid()),
        sa.column("order_id", sa.Uuid()),
        sa.column(
            "from_status",
            sa.Enum(
                "PENDING", "ACCEPTED", "PICKED_UP", "DELIVERED", "CANCELLED", name="order_status"
            ),
        ),
        sa.column(
            "to_status",
            sa.Enum(
                "PENDING", "ACCEPTED", "PICKED_UP", "DELIVERED", "CANCELLED", name="order_status"
            ),
        ),
        sa.column("actor_id", sa.Uuid()),
        sa.column("changed_at", sa.DateTime(timezone=True)),
    )


def upgrade() -> None:
    conn = op.get_bind()

    already = conn.execute(
        sa.text("SELECT 1 FROM users WHERE email IN (:e1, :e2, :e3, :e4) LIMIT 1"),
        {"e1": SEED_EMAILS[0], "e2": SEED_EMAILS[1], "e3": SEED_EMAILS[2], "e4": SEED_EMAILS[3]},
    ).scalar()
    if already:
        return

    op.bulk_insert(
        _users_table(),
        [
            {
                **u,
                "password_hash": PASSWORD_HASH,
                "created_at": _dt(u["created_at"]),
                "updated_at": _dt(u["created_at"]),
            }
            for u in USERS
        ],
    )
    op.bulk_insert(
        _orders_table(),
        [
            {
                **o,
                "delivery_proof_key": o.get("delivery_proof_key"),
                "created_at": _dt(o["created_at"]),
                "updated_at": _dt(o["created_at"]),
            }
            for o in ORDERS
        ],
    )
    op.bulk_insert(_items_table(), ITEMS)
    op.bulk_insert(
        _history_table(),
        [{**h, "changed_at": _dt(h["changed_at"])} for h in HISTORY],
    )


def _ids_param(ids: list[str]) -> sa.bindparam:
    return sa.bindparam("ids", value=ids, expanding=True, type_=sa.Uuid())


def downgrade() -> None:
    conn = op.get_bind()
    order_ids = list(SEED_ORDER_IDS)
    user_ids = list(SEED_USER_IDS)

    conn.execute(
        sa.text("DELETE FROM order_status_history WHERE order_id IN :ids").bindparams(
            _ids_param(order_ids)
        )
    )
    conn.execute(
        sa.text("DELETE FROM order_items WHERE order_id IN :ids").bindparams(_ids_param(order_ids))
    )
    conn.execute(sa.text("DELETE FROM orders WHERE id IN :ids").bindparams(_ids_param(order_ids)))
    conn.execute(
        sa.text("DELETE FROM refresh_tokens WHERE user_id IN :ids").bindparams(_ids_param(user_ids))
    )
    conn.execute(sa.text("DELETE FROM users WHERE id IN :ids").bindparams(_ids_param(user_ids)))

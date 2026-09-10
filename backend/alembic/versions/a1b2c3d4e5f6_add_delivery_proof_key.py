"""add delivery proof key

Revision ID: a1b2c3d4e5f6
Revises: 54681dad5c18
Create Date: 2026-09-10 00:00:00.000000

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "a1b2c3d4e5f6"
down_revision: str | None = "54681dad5c18"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "orders",
        sa.Column("delivery_proof_key", sa.String(length=255), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("orders", "delivery_proof_key")

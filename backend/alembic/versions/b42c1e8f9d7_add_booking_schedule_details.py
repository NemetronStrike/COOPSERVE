"""add booking schedule details and accepted status

Revision ID: b42c1e8f9d7
Revises: f691199e987a
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b42c1e8f9d7"
down_revision: Union[str, None] = "f691199e987a"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("bookings", sa.Column("scheduled_end_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("bookings", sa.Column("service_address", sa.String(length=500), nullable=True))
    op.execute("ALTER TYPE bookingstatus ADD VALUE IF NOT EXISTS 'accepted'")


def downgrade() -> None:
    op.drop_column("bookings", "service_address")
    op.drop_column("bookings", "scheduled_end_at")
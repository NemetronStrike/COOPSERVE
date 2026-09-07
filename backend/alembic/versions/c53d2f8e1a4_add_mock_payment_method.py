"""add mock payment method

Revision ID: c53d2f8e1a4
Revises: b42c1e8f9d7
"""
from typing import Sequence, Union

from alembic import op


revision: str = "c53d2f8e1a4"
down_revision: Union[str, None] = "b42c1e8f9d7"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute("ALTER TYPE paymentmethod ADD VALUE IF NOT EXISTS 'mock'")


def downgrade() -> None:
    pass
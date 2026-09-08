"""add complaint classification

Revision ID: e75f280a3a2b
Revises: f691199e987a
Create Date: 2026-09-08 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e75f280a3a2b'
down_revision: Union[str, None] = 'd64e8f2a1b5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add new values to ComplaintCategory ENUM
    op.execute("ALTER TYPE complaintcategory ADD VALUE IF NOT EXISTS 'late_arrival'")
    op.execute("ALTER TYPE complaintcategory ADD VALUE IF NOT EXISTS 'pricing_payment'")
    op.execute("ALTER TYPE complaintcategory ADD VALUE IF NOT EXISTS 'safety'")
    op.execute("ALTER TYPE complaintcategory ADD VALUE IF NOT EXISTS 'property_damage'")
    op.execute("ALTER TYPE complaintcategory ADD VALUE IF NOT EXISTS 'booking_issue'")

    # Create new ENUM types
    op.execute("CREATE TYPE complaintseverity AS ENUM ('low', 'medium', 'high', 'critical')")
    op.execute("CREATE TYPE complainturgency AS ENUM ('low', 'medium', 'high', 'critical')")

    # Add new columns to complaints table
    op.add_column('complaints', sa.Column('severity', sa.Enum('low', 'medium', 'high', 'critical', name='complaintseverity'), nullable=True))
    op.add_column('complaints', sa.Column('urgency', sa.Enum('low', 'medium', 'high', 'critical', name='complainturgency'), nullable=True))
    op.add_column('complaints', sa.Column('summary', sa.Text(), nullable=True))
    op.add_column('complaints', sa.Column('suggested_action', sa.Text(), nullable=True))
    op.add_column('complaints', sa.Column('classification_source', sa.String(length=50), nullable=True))


def downgrade() -> None:
    op.drop_column('complaints', 'classification_source')
    op.drop_column('complaints', 'suggested_action')
    op.drop_column('complaints', 'summary')
    op.drop_column('complaints', 'urgency')
    op.drop_column('complaints', 'severity')
    
    op.execute("DROP TYPE complainturgency")
    op.execute("DROP TYPE complaintseverity")

# Import all models here so that Base.metadata is fully populated
# when Alembic generates or applies migrations.

from app.models.base import Base  # noqa: F401
from app.models.user import User, Customer, Worker, Admin  # noqa: F401
from app.models.worker import Skill, WorkerSkill, WorkerVerification, Availability  # noqa: F401
from app.models.service import Service  # noqa: F401
from app.models.location import Location  # noqa: F401
from app.models.booking import Booking  # noqa: F401
from app.models.payment import Payment, Invoice  # noqa: F401
from app.models.rating import Rating, Complaint  # noqa: F401

__all__ = [
    "Base",
    "User", "Customer", "Worker", "Admin",
    "Skill", "WorkerSkill", "WorkerVerification", "Availability",
    "Service",
    "Location",
    "Booking",
    "Payment", "Invoice",
    "Rating", "Complaint",
]

import enum
from datetime import datetime

from sqlalchemy import CheckConstraint, DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class ComplaintStatus(str, enum.Enum):
    open = "open"
    under_review = "under_review"
    resolved = "resolved"
    closed = "closed"


class ComplaintCategory(str, enum.Enum):
    service_quality = "service_quality"
    worker_behaviour = "worker_behaviour"
    late_arrival = "late_arrival"
    pricing_payment = "pricing_payment"
    safety = "safety"
    property_damage = "property_damage"
    booking_issue = "booking_issue"
    no_show = "no_show"
    other = "other"


class ComplaintSeverity(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class ComplaintUrgency(str, enum.Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"


class Rating(Base):
    __tablename__ = "ratings"
    __table_args__ = (
        CheckConstraint("rating_value >= 1 AND rating_value <= 5", name="ck_rating_value"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    booking_id: Mapped[int] = mapped_column(
        ForeignKey("bookings.id", ondelete="RESTRICT"), unique=True, nullable=False
    )
    customer_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    worker_id: Mapped[int] = mapped_column(
        ForeignKey("workers.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    rating_value: Mapped[int] = mapped_column(Integer, nullable=False)
    review: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    booking: Mapped["Booking"] = relationship(back_populates="rating")
    customer: Mapped["Customer"] = relationship(back_populates="ratings")
    worker: Mapped["Worker"] = relationship(back_populates="ratings")


class Complaint(Base):
    __tablename__ = "complaints"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    booking_id: Mapped[int] = mapped_column(
        ForeignKey("bookings.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    complainant_id: Mapped[int] = mapped_column(
        ForeignKey("customers.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    category: Mapped[ComplaintCategory] = mapped_column(
        Enum(ComplaintCategory), nullable=False
    )
    description: Mapped[str] = mapped_column(Text, nullable=False)
    severity: Mapped[ComplaintSeverity | None] = mapped_column(Enum(ComplaintSeverity))
    urgency: Mapped[ComplaintUrgency | None] = mapped_column(Enum(ComplaintUrgency))
    summary: Mapped[str | None] = mapped_column(Text)
    suggested_action: Mapped[str | None] = mapped_column(Text)
    classification_source: Mapped[str | None] = mapped_column(String(50))
    status: Mapped[ComplaintStatus] = mapped_column(
        Enum(ComplaintStatus), default=ComplaintStatus.open, nullable=False, index=True
    )
    resolution_notes: Mapped[str | None] = mapped_column(Text)
    assigned_admin_id: Mapped[int | None] = mapped_column(
        ForeignKey("admins.id", ondelete="SET NULL")
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    booking: Mapped["Booking"] = relationship(back_populates="complaint")
    complainant: Mapped["Customer"] = relationship(back_populates="complaints")

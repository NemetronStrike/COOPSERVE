import enum
from datetime import datetime

from sqlalchemy import (
    Boolean, Date, DateTime, Enum, ForeignKey,
    String, Text, Time, UniqueConstraint, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class VerificationStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class Skill(Base):
    __tablename__ = "skills"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), unique=True, nullable=False)
    category: Mapped[str | None] = mapped_column(String(100))
    description: Mapped[str | None] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    workers: Mapped[list["WorkerSkill"]] = relationship(back_populates="skill")


class WorkerSkill(Base):
    __tablename__ = "worker_skills"
    __table_args__ = (UniqueConstraint("worker_id", "skill_id", name="uq_worker_skill"),)

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    worker_id: Mapped[int] = mapped_column(
        ForeignKey("workers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    skill_id: Mapped[int] = mapped_column(
        ForeignKey("skills.id", ondelete="CASCADE"), nullable=False, index=True
    )
    years_experience: Mapped[int | None] = mapped_column()
    is_primary: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    worker: Mapped["Worker"] = relationship(back_populates="skills")
    skill: Mapped["Skill"] = relationship(back_populates="workers")


class WorkerVerification(Base):
    __tablename__ = "worker_verifications"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    worker_id: Mapped[int] = mapped_column(
        ForeignKey("workers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    document_type: Mapped[str] = mapped_column(String(100), nullable=False)
    document_reference: Mapped[str | None] = mapped_column(String(255))
    status: Mapped[VerificationStatus] = mapped_column(
        Enum(VerificationStatus), default=VerificationStatus.pending, nullable=False
    )
    reviewed_by_admin_id: Mapped[int | None] = mapped_column(
        ForeignKey("admins.id", ondelete="SET NULL")
    )
    notes: Mapped[str | None] = mapped_column(Text)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    worker: Mapped["Worker"] = relationship(back_populates="verifications")


class Availability(Base):
    __tablename__ = "availability"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    worker_id: Mapped[int] = mapped_column(
        ForeignKey("workers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    day_of_week: Mapped[int | None] = mapped_column()   # 0=Mon … 6=Sun; NULL = specific date
    specific_date: Mapped[datetime | None] = mapped_column(Date)
    start_time: Mapped[datetime] = mapped_column(Time(timezone=False), nullable=False)
    end_time: Mapped[datetime] = mapped_column(Time(timezone=False), nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    worker: Mapped["Worker"] = relationship(back_populates="availability")

import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class UserRole(str, enum.Enum):
    customer = "customer"
    worker = "worker"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    full_name: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    phone: Mapped[str] = mapped_column(String(20), unique=True, nullable=False, index=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    customer_profile: Mapped["Customer"] = relationship(back_populates="user", uselist=False)
    worker_profile: Mapped["Worker"] = relationship(back_populates="user", uselist=False)
    admin_profile: Mapped["Admin"] = relationship(back_populates="user", uselist=False)


class Customer(Base):
    __tablename__ = "customers"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        __import__("sqlalchemy").ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    preferred_language: Mapped[str | None] = mapped_column(String(10))
    address_notes: Mapped[str | None] = mapped_column(String(500))

    # Relationships
    user: Mapped["User"] = relationship(back_populates="customer_profile")
    bookings: Mapped[list["Booking"]] = relationship(back_populates="customer")
    ratings: Mapped[list["Rating"]] = relationship(back_populates="customer")
    complaints: Mapped[list["Complaint"]] = relationship(back_populates="complainant")


class Worker(Base):
    __tablename__ = "workers"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        __import__("sqlalchemy").ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    bio: Mapped[str | None] = mapped_column(String(1000))
    years_of_experience: Mapped[int | None] = mapped_column()
    average_rating: Mapped[float | None] = mapped_column()
    total_jobs: Mapped[int] = mapped_column(default=0, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Relationships
    user: Mapped["User"] = relationship(back_populates="worker_profile")
    skills: Mapped[list["WorkerSkill"]] = relationship(back_populates="worker")
    verifications: Mapped[list["WorkerVerification"]] = relationship(back_populates="worker")
    availability: Mapped[list["Availability"]] = relationship(back_populates="worker")
    bookings: Mapped[list["Booking"]] = relationship(back_populates="worker")
    ratings: Mapped[list["Rating"]] = relationship(back_populates="worker")


class Admin(Base):
    __tablename__ = "admins"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        __import__("sqlalchemy").ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )
    cooperative_id: Mapped[str | None] = mapped_column(String(100), unique=True)
    department: Mapped[str | None] = mapped_column(String(100))

    # Relationships
    user: Mapped["User"] = relationship(back_populates="admin_profile")

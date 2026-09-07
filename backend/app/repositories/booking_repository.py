from datetime import datetime

from sqlalchemy import and_, or_
from sqlalchemy.orm import Session, joinedload

from app.models.booking import Booking, BookingStatus
from app.models.user import Customer, Worker


def booking_query(db: Session):
    return db.query(Booking).options(
        joinedload(Booking.customer).joinedload(Customer.user),
        joinedload(Booking.worker).joinedload(Worker.user),
        joinedload(Booking.service),
    )


def create_booking(db: Session, booking: Booking) -> Booking:
    db.add(booking)
    db.commit()
    db.refresh(booking)
    return booking


def list_customer_bookings(db: Session, customer_id: int) -> list[Booking]:
    return (
        booking_query(db)
        .filter(Booking.customer_id == customer_id)
        .order_by(Booking.scheduled_at.desc())
        .all()
    )


def list_worker_bookings(db: Session, worker_id: int) -> list[Booking]:
    return (
        booking_query(db)
        .filter(Booking.worker_id == worker_id)
        .order_by(Booking.scheduled_at.desc())
        .all()
    )


def get_booking(db: Session, booking_id: int) -> Booking | None:
    return booking_query(db).filter(Booking.id == booking_id).first()


def has_conflicting_booking(
    db: Session,
    *,
    worker_id: int,
    start: datetime,
    end: datetime,
) -> bool:
    return (
        db.query(Booking.id)
        .filter(
            Booking.worker_id == worker_id,
            Booking.status.not_in([BookingStatus.cancelled]),
            Booking.scheduled_end_at.is_not(None),
            and_(Booking.scheduled_at < end, Booking.scheduled_end_at > start),
        )
        .first()
        is not None
    )
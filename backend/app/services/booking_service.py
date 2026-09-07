from datetime import datetime, timezone
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.booking import Booking, BookingStatus
from app.models.payment import PaymentStatus
from app.models.notification import Notification
from app.models.service import Service
from app.models.user import User, UserRole, Worker
from app.repositories.booking_repository import (
    create_booking,
    get_booking,
    has_conflicting_booking,
    list_customer_bookings,
    list_worker_bookings,
)
from app.repositories.worker_repository import list_active_workers
from app.schemas.booking import BookingCreate, BookingSummary


def _customer_id(user: User) -> int:
    if user.role != UserRole.customer or user.customer_profile is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Customers only")
    return user.customer_profile.id


def _summary(booking: Booking) -> BookingSummary:
    return BookingSummary(
        id=booking.id,
        customer_id=booking.customer_id,
        worker_id=booking.worker_id,
        service_id=booking.service_id,
        scheduled_at=booking.scheduled_at,
        scheduled_end_at=booking.scheduled_end_at,
        service_address=booking.service_address,
        amount=booking.price,
        status=booking.status,
        created_at=booking.created_at,
        updated_at=booking.updated_at,
        customer_name=booking.customer.user.full_name,
        worker_name=booking.worker.user.full_name if booking.worker else None,
        service_name=booking.service.name,
        payment_id=booking.payment.id if booking.payment else None,
        payment_status=(
            "success"
            if booking.payment.status == PaymentStatus.paid
            else booking.payment.status.value
        ) if booking.payment else None,
        transaction_reference=booking.payment.transaction_reference
        if booking.payment
        else None,
        is_emergency=booking.is_emergency,
    )


def _validate_worker_for_service(db: Session, worker_id: int, service: Service) -> Worker:
    workers = list_active_workers(db, service_id=service.id)
    worker = next((item for item in workers if item.id == worker_id), None)
    if worker is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Worker is not eligible for this service",
        )
    return worker


def create_customer_booking(db: Session, user: User, request: BookingCreate) -> BookingSummary:
    customer_id = _customer_id(user)
    service = db.query(Service).filter(Service.id == request.service_id, Service.is_active.is_(True)).first()
    if service is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Service not found")

    worker = _validate_worker_for_service(db, request.worker_id, service)
    if request.end_time <= request.start_time:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="End time must be after start time")

    start = datetime.combine(
        request.scheduled_date,
        request.start_time,
        tzinfo=timezone.utc,
    )
    end = datetime.combine(
        request.scheduled_date,
        request.end_time,
        tzinfo=timezone.utc,
    )
    if start <= datetime.now(timezone.utc):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Scheduled time must be in the future")
    if has_conflicting_booking(db, worker_id=worker.id, start=start, end=end):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Worker is already booked for this time")

    booking = Booking(
        customer_id=customer_id,
        worker_id=worker.id,
        service_id=service.id,
        scheduled_at=start,
        scheduled_end_at=end,
        service_address=request.service_address,
        price=service.base_price * (Decimal("1.10") if request.is_emergency else Decimal("1")),
        status=BookingStatus.pending,
        is_emergency=request.is_emergency,
    )
    created = create_booking(db, booking)
    db.add(Notification(
        user_id=user.id,
        title="Booking created",
        message=f"Your {'emergency ' if created.is_emergency else ''}booking for {service.name} was created.",
        type="booking_created",
        related_booking_id=created.id,
    ))
    if worker.user_id != user.id:
        db.add(Notification(
            user_id=worker.user_id,
            title="New booking assigned",
            message=f"A new booking for {service.name} is waiting for your review.",
            type="booking_assigned",
            related_booking_id=created.id,
        ))
    db.commit()
    return _summary(created)


def customer_bookings(db: Session, user: User) -> list[BookingSummary]:
    customer_id = _customer_id(user)
    return [_summary(item) for item in list_customer_bookings(db, customer_id)]


def worker_bookings(db: Session, user: User) -> list[BookingSummary]:
    if user.role != UserRole.worker or user.worker_profile is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Workers only")
    return [_summary(item) for item in list_worker_bookings(db, user.worker_profile.id)]


def booking_details(db: Session, user: User, booking_id: int) -> BookingSummary:
    booking = get_booking(db, booking_id)
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    is_customer = user.customer_profile and booking.customer_id == user.customer_profile.id
    is_worker = user.worker_profile and booking.worker_id == user.worker_profile.id
    if not is_customer and not is_worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    return _summary(booking)


_TRANSITIONS = {
    BookingStatus.pending: {BookingStatus.accepted, BookingStatus.cancelled},
    BookingStatus.accepted: {BookingStatus.in_progress, BookingStatus.cancelled},
    BookingStatus.in_progress: {BookingStatus.completed, BookingStatus.cancelled},
}


def update_booking_status(db: Session, user: User, booking_id: int, new_status: BookingStatus) -> BookingSummary:
    if user.role != UserRole.worker or user.worker_profile is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Workers only")
    booking = get_booking(db, booking_id)
    if booking is None or booking.worker_id != user.worker_profile.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    if new_status not in _TRANSITIONS.get(booking.status, set()):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid booking status transition")
    booking.status = new_status
    db.commit()
    db.refresh(booking)
    if booking.customer and booking.customer.user:
        labels = {
            BookingStatus.accepted: "Booking accepted",
            BookingStatus.in_progress: "Service started",
            BookingStatus.completed: "Service completed",
        }
        if new_status in labels:
            db.add(Notification(
                user_id=booking.customer.user_id,
                title=labels[new_status],
                message=f"Your booking #{booking.id} is now {new_status.value.replace('_', ' ')}.",
                type=f"booking_{new_status.value}",
                related_booking_id=booking.id,
            ))
            db.commit()
    return _summary(booking)
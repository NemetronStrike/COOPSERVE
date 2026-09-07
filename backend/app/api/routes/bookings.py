from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user, require_customer, require_worker
from app.models.user import User
from app.schemas.booking import BookingCreate, BookingResponse, BookingStatusUpdate, BookingSummary
from app.services.booking_service import (
    booking_details,
    create_customer_booking,
    customer_bookings,
    update_booking_status,
    worker_bookings,
)

router = APIRouter(prefix="/bookings", tags=["bookings"])


@router.post("", response_model=BookingSummary, status_code=201)
def create(
    request: BookingCreate,
    db: Session = Depends(get_db),
    user: User = Depends(require_customer),
) -> BookingSummary:
    return create_customer_booking(db, user, request)


@router.get("/customer", response_model=list[BookingSummary])
def customer_list(
    db: Session = Depends(get_db),
    user: User = Depends(require_customer),
) -> list[BookingSummary]:
    return customer_bookings(db, user)


@router.get("/worker", response_model=list[BookingSummary])
def worker_list(
    db: Session = Depends(get_db),
    user: User = Depends(require_worker),
) -> list[BookingSummary]:
    return worker_bookings(db, user)


@router.get("/{booking_id}", response_model=BookingSummary)
def details(
    booking_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> BookingSummary:
    return booking_details(db, user, booking_id)


@router.patch("/{booking_id}/status", response_model=BookingSummary)
def status_update(
    booking_id: int,
    request: BookingStatusUpdate,
    db: Session = Depends(get_db),
    user: User = Depends(require_worker),
) -> BookingSummary:
    return update_booking_status(db, user, booking_id, request.status)
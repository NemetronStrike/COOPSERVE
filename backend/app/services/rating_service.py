from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from sqlalchemy import func
from app.models.booking import Booking, BookingStatus
from app.models.rating import Rating
from app.models.user import User, UserRole, Worker
from app.repositories.rating_repository import create_rating, get_rating_for_booking
from app.schemas.rating import RatingResponse


def _customer_id(user: User) -> int:
    if user.role != UserRole.customer or user.customer_profile is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Customers only")
    return user.customer_profile.id


def _response(rating: Rating) -> RatingResponse:
    return RatingResponse(
        id=rating.id,
        booking_id=rating.booking_id,
        customer_id=rating.customer_id,
        worker_id=rating.worker_id,
        rating=rating.rating_value,
        review=rating.review,
        created_at=rating.created_at,
    )


def create_customer_rating(db: Session, user: User, booking_id: int, rating_value: int, review: str | None) -> RatingResponse:
    customer_id = _customer_id(user)
    booking = db.query(Booking).filter(Booking.id == booking_id, Booking.customer_id == customer_id).first()
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    if booking.status != BookingStatus.completed:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only completed bookings can be rated")
    if booking.worker_id is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Booking has no worker")
    if get_rating_for_booking(db, booking_id) is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Booking is already rated")
    new_rating = create_rating(db, Rating(
        booking_id=booking.id,
        customer_id=customer_id,
        worker_id=booking.worker_id,
        rating_value=rating_value,
        review=review,
    ))

    # Recalculate average rating for the worker
    avg_result = db.query(func.avg(Rating.rating_value), func.count(Rating.id)).filter(
        Rating.worker_id == booking.worker_id
    ).first()

    if avg_result and avg_result[0] is not None:
        worker = db.query(Worker).filter(Worker.id == booking.worker_id).first()
        if worker:
            worker.average_rating = float(avg_result[0])
            worker.total_jobs = avg_result[1]
            db.commit()
    else:
        worker = db.query(Worker).filter(Worker.id == booking.worker_id).first()
        if worker:
            worker.average_rating = 0.0
            worker.total_jobs = 0
            db.commit()

    return _response(new_rating)


def get_booking_rating(db: Session, user: User, booking_id: int) -> RatingResponse | None:
    customer_id = _customer_id(user)
    booking = db.query(Booking).filter(Booking.id == booking_id, Booking.customer_id == customer_id).first()
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    rating = get_rating_for_booking(db, booking_id)
    return _response(rating) if rating else None
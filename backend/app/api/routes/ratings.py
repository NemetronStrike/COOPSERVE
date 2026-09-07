from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_customer
from app.models.user import User
from app.schemas.rating import RatingCreate, RatingResponse
from app.services.rating_service import create_customer_rating, get_booking_rating

router = APIRouter(prefix="/ratings", tags=["ratings"])


@router.post("", response_model=RatingResponse, status_code=201)
def create(request: RatingCreate, db: Session = Depends(get_db), user: User = Depends(require_customer)) -> RatingResponse:
    return create_customer_rating(db, user, request.booking_id, request.rating, request.review)


@router.get("/booking/{booking_id}", response_model=RatingResponse | None)
def booking_rating(booking_id: int, db: Session = Depends(get_db), user: User = Depends(require_customer)) -> RatingResponse | None:
    return get_booking_rating(db, user, booking_id)
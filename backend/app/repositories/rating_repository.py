from sqlalchemy.orm import Session

from app.models.rating import Rating


def get_rating_for_booking(db: Session, booking_id: int) -> Rating | None:
    return db.query(Rating).filter(Rating.booking_id == booking_id).first()


def create_rating(db: Session, rating: Rating) -> Rating:
    db.add(rating)
    db.commit()
    db.refresh(rating)
    return rating
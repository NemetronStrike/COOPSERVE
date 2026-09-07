from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class RatingCreate(BaseModel):
    booking_id: int
    rating: int = Field(ge=1, le=5)
    review: str | None = Field(default=None, max_length=1000)

    @field_validator("review")
    @classmethod
    def normalize_review(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None


class RatingResponse(BaseModel):
    id: int
    booking_id: int
    customer_id: int
    worker_id: int
    rating: int
    review: str | None
    created_at: datetime | None
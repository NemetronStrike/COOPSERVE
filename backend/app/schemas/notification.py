from datetime import datetime

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: int
    title: str
    message: str
    type: str
    related_booking_id: int | None
    is_read: bool
    created_at: datetime | None


class VerificationUpdate(BaseModel):
    status: str
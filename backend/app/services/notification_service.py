from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.notification import Notification
from app.models.user import User
from app.repositories.notification_repository import get_notification, list_notifications
from app.schemas.notification import NotificationResponse


def _response(item: Notification) -> NotificationResponse:
    return NotificationResponse(
        id=item.id,
        title=item.title,
        message=item.message,
        type=item.type,
        related_booking_id=item.related_booking_id,
        is_read=item.is_read,
        created_at=item.created_at,
    )


def user_notifications(db: Session, user: User) -> list[NotificationResponse]:
    return [_response(item) for item in list_notifications(db, user.id)]


def mark_notification_read(db: Session, user: User, notification_id: int) -> NotificationResponse:
    item = get_notification(db, notification_id, user.id)
    if item is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    item.is_read = True
    db.commit()
    db.refresh(item)
    return _response(item)
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.notification import NotificationResponse
from app.services.notification_service import mark_notification_read, user_notifications

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=list[NotificationResponse])
def notifications(db: Session = Depends(get_db), user: User = Depends(get_current_user)) -> list[NotificationResponse]:
    return user_notifications(db, user)


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def read(notification_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)) -> NotificationResponse:
    return mark_notification_read(db, user, notification_id)
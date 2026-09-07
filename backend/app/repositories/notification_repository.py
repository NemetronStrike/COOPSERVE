from sqlalchemy.orm import Session

from app.models.notification import Notification


def list_notifications(db: Session, user_id: int) -> list[Notification]:
    return (
        db.query(Notification)
        .filter(Notification.user_id == user_id)
        .order_by(Notification.created_at.desc(), Notification.id.desc())
        .all()
    )


def get_notification(db: Session, notification_id: int, user_id: int) -> Notification | None:
    return db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == user_id,
    ).first()
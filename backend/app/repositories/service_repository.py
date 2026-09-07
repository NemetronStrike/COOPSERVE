from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.models.service import Service


def list_active_services(
    db: Session,
    *,
    search: str | None = None,
    category: str | None = None,
) -> list[Service]:
    query = db.query(Service).filter(Service.is_active.is_(True))

    if search:
        search_term = f"%{search.strip()}%"
        query = query.filter(
            or_(
                Service.name.ilike(search_term),
                Service.description.ilike(search_term),
            )
        )
    if category:
        query = query.filter(Service.category.ilike(category.strip()))

    return query.order_by(Service.category, Service.name).all()


def get_active_service(db: Session, service_id: int) -> Service | None:
    return (
        db.query(Service)
        .filter(Service.id == service_id, Service.is_active.is_(True))
        .first()
    )
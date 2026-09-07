from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.service import Service
from app.repositories.service_repository import (
    get_active_service,
    list_active_services,
)


def list_services(
    db: Session,
    *,
    search: str | None = None,
    category: str | None = None,
) -> list[Service]:
    return list_active_services(db, search=search, category=category)


def get_service(db: Session, service_id: int) -> Service:
    if service_id < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Service ID must be positive",
        )

    service = get_active_service(db, service_id)
    if service is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Service not found",
        )
    return service
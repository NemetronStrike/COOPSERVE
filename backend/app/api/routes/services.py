from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.service import ServiceResponse
from app.services.service_catalog_service import get_service, list_services

router = APIRouter(prefix="/services", tags=["services"])


@router.get("", response_model=list[ServiceResponse])
def services(
    search: str | None = Query(default=None, max_length=100),
    category: str | None = Query(default=None, max_length=100),
    db: Session = Depends(get_db),
) -> list[ServiceResponse]:
    if search is not None and not search.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search cannot be blank",
        )
    if category is not None and not category.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category cannot be blank",
        )
    return list_services(db, search=search, category=category)


@router.get("/{service_id}", response_model=ServiceResponse)
def service_detail(
    service_id: int,
    db: Session = Depends(get_db),
) -> ServiceResponse:
    return get_service(db, service_id)
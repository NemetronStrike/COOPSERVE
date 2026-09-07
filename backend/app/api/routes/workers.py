from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.schemas.worker import WorkerResponse
from app.services.worker_service import get_worker, list_workers

router = APIRouter(prefix="/workers", tags=["workers"])


@router.get("", response_model=list[WorkerResponse])
def workers(
    service_id: int | None = Query(default=None),
    db: Session = Depends(get_db),
) -> list[WorkerResponse]:
    return list_workers(db, service_id=service_id)


@router.get("/{worker_id}", response_model=WorkerResponse)
def worker_detail(
    worker_id: int,
    db: Session = Depends(get_db),
) -> WorkerResponse:
    return get_worker(db, worker_id)
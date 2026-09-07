from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models.service import Service
from app.models.user import Worker
from app.repositories.worker_repository import get_active_worker, list_active_workers
from app.schemas.worker import WorkerResponse


def _to_response(worker: Worker) -> WorkerResponse:
    return WorkerResponse(
        id=worker.id,
        user_id=worker.user_id,
        name=worker.user.full_name,
        bio=worker.bio,
        skills=[item.skill.name for item in worker.skills if item.skill.is_active],
        experience_years=worker.years_of_experience,
        rating=worker.average_rating or 0.0,
        completed_jobs=worker.total_jobs,
        is_available=any(item.is_available for item in worker.availability)
        if worker.availability
        else True,
        is_verified=worker.is_verified,
    )


def list_workers(db: Session, service_id: int | None = None) -> list[WorkerResponse]:
    if service_id is not None:
        if service_id < 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Service ID must be positive",
            )
        if not db.query(Service).filter(Service.id == service_id).first():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Service not found",
            )
    return [_to_response(worker) for worker in list_active_workers(db, service_id=service_id)]


def get_worker(db: Session, worker_id: int) -> WorkerResponse:
    if worker_id < 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Worker ID must be positive",
        )
    worker = get_active_worker(db, worker_id)
    if worker is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Worker not found",
        )
    return _to_response(worker)
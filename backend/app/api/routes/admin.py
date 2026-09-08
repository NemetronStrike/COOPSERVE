from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_admin
from app.models.user import User
from app.schemas.admin import AdminDashboardResponse, AdminWorkerResponse, DemandForecastResponse
from app.schemas.notification import VerificationUpdate
from app.services.admin_service import dashboard, update_verification, workers
from app.services.forecasting_service import get_forecast
router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/dashboard", response_model=AdminDashboardResponse)
def admin_dashboard(db: Session = Depends(get_db), _: User = Depends(require_admin)) -> AdminDashboardResponse:
    return dashboard(db)


@router.get("/workers", response_model=list[AdminWorkerResponse])
def admin_workers(
    verification_status: str | None = Query(default=None),
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> list[AdminWorkerResponse]:
    return workers(db, verification_status=verification_status)


@router.patch("/workers/{worker_id}/verification", response_model=AdminWorkerResponse)
def verify_worker(
    worker_id: int,
    request: VerificationUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> AdminWorkerResponse:
    return update_verification(db, worker_id, request.status)


@router.get("/forecasting", response_model=DemandForecastResponse)
def admin_forecasting(db: Session = Depends(get_db), _: User = Depends(require_admin)) -> DemandForecastResponse:
    return get_forecast(db)
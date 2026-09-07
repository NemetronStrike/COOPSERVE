from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.booking import Booking, BookingStatus
from app.models.payment import Payment
from app.models.user import User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill, WorkerVerification, VerificationStatus
from app.schemas.admin import AdminDashboardResponse, AdminWorkerResponse


def dashboard(db: Session) -> AdminDashboardResponse:
    return AdminDashboardResponse(
        total_customers=db.query(User).filter(User.role == UserRole.customer).count(),
        total_workers=db.query(Worker).count(),
        verified_workers=db.query(Worker).filter(Worker.is_verified.is_(True)).count(),
        pending_worker_verifications=db.query(Worker).filter(Worker.is_verified.is_(False)).count(),
        total_bookings=db.query(Booking).count(),
        pending_bookings=db.query(Booking).filter(Booking.status == BookingStatus.pending).count(),
        completed_bookings=db.query(Booking).filter(Booking.status == BookingStatus.completed).count(),
        cancelled_bookings=db.query(Booking).filter(Booking.status == BookingStatus.cancelled).count(),
        total_payments=db.query(Payment).count(),
    )


def _verification_status(db: Session, worker: Worker) -> str:
    if worker.is_verified:
        return "verified"
    latest = db.query(WorkerVerification).filter(
        WorkerVerification.worker_id == worker.id,
    ).order_by(WorkerVerification.id.desc()).first()
    return "rejected" if latest and latest.status == VerificationStatus.rejected else "pending"


def workers(db: Session, verification_status: str | None = None) -> list[AdminWorkerResponse]:
    items = db.query(Worker).join(Worker.user).filter(User.role == UserRole.worker).all()
    result = []
    for worker in items:
        current_status = _verification_status(db, worker)
        if verification_status and verification_status != current_status:
            continue
        result.append(AdminWorkerResponse(
            id=worker.id,
            name=worker.user.full_name,
            skills=[item.skill.name for item in worker.skills if item.skill.is_active],
            experience_years=worker.years_of_experience,
            rating=worker.average_rating or 0.0,
            total_jobs=worker.total_jobs,
            is_available=any(item.is_available for item in worker.availability) if worker.availability else True,
            verification_status=current_status,
        ))
    return result


def update_verification(db: Session, worker_id: int, new_status: str) -> AdminWorkerResponse:
    if new_status not in {"pending", "verified", "rejected"}:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid verification status")
    worker = db.query(Worker).filter(Worker.id == worker_id).first()
    if worker is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Worker not found")
    worker.is_verified = new_status == "verified"
    mapped_status = {
        "pending": VerificationStatus.pending,
        "verified": VerificationStatus.approved,
        "rejected": VerificationStatus.rejected,
    }[new_status]
    db.add(WorkerVerification(
        worker_id=worker.id,
        document_type="admin_review",
        status=mapped_status,
    ))
    db.commit()
    db.refresh(worker)
    return workers(db, verification_status=new_status)[0]
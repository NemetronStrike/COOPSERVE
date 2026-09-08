from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_customer, require_admin
from app.models.user import User
from app.models.booking import Booking
from app.schemas.complaint import ComplaintCreate, ComplaintRead, ComplaintUpdate
from app.services import complaint_service

router = APIRouter(prefix="/complaints", tags=["complaints"])

@router.post("/", response_model=ComplaintRead, status_code=status.HTTP_201_CREATED)
def create_complaint(
    complaint_in: ComplaintCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer)
):
    if len(complaint_in.description.strip()) < 5:
        raise HTTPException(status_code=400, detail="Complaint description too short.")
    if len(complaint_in.description) > 2000:
        raise HTTPException(status_code=400, detail="Complaint description too long.")
        
    if complaint_in.booking_id:
        booking = db.query(Booking).filter(Booking.id == complaint_in.booking_id).first()
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found.")
        if booking.customer_id != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized to complain about this booking.")
    
    complaint = complaint_service.create_complaint_record(db, customer_id=current_user.id, complaint_in=complaint_in)
    return complaint

@router.get("/customer", response_model=list[ComplaintRead])
def get_customer_complaints(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_customer)
):
    return complaint_service.get_customer_complaints(db, customer_id=current_user.id)

@router.get("/admin", response_model=list[ComplaintRead])
def get_admin_complaints(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    return complaint_service.get_all_complaints(db)

@router.patch("/admin/{complaint_id}/status", response_model=ComplaintRead)
def update_complaint_status(
    complaint_id: int,
    update_in: ComplaintUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin)
):
    complaint = complaint_service.update_complaint_status(
        db, 
        complaint_id=complaint_id, 
        status=update_in.status, 
        resolution_notes=update_in.resolution_notes
    )
    if not complaint:
        raise HTTPException(status_code=404, detail="Complaint not found")
    return complaint

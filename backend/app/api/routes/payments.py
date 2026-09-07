from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user, require_customer
from app.models.user import User
from app.schemas.payment import InvoiceResponse, PaymentCreate, PaymentResponse
from app.services.payment_service import create_mock_payment, get_booking_invoice, get_customer_payment

router = APIRouter(tags=["payments"])


@router.post("/payments", response_model=PaymentResponse, status_code=201)
def pay(request: PaymentCreate, db: Session = Depends(get_db), user: User = Depends(require_customer)) -> PaymentResponse:
    return create_mock_payment(db, user, request.booking_id, request.payment_method)


@router.get("/payments/{payment_id}", response_model=PaymentResponse)
def payment_details(payment_id: int, db: Session = Depends(get_db), user: User = Depends(require_customer)) -> PaymentResponse:
    return get_customer_payment(db, user, payment_id)


@router.get("/bookings/{booking_id}/invoice", response_model=InvoiceResponse)
def invoice(booking_id: int, db: Session = Depends(get_db), user: User = Depends(get_current_user)) -> InvoiceResponse:
    return get_booking_invoice(db, user, booking_id)
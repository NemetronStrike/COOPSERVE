from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.orm import Session, joinedload

from app.models.booking import Booking, BookingStatus
from app.models.payment import Invoice, Payment, PaymentMethod, PaymentStatus
from app.models.notification import Notification
from app.models.user import User, UserRole
from app.repositories.payment_repository import (
    get_invoice_for_booking,
    get_payment,
    get_payment_for_booking,
)
from app.schemas.payment import InvoiceResponse, PaymentResponse


def _customer_id(user: User) -> int:
    if user.role != UserRole.customer or user.customer_profile is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Customers only")
    return user.customer_profile.id


def _payment_response(payment: Payment, *, status_label: str = "success") -> PaymentResponse:
    return PaymentResponse(
        id=payment.id,
        booking_id=payment.booking_id,
        amount=payment.amount,
        payment_method=payment.method.value if payment.method else "mock",
        status=status_label,
        transaction_reference=payment.transaction_reference or "",
        created_at=payment.created_at,
    )


def create_mock_payment(db: Session, user: User, booking_id: int, payment_method: str) -> PaymentResponse:
    customer_id = _customer_id(user)
    if payment_method.lower() != "mock":
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Only mock payment is available")

    booking = (
        db.query(Booking)
        .options(joinedload(Booking.payment))
        .filter(Booking.id == booking_id, Booking.customer_id == customer_id)
        .first()
    )
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    if booking.status == BookingStatus.cancelled:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cancelled bookings cannot be paid")
    if booking.payment is not None and booking.payment.status == PaymentStatus.paid:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Booking is already paid")

    payment = booking.payment or Payment(
        booking_id=booking.id,
        amount=booking.price,
        method=PaymentMethod.mock,
    )
    payment.amount = booking.price
    payment.method = PaymentMethod.mock
    payment.status = PaymentStatus.paid
    payment.paid_at = datetime.now(timezone.utc)
    db.add(payment)
    db.flush()
    payment.transaction_reference = f"MOCK-{payment.id}"

    invoice = payment.invoice or Invoice(
        payment_id=payment.id,
        invoice_number=f"INV-{payment.id}",
        subtotal=booking.price,
        tax=0,
        total=booking.price,
    )
    db.add(invoice)
    db.commit()
    db.refresh(payment)
    db.add(Notification(
        user_id=user.id,
        title="Payment successful",
        message=f"Payment for booking #{booking.id} was successful.",
        type="payment_success",
        related_booking_id=booking.id,
    ))
    db.commit()
    return _payment_response(payment)


def get_customer_payment(db: Session, user: User, payment_id: int) -> PaymentResponse:
    customer_id = _customer_id(user)
    payment = get_payment(db, payment_id)
    if payment is None or payment.booking.customer_id != customer_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    return _payment_response(payment, status_label="success" if payment.status == PaymentStatus.paid else payment.status.value)


def get_booking_invoice(db: Session, user: User, booking_id: int) -> InvoiceResponse:
    booking = db.query(Booking).filter(Booking.id == booking_id).first()
    if booking is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Booking not found")
    is_customer = user.customer_profile and booking.customer_id == user.customer_profile.id
    is_worker = user.worker_profile and booking.worker_id == user.worker_profile.id
    if not is_customer and not is_worker:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found")
    invoice = get_invoice_for_booking(db, booking_id)
    if invoice is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invoice not found")
    payment = invoice.payment
    return InvoiceResponse(
        id=invoice.id,
        invoice_number=invoice.invoice_number,
        booking_id=booking.id,
        customer_name=booking.customer.user.full_name,
        worker_name=booking.worker.user.full_name if booking.worker else None,
        service_name=booking.service.name,
        scheduled_at=booking.scheduled_at,
        service_address=booking.service_address,
        subtotal=invoice.subtotal,
        tax=invoice.tax,
        total=invoice.total,
        payment_status="success" if payment.status == PaymentStatus.paid else payment.status.value,
        transaction_reference=payment.transaction_reference or "",
        issued_at=invoice.issued_at,
    )
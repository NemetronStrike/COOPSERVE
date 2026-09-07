from sqlalchemy.orm import Session

from app.models.payment import Invoice, Payment


def get_payment_for_booking(db: Session, booking_id: int) -> Payment | None:
    return (
        db.query(Payment)
        .filter(Payment.booking_id == booking_id)
        .first()
    )


def get_payment(db: Session, payment_id: int) -> Payment | None:
    return (
        db.query(Payment)
        .filter(Payment.id == payment_id)
        .first()
    )


def get_invoice_for_booking(db: Session, booking_id: int) -> Invoice | None:
    return (
        db.query(Invoice)
        .join(Invoice.payment)
        .filter(Payment.booking_id == booking_id)
        .first()
    )
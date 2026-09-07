from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class PaymentCreate(BaseModel):
    booking_id: int
    payment_method: str = Field(default="mock", min_length=1, max_length=20)


class PaymentResponse(BaseModel):
    id: int
    booking_id: int
    amount: Decimal
    payment_method: str
    status: str
    transaction_reference: str
    created_at: datetime | None


class InvoiceResponse(BaseModel):
    id: int
    invoice_number: str
    booking_id: int
    customer_name: str
    worker_name: str | None
    service_name: str
    scheduled_at: datetime
    service_address: str | None
    subtotal: Decimal
    tax: Decimal
    total: Decimal
    payment_status: str
    transaction_reference: str
    issued_at: datetime | None
from datetime import date, datetime, time
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.booking import BookingStatus


class BookingCreate(BaseModel):
    service_id: int
    worker_id: int
    scheduled_date: date
    start_time: time
    end_time: time
    service_address: str = Field(min_length=1, max_length=500)

    @field_validator("service_address")
    @classmethod
    def validate_address(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Service address cannot be empty")
        return value


class BookingStatusUpdate(BaseModel):
    status: BookingStatus


class BookingResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: int
    customer_id: int
    worker_id: int | None
    service_id: int
    scheduled_at: datetime
    scheduled_end_at: datetime | None
    service_address: str | None
    amount: Decimal = Field(
        validation_alias="price",
        serialization_alias="amount",
    )
    status: BookingStatus
    created_at: datetime | None
    updated_at: datetime | None


class BookingSummary(BookingResponse):
    customer_name: str
    worker_name: str | None
    service_name: str
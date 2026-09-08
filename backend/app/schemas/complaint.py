from datetime import datetime
from pydantic import BaseModel, ConfigDict

from app.models.rating import ComplaintCategory, ComplaintSeverity, ComplaintStatus, ComplaintUrgency

class ComplaintBase(BaseModel):
    category: ComplaintCategory
    description: str

class ComplaintCreate(ComplaintBase):
    booking_id: int | None = None

class ComplaintUpdate(BaseModel):
    status: ComplaintStatus
    resolution_notes: str | None = None

class ComplaintRead(ComplaintBase):
    id: int
    complainant_id: int
    booking_id: int | None
    status: ComplaintStatus
    resolution_notes: str | None
    assigned_admin_id: int | None
    severity: ComplaintSeverity | None
    urgency: ComplaintUrgency | None
    summary: str | None
    suggested_action: str | None
    classification_source: str | None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

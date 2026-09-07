from pydantic import BaseModel


class AdminDashboardResponse(BaseModel):
    total_customers: int
    total_workers: int
    verified_workers: int
    pending_worker_verifications: int
    total_bookings: int
    pending_bookings: int
    completed_bookings: int
    cancelled_bookings: int
    total_payments: int


class AdminWorkerResponse(BaseModel):
    id: int
    name: str
    skills: list[str]
    experience_years: int | None
    rating: float
    total_jobs: int
    is_available: bool
    verification_status: str
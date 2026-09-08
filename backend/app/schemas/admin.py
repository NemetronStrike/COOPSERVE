from datetime import date, datetime
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


class DailyForecast(BaseModel):
    date: date
    predicted_demand: float
    available_supply: float
    status: str  # "shortage" | "sufficient"


class CategoryForecast(BaseModel):
    category: str
    daily_forecasts: list[DailyForecast]


class DemandForecastResponse(BaseModel):
    generated_at: datetime
    forecasts: list[CategoryForecast]
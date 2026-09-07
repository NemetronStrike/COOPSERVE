from fastapi import APIRouter
from pydantic import BaseModel

from app.core.database import check_db_connection

router = APIRouter(tags=["health"])


class HealthResponse(BaseModel):
    status: str
    database: str


@router.get("/health", response_model=HealthResponse)
def health_check() -> HealthResponse:
    db_ok = check_db_connection()
    return HealthResponse(
        status="healthy",
        database="connected" if db_ok else "unavailable",
    )

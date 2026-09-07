from pydantic import BaseModel
from typing import Any

class ServiceSearchRequest(BaseModel):
    query: str

class AIServiceResponse(BaseModel):
    interpretation: str
    services: list[Any]

class WorkerMatchRequest(BaseModel):
    service_id: int
    urgency: str = "normal"
    notes: str | None = None

class AIWorkerMatchResponse(BaseModel):
    id: int
    name: str
    match_score: float
    explanation: str
    average_rating: float
    years_of_experience: int
    total_jobs: int

class WorkerMatchResponseList(BaseModel):
    matches: list[AIWorkerMatchResponse]

from pydantic import BaseModel, ConfigDict


class WorkerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    name: str
    bio: str | None
    skills: list[str]
    experience_years: int | None
    rating: float
    completed_jobs: int
    is_available: bool
    is_verified: bool
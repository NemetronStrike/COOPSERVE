from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class ServiceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: str | None
    category: str
    base_price: Decimal
    is_active: bool
    rating: float = 0.0
    review_count: int = 0


class ServiceQuery(BaseModel):
    search: str | None = Field(default=None, max_length=100)
    category: str | None = Field(default=None, max_length=100)
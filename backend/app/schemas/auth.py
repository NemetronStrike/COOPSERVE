from pydantic import BaseModel, EmailStr, field_validator
from app.models.user import UserRole


class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    password: str
    role: UserRole
    # Worker-specific (optional)
    skills: str | None = None
    certifications: str | None = None
    # Admin-specific (optional)
    cooperative_id: str | None = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        digits = v.lstrip("+")
        if not digits.isdigit() or not (10 <= len(digits) <= 13):
            raise ValueError("Enter a valid phone number (10–13 digits)")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one number")
        return v


class LoginRequest(BaseModel):
    identifier: str   # email or phone
    password: str
    role: UserRole


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    user_id: int
    full_name: str


class UserResponse(BaseModel):
    id: int
    full_name: str
    email: str
    phone: str
    role: str
    is_active: bool

    model_config = {"from_attributes": True}

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import (
    get_current_user,
    require_customer,
    require_worker,
    require_admin,
)
from app.models.user import User
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse, UserResponse
from app.services.auth_service import register_user, login_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=TokenResponse, status_code=201)
def register(req: RegisterRequest, db: Session = Depends(get_db)) -> TokenResponse:
    return register_user(db, req)


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    return login_user(db, req)


@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


# ── Role-check test endpoints ───────────────────────────────────────────────

@router.get("/test/customer")
def test_customer(user: User = Depends(require_customer)) -> dict:
    return {"ok": True, "role": user.role.value, "user_id": user.id}


@router.get("/test/worker")
def test_worker(user: User = Depends(require_worker)) -> dict:
    return {"ok": True, "role": user.role.value, "user_id": user.id}


@router.get("/test/admin")
def test_admin(user: User = Depends(require_admin)) -> dict:
    return {"ok": True, "role": user.role.value, "user_id": user.id}

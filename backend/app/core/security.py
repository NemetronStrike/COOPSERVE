from datetime import datetime, timedelta, timezone

import bcrypt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.database import get_db
from app.models.user import User, UserRole

settings = get_settings()
_bearer = HTTPBearer(auto_error=False)

_401 = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Not authenticated",
    headers={"WWW-Authenticate": "Bearer"},
)


# ── Password hashing ──────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())


# ── JWT ───────────────────────────────────────────────────────────────────────

def create_access_token(subject: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.access_token_expire_minutes
    )
    payload = {"sub": subject, "role": role, "exp": expire}
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_access_token(token: str) -> dict:
    """Raises JWTError if token is invalid or expired."""
    return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])


# ── Auth dependencies ─────────────────────────────────────────────────────────

def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise _401
    try:
        payload = decode_access_token(credentials.credentials)
        user_id: str | None = payload.get("sub")
        if user_id is None:
            raise _401
    except JWTError:
        raise _401

    user = db.get(User, int(user_id))
    if user is None or not user.is_active:
        raise _401
    return user


def require_customer(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.customer:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Customers only")
    return user


def require_worker(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.worker:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Workers only")
    return user


def require_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.admin:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Admins only")
    return user

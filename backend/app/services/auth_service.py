from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import hash_password, verify_password, create_access_token
from app.models.user import User, Customer, Worker, Admin, UserRole
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse


def register_user(db: Session, req: RegisterRequest) -> TokenResponse:
    # Duplicate checks
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail="Email already registered")
    if db.query(User).filter(User.phone == req.phone).first():
        raise HTTPException(status_code=status.HTTP_409_CONFLICT,
                            detail="Phone number already registered")

    user = User(
        full_name=req.full_name,
        email=req.email,
        phone=req.phone,
        role=req.role,
        hashed_password=hash_password(req.password),
    )
    db.add(user)
    db.flush()  # get user.id before creating profile

    if req.role == UserRole.customer:
        db.add(Customer(user_id=user.id))

    elif req.role == UserRole.worker:
        db.add(Worker(
            user_id=user.id,
            bio=req.certifications,
        ))

    elif req.role == UserRole.admin:
        db.add(Admin(
            user_id=user.id,
            cooperative_id=req.cooperative_id,
        ))

    db.commit()
    db.refresh(user)

    token = create_access_token(subject=str(user.id), role=user.role.value)
    return TokenResponse(
        access_token=token,
        role=user.role.value,
        user_id=user.id,
        full_name=user.full_name,
    )


def login_user(db: Session, req: LoginRequest) -> TokenResponse:
    # Find by email or phone
    identifier = req.identifier.strip()
    if "@" in identifier:
        user = db.query(User).filter(User.email == identifier).first()
    else:
        user = db.query(User).filter(User.phone == identifier).first()

    invalid = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid credentials",
    )

    if not user or not user.is_active:
        raise invalid
    if user.role != req.role:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"This account is not registered as {req.role.value}",
        )
    if not verify_password(req.password, user.hashed_password):
        raise invalid

    token = create_access_token(subject=str(user.id), role=user.role.value)
    return TokenResponse(
        access_token=token,
        role=user.role.value,
        user_id=user.id,
        full_name=user.full_name,
    )

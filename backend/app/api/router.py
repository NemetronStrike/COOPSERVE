from fastapi import APIRouter
from app.api.routes import health, auth

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)

# Future routers:
# api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
# api_router.include_router(workers.router,  prefix="/workers",  tags=["workers"])
# api_router.include_router(admin.router,    prefix="/admin",    tags=["admin"])

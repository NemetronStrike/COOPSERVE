from fastapi import APIRouter
from app.api.routes import health

api_router = APIRouter()
api_router.include_router(health.router)

# Future routers registered here, e.g.:
# api_router.include_router(auth.router,     prefix="/auth",     tags=["auth"])
# api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
# api_router.include_router(workers.router,  prefix="/workers",  tags=["workers"])
# api_router.include_router(admin.router,    prefix="/admin",    tags=["admin"])

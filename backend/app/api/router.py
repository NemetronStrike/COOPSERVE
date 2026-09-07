from fastapi import APIRouter
from app.api.routes import admin, auth, bookings, health, notifications, payments, ratings, services, workers

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(services.router)
api_router.include_router(workers.router)
api_router.include_router(bookings.router)
api_router.include_router(payments.router)
api_router.include_router(ratings.router)
api_router.include_router(admin.router)
api_router.include_router(notifications.router)

# Future routers:
# api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
# api_router.include_router(workers.router,  prefix="/workers",  tags=["workers"])
# api_router.include_router(admin.router,    prefix="/admin",    tags=["admin"])

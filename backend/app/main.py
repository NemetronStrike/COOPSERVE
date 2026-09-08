from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.api.router import api_router

settings = get_settings()


def create_app() -> FastAPI:
    app = FastAPI(
        title="COOPSERVE API",
        description="Cooperative Gig Services Platform — SIH26089",
        version="0.1.0",
        docs_url="/docs" if settings.app_debug else None,
        redoc_url="/redoc" if settings.app_debug else None,
    )

    # ── CORS ──────────────────────────────────────────────────────────────────
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # ── Routers ───────────────────────────────────────────────────────────────
    app.include_router(api_router)

    return app


app = create_app()

@app.on_event("startup")
def startup_seed_data():
    """
    TODO: Temporary deployment-safe seed mechanism.
    Seeds missing demo services and workers directly on startup.
    REMOVE THIS HOOK after the first successful Render deployment and verification.
    """
    import logging
    logger = logging.getLogger(__name__)
    try:
        from scripts.seed_services import seed_services
        from scripts.seed_workers import seed_workers
        
        logger.info("Running automatic service catalog seeding on startup...")
        service_count = seed_services()
        logger.info(f"Automatically seeded {service_count} demo services.")
        
        logger.info("Running automatic worker marketplace seeding on startup...")
        worker_count = seed_workers()
        logger.info(f"Automatically seeded {worker_count} demo workers.")
        
    except Exception as e:
        logger.error(f"Failed to seed demo data: {e}")

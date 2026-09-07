"""Insert or update the repeatable demo service catalog.

Run from the backend directory:
    python -m scripts.seed_services
"""

from decimal import Decimal

from app.core.database import SessionLocal
from app.models.service import Service

DEMO_SERVICES = (
    {
        "name": "Home Cleaning",
        "description": "Trusted help for a fresh, comfortable home.",
        "category": "Cleaning",
        "base_price": Decimal("499.00"),
    },
    {
        "name": "Deep Cleaning",
        "description": "A detailed clean for homes that need extra care.",
        "category": "Cleaning",
        "base_price": Decimal("899.00"),
    },
    {
        "name": "Electrical Repair",
        "description": "Skilled support for everyday electrical needs.",
        "category": "Repairs",
        "base_price": Decimal("299.00"),
    },
    {
        "name": "Plumbing Repair",
        "description": "Quick, dependable fixes from verified workers.",
        "category": "Repairs",
        "base_price": Decimal("349.00"),
    },
    {
        "name": "Appliance Repair",
        "description": "Care and repairs for the appliances your household relies on.",
        "category": "Repairs",
        "base_price": Decimal("399.00"),
    },
    {
        "name": "AC Service",
        "description": "Seasonal service to keep your cooling efficient.",
        "category": "Maintenance",
        "base_price": Decimal("599.00"),
    },
    {
        "name": "Painting",
        "description": "Reliable painting support for rooms and community spaces.",
        "category": "Maintenance",
        "base_price": Decimal("1499.00"),
    },
    {
        "name": "Carpentry",
        "description": "Practical repairs and custom work for your home.",
        "category": "Maintenance",
        "base_price": Decimal("499.00"),
    },
    {
        "name": "Gardening",
        "description": "Keep your outdoor spaces healthy and welcoming.",
        "category": "Home Care",
        "base_price": Decimal("449.00"),
    },
)


def seed_services() -> int:
    db = SessionLocal()
    try:
        for data in DEMO_SERVICES:
            service = (
                db.query(Service)
                .filter(
                    Service.name == data["name"],
                    Service.category == data["category"],
                )
                .first()
            )
            if service is None:
                service = Service(**data)
                db.add(service)
            else:
                for key, value in data.items():
                    setattr(service, key, value)
                service.is_active = True
        db.commit()
        return len(DEMO_SERVICES)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    print(f"Seeded {seed_services()} demo services.")
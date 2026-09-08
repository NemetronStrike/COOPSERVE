"""Insert historical demo bookings for demand forecasting testing.

Run from the backend directory:
    python -m scripts.seed_bookings
"""

import random
from datetime import date, datetime, timedelta

from app.core.database import SessionLocal
from app.models.booking import Booking, BookingStatus
from app.models.service import Service
from app.models.user import User, UserRole

def seed_bookings(days: int = 30, bookings_per_day: tuple[int, int] = (2, 8)) -> int:
    db = SessionLocal()
    try:
        # Get references
        customer = db.query(User).filter(User.role == UserRole.customer).first()
        services = db.query(Service).all()
        
        if not customer or not services:
            print("Need at least one customer and services to seed bookings.")
            return 0
            
        # Idempotency: Clear existing demo seeds to prevent duplication
        deleted_count = db.query(Booking).filter(Booking.notes == "DEMO_SEED").delete()
        if deleted_count > 0:
            print(f"Cleared {deleted_count} existing demo bookings.")
        
        today = date.today()
        count = 0
        
        for i in range(days):
            target_date = today - timedelta(days=i)
            # Add some randomness to daily demand based on day of week
            # Weekends might be busier for certain services
            is_weekend = target_date.weekday() >= 5
            daily_count = random.randint(bookings_per_day[0], bookings_per_day[1])
            if is_weekend:
                daily_count += random.randint(1, 4)
                
            for _ in range(daily_count):
                service = random.choice(services)
                # Random time between 9 AM and 5 PM
                hour = random.randint(9, 17)
                scheduled_at = datetime.combine(target_date, datetime.min.time()) + timedelta(hours=hour)
                
                b = Booking(
                    customer_id=customer.id,
                    service_id=service.id,
                    status=BookingStatus.completed,
                    scheduled_at=scheduled_at,
                    price=service.base_price,
                    is_emergency=random.choice([True, False, False, False]),
                    notes="DEMO_SEED" # Clearly identify synthetic demo records
                )
                db.add(b)
                count += 1
                
        db.commit()
        return count
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    count = seed_bookings()
    print(f"Seeded {count} historical demo bookings.")

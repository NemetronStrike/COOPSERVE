from datetime import date, datetime, timedelta
from typing import Any

from sqlalchemy import func, and_, or_
from sqlalchemy.orm import Session

from app.models.booking import Booking, BookingStatus
from app.models.service import Service
from app.models.user import Worker
from app.models.worker import WorkerSkill, Skill, Availability
from app.schemas.admin import DemandForecastResponse, CategoryForecast, DailyForecast


def get_forecast(db: Session, days: int = 7, historical_weeks: int = 4) -> DemandForecastResponse:
    today = date.today()
    # Get distinct categories from Services
    categories = [cat[0] for cat in db.query(Service.category).distinct().all()]

    forecasts: dict[str, CategoryForecast] = {}
    for cat in categories:
        forecasts[cat] = CategoryForecast(category=cat, daily_forecasts=[])

    for i in range(days):
        target_date = today + timedelta(days=i)
        target_dow = target_date.weekday()  # 0=Mon, 6=Sun

        for cat in categories:
            # 1. Forecast Demand
            # Average bookings for this category on the same day of the week over the last `historical_weeks`
            historical_dates = [target_date - timedelta(weeks=w) for w in range(1, historical_weeks + 1)]
            
            demand = 0.0
            for h_date in historical_dates:
                # Count bookings where scheduled_at falls on h_date
                h_start = datetime.combine(h_date, datetime.min.time())
                h_end = h_start + timedelta(days=1)
                
                count = (
                    db.query(Booking)
                    .join(Service, Service.id == Booking.service_id)
                    .filter(Service.category == cat)
                    .filter(Booking.scheduled_at >= h_start)
                    .filter(Booking.scheduled_at < h_end)
                    .filter(Booking.status != BookingStatus.cancelled)
                    .count()
                )
                demand += count
            
            avg_demand = demand / historical_weeks

            # 2. Estimate Supply
            # For this lightweight demo, start with base supply and subtract workers explicitly unavailable on this DOW or specific date
            unavailable_workers = (
                db.query(Availability.worker_id)
                .filter(Availability.is_available.is_(False))
                .filter(
                    or_(
                        Availability.day_of_week == target_dow,
                        Availability.specific_date == target_date
                    )
                )
                .distinct()
                .subquery()
            )

            # Subquery for workers who are already booked on this target date
            target_start = datetime.combine(target_date, datetime.min.time())
            target_end = target_start + timedelta(days=1)
            booked_workers = (
                db.query(Booking.worker_id)
                .filter(Booking.worker_id.isnot(None))
                .filter(Booking.scheduled_at >= target_start)
                .filter(Booking.scheduled_at < target_end)
                .filter(Booking.status.in_([
                    BookingStatus.pending, 
                    BookingStatus.accepted, 
                    BookingStatus.in_progress
                ]))
                .distinct()
                .subquery()
            )

            supply = (
                db.query(Worker)
                .join(WorkerSkill, WorkerSkill.worker_id == Worker.id)
                .join(Skill, Skill.id == WorkerSkill.skill_id)
                .filter(Worker.is_verified.is_(True))
                .filter(Skill.category == cat)
                .filter(Worker.id.not_in(unavailable_workers))
                .filter(Worker.id.not_in(booked_workers))
                .distinct()
                .count()
            )

            # Cap demand to an integer or single decimal, we'll round it
            predicted_demand = round(avg_demand, 1)

            forecasts[cat].daily_forecasts.append(
                DailyForecast(
                    date=target_date,
                    predicted_demand=predicted_demand,
                    available_supply=float(supply),
                    status="shortage" if predicted_demand > supply else "sufficient"
                )
            )

    return DemandForecastResponse(
        generated_at=datetime.utcnow(),
        forecasts=list(forecasts.values())
    )

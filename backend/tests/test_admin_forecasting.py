import unittest
from datetime import date, datetime, timedelta
from decimal import Decimal
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.core.database import Base, get_db
from app.models.user import User, UserRole, Customer, Worker, Admin
from app.models.service import Service
from app.models.worker import Skill, WorkerSkill
from app.models.booking import Booking, BookingStatus
from app.core.security import create_access_token

engine = create_engine(
    "sqlite://",
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
Base.metadata.create_all(engine)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()




class TestAdminForecasting(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        app.dependency_overrides[get_db] = override_get_db
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls) -> None:
        app.dependency_overrides.clear()

    def setUp(self) -> None:
        self.db = TestingSessionLocal()
        # Clean DB
        self.db.query(Booking).delete()
        self.db.query(WorkerSkill).delete()
        self.db.query(Skill).delete()
        self.db.query(Customer).delete()
        self.db.query(Worker).delete()
        self.db.query(Service).delete()
        self.db.query(Admin).delete()
        self.db.query(User).delete()
        self.db.commit()

        # Admin user
        self.admin_user = User(email="admin@ex.com", full_name="Admin", phone="1111111111", hashed_password="pw", role=UserRole.admin, is_active=True)
        self.db.add(self.admin_user)
        self.db.commit()
        self.admin_token = create_access_token(subject=str(self.admin_user.id), role=self.admin_user.role.value)
        self.headers = {"Authorization": f"Bearer {self.admin_token}"}
        
        # Service
        self.service = Service(name="Test Cleaning", category="Cleaning", base_price=Decimal("10.0"), is_active=True)
        self.db.add(self.service)
        
        # Worker
        self.worker_user = User(email="w@ex.com", full_name="Worker", phone="2222222222", hashed_password="pw", role=UserRole.worker, is_active=True)
        self.db.add(self.worker_user)
        self.db.commit()
        
        self.worker = Worker(user_id=self.worker_user.id, years_of_experience=2, is_verified=True)
        self.db.add(self.worker)
        self.db.commit()
        
        self.skill = Skill(name="Cleaning", category="Cleaning", is_active=True)
        self.db.add(self.skill)
        self.db.commit()
        
        self.db.add(WorkerSkill(worker_id=self.worker.id, skill_id=self.skill.id, is_primary=True))
        
        # Customer
        self.customer_user = User(email="c@ex.com", full_name="Cust", phone="3333333333", hashed_password="pw", role=UserRole.customer, is_active=True)
        self.db.add(self.customer_user)
        self.db.commit()
        
        # Seed bookings over last 4 weeks exactly on today's day of week
        today = date.today()
        # Create bookings for last 4 weeks same DOW
        for w in range(1, 5):
            d = today - timedelta(weeks=w)
            b = Booking(
                customer_id=self.customer_user.id,
                service_id=self.service.id,
                status=BookingStatus.completed,
                price=Decimal("10.0"),
                scheduled_at=datetime.combine(d, datetime.min.time()),
            )
            self.db.add(b)
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_get_forecasting(self) -> None:
        response = self.client.get("/admin/forecasting", headers=self.headers)
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertIn("forecasts", data)
        self.assertEqual(len(data["forecasts"]), 1)
        
        cat_forecast = data["forecasts"][0]
        self.assertEqual(cat_forecast["category"], "Cleaning")
        self.assertEqual(len(cat_forecast["daily_forecasts"]), 7)
        
        today_forecast = cat_forecast["daily_forecasts"][0]
        self.assertEqual(today_forecast["predicted_demand"], 1.0) # 4 bookings in 4 weeks
        self.assertEqual(today_forecast["available_supply"], 1.0)
        self.assertEqual(today_forecast["status"], "sufficient")

    def test_worker_overlap_booking(self) -> None:
        # Create a future active booking for the worker today
        today = date.today()
        b = Booking(
            customer_id=self.customer_user.id,
            service_id=self.service.id,
            worker_id=self.worker.id,
            status=BookingStatus.accepted,
            price=Decimal("10.0"),
            scheduled_at=datetime.combine(today, datetime.min.time()) + timedelta(hours=10),
        )
        self.db.add(b)
        self.db.commit()

        response = self.client.get("/admin/forecasting", headers=self.headers)
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        today_forecast = data["forecasts"][0]["daily_forecasts"][0]
        
        # The worker is booked today, so available supply should drop to 0
        self.assertEqual(today_forecast["available_supply"], 0.0)
        self.assertEqual(today_forecast["status"], "shortage")

    def test_unauthorized(self) -> None:
        # User auth instead of admin auth
        customer_token = create_access_token(subject=str(self.customer_user.id), role=self.customer_user.role.value)
        response = self.client.get("/admin/forecasting", headers={"Authorization": f"Bearer {customer_token}"})
        self.assertEqual(response.status_code, 403)

if __name__ == "__main__":
    unittest.main()

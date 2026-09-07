import unittest
from datetime import date, time, timedelta
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base
from app.core.security import require_admin
from app.models.booking import Booking, BookingStatus
from app.models.notification import Notification
from app.models.service import Service
from app.models.user import Admin, Customer, User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill, WorkerVerification
from app.schemas.booking import BookingCreate
from app.services.admin_service import dashboard, update_verification, workers
from app.services.booking_service import create_customer_booking
from app.services.notification_service import mark_notification_read, user_notifications


class AdminEmergencyNotificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        Base.metadata.create_all(engine)
        cls.session_factory = sessionmaker(bind=engine, expire_on_commit=False)

    def setUp(self) -> None:
        self.db: Session = self.session_factory()
        self.db.query(Notification).delete()
        self.db.query(WorkerVerification).delete()
        self.db.query(WorkerSkill).delete()
        self.db.query(Booking).delete()
        self.db.query(Skill).delete()
        self.db.query(Customer).delete()
        self.db.query(Admin).delete()
        self.db.query(Worker).delete()
        self.db.query(User).delete()
        self.db.query(Service).delete()

        service = Service(name="Home Cleaning", description="Cleaning", category="Cleaning", base_price=Decimal("500"), is_active=True)
        self.db.add(service)
        self.db.flush()
        admin_user = User(full_name="Admin", email="admin@test.com", phone="9500000001", role=UserRole.admin, hashed_password="test", is_active=True)
        customer_user = User(full_name="Customer", email="customer@test.com", phone="9500000002", role=UserRole.customer, hashed_password="test", is_active=True)
        worker_user = User(full_name="Worker", email="worker@test.com", phone="9500000003", role=UserRole.worker, hashed_password="test", is_active=True)
        self.db.add_all([admin_user, customer_user, worker_user])
        self.db.flush()
        self.admin = Admin(user_id=admin_user.id)
        self.customer = Customer(user_id=customer_user.id)
        self.worker = Worker(user_id=worker_user.id, years_of_experience=5, average_rating=4.5, total_jobs=20, is_verified=True)
        self.db.add_all([self.admin, self.customer, self.worker])
        self.db.flush()
        admin_user.admin_profile = self.admin
        customer_user.customer_profile = self.customer
        worker_user.worker_profile = self.worker
        skill = Skill(name="Home Cleaning", category="Cleaning", is_active=True)
        self.db.add(skill)
        self.db.flush()
        self.db.add(WorkerSkill(worker_id=self.worker.id, skill_id=skill.id, is_primary=True))
        self.db.commit()
        self.admin_user = admin_user
        self.customer_user = customer_user
        self.worker_user = worker_user
        self.service = service

    def tearDown(self) -> None:
        self.db.close()

    def test_admin_dashboard_and_verification(self) -> None:
        stats = dashboard(self.db)
        self.assertEqual(stats.total_customers, 1)
        self.assertEqual(stats.total_workers, 1)
        self.assertEqual(workers(self.db)[0].verification_status, "verified")
        updated = update_verification(self.db, self.worker.id, "rejected")
        self.assertEqual(updated.verification_status, "rejected")
        self.assertFalse(self.db.get(Worker, self.worker.id).is_verified)

        with self.assertRaisesRegex(HTTPException, "Admins only"):
            require_admin(self.customer_user)

    def test_emergency_booking_surcharge_and_event_notification(self) -> None:
        request = BookingCreate(
            service_id=self.service.id,
            worker_id=self.worker.id,
            scheduled_date=date.today() + timedelta(days=2),
            start_time=time(14),
            end_time=time(15),
            service_address="12 Cooperative Road",
            is_emergency=True,
        )
        booking = create_customer_booking(self.db, self.customer_user, request)
        self.assertEqual(booking.amount, Decimal("550.00"))
        self.assertTrue(booking.is_emergency)
        notes = user_notifications(self.db, self.customer_user)
        self.assertTrue(any(item.type == "booking_created" for item in notes))
        unread = next(item for item in notes if not item.is_read)
        marked = mark_notification_read(self.db, self.customer_user, unread.id)
        self.assertTrue(marked.is_read)
        with self.assertRaisesRegex(HTTPException, "Notification not found"):
            mark_notification_read(self.db, self.worker_user, unread.id)


if __name__ == "__main__":
    unittest.main()
import unittest
from datetime import date, time, timedelta
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.models.booking import Booking, BookingStatus
from app.models.service import Service
from app.models.user import Customer, User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill
from app.schemas.booking import BookingCreate
from app.services.booking_service import create_customer_booking, cancel_customer_booking, update_booking_status
from app.core.database import Base


class CancellationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        Base.metadata.create_all(engine)
        cls.session_factory = sessionmaker(bind=engine, expire_on_commit=False)

    def setUp(self) -> None:
        self.db: Session = self.session_factory()
        self.db.query(Booking).delete()
        self.db.query(WorkerSkill).delete()
        self.db.query(Skill).delete()
        self.db.query(Customer).delete()
        self.db.query(Worker).delete()
        self.db.query(User).delete()
        self.db.query(Service).delete()

        self.service = Service(
            name="Test Service",
            description="Test Description",
            category="Test Category",
            base_price=Decimal("100.00"),
            is_active=True,
        )
        self.db.add(self.service)
        self.db.flush()

        customer_user1 = User(full_name="C1", email="c1@example.com", phone="11", role=UserRole.customer, hashed_password="pw", is_active=True)
        worker_user = User(full_name="W1", email="w1@example.com", phone="21", role=UserRole.worker, hashed_password="pw", is_active=True)
        self.db.add_all([customer_user1, worker_user])
        self.db.flush()

        self.customer1 = Customer(user_id=customer_user1.id)
        self.worker = Worker(user_id=worker_user.id, years_of_experience=1, average_rating=0.0, total_jobs=0, is_verified=True)
        self.db.add_all([self.customer1, self.worker])
        self.db.flush()
        
        customer_user1.customer_profile = self.customer1
        worker_user.worker_profile = self.worker

        self.db.commit()
        self.db.refresh(customer_user1)
        self.db.refresh(worker_user)
        self.db.refresh(self.worker)
        
        skill = Skill(name="Test Service", category="Test Category", is_active=True)
        self.db.add(skill)
        self.db.flush()
        self.db.add(WorkerSkill(worker_id=self.worker.id, skill_id=skill.id, is_primary=True))
        self.db.commit()

        self.customer_user1 = customer_user1
        self.worker_user = worker_user

    def tearDown(self) -> None:
        self.db.close()

    def test_customer_can_cancel_pending_booking(self) -> None:
        booking_req = BookingCreate(service_id=self.service.id, worker_id=self.worker.id, scheduled_date=date.today() + timedelta(days=2), start_time=time(10, 0), end_time=time(11, 0), service_address="Add1")
        booking = create_customer_booking(self.db, self.customer_user1, booking_req)
        
        self.assertEqual(booking.status, BookingStatus.pending)
        cancelled = cancel_customer_booking(self.db, self.customer_user1, booking.id)
        self.assertEqual(cancelled.status, BookingStatus.cancelled)

    def test_customer_can_cancel_accepted_booking(self) -> None:
        booking_req = BookingCreate(service_id=self.service.id, worker_id=self.worker.id, scheduled_date=date.today() + timedelta(days=2), start_time=time(10, 0), end_time=time(11, 0), service_address="Add1")
        booking = create_customer_booking(self.db, self.customer_user1, booking_req)
        update_booking_status(self.db, self.worker_user, booking.id, BookingStatus.accepted)
        
        cancelled = cancel_customer_booking(self.db, self.customer_user1, booking.id)
        self.assertEqual(cancelled.status, BookingStatus.cancelled)

    def test_customer_cannot_cancel_in_progress_booking(self) -> None:
        booking_req = BookingCreate(service_id=self.service.id, worker_id=self.worker.id, scheduled_date=date.today() + timedelta(days=2), start_time=time(10, 0), end_time=time(11, 0), service_address="Add1")
        booking = create_customer_booking(self.db, self.customer_user1, booking_req)
        update_booking_status(self.db, self.worker_user, booking.id, BookingStatus.accepted)
        update_booking_status(self.db, self.worker_user, booking.id, BookingStatus.in_progress)
        
        with self.assertRaisesRegex(HTTPException, "Only pending or accepted bookings can be cancelled"):
            cancel_customer_booking(self.db, self.customer_user1, booking.id)

if __name__ == "__main__":
    unittest.main()

import unittest
from datetime import date, time, timedelta
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.models.booking import Booking, BookingStatus
from app.models.rating import Rating
from app.models.service import Service
from app.models.user import Customer, User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill
from app.schemas.booking import BookingCreate
from app.services.booking_service import create_customer_booking, update_booking_status
from app.services.rating_service import create_customer_rating, get_booking_rating
from app.core.database import Base


class RatingTests(unittest.TestCase):
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
        self.db.query(Rating).delete()
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
        customer_user2 = User(full_name="C2", email="c2@example.com", phone="12", role=UserRole.customer, hashed_password="pw", is_active=True)
        worker_user = User(full_name="W1", email="w1@example.com", phone="21", role=UserRole.worker, hashed_password="pw", is_active=True)
        self.db.add_all([customer_user1, customer_user2, worker_user])
        self.db.flush()

        self.customer1 = Customer(user_id=customer_user1.id)
        self.customer2 = Customer(user_id=customer_user2.id)
        self.worker = Worker(user_id=worker_user.id, years_of_experience=1, average_rating=0.0, total_jobs=0, is_verified=True)
        self.db.add_all([self.customer1, self.customer2, self.worker])
        self.db.flush()
        
        customer_user1.customer_profile = self.customer1
        customer_user2.customer_profile = self.customer2
        worker_user.worker_profile = self.worker

        self.db.commit()
        self.db.refresh(customer_user1)
        self.db.refresh(customer_user2)
        self.db.refresh(worker_user)
        self.db.refresh(self.worker)
        
        skill = Skill(name="Test Service", category="Test Category", is_active=True)
        self.db.add(skill)
        self.db.flush()
        self.db.add(WorkerSkill(worker_id=self.worker.id, skill_id=skill.id, is_primary=True))
        self.db.commit()

        self.customer_user1 = customer_user1
        self.customer_user2 = customer_user2
        self.worker_user = worker_user

    def tearDown(self) -> None:
        self.db.close()

    def test_rating_updates_average_and_total(self) -> None:
        # Create booking 1
        booking1_req = BookingCreate(service_id=self.service.id, worker_id=self.worker.id, scheduled_date=date.today(), start_time=time(10, 0), end_time=time(11, 0), service_address="Add1")
        booking1 = create_customer_booking(self.db, self.customer_user1, booking1_req)
        # Advance status to completed
        update_booking_status(self.db, self.worker_user, booking1.id, BookingStatus.accepted)
        update_booking_status(self.db, self.worker_user, booking1.id, BookingStatus.in_progress)
        update_booking_status(self.db, self.worker_user, booking1.id, BookingStatus.completed)

        # Create rating
        create_customer_rating(self.db, self.customer_user1, booking1.id, rating_value=4, review="Good")

        self.db.refresh(self.worker)
        self.assertEqual(self.worker.average_rating, 4.0)
        self.assertEqual(self.worker.total_jobs, 1)

        # Create booking 2
        booking2_req = BookingCreate(service_id=self.service.id, worker_id=self.worker.id, scheduled_date=date.today(), start_time=time(12, 0), end_time=time(13, 0), service_address="Add2")
        booking2 = create_customer_booking(self.db, self.customer_user2, booking2_req)
        update_booking_status(self.db, self.worker_user, booking2.id, BookingStatus.accepted)
        update_booking_status(self.db, self.worker_user, booking2.id, BookingStatus.in_progress)
        update_booking_status(self.db, self.worker_user, booking2.id, BookingStatus.completed)

        # Create rating
        create_customer_rating(self.db, self.customer_user2, booking2.id, rating_value=5, review="Great")

        self.db.refresh(self.worker)
        self.assertEqual(self.worker.average_rating, 4.5)
        self.assertEqual(self.worker.total_jobs, 2)

    def test_duplicate_rating_rejected(self) -> None:
        booking1_req = BookingCreate(service_id=self.service.id, worker_id=self.worker.id, scheduled_date=date.today(), start_time=time(10, 0), end_time=time(11, 0), service_address="Add1")
        booking1 = create_customer_booking(self.db, self.customer_user1, booking1_req)
        update_booking_status(self.db, self.worker_user, booking1.id, BookingStatus.accepted)
        update_booking_status(self.db, self.worker_user, booking1.id, BookingStatus.in_progress)
        update_booking_status(self.db, self.worker_user, booking1.id, BookingStatus.completed)

        create_customer_rating(self.db, self.customer_user1, booking1.id, rating_value=4, review="Good")
        
        with self.assertRaisesRegex(HTTPException, "Booking is already rated"):
            create_customer_rating(self.db, self.customer_user1, booking1.id, rating_value=5, review="Duplicate")

if __name__ == "__main__":
    unittest.main()

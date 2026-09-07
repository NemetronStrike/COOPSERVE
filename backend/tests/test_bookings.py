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
from app.schemas.booking import BookingCreate, BookingResponse
from app.services.booking_service import (
    booking_details,
    create_customer_booking,
    customer_bookings,
    update_booking_status,
    worker_bookings,
)
from app.core.database import Base


class BookingTests(unittest.TestCase):
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
            name="Home Cleaning",
            description="Cleaning",
            category="Cleaning",
            base_price=Decimal("499.00"),
            is_active=True,
        )
        other_service = Service(
            name="Electrical Repair",
            description="Repairs",
            category="Repairs",
            base_price=Decimal("299.00"),
            is_active=True,
        )
        self.db.add_all([self.service, other_service])
        self.db.flush()

        customer_user = User(
            full_name="Customer One", email="customer1@example.com",
            phone="9100000001", role=UserRole.customer,
            hashed_password="test", is_active=True,
        )
        other_customer_user = User(
            full_name="Customer Two", email="customer2@example.com",
            phone="9100000002", role=UserRole.customer,
            hashed_password="test", is_active=True,
        )
        worker_user = User(
            full_name="Worker One", email="worker1@example.com",
            phone="9200000001", role=UserRole.worker,
            hashed_password="test", is_active=True,
        )
        other_worker_user = User(
            full_name="Worker Two", email="worker2@example.com",
            phone="9200000002", role=UserRole.worker,
            hashed_password="test", is_active=True,
        )
        self.db.add_all([customer_user, other_customer_user, worker_user, other_worker_user])
        self.db.flush()

        self.customer = Customer(user_id=customer_user.id)
        self.other_customer = Customer(user_id=other_customer_user.id)
        self.worker = Worker(
            user_id=worker_user.id, years_of_experience=6,
            average_rating=4.8, total_jobs=100, is_verified=True,
        )
        self.other_worker = Worker(
            user_id=other_worker_user.id, years_of_experience=4,
            average_rating=4.5, total_jobs=40, is_verified=True,
        )
        self.db.add_all([self.customer, self.other_customer, self.worker, self.other_worker])
        self.db.flush()
        customer_user.customer_profile = self.customer
        other_customer_user.customer_profile = self.other_customer
        worker_user.worker_profile = self.worker
        other_worker_user.worker_profile = self.other_worker

        skill = Skill(name="Home Cleaning", category="Cleaning", is_active=True)
        self.db.add(skill)
        self.db.flush()
        self.db.add_all([
            WorkerSkill(worker_id=self.worker.id, skill_id=skill.id, is_primary=True),
            WorkerSkill(worker_id=self.other_worker.id, skill_id=skill.id, is_primary=True),
        ])
        self.db.commit()
        self.db.refresh(customer_user)
        self.db.refresh(other_customer_user)
        self.db.refresh(worker_user)
        self.db.refresh(other_worker_user)
        self.customer_user = customer_user
        self.other_customer_user = other_customer_user
        self.worker_user = worker_user
        self.other_worker_user = other_worker_user

    def tearDown(self) -> None:
        self.db.close()

    def request(self, **overrides) -> BookingCreate:
        values = {
            "service_id": self.service.id,
            "worker_id": self.worker.id,
            "scheduled_date": date.today() + timedelta(days=2),
            "start_time": time(14, 0),
            "end_time": time(15, 0),
            "service_address": "12 Cooperative Road",
        }
        values.update(overrides)
        return BookingCreate(**values)

    def test_customer_can_create_booking_with_service_price(self) -> None:
        result = create_customer_booking(self.db, self.customer_user, self.request())
        self.assertEqual(result.status, BookingStatus.pending)
        self.assertEqual(result.amount, Decimal("499.00"))
        self.assertEqual(result.service_address, "12 Cooperative Road")
        orm_booking = self.db.query(Booking).one()
        self.assertEqual(
            BookingResponse.model_validate(orm_booking).amount,
            Decimal("499.00"),
        )

    def test_non_customer_cannot_create_booking(self) -> None:
        with self.assertRaisesRegex(HTTPException, "Customers only"):
            create_customer_booking(self.db, self.worker_user, self.request())

    def test_invalid_service_worker_and_time_are_rejected(self) -> None:
        with self.assertRaisesRegex(HTTPException, "Service not found"):
            create_customer_booking(self.db, self.customer_user, self.request(service_id=999))
        with self.assertRaisesRegex(HTTPException, "not eligible"):
            create_customer_booking(self.db, self.customer_user, self.request(worker_id=999))
        with self.assertRaisesRegex(HTTPException, "End time"):
            create_customer_booking(self.db, self.customer_user, self.request(end_time=time(13, 0)))
        with self.assertRaises(ValueError):
            self.request(service_address="   ")

    def test_overlapping_booking_is_rejected(self) -> None:
        create_customer_booking(self.db, self.customer_user, self.request())
        with self.assertRaisesRegex(HTTPException, "already booked"):
            create_customer_booking(
                self.db,
                self.other_customer_user,
                self.request(start_time=time(14, 30), end_time=time(15, 30)),
            )

    def test_customer_and_worker_ownership(self) -> None:
        created = create_customer_booking(self.db, self.customer_user, self.request())
        self.assertEqual(len(customer_bookings(self.db, self.customer_user)), 1)
        self.assertEqual(len(worker_bookings(self.db, self.worker_user)), 1)
        with self.assertRaisesRegex(HTTPException, "Booking not found"):
            booking_details(self.db, self.other_customer_user, created.id)
        self.assertEqual(booking_details(self.db, self.customer_user, created.id).id, created.id)

    def test_worker_status_lifecycle_and_invalid_jump(self) -> None:
        created = create_customer_booking(self.db, self.customer_user, self.request())
        accepted = update_booking_status(self.db, self.worker_user, created.id, BookingStatus.accepted)
        self.assertEqual(accepted.status, BookingStatus.accepted)
        in_progress = update_booking_status(self.db, self.worker_user, created.id, BookingStatus.in_progress)
        self.assertEqual(in_progress.status, BookingStatus.in_progress)
        completed = update_booking_status(self.db, self.worker_user, created.id, BookingStatus.completed)
        self.assertEqual(completed.status, BookingStatus.completed)

        with self.assertRaisesRegex(HTTPException, "Invalid booking status"):
            update_booking_status(self.db, self.worker_user, created.id, BookingStatus.pending)

    def test_unassigned_worker_cannot_update_booking(self) -> None:
        created = create_customer_booking(self.db, self.customer_user, self.request())
        with self.assertRaisesRegex(HTTPException, "Booking not found"):
            update_booking_status(self.db, self.other_worker_user, created.id, BookingStatus.accepted)


if __name__ == "__main__":
    unittest.main()
import unittest
from datetime import date, time, timedelta
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.database import Base
from app.models.booking import Booking, BookingStatus
from app.models.payment import Invoice, Payment
from app.models.rating import Rating
from app.models.service import Service
from app.models.user import Customer, User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill
from app.schemas.booking import BookingCreate
from app.schemas.rating import RatingCreate
from app.services.booking_service import create_customer_booking, update_booking_status
from app.services.payment_service import create_mock_payment, get_booking_invoice, get_customer_payment
from app.services.rating_service import create_customer_rating, get_booking_rating


class TransactionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
        Base.metadata.create_all(engine)
        cls.session_factory = sessionmaker(bind=engine, expire_on_commit=False)

    def setUp(self) -> None:
        self.db: Session = self.session_factory()
        self.db.query(Rating).delete()
        self.db.query(Invoice).delete()
        self.db.query(Payment).delete()
        self.db.query(Booking).delete()
        self.db.query(WorkerSkill).delete()
        self.db.query(Skill).delete()
        self.db.query(Customer).delete()
        self.db.query(Worker).delete()
        self.db.query(User).delete()
        self.db.query(Service).delete()

        service = Service(name="Home Cleaning", description="Cleaning", category="Cleaning", base_price=Decimal("499"), is_active=True)
        self.db.add(service)
        self.db.flush()
        customer_user = User(full_name="Customer One", email="tx-customer@example.com", phone="9400000001", role=UserRole.customer, hashed_password="test", is_active=True)
        other_user = User(full_name="Customer Two", email="tx-other@example.com", phone="9400000002", role=UserRole.customer, hashed_password="test", is_active=True)
        worker_user = User(full_name="Worker One", email="tx-worker@example.com", phone="9400000003", role=UserRole.worker, hashed_password="test", is_active=True)
        self.db.add_all([customer_user, other_user, worker_user])
        self.db.flush()
        self.customer = Customer(user_id=customer_user.id)
        self.other_customer = Customer(user_id=other_user.id)
        self.worker = Worker(user_id=worker_user.id, years_of_experience=5, average_rating=4.8, total_jobs=20, is_verified=True)
        self.db.add_all([self.customer, self.other_customer, self.worker])
        self.db.flush()
        customer_user.customer_profile = self.customer
        other_user.customer_profile = self.other_customer
        worker_user.worker_profile = self.worker
        skill = Skill(name="Home Cleaning", category="Cleaning", is_active=True)
        self.db.add(skill)
        self.db.flush()
        self.db.add(WorkerSkill(worker_id=self.worker.id, skill_id=skill.id, is_primary=True))
        self.db.commit()
        self.customer_user = customer_user
        self.other_user = other_user
        self.worker_user = worker_user
        self.service = service

    def tearDown(self) -> None:
        self.db.close()

    def _booking(self, *, status: BookingStatus = BookingStatus.pending):
        request = BookingCreate(
            service_id=self.service.id,
            worker_id=self.worker.id,
            scheduled_date=date.today() + timedelta(days=2),
            start_time=time(14),
            end_time=time(15),
            service_address="12 Cooperative Road",
        )
        booking = create_customer_booking(self.db, self.customer_user, request)
        if status != BookingStatus.pending:
            self.db.query(Booking).filter(Booking.id == booking.id).update({"status": status})
            self.db.commit()
        return booking.id

    def test_payment_uses_booking_amount_and_duplicate_is_rejected(self) -> None:
        booking_id = self._booking()
        payment = create_mock_payment(self.db, self.customer_user, booking_id, "mock")
        self.assertEqual(payment.amount, Decimal("499.00"))
        self.assertEqual(payment.status, "success")
        self.assertTrue(payment.transaction_reference.startswith("MOCK-"))
        with self.assertRaisesRegex(HTTPException, "already paid"):
            create_mock_payment(self.db, self.customer_user, booking_id, "mock")

    def test_payment_and_invoice_authorization(self) -> None:
        booking_id = self._booking()
        payment = create_mock_payment(self.db, self.customer_user, booking_id, "mock")
        self.assertEqual(get_customer_payment(self.db, self.customer_user, payment.id).booking_id, booking_id)
        with self.assertRaisesRegex(HTTPException, "Payment not found"):
            get_customer_payment(self.db, self.other_user, payment.id)
        invoice = get_booking_invoice(self.db, self.customer_user, booking_id)
        self.assertEqual(invoice.invoice_number, f"INV-{payment.id}")
        self.assertEqual(invoice.total, Decimal("499.00"))
        with self.assertRaisesRegex(HTTPException, "Invoice not found"):
            get_booking_invoice(self.db, self.other_user, booking_id)

    def test_rating_requires_completed_booking_and_prevents_duplicates(self) -> None:
        booking_id = self._booking()
        with self.assertRaisesRegex(HTTPException, "completed bookings"):
            create_customer_rating(self.db, self.customer_user, booking_id, 5, "Good")
        self.db.query(Booking).filter(Booking.id == booking_id).update({"status": BookingStatus.completed})
        self.db.commit()
        rating = create_customer_rating(self.db, self.customer_user, booking_id, 5, "Excellent service")
        self.assertEqual(rating.rating, 5)
        self.assertEqual(get_booking_rating(self.db, self.customer_user, booking_id).review, "Excellent service")
        with self.assertRaisesRegex(HTTPException, "already rated"):
            create_customer_rating(self.db, self.customer_user, booking_id, 4, "Again")

    def test_rating_validation_and_ownership(self) -> None:
        booking_id = self._booking(status=BookingStatus.completed)
        with self.assertRaisesRegex(HTTPException, "Booking not found"):
            create_customer_rating(self.db, self.other_user, booking_id, 5, None)
        with self.assertRaises(ValueError):
            RatingCreate(booking_id=booking_id, rating=0, review="Invalid")


if __name__ == "__main__":
    unittest.main()
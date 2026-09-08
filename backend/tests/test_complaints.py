import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.core.database import Base, get_db
from app.models.user import User, UserRole, Customer, Admin
from app.core.security import create_access_token
from app.models.rating import ComplaintCategory, ComplaintSeverity, ComplaintUrgency, ComplaintStatus, Complaint
from app.models.service import Service
from app.models.booking import Booking
from datetime import datetime, timedelta, timezone

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


class TestComplaints(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        app.dependency_overrides[get_db] = override_get_db
        cls.client = TestClient(app)

    @classmethod
    def tearDownClass(cls) -> None:
        app.dependency_overrides.clear()

    def setUp(self) -> None:
        self.db = TestingSessionLocal()
        self.db.query(Complaint).delete()
        self.db.query(Booking).delete()
        self.db.query(Service).delete()
        self.db.query(Customer).delete()
        self.db.query(Admin).delete()
        self.db.query(User).delete()
        self.db.commit()

        self.customer_user = User(email="cust@ex.com", phone="1234567890", full_name="Customer", hashed_password="pw", role=UserRole.customer, is_active=True)
        self.admin_user = User(email="admin@ex.com", phone="1111111111", full_name="Admin", hashed_password="pw", role=UserRole.admin, is_active=True)
        
        self.db.add(self.customer_user)
        self.db.add(self.admin_user)
        self.db.commit()
        
        self.customer = Customer(user_id=self.customer_user.id)
        self.admin = Admin(user_id=self.admin_user.id)
        self.db.add(self.customer)
        self.db.add(self.admin)
        self.db.commit()
        
        self.customer_user.customer_profile = self.customer
        self.admin_user.admin_profile = self.admin
        
        self.db.refresh(self.customer_user)
        self.db.refresh(self.admin_user)
        
        self.customer_token = create_access_token(subject=str(self.customer_user.id), role=self.customer_user.role)
        self.admin_token = create_access_token(subject=str(self.admin_user.id), role=self.admin_user.role)
        
        self.headers_customer = {"Authorization": f"Bearer {self.customer_token}"}
        self.headers_admin = {"Authorization": f"Bearer {self.admin_token}"}

        self.service = Service(category="Test Category", name="Test Service", description="Test", base_price=10.0, is_active=True)
        self.db.add(self.service)
        self.db.commit()

        self.booking = Booking(
            customer_id=self.customer.id,
            service_id=self.service.id,
            scheduled_at=datetime.now(timezone.utc) + timedelta(days=1),
            price=10.0
        )
        self.db.add(self.booking)
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    @patch("app.services.complaint_service.generate_structured_json")
    def test_customer_can_create_complaint_mocked_gemini(self, mock_gemini):
        mock_gemini.return_value = {
            "category": "service_quality",
            "severity": "medium",
            "urgency": "medium",
            "summary": "Service was not great.",
            "suggested_action": "Review the service."
        }
        
        payload = {
            "category": "service_quality",
            "description": "The service was really bad and not up to the mark.",
            "booking_id": self.booking.id
        }
        response = self.client.post("/complaints/", json=payload, headers=self.headers_customer)
        self.assertEqual(response.status_code, 201)
        data = response.json()
        self.assertEqual(data["category"], "service_quality")
        self.assertEqual(data["classification_source"], "gemini")
        self.assertEqual(data["summary"], "Service was not great.")

    @patch("app.services.complaint_service.generate_structured_json")
    def test_customer_can_create_complaint_fallback(self, mock_gemini):
        mock_gemini.return_value = None  # Simulate Gemini failure
        
        payload = {
            "category": "other",
            "description": "The worker didn't arrive for my scheduled booking.",
            "booking_id": self.booking.id
        }
        response = self.client.post("/complaints/", json=payload, headers=self.headers_customer)
        self.assertEqual(response.status_code, 201)
        data = response.json()
        self.assertEqual(data["category"], "no_show")
        self.assertEqual(data["classification_source"], "fallback")
        self.assertEqual(data["severity"], "high")

    @patch("app.services.complaint_service.generate_structured_json")
    def test_customer_can_create_complaint_malformed_gemini(self, mock_gemini):
        mock_gemini.return_value = {"invalid": "schema", "category": "not_an_enum"}  # Malformed
        
        payload = {
            "category": "other",
            "description": "The worker didn't arrive for my scheduled booking.",
            "booking_id": self.booking.id
        }
        response = self.client.post("/complaints/", json=payload, headers=self.headers_customer)
        self.assertEqual(response.status_code, 201)
        data = response.json()
        self.assertEqual(data["classification_source"], "fallback")
        self.assertEqual(data["category"], "no_show")

    def test_get_customer_complaints(self):
        response = self.client.get("/complaints/customer", headers=self.headers_customer)
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.json(), list)

    def test_admin_can_get_all_complaints(self):
        response = self.client.get("/complaints/admin", headers=self.headers_admin)
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response.json(), list)

    def test_customer_cannot_get_all_complaints(self):
        response = self.client.get("/complaints/admin", headers=self.headers_customer)
        self.assertEqual(response.status_code, 403)

    @patch("app.services.complaint_service.generate_structured_json")
    def test_admin_can_update_complaint_status(self, mock_gemini):
        mock_gemini.return_value = None
        payload = {
            "category": "other",
            "description": "Some complaint to update.",
            "booking_id": self.booking.id
        }
        res_create = self.client.post("/complaints/", json=payload, headers=self.headers_customer)
        complaint_id = res_create.json()["id"]

        update_payload = {
            "status": "resolved",
            "resolution_notes": "Issue resolved after investigation."
        }
        res_update = self.client.patch(f"/complaints/admin/{complaint_id}/status", json=update_payload, headers=self.headers_admin)
        self.assertEqual(res_update.status_code, 200)
        self.assertEqual(res_update.json()["status"], "resolved")

    @patch("app.services.complaint_service.generate_structured_json")
    def test_customer_cannot_update_complaint_status(self, mock_gemini):
        mock_gemini.return_value = None
        payload = {
            "category": "other",
            "description": "Some complaint to update.",
            "booking_id": self.booking.id
        }
        res_create = self.client.post("/complaints/", json=payload, headers=self.headers_customer)
        complaint_id = res_create.json()["id"]

        update_payload = {
            "status": "resolved",
            "resolution_notes": "I resolve it myself."
        }
        res_update = self.client.patch(f"/complaints/admin/{complaint_id}/status", json=update_payload, headers=self.headers_customer)
        self.assertEqual(res_update.status_code, 403)

if __name__ == "__main__":
    unittest.main()

import unittest
from unittest.mock import patch
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from decimal import Decimal

from app.main import app
from app.core.database import Base, get_db
from app.models.user import User, UserRole, Customer, Worker
from app.models.service import Service
from app.models.worker import Skill, WorkerSkill
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

app.dependency_overrides[get_db] = override_get_db

class TestAIEndpoints(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)

    def setUp(self) -> None:
        self.db = TestingSessionLocal()
        self.db.query(WorkerSkill).delete()
        self.db.query(Skill).delete()
        self.db.query(Customer).delete()
        self.db.query(Worker).delete()
        self.db.query(Service).delete()
        self.db.query(User).delete()
        self.db.commit()

        self.service1 = Service(name="Plumbing", description="Fix pipes", category="Home", base_price=Decimal("50.0"), is_active=True)
        self.db.add(self.service1)
        
        self.customer_user = User(email="cust@ex.com", phone="1234567890", full_name="Customer", hashed_password="pw", role=UserRole.customer, is_active=True)
        self.db.add(self.customer_user)
        self.db.commit()
        
        self.customer = Customer(user_id=self.customer_user.id)
        self.db.add(self.customer)
        self.customer_user.customer_profile = self.customer
        
        # Add a worker for the service
        self.worker_user = User(email="w1@ex.com", phone="0987654321", full_name="Worker", hashed_password="pw", role=UserRole.worker, is_active=True)
        self.db.add(self.worker_user)
        self.db.commit()
        
        self.worker = Worker(user_id=self.worker_user.id, years_of_experience=5, average_rating=4.5, total_jobs=10, is_verified=True)
        self.db.add(self.worker)
        self.worker_user.worker_profile = self.worker
        
        self.skill = Skill(name="Plumbing", category="Home", is_active=True)
        self.db.add(self.skill)
        self.db.commit()
        
        self.worker_skill = WorkerSkill(worker_id=self.worker.id, skill_id=self.skill.id, is_primary=True)
        self.db.add(self.worker_skill)
        self.db.commit()
        
        self.db.refresh(self.service1)
        self.db.refresh(self.customer_user)
        self.customer_token = create_access_token(subject=str(self.customer_user.id), role=self.customer_user.role)
        self.headers = {"Authorization": f"Bearer {self.customer_token}"}

    def tearDown(self) -> None:
        self.db.close()

    @patch("app.api.routes.ai.generate_structured_json")
    def test_search_services_fallback(self, mock_ai) -> None:
        mock_ai.return_value = {}
        response = self.client.post("/ai/service-search", json={"query": "Plumbing"}, headers=self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertIn("services", response.json())
        self.assertTrue(len(response.json()["services"]) >= 1)
        self.assertEqual(response.json()["services"][0]["name"], "Plumbing")

    @patch("app.api.routes.ai.generate_structured_json")
    def test_search_services_mock(self, mock_ai) -> None:
        mock_ai.return_value = {
            "intent": "Testing search",
            "search_keywords": ["Plumbing"],
            "suggested_category": "Home",
            "urgency": "normal"
        }
        response = self.client.post("/ai/service-search", json={"query": "I need plumbing"}, headers=self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["interpretation"], "Testing search")

    @patch("app.api.routes.ai.generate_structured_json")
    def test_match_workers_fallback(self, mock_ai) -> None:
        mock_ai.return_value = {}
        response = self.client.post("/ai/match-workers", json={"service_id": self.service1.id, "urgency": "high"}, headers=self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertIn("matches", response.json())
        self.assertEqual(len(response.json()["matches"]), 1)
        self.assertEqual(response.json()["matches"][0]["id"], self.worker.id)
        self.assertEqual(response.json()["matches"][0]["match_score"], 60.0)

    @patch("app.api.routes.ai.generate_structured_json")
    def test_match_workers_mock(self, mock_ai) -> None:
        mock_ai.return_value = {
            "explanations": {
                str(self.worker.id): "AI customized explanation"
            }
        }
        response = self.client.post("/ai/match-workers", json={"service_id": self.service1.id, "urgency": "high"}, headers=self.headers)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["matches"][0]["explanation"], "AI customized explanation")

    def test_unauthorized(self) -> None:
        response = self.client.post("/ai/service-search", json={"query": "Plumbing"})
        self.assertEqual(response.status_code, 401)

if __name__ == "__main__":
    unittest.main()

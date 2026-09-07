import unittest
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.routes.workers import worker_detail, workers
from app.core.database import Base
from app.models.service import Service
from app.models.user import User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill


class WorkerDiscoveryTests(unittest.TestCase):
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
        self.db.query(WorkerSkill).delete()
        self.db.query(Worker).delete()
        self.db.query(Skill).delete()
        self.db.query(User).delete()
        self.db.query(Service).delete()

        cleaning = Service(
            name="Home Cleaning",
            description="Cleaning",
            category="Cleaning",
            base_price=Decimal("499.00"),
            is_active=True,
        )
        repairs = Service(
            name="Electrical Repair",
            description="Repairs",
            category="Repairs",
            base_price=Decimal("299.00"),
            is_active=True,
        )
        unmatched = Service(
            name="Gardening",
            description="Home care",
            category="Home Care",
            base_price=Decimal("449.00"),
            is_active=True,
        )
        self.db.add_all([cleaning, repairs, unmatched])
        self.db.flush()

        self.db.add_all([
            User(
                id=1,
                full_name="Aarav Sharma",
                email="aarav@example.com",
                phone="9000000001",
                role=UserRole.worker,
                hashed_password="test",
                is_active=True,
            ),
            User(
                id=2,
                full_name="Rohan Verma",
                email="rohan@example.com",
                phone="9000000002",
                role=UserRole.worker,
                hashed_password="test",
                is_active=True,
            ),
        ])
        self.db.flush()
        workers_db = [
            Worker(
                id=1,
                user_id=1,
                years_of_experience=6,
                average_rating=4.8,
                total_jobs=142,
                is_verified=True,
            ),
            Worker(
                id=2,
                user_id=2,
                years_of_experience=8,
                average_rating=4.9,
                total_jobs=176,
                is_verified=True,
            ),
        ]
        self.db.add_all(workers_db)
        cleaning_skill = Skill(name="Home Cleaning", category="Cleaning", is_active=True)
        repair_skill = Skill(name="Electrical Repair", category="Repairs", is_active=True)
        self.db.add_all([cleaning_skill, repair_skill])
        self.db.flush()
        self.db.add_all([
            WorkerSkill(worker_id=1, skill_id=cleaning_skill.id, is_primary=True),
            WorkerSkill(worker_id=2, skill_id=repair_skill.id, is_primary=True),
        ])
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_lists_workers(self) -> None:
        result = workers(service_id=None, db=self.db)
        self.assertEqual(len(result), 2)
        self.assertEqual(result[0].name, "Rohan Verma")

    def test_filters_workers_by_service(self) -> None:
        service_id = self.db.query(Service).filter(Service.name == "Home Cleaning").one().id
        result = workers(service_id=service_id, db=self.db)
        self.assertEqual([worker.name for worker in result], ["Aarav Sharma"])

    def test_no_matching_service_workers(self) -> None:
        service_id = self.db.query(Service).filter(Service.name == "Gardening").one().id
        result = workers(service_id=service_id, db=self.db)
        self.assertEqual(result, [])

    def test_worker_detail_and_invalid_id(self) -> None:
        result = worker_detail(worker_id=1, db=self.db)
        self.assertEqual(result.name, "Aarav Sharma")

        with self.assertRaisesRegex(HTTPException, "Worker not found"):
            worker_detail(worker_id=999, db=self.db)

    def test_invalid_service_id(self) -> None:
        with self.assertRaisesRegex(HTTPException, "Service not found"):
            workers(service_id=999, db=self.db)


if __name__ == "__main__":
    unittest.main()
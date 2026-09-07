import unittest
from decimal import Decimal

from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.api.routes.services import service_detail, services
from app.models.service import Service
from app.services.service_catalog_service import get_service


class ServiceCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        Service.__table__.create(engine)
        cls.session_factory = sessionmaker(bind=engine, expire_on_commit=False)

    def setUp(self) -> None:
        self.db: Session = self.session_factory()
        self.db.query(Service).delete()
        self.db.add_all(
            [
                Service(
                    name="Home Cleaning",
                    description="A fresh home with trusted help",
                    category="Cleaning",
                    base_price=Decimal("499.00"),
                    is_active=True,
                ),
                Service(
                    name="Electrical Repair",
                    description="Skilled electrical support",
                    category="Repairs",
                    base_price=Decimal("299.00"),
                    is_active=True,
                ),
                Service(
                    name="Hidden Service",
                    description="Inactive catalog item",
                    category="Other",
                    base_price=Decimal("100.00"),
                    is_active=False,
                ),
            ]
        )
        self.db.commit()

    def tearDown(self) -> None:
        self.db.close()

    def test_lists_only_active_services(self) -> None:
        response = services(search=None, category=None, db=self.db)
        self.assertEqual(len(response), 2)

    def test_search_and_category_filters(self) -> None:
        response = services(
            search="ELECTRICAL",
            category="Repairs",
            db=self.db,
        )
        self.assertEqual(response[0].name, "Electrical Repair")

    def test_empty_search_result(self) -> None:
        response = services(search="gardening", category=None, db=self.db)
        self.assertEqual(response, [])

    def test_invalid_query_and_missing_service(self) -> None:
        with self.assertRaisesRegex(HTTPException, "Search cannot be blank"):
            services(search="   ", db=self.db)

        with self.assertRaisesRegex(HTTPException, "Service not found"):
            service_detail(service_id=9999, db=self.db)

        with self.assertRaisesRegex(HTTPException, "Service ID must be positive"):
            service_detail(service_id=0, db=self.db)

    def test_service_detail(self) -> None:
        service_id = self.db.query(Service).filter(Service.name == "Home Cleaning").one().id
        response = service_detail(service_id=service_id, db=self.db)
        self.assertEqual(response.category, "Cleaning")


if __name__ == "__main__":
    unittest.main()
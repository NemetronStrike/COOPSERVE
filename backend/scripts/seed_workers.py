"""Insert or update repeatable demo workers and their service skills.

Run from the backend directory:
    python -m scripts.seed_workers
"""

from app.core.database import SessionLocal
from app.core.security import hash_password
from app.models.user import User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill

DEMO_WORKERS = (
    {"name": "Aarav Sharma", "email": "demo.aarav@coopserve.local", "phone": "9000000001", "skill": "Home Cleaning", "category": "Cleaning", "bio": "Experienced home-care professional for routine and deep cleaning.", "years": 6, "rating": 4.8, "jobs": 142},
    {"name": "Meera Nair", "email": "demo.meera@coopserve.local", "phone": "9000000002", "skill": "Plumbing Repair", "category": "Repairs", "bio": "Reliable plumbing repairs for homes and community spaces.", "years": 7, "rating": 4.7, "jobs": 118},
    {"name": "Rohan Verma", "email": "demo.rohan@coopserve.local", "phone": "9000000003", "skill": "Electrical Repair", "category": "Repairs", "bio": "Safety-focused electrical troubleshooting and repair specialist.", "years": 8, "rating": 4.9, "jobs": 176},
    {"name": "Kavya Iyer", "email": "demo.kavya@coopserve.local", "phone": "9000000004", "skill": "AC Service", "category": "Maintenance", "bio": "Seasonal AC maintenance and efficient cooling service.", "years": 5, "rating": 4.6, "jobs": 91},
    {"name": "Vikram Singh", "email": "demo.vikram@coopserve.local", "phone": "9000000005", "skill": "Appliance Repair", "category": "Repairs", "bio": "Household appliance diagnostics and dependable repairs.", "years": 9, "rating": 4.8, "jobs": 203},
    {"name": "Nisha Thomas", "email": "demo.nisha@coopserve.local", "phone": "9000000006", "skill": "Painting", "category": "Maintenance", "bio": "Careful interior painting for homes and cooperative facilities.", "years": 4, "rating": 4.5, "jobs": 67},
    {"name": "Imran Khan", "email": "demo.imran@coopserve.local", "phone": "9000000007", "skill": "Gardening", "category": "Home Care", "bio": "Practical garden care and outdoor space maintenance.", "years": 6, "rating": 4.6, "jobs": 84},
    {"name": "Sana Joshi", "email": "demo.sana@coopserve.local", "phone": "9000000008", "skill": "Carpentry", "category": "Maintenance", "bio": "Furniture fixes and thoughtful carpentry for everyday homes.", "years": 10, "rating": 4.9, "jobs": 231},
)


def seed_workers() -> int:
    db = SessionLocal()
    try:
        for data in DEMO_WORKERS:
            skill = db.query(Skill).filter(Skill.name == data["skill"]).first()
            if skill is None:
                skill = Skill(
                    name=data["skill"],
                    category=data["category"],
                    description=f"{data['skill']} service skill",
                    is_active=True,
                )
                db.add(skill)
                db.flush()

            user = db.query(User).filter(User.email == data["email"]).first()
            if user is None:
                user = User(
                    full_name=data["name"],
                    email=data["email"],
                    phone=data["phone"],
                    role=UserRole.worker,
                    hashed_password=hash_password("DemoWorker123!"),
                    is_active=True,
                )
                db.add(user)
                db.flush()
            else:
                user.full_name = data["name"]
                user.role = UserRole.worker
                user.is_active = True

            worker = db.query(Worker).filter(Worker.user_id == user.id).first()
            if worker is None:
                worker = Worker(user_id=user.id)
                db.add(worker)
                db.flush()
            worker.bio = data["bio"]
            worker.years_of_experience = data["years"]
            worker.average_rating = data["rating"]
            worker.total_jobs = data["jobs"]
            worker.is_verified = True

            link = db.query(WorkerSkill).filter(
                WorkerSkill.worker_id == worker.id,
                WorkerSkill.skill_id == skill.id,
            ).first()
            if link is None:
                db.add(WorkerSkill(
                    worker_id=worker.id,
                    skill_id=skill.id,
                    years_experience=data["years"],
                    is_primary=True,
                ))
            else:
                link.years_experience = data["years"]
                link.is_primary = True

        db.commit()
        return len(DEMO_WORKERS)
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    print(f"Seeded {seed_workers()} demo workers.")
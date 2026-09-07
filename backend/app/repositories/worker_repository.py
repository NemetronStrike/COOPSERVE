from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.models.service import Service
from app.models.user import User, UserRole, Worker
from app.models.worker import Skill, WorkerSkill


def list_active_workers(
    db: Session,
    *,
    service_id: int | None = None,
) -> list[Worker]:
    query = (
        db.query(Worker)
        .join(Worker.user)
        .options(
            joinedload(Worker.user),
            joinedload(Worker.skills).joinedload(WorkerSkill.skill),
        )
        .filter(
            User.is_active.is_(True),
            User.role == UserRole.worker,
            Worker.is_verified.is_(True),
        )
    )

    if service_id is not None:
        query = (
            query.join(WorkerSkill, WorkerSkill.worker_id == Worker.id)
            .join(Service, Service.id == service_id)
            .filter(
                WorkerSkill.skill_id.is_not(None),
                WorkerSkill.is_primary.is_(True),
            )
            .filter(
                or_(
                    WorkerSkill.skill.has(Skill.name == Service.name),
                    WorkerSkill.skill.has(Skill.category == Service.category),
                )
            )
            .distinct()
        )

    return query.order_by(Worker.average_rating.desc().nullslast(), Worker.id).all()


def get_active_worker(db: Session, worker_id: int) -> Worker | None:
    return (
        db.query(Worker)
        .join(Worker.user)
        .options(
            joinedload(Worker.user),
            joinedload(Worker.skills).joinedload(WorkerSkill.skill),
        )
        .filter(
            Worker.id == worker_id,
            User.is_active.is_(True),
            User.role == UserRole.worker,
            Worker.is_verified.is_(True),
        )
        .first()
    )
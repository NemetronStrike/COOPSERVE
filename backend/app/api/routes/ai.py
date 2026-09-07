import json
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Any

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User, Worker
from app.models.service import Service
from app.repositories.service_repository import list_active_services
from app.repositories.worker_repository import list_active_workers
from app.schemas.ai import (
    ServiceSearchRequest, 
    AIServiceResponse,
    WorkerMatchRequest,
    WorkerMatchResponseList,
    AIWorkerMatchResponse
)
from app.services.ai_service import generate_structured_json
from app.schemas.service import ServiceResponse

router = APIRouter(prefix="/ai", tags=["ai"])

@router.post("/service-search", response_model=AIServiceResponse)
def service_search(
    request: ServiceSearchRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Any:
    schema = """
    {
      "intent": "The user's underlying intent",
      "search_keywords": ["keyword1", "keyword2"],
      "suggested_category": "A generic category if applicable, or null",
      "urgency": "normal or high"
    }
    """
    ai_result = generate_structured_json(
        prompt=f"Analyze this customer request for household or gig services: '{request.query}'",
        schema_description=schema,
    )
    
    keywords = ai_result.get("search_keywords", [])
    if not keywords:
        keywords = request.query.split()

    services = []
    # Simple search combining keywords
    for keyword in keywords:
        found = list_active_services(db, search=keyword)
        for s in found:
            if not any(existing.id == s.id for existing in services):
                services.append(s)
                
    # If no services found from keywords, try without keywords (all services)
    if not services:
        services = list_active_services(db)

    return {
        "interpretation": ai_result.get("intent", f"Searching for: {request.query}"),
        "services": [ServiceResponse.model_validate(s) for s in services]
    }

@router.post("/match-workers", response_model=WorkerMatchResponseList)
def match_workers(
    request: WorkerMatchRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Any:
    service = db.query(Service).filter(Service.id == request.service_id, Service.is_active.is_(True)).first()
    if not service:
        raise HTTPException(status_code=404, detail="Service not found")
        
    workers = list_active_workers(db, service_id=request.service_id)
    if not workers:
        return {"matches": []}
        
    scored_workers = []
    for w in workers:
        # Deterministic scoring
        rating_score = float(w.average_rating) * 10
        exp_score = min(w.years_of_experience, 10) * 2
        jobs_score = min(w.total_jobs, 50) * 0.5
        
        total_score = rating_score + exp_score + jobs_score
        scored_workers.append((w, total_score))
        
    # Sort descending
    scored_workers.sort(key=lambda x: x[1], reverse=True)
    top_workers = scored_workers[:3]
    
    # Generate explanations using AI
    prompt = f"We have a customer who needs {service.name}. Urgency: {request.urgency}. Notes: {request.notes or 'None'}. "
    prompt += "Here are the top workers we found based on deterministic scoring:\n"
    for i, (w, score) in enumerate(top_workers):
        prompt += f"Worker ID {w.id}: {w.user.full_name}, {w.average_rating} stars, {w.years_of_experience} years exp, {w.total_jobs} jobs completed. Score: {score}\n"
        
    schema = """
    {
      "explanations": {
        "worker_id_as_string": "1-2 sentence explanation of why this worker is a great match"
      }
    }
    """
    ai_result = generate_structured_json(prompt, schema)
    explanations = ai_result.get("explanations", {})
    
    matches = []
    for w, score in top_workers:
        exp = explanations.get(str(w.id), f"Highly rated worker with {w.years_of_experience} years of experience.")
        matches.append({
            "id": w.id,
            "name": w.user.full_name,
            "match_score": score,
            "explanation": exp,
            "average_rating": w.average_rating,
            "years_of_experience": w.years_of_experience,
            "total_jobs": w.total_jobs,
        })
        
    return {"matches": matches}

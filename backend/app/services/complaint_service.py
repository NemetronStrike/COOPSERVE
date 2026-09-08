import logging
from sqlalchemy.orm import Session
from app.models.rating import Complaint, ComplaintCategory, ComplaintSeverity, ComplaintUrgency, ComplaintStatus
from app.schemas.complaint import ComplaintCreate
from app.services.ai_service import generate_structured_json

logger = logging.getLogger(__name__)

COMPLAINT_SCHEMA_DESC = """
{
  "category": "service_quality|worker_behaviour|late_arrival|pricing_payment|safety|property_damage|booking_issue|no_show|other",
  "severity": "low|medium|high|critical",
  "urgency": "low|medium|high|critical",
  "summary": "A concise 1-sentence summary of the issue.",
  "suggested_action": "A short suggested action for the admin."
}
"""

def fallback_classifier(text: str) -> dict:
    text_lower = text.lower()
    
    # Simple deterministic fallback rules
    if any(kw in text_lower for kw in ["danger", "unsafe", "threat", "injury", "attack"]):
        category = ComplaintCategory.safety
        severity = ComplaintSeverity.critical
        urgency = ComplaintUrgency.high
    elif any(kw in text_lower for kw in ["late", "delayed"]):
        category = ComplaintCategory.late_arrival
        severity = ComplaintSeverity.medium
        urgency = ComplaintUrgency.medium
    elif any(kw in text_lower for kw in ["didn't arrive", "no show", "never came"]):
        category = ComplaintCategory.no_show
        severity = ComplaintSeverity.high
        urgency = ComplaintUrgency.high
    elif any(kw in text_lower for kw in ["charged", "price", "payment", "money", "extra"]):
        category = ComplaintCategory.pricing_payment
        severity = ComplaintSeverity.medium
        urgency = ComplaintUrgency.low
    elif any(kw in text_lower for kw in ["rude", "behavior", "abusive", "yell"]):
        category = ComplaintCategory.worker_behaviour
        severity = ComplaintSeverity.high
        urgency = ComplaintUrgency.medium
    elif any(kw in text_lower for kw in ["damaged", "broken", "destroyed"]):
        category = ComplaintCategory.property_damage
        severity = ComplaintSeverity.high
        urgency = ComplaintUrgency.medium
    elif any(kw in text_lower for kw in ["booking", "cancel", "schedule"]):
        category = ComplaintCategory.booking_issue
        severity = ComplaintSeverity.low
        urgency = ComplaintUrgency.low
    else:
        category = ComplaintCategory.other
        severity = ComplaintSeverity.low
        urgency = ComplaintUrgency.low

    return {
        "category": category,
        "severity": severity,
        "urgency": urgency,
        "summary": text[:100] + "..." if len(text) > 100 else text,
        "suggested_action": "Review complaint manually."
    }

def create_complaint_record(db: Session, customer_id: int, complaint_in: ComplaintCreate) -> Complaint:
    # Attempt Gemini classification
    prompt = f"Analyze the following customer complaint and classify it:\n\n{complaint_in.description}"
    gemini_result = generate_structured_json(prompt, COMPLAINT_SCHEMA_DESC)
    
    classification_source = "gemini"
    classification = {}
    
    # Validate Gemini output
    if gemini_result and isinstance(gemini_result, dict):
        try:
            category = ComplaintCategory(gemini_result.get("category", ""))
            severity = ComplaintSeverity(gemini_result.get("severity", ""))
            urgency = ComplaintUrgency(gemini_result.get("urgency", ""))
            classification = {
                "category": category,
                "severity": severity,
                "urgency": urgency,
                "summary": gemini_result.get("summary", ""),
                "suggested_action": gemini_result.get("suggested_action", "")
            }
        except ValueError:
            # Enum validation failed
            classification = {}
            
    if not classification:
        classification_source = "fallback"
        classification = fallback_classifier(complaint_in.description)
        # If user explicitly provided a category in input (like from a dropdown), maybe use it
        # But instructions say "Gemini is the primary classifier", so we rely on AI/fallback.

    db_complaint = Complaint(
        complainant_id=customer_id,
        booking_id=complaint_in.booking_id,
        category=classification["category"],
        description=complaint_in.description,
        severity=classification["severity"],
        urgency=classification["urgency"],
        summary=classification["summary"],
        suggested_action=classification["suggested_action"],
        classification_source=classification_source,
        status=ComplaintStatus.open
    )
    db.add(db_complaint)
    db.commit()
    db.refresh(db_complaint)
    return db_complaint

def get_customer_complaints(db: Session, customer_id: int) -> list[Complaint]:
    return db.query(Complaint).filter(Complaint.complainant_id == customer_id).order_by(Complaint.created_at.desc()).all()

def get_all_complaints(db: Session) -> list[Complaint]:
    return db.query(Complaint).order_by(Complaint.created_at.desc()).all()

def update_complaint_status(db: Session, complaint_id: int, status: ComplaintStatus, resolution_notes: str = None) -> Complaint:
    complaint = db.query(Complaint).filter(Complaint.id == complaint_id).first()
    if not complaint:
        return None
    complaint.status = status
    if resolution_notes is not None:
        complaint.resolution_notes = resolution_notes
    db.commit()
    db.refresh(complaint)
    return complaint

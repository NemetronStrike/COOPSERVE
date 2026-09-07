import json
import logging
from typing import Any

import google.generativeai as genai

from app.core.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()

# Initialize Gemini if key is provided
_gemini_client_configured = False
if settings.gemini_api_key:
    try:
        genai.configure(api_key=settings.gemini_api_key)
        _gemini_client_configured = True
    except Exception as e:
        logger.warning(f"Failed to configure Gemini API: {e}")

def _get_model(model_name: str = "gemini-1.5-flash") -> genai.GenerativeModel:
    if not _gemini_client_configured:
        raise RuntimeError("Gemini API is not configured. Missing GEMINI_API_KEY.")
    return genai.GenerativeModel(model_name=model_name)

def generate_structured_json(prompt: str, schema_description: str, model_name: str = "gemini-1.5-flash") -> dict[str, Any]:
    """
    Generates a structured JSON response from Gemini.
    """
    if not _gemini_client_configured:
        logger.warning("Gemini API not configured. Returning fallback data for prompt: %s", prompt)
        return {}

    full_prompt = f"""
{prompt}

You must respond ONLY with valid JSON matching this description:
{schema_description}

Do NOT wrap the JSON in Markdown formatting like ```json ... ```. Just return the raw JSON object.
"""
    try:
        model = _get_model(model_name)
        response = model.generate_content(
            full_prompt,
            generation_config=genai.types.GenerationConfig(
                response_mime_type="application/json",
            ),
        )
        # Parse the JSON
        if not response.text:
            return {}
            
        try:
            return json.loads(response.text)
        except json.JSONDecodeError:
            # Fallback for models that might still include markdown blocks despite instructions
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.endswith("```"):
                text = text[:-3]
            return json.loads(text.strip())
            
    except Exception as e:
        logger.error(f"Error calling Gemini API: {e}")
        return {}

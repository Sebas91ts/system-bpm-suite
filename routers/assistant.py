from fastapi import APIRouter, HTTPException

from schemas.assistant_schema import AssistantRequest, AssistantResponse
from schemas.form_fill_schema import FormFillRequest, FormFillResponse
from services.assistant_service import AssistantService
from services.form_fill_service import FormFillService
from utils.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)
service: AssistantService | None = None
form_fill_service: FormFillService | None = None


@router.post("/assistant", response_model=AssistantResponse)
async def assistant(payload: AssistantRequest) -> AssistantResponse:
    logger.info("Request received at /ai/assistant")
    try:
        response = get_assistant_service().answer(payload.message)
        logger.info("Assistant response generated successfully")
        return AssistantResponse(response=response)
    except Exception as exc:
        logger.exception("Assistant endpoint failed")
        if _is_gemini_quota_error(exc):
            raise HTTPException(
                status_code=503,
                detail="IA temporalmente no disponible por cuota de Gemini. Intenta mas tarde.",
            ) from exc
        raise HTTPException(status_code=500, detail="No se pudo procesar la solicitud de IA") from exc


@router.post("/fill-form", response_model=FormFillResponse)
async def fill_form(payload: FormFillRequest) -> FormFillResponse:
    logger.info("Request received at /ai/fill-form")
    try:
        response = get_form_fill_service().suggest_values(payload)
        logger.info("Form fill response generated successfully")
        return response
    except Exception as exc:
        logger.exception("Form fill endpoint failed")
        if _is_gemini_quota_error(exc):
            raise HTTPException(
                status_code=503,
                detail="IA temporalmente no disponible por cuota de Gemini. Intenta mas tarde.",
            ) from exc
        raise HTTPException(status_code=500, detail="No se pudo sugerir el llenado del formulario") from exc


def _is_gemini_quota_error(exc: Exception) -> bool:
    message = str(exc).lower()
    return (
        "429" in message
        or "resource_exhausted" in message
        or "quota exceeded" in message
    )


def get_assistant_service() -> AssistantService:
    global service
    if service is None:
        service = AssistantService()
    return service


def get_form_fill_service() -> FormFillService:
    global form_fill_service
    if form_fill_service is None:
        form_fill_service = FormFillService()
    return form_fill_service

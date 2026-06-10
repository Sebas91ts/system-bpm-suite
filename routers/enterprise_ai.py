from fastapi import APIRouter, HTTPException

from schemas.enterprise_ai_schema import (
    DocumentAnalysisRequest,
    DocumentAnalysisResponse,
    EnterpriseAiContextRequest,
    EnterpriseAssistResponse,
    ProcessRecommendationResponse,
    ReportPlanResponse,
)
from services.enterprise_ai_service import EnterpriseAiService
from utils.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)
service: EnterpriseAiService | None = None


@router.post("/assist", response_model=EnterpriseAssistResponse)
async def assist(payload: EnterpriseAiContextRequest) -> EnterpriseAssistResponse:
    logger.info("Request received at /ai/assist")
    return _execute(lambda: get_service().assist(payload), "No se pudo procesar la asistencia IA")


@router.post("/recommend-process", response_model=ProcessRecommendationResponse)
async def recommend_process(payload: EnterpriseAiContextRequest) -> ProcessRecommendationResponse:
    logger.info("Request received at /ai/recommend-process")
    return _execute(lambda: get_service().recommend_process(payload), "No se pudo recomendar un proceso")


@router.post("/reports", response_model=ReportPlanResponse)
async def reports(payload: EnterpriseAiContextRequest) -> ReportPlanResponse:
    logger.info("Request received at /ai/reports")
    return _execute(lambda: get_service().plan_report(payload), "No se pudo interpretar el reporte")


@router.post("/document-analysis", response_model=DocumentAnalysisResponse)
async def document_analysis(payload: DocumentAnalysisRequest) -> DocumentAnalysisResponse:
    logger.info("Request received at /ai/document-analysis")
    return _execute(lambda: get_service().analyze_document(payload), "No se pudo analizar el documento")


@router.post("/voice", response_model=EnterpriseAssistResponse)
async def voice(payload: EnterpriseAiContextRequest) -> EnterpriseAssistResponse:
    logger.info("Request received at /ai/voice")
    return _execute(lambda: get_service().voice(payload), "No se pudo procesar la solicitud de voz")


@router.post("/context", response_model=EnterpriseAiContextRequest)
async def context(payload: EnterpriseAiContextRequest) -> EnterpriseAiContextRequest:
    logger.info("Request received at /ai/context")
    return payload


def _execute(operation, fallback_message: str):
    try:
        return operation()
    except Exception as exc:
        logger.exception("Enterprise AI endpoint failed")
        if _is_gemini_quota_error(exc):
            raise HTTPException(
                status_code=503,
                detail="IA temporalmente no disponible por cuota de Gemini. Intenta mas tarde.",
            ) from exc
        raise HTTPException(status_code=500, detail=fallback_message) from exc


def _is_gemini_quota_error(exc: Exception) -> bool:
    message = str(exc).lower()
    return "429" in message or "resource_exhausted" in message or "quota exceeded" in message


def get_service() -> EnterpriseAiService:
    global service
    if service is None:
        service = EnterpriseAiService()
    return service

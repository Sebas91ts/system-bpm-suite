from fastapi import APIRouter, HTTPException

from schemas.intelligent_routing_schema import (
    AssignmentRecommendationResponse,
    RiskPredictionResponse,
    RoutingContextRequest,
    RoutingDashboardResponse,
)
from services.intelligent_routing_service import IntelligentRoutingService
from utils.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)
service: IntelligentRoutingService | None = None


@router.post("/routing/predict-task", response_model=RiskPredictionResponse)
async def predict_task(payload: RoutingContextRequest) -> RiskPredictionResponse:
    logger.info("Request received at /ai/routing/predict-task")
    return _execute(lambda: get_service().predict_task(payload), "No se pudo predecir riesgo de tarea")


@router.post("/routing/predict-instance", response_model=RiskPredictionResponse)
async def predict_instance(payload: RoutingContextRequest) -> RiskPredictionResponse:
    logger.info("Request received at /ai/routing/predict-instance")
    return _execute(lambda: get_service().predict_instance(payload), "No se pudo predecir riesgo de instancia")


@router.post("/routing/recommend-assignment", response_model=AssignmentRecommendationResponse)
async def recommend_assignment(payload: RoutingContextRequest) -> AssignmentRecommendationResponse:
    logger.info("Request received at /ai/routing/recommend-assignment")
    return _execute(lambda: get_service().recommend_assignment(payload), "No se pudo recomendar asignacion")


@router.post("/routing/dashboard", response_model=RoutingDashboardResponse)
async def dashboard(payload: RoutingContextRequest) -> RoutingDashboardResponse:
    logger.info("Request received at /ai/routing/dashboard")
    return _execute(lambda: get_service().dashboard(payload), "No se pudo construir dashboard inteligente")


def _execute(operation, fallback_message: str):
    try:
        return operation()
    except Exception as exc:
        logger.exception("Intelligent routing endpoint failed")
        raise HTTPException(status_code=500, detail=fallback_message) from exc


def get_service() -> IntelligentRoutingService:
    global service
    if service is None:
        service = IntelligentRoutingService()
    return service

import json
from typing import Any

from schemas.enterprise_ai_schema import (
    DocumentAnalysisRequest,
    DocumentAnalysisResponse,
    EnterpriseAiContextRequest,
    EnterpriseAssistResponse,
    ProcessRecommendationResponse,
    ReportPlanResponse,
)
from services.gemini_service import GeminiService
from services.json_ai_utils import clamp_confidence, parse_json_object
from utils.logger import get_logger

logger = get_logger(__name__)


class EnterpriseAiService:
    def __init__(self, gemini_service: GeminiService | None = None) -> None:
        self._gemini_service = gemini_service or GeminiService()
        self._generation_config = {
            "temperature": 0.2,
            "top_p": 0.8,
        }

    def assist(self, payload: EnterpriseAiContextRequest) -> EnterpriseAssistResponse:
        parsed = self._ask_json(self._build_assist_prompt(payload))
        return EnterpriseAssistResponse(
            response=str(parsed.get("response") or "No pude construir una respuesta con el contexto disponible."),
            intent=parsed.get("intent"),
            confidence=clamp_confidence(parsed.get("confidence")),
            suggestedActions=_as_string_list(parsed.get("suggestedActions")),
            structuredData=parsed.get("structuredData") if isinstance(parsed.get("structuredData"), dict) else {},
        )

    def recommend_process(self, payload: EnterpriseAiContextRequest) -> ProcessRecommendationResponse:
        parsed = self._ask_json(self._build_recommend_process_prompt(payload))
        process_key = parsed.get("processKey")
        valid_keys = {str(item.get("processKey")) for item in payload.processes if item.get("processKey")}
        if process_key not in valid_keys:
            process_key = None
        return ProcessRecommendationResponse(
            intent=str(parsed.get("intent") or "UNKNOWN"),
            processKey=process_key,
            confidence=clamp_confidence(parsed.get("confidence")),
            reason=str(parsed.get("reason") or "No se encontro un proceso real con confianza suficiente."),
            requiredDocuments=_as_string_list(parsed.get("requiredDocuments")),
            requiredForms=_as_string_list(parsed.get("requiredForms")),
            alternatives=[key for key in _as_string_list(parsed.get("alternatives")) if key in valid_keys],
        )

    def plan_report(self, payload: EnterpriseAiContextRequest) -> ReportPlanResponse:
        try:
            parsed = self._ask_json(self._build_report_prompt(payload))
        except Exception as exc:
            logger.warning("Enterprise report planning degraded to local rules: %s", exc)
            return _local_report_plan(payload, exc)
        filters = parsed.get("filters") if isinstance(parsed.get("filters"), dict) else {}
        return ReportPlanResponse(
            reportType=str(parsed.get("reportType") or "unknown"),
            filters=filters,
            groupBy=parsed.get("groupBy"),
            format=str(parsed.get("format") or "JSON").upper(),
            columns=_as_string_list(parsed.get("columns")),
            confidence=clamp_confidence(parsed.get("confidence")),
            reason=str(parsed.get("reason") or ""),
        )

    def analyze_document(self, payload: DocumentAnalysisRequest) -> DocumentAnalysisResponse:
        parsed = self._ask_json(self._build_document_analysis_prompt(payload))
        return DocumentAnalysisResponse(
            documentType=str(parsed.get("documentType") or "desconocido"),
            confidence=clamp_confidence(parsed.get("confidence")),
            executiveSummary=str(parsed.get("executiveSummary") or ""),
            shortSummary=str(parsed.get("shortSummary") or ""),
            detailedSummary=str(parsed.get("detailedSummary") or ""),
            keywords=_as_string_list(parsed.get("keywords")),
            suggestedTags=_as_string_list(parsed.get("suggestedTags")),
            entities=parsed.get("entities") if isinstance(parsed.get("entities"), dict) else {},
        )

    def voice(self, payload: EnterpriseAiContextRequest) -> EnterpriseAssistResponse:
        return self.assist(payload)

    def _ask_json(self, prompt: str) -> dict[str, Any]:
        raw = self._gemini_service.generate_text(prompt, config=self._generation_config)
        logger.info("Enterprise AI response received: %s", raw[:240])
        return parse_json_object(raw)

    def _build_assist_prompt(self, payload: EnterpriseAiContextRequest) -> str:
        return (
            _base_instruction()
            + "\nActua como Agente Inteligente BPM Empresarial.\n"
            + "Responde preguntas sobre tareas, procesos, documentos, formularios y aprobaciones usando SOLO el contexto real recibido.\n"
            + "Si el dato no esta en el contexto, dilo claramente y sugiere la accion segura.\n"
            + "Devuelve SOLO JSON con este formato:\n"
            + '{"response":"...","intent":"...","confidence":0.0,"suggestedActions":[],"structuredData":{}}\n'
            + _context_block(payload)
        )

    def _build_recommend_process_prompt(self, payload: EnterpriseAiContextRequest) -> str:
        return (
            _base_instruction()
            + "\nDetecta la intencion del usuario y recomienda un proceso BPM real.\n"
            + "Regla critica: NO inventes processKey. Solo puedes usar processKey presente en context.processes.\n"
            + "Si hay ambiguedad, processKey debe ser null, confidence menor a 0.65 y alternatives debe listar candidatos reales.\n"
            + "Devuelve SOLO JSON con este formato:\n"
            + '{"intent":"...","processKey":null,"confidence":0.0,"reason":"...","requiredDocuments":[],"requiredForms":[],"alternatives":[]}\n'
            + _context_block(payload)
        )

    def _build_report_prompt(self, payload: EnterpriseAiContextRequest) -> str:
        return (
            _base_instruction()
            + "\nInterpreta solicitudes de reportes. NO generes datos. Solo devuelve una consulta estructurada para Spring Boot.\n"
            + "Tipos validos sugeridos: documents, tasks, processes, audit, forms, productivity.\n"
            + "Formatos validos: JSON, PDF, EXCEL, WORD.\n"
            + "Puedes proponer columns dinamicas si el usuario pide calculos o vistas especificas, por ejemplo: tiempoAbierto, fechaInicio, estadoActual.\n"
            + "Si pide procesos activos o sin completar, usa reportType processes y filters.active=true.\n"
            + "Devuelve SOLO JSON con este formato:\n"
            + '{"reportType":"documents","filters":{},"groupBy":null,"format":"JSON","columns":[],"confidence":0.0,"reason":"..."}\n'
            + _context_block(payload)
        )

    def _build_document_analysis_prompt(self, payload: DocumentAnalysisRequest) -> str:
        safe_text = payload.text[:12000]
        return (
            _base_instruction()
            + "\nAnaliza el texto documental usando Gemini, preparando una futura sustitucion por TensorFlow.\n"
            + "Clasifica solo entre: contrato, memorandum, carta, solicitud, factura, acta, otro.\n"
            + "Extrae entidades: persona, empresa, fecha, monto, numeroTramite, numeroDocumento.\n"
            + "Devuelve SOLO JSON con este formato:\n"
            + '{"documentType":"otro","confidence":0.0,"executiveSummary":"...","shortSummary":"...",'
            + '"detailedSummary":"...","keywords":[],"suggestedTags":[],"entities":{}}\n'
            + f"Contexto: {json.dumps(payload.context, ensure_ascii=False)}\n"
            + f"Texto:\n{safe_text}\n"
        )


def _base_instruction() -> str:
    return (
        "Eres la capa de IA empresarial de un sistema BPM.\n"
        "Debes respetar seguridad: el backend ya filtro el contexto, por lo tanto nunca inventes datos fuera de ese contexto.\n"
        "Responde en espanol, con lenguaje claro y operativo.\n"
    )


def _context_block(payload: EnterpriseAiContextRequest) -> str:
    return "Contexto JSON real:\n" + json.dumps(payload.model_dump(), ensure_ascii=False, default=str)[:30000]


def _as_string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item) for item in value if item is not None and str(item).strip()]


def _local_report_plan(payload: EnterpriseAiContextRequest, exc: Exception | None = None) -> ReportPlanResponse:
    message = _normalize(payload.message)
    report_type = "audit"
    filters: dict[str, Any] = {}
    columns: list[str] = []
    group_by: str | None = None
    output_format = "JSON"

    if "document" in message or "archivo" in message:
        report_type = "documents"
    if "tarea" in message:
        report_type = "tasks"
    if "formulario" in message:
        report_type = "forms"
    if "proceso" in message or "tramite" in message or "instancia" in message:
        report_type = "processes"

    if "activo" in message or "sin completar" in message or "pendiente" in message or "abierto" in message:
        filters["active"] = True
    if "rechaz" in message:
        filters["status"] = "REJECTED"
    if "aprob" in message:
        filters["status"] = "APPROVED"
    if "complet" in message and report_type != "processes":
        filters["action"] = "TASK_COMPLETED" if report_type == "tasks" else "FORM_SUBMITTED"
    if "area" in message or "departamento" in message:
        group_by = "area"

    if report_type == "processes":
        columns = ["Proceso", "Instancia", "Estado", "Inicio", "Tiempo abierto", "Iniciado por"]

    if "pdf" in message:
        output_format = "PDF"
    elif "excel" in message or "xls" in message:
        output_format = "EXCEL"
    elif "word" in message or "doc" in message:
        output_format = "WORD"

    reason = "Plan interpretado localmente porque Gemini no respondio."
    if exc is not None and _is_quota_or_availability_error(exc):
        reason = "Gemini esta sin cuota o temporalmente saturado; se uso interpretacion local segura."

    return ReportPlanResponse(
        reportType=report_type,
        filters=filters,
        groupBy=group_by,
        format=output_format,
        columns=columns,
        confidence=0.72,
        reason=reason,
    )


def _is_quota_or_availability_error(exc: Exception) -> bool:
    message = str(exc).lower()
    return (
        "429" in message
        or "resource_exhausted" in message
        or "quota exceeded" in message
        or "503" in message
        or "unavailable" in message
    )


def _normalize(value: str) -> str:
    replacements = str.maketrans("áéíóúüñ", "aeiouun")
    return str(value or "").lower().translate(replacements)

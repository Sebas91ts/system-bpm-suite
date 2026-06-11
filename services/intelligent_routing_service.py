from __future__ import annotations

from datetime import datetime, timezone
from statistics import mean
from typing import Any

from ml.model_registry import ModelRegistry
from schemas.intelligent_routing_schema import (
    AnomalyItem,
    AssignmentRecommendationResponse,
    RiskPredictionResponse,
    RoutingContextRequest,
    RoutingDashboardResponse,
    RoutingRecommendation,
)


class IntelligentRoutingService:
    def __init__(self, registry: ModelRegistry | None = None) -> None:
        self._registry = registry or ModelRegistry()

    def predict_task(self, payload: RoutingContextRequest) -> RiskPredictionResponse:
        metrics = payload.metrics or {}
        age_hours = _number(metrics.get("taskAgeHours"))
        avg_hours = max(_number(metrics.get("averageCompletionHours")), 1.0)
        area_backlog = _number(metrics.get("areaBacklog"))
        missing_documents = _number(metrics.get("missingRequiredDocuments"))
        active_instance_hours = _number(metrics.get("instanceAgeHours"))
        rejection_count = _number(metrics.get("recentRejections"))

        features = [
            min(age_hours / max(avg_hours, 1.0), 5.0),
            min(area_backlog / 10.0, 5.0),
            min(missing_documents, 5.0),
            min(active_instance_hours / 72.0, 5.0),
            min(rejection_count, 5.0),
        ]

        model_score = self._registry.predict_delay_risk(features)
        heuristic_score, factors = self._heuristic_risk(features, age_hours, avg_hours)
        risk_score = _clamp(model_score if model_score is not None else heuristic_score)
        factors.extend(self._document_factors(missing_documents))
        factors.extend(self._backlog_factors(area_backlog))
        priority = self._priority_label(risk_score)

        return RiskPredictionResponse(
            riskLevel=self._risk_label(risk_score),
            riskScore=round(risk_score, 3),
            expectedDelayHours=round(max(0.0, age_hours - avg_hours) + risk_score * 8.0, 2),
            priority=priority,
            factors=_unique(factors),
            recommendations=self._recommendations(risk_score, missing_documents, area_backlog),
            modelUsed=self._model_used(model_score),
        )

    def predict_instance(self, payload: RoutingContextRequest) -> RiskPredictionResponse:
        metrics = payload.metrics or {}
        instance_age = _number(metrics.get("instanceAgeHours"))
        active_tasks = _number(metrics.get("activeTasks"))
        completed_tasks = _number(metrics.get("completedTasks"))
        missing_documents = _number(metrics.get("missingRequiredDocuments"))

        base = 0.18
        if instance_age > 24:
            base += 0.18
        if instance_age > 72:
            base += 0.22
        if active_tasks == 0 and completed_tasks > 0:
            base += 0.15
        if missing_documents > 0:
            base += min(0.25, missing_documents * 0.08)

        factors: list[str] = []
        if instance_age > 24:
            factors.append("La instancia lleva mas de 24 horas activa")
        if instance_age > 72:
            factors.append("La instancia supera 72 horas sin finalizar")
        if active_tasks == 0 and completed_tasks > 0:
            factors.append("No se detectan tareas activas aunque la instancia no finalizo")
        factors.extend(self._document_factors(missing_documents))

        risk_score = _clamp(base)
        return RiskPredictionResponse(
            riskLevel=self._risk_label(risk_score),
            riskScore=round(risk_score, 3),
            expectedDelayHours=round(risk_score * 24.0, 2),
            priority=self._priority_label(risk_score),
            factors=_unique(factors) or ["Riesgo calculado con datos operativos de la instancia"],
            recommendations=self._recommendations(risk_score, missing_documents, active_tasks),
            modelUsed="heuristic_instance_risk",
        )

    def recommend_assignment(self, payload: RoutingContextRequest) -> AssignmentRecommendationResponse:
        risk = self.predict_task(payload)
        candidates = payload.candidates or []
        ranked = sorted(
            [self._score_candidate(candidate, risk.riskScore) for candidate in candidates],
            key=lambda item: item.score,
            reverse=True,
        )
        return AssignmentRecommendationResponse(
            priority=risk.priority,
            priorityScore=round(risk.riskScore * 100, 1),
            bestRoute=ranked[0] if ranked else None,
            alternatives=ranked[1:4],
            factors=risk.factors,
            modelUsed=risk.modelUsed,
        )

    def dashboard(self, payload: RoutingContextRequest) -> RoutingDashboardResponse:
        tasks = payload.metrics.get("activeTaskContexts", []) if payload.metrics else []
        instances = payload.metrics.get("activeInstanceContexts", []) if payload.metrics else []
        task_predictions = [self.predict_task(RoutingContextRequest(**task)) for task in tasks[:50]]
        instance_predictions = [self.predict_instance(RoutingContextRequest(**instance)) for instance in instances[:50]]

        high_risk_tasks = [
            {**tasks[index].get("task", {}), "riskScore": prediction.riskScore, "riskLevel": prediction.riskLevel}
            for index, prediction in enumerate(task_predictions)
            if prediction.riskScore >= 0.65
        ][:10]
        high_risk_instances = [
            {**instances[index].get("instance", {}), "riskScore": prediction.riskScore, "riskLevel": prediction.riskLevel}
            for index, prediction in enumerate(instance_predictions)
            if prediction.riskScore >= 0.65
        ][:10]

        anomalies = self._detect_anomalies(tasks, instances)
        return RoutingDashboardResponse(
            modelStatus=self._registry.model_status(),
            highRiskTasks=high_risk_tasks,
            highRiskInstances=high_risk_instances,
            anomalies=anomalies,
            recommendations=self._dashboard_recommendations(high_risk_tasks, high_risk_instances, anomalies),
        )

    def _score_candidate(self, candidate: dict[str, Any], risk_score: float) -> RoutingRecommendation:
        backlog = _number(candidate.get("backlog"))
        avg_hours = _number(candidate.get("averageCompletionHours"))
        completed = _number(candidate.get("completedTasks"))
        availability = 1.0 / (1.0 + backlog)
        experience = min(completed / 20.0, 1.0)
        speed = 1.0 / (1.0 + max(avg_hours, 1.0) / 24.0)
        score = _clamp(0.45 * availability + 0.35 * speed + 0.2 * experience - risk_score * 0.1)
        return RoutingRecommendation(
            targetType=str(candidate.get("type") or "USER"),
            targetId=_optional_str(candidate.get("id")),
            targetName=_optional_str(candidate.get("name") or candidate.get("email")),
            score=round(score, 3),
            reason=f"Carga {int(backlog)}, promedio {avg_hours:.1f}h, experiencia {int(completed)} tareas",
        )

    def _heuristic_risk(self, features: list[float], age_hours: float, avg_hours: float) -> tuple[float, list[str]]:
        score = 0.16 + features[0] * 0.18 + features[1] * 0.10 + features[2] * 0.12 + features[3] * 0.07 + features[4] * 0.08
        factors: list[str] = []
        if age_hours > avg_hours:
            factors.append("La tarea ya supera el tiempo promedio historico")
        if age_hours > avg_hours * 2:
            factors.append("La tarea duplica el promedio historico")
        return _clamp(score), factors

    def _detect_anomalies(self, tasks: list[dict[str, Any]], instances: list[dict[str, Any]]) -> list[AnomalyItem]:
        anomalies: list[AnomalyItem] = []
        for item in tasks:
            metrics = item.get("metrics", {})
            task = item.get("task", {})
            age = _number(metrics.get("taskAgeHours"))
            avg_hours = max(_number(metrics.get("averageCompletionHours")), 1.0)
            if age > avg_hours * 3 and age > 4:
                anomalies.append(AnomalyItem(
                    type="TASK_DELAY_ANOMALY",
                    severity="HIGH",
                    score=round(_clamp(age / (avg_hours * 4)), 3),
                    description=f"Tarea {task.get('name') or task.get('id')} muy por encima del promedio historico",
                    entityId=_optional_str(task.get("id")),
                ))
        for item in instances:
            metrics = item.get("metrics", {})
            instance = item.get("instance", {})
            if _number(metrics.get("instanceAgeHours")) > 96 and _number(metrics.get("activeTasks")) == 0:
                anomalies.append(AnomalyItem(
                    type="STALLED_INSTANCE",
                    severity="CRITICAL",
                    score=0.95,
                    description="Instancia antigua sin tareas activas detectadas",
                    entityId=_optional_str(instance.get("id")),
                ))
        return anomalies[:20]

    def _document_factors(self, missing_documents: float) -> list[str]:
        return ["Hay documentos obligatorios pendientes"] if missing_documents > 0 else []

    def _backlog_factors(self, area_backlog: float) -> list[str]:
        if area_backlog >= 10:
            return ["El area tiene acumulacion alta de tareas"]
        if area_backlog >= 5:
            return ["El area tiene carga moderada de tareas"]
        return []

    def _recommendations(self, risk_score: float, missing_documents: float, area_backlog: float) -> list[str]:
        recommendations: list[str] = []
        if risk_score >= 0.75:
            recommendations.append("Priorizar esta tarea en la bandeja del area")
        if missing_documents > 0:
            recommendations.append("Solicitar documentos obligatorios antes de completar")
        if area_backlog >= 5:
            recommendations.append("Evaluar reasignacion a un usuario con menor carga")
        return recommendations or ["Mantener seguimiento normal"]

    def _dashboard_recommendations(
        self,
        high_risk_tasks: list[dict[str, Any]],
        high_risk_instances: list[dict[str, Any]],
        anomalies: list[AnomalyItem],
    ) -> list[str]:
        recommendations: list[str] = []
        if high_risk_tasks:
            recommendations.append(f"Revisar {len(high_risk_tasks)} tareas con riesgo alto de demora")
        if high_risk_instances:
            recommendations.append(f"Monitorear {len(high_risk_instances)} instancias activas con riesgo alto")
        if anomalies:
            recommendations.append(f"Atender {len(anomalies)} anomalias operativas detectadas")
        return recommendations or ["No se detectaron riesgos altos con los datos actuales"]

    def _risk_label(self, score: float) -> str:
        if score >= 0.75:
            return "HIGH"
        if score >= 0.45:
            return "MEDIUM"
        return "LOW"

    def _priority_label(self, score: float) -> str:
        if score >= 0.80:
            return "URGENT"
        if score >= 0.55:
            return "HIGH"
        if score >= 0.30:
            return "NORMAL"
        return "LOW"

    def _model_used(self, model_score: float | None) -> str:
        return "tensorflow_delay_risk_model" if model_score is not None else "heuristic_fallback"


def _number(value: Any) -> float:
    try:
        return float(value or 0)
    except (TypeError, ValueError):
        return 0.0


def _optional_str(value: Any) -> str | None:
    if value is None:
        return None
    text = str(value).strip()
    return text or None


def _clamp(value: float) -> float:
    return max(0.0, min(1.0, value))


def _unique(values: list[str]) -> list[str]:
    seen: set[str] = set()
    result: list[str] = []
    for value in values:
        if value and value not in seen:
            seen.add(value)
            result.append(value)
    return result

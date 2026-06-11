from typing import Any

from pydantic import BaseModel, Field


class RoutingContextRequest(BaseModel):
    task: dict[str, Any] = Field(default_factory=dict)
    instance: dict[str, Any] = Field(default_factory=dict)
    metrics: dict[str, Any] = Field(default_factory=dict)
    candidates: list[dict[str, Any]] = Field(default_factory=list)
    history: list[dict[str, Any]] = Field(default_factory=list)
    documents: list[dict[str, Any]] = Field(default_factory=list)


class RoutingRecommendation(BaseModel):
    targetType: str = "AREA"
    targetId: str | None = None
    targetName: str | None = None
    score: float = 0.0
    reason: str = ""


class RiskPredictionResponse(BaseModel):
    riskLevel: str
    riskScore: float
    expectedDelayHours: float
    priority: str
    factors: list[str] = Field(default_factory=list)
    recommendations: list[str] = Field(default_factory=list)
    modelUsed: str


class AssignmentRecommendationResponse(BaseModel):
    priority: str
    priorityScore: float
    bestRoute: RoutingRecommendation | None = None
    alternatives: list[RoutingRecommendation] = Field(default_factory=list)
    factors: list[str] = Field(default_factory=list)
    modelUsed: str


class AnomalyItem(BaseModel):
    type: str
    severity: str
    score: float
    description: str
    entityId: str | None = None


class RoutingDashboardResponse(BaseModel):
    modelStatus: str
    highRiskTasks: list[dict[str, Any]] = Field(default_factory=list)
    highRiskInstances: list[dict[str, Any]] = Field(default_factory=list)
    anomalies: list[AnomalyItem] = Field(default_factory=list)
    recommendations: list[str] = Field(default_factory=list)

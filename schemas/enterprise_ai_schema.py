from typing import Any

from pydantic import BaseModel, Field


class EnterpriseAiContextRequest(BaseModel):
    message: str = Field(min_length=1)
    user: dict[str, Any] = Field(default_factory=dict)
    currentContext: dict[str, Any] = Field(default_factory=dict)
    processes: list[dict[str, Any]] = Field(default_factory=list)
    tasks: list[dict[str, Any]] = Field(default_factory=list)
    documents: list[dict[str, Any]] = Field(default_factory=list)
    forms: list[dict[str, Any]] = Field(default_factory=list)
    areas: list[dict[str, Any]] = Field(default_factory=list)
    limits: dict[str, Any] = Field(default_factory=dict)


class EnterpriseAssistResponse(BaseModel):
    response: str
    intent: str | None = None
    confidence: float | None = None
    suggestedActions: list[str] = Field(default_factory=list)
    structuredData: dict[str, Any] = Field(default_factory=dict)


class ProcessRecommendationResponse(BaseModel):
    intent: str
    processKey: str | None = None
    confidence: float
    reason: str
    requiredDocuments: list[str] = Field(default_factory=list)
    requiredForms: list[str] = Field(default_factory=list)
    alternatives: list[str] = Field(default_factory=list)


class ReportPlanResponse(BaseModel):
    reportType: str
    filters: dict[str, Any] = Field(default_factory=dict)
    groupBy: str | None = None
    format: str = "JSON"
    columns: list[str] = Field(default_factory=list)
    confidence: float = 0.0
    reason: str = ""


class DocumentAnalysisRequest(BaseModel):
    text: str = Field(min_length=1)
    documentId: str | None = None
    analysisType: str | None = None
    context: dict[str, Any] = Field(default_factory=dict)


class DocumentAnalysisResponse(BaseModel):
    documentType: str
    confidence: float
    executiveSummary: str
    shortSummary: str
    detailedSummary: str
    keywords: list[str] = Field(default_factory=list)
    suggestedTags: list[str] = Field(default_factory=list)
    entities: dict[str, Any] = Field(default_factory=dict)

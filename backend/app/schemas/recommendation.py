import json
from datetime import datetime
from typing import Any
from pydantic import BaseModel, Field


class RecommendationRequest(BaseModel):
    location: str | None = None
    travel_context: str | None = None


class MealSuggestion(BaseModel):
    name: str
    description: str
    when_to_eat: str
    why: str
    order_url: str | None = None
    calories: int | None = None
    order_method: str | None = None
    tags: list[str] = Field(default_factory=list)


class RecommendationResponse(BaseModel):
    id: str
    user_id: str
    generated_at: datetime
    location: str
    travel_context: str | None
    window_start: datetime
    window_end: datetime
    calendar_summary: list[dict]
    recommendations: list[MealSuggestion]
    general_advice: str | None = None
    window_analyzed: str | None = None

    model_config = {"from_attributes": True}

    @classmethod
    def from_orm_model(cls, obj: Any) -> "RecommendationResponse":
        try:
            calendar_data = json.loads(obj.calendar_summary) if obj.calendar_summary else []
        except (json.JSONDecodeError, TypeError):
            calendar_data = []

        try:
            rec_data = json.loads(obj.recommendations_json) if obj.recommendations_json else {}
        except (json.JSONDecodeError, TypeError):
            rec_data = {}

        suggestions: list[MealSuggestion] = []
        general_advice: str | None = None
        window_analyzed: str | None = None

        if isinstance(rec_data, dict):
            raw_recs = rec_data.get("recommendations", [])
            general_advice = rec_data.get("general_advice")
            window_analyzed = rec_data.get("window_analyzed")
            for r in raw_recs:
                if isinstance(r, dict):
                    suggestions.append(
                        MealSuggestion(
                            name=r.get("name", ""),
                            description=r.get("description", ""),
                            when_to_eat=r.get("when_to_eat", ""),
                            why=r.get("why", ""),
                            order_url=r.get("order_url"),
                            calories=r.get("calories") or r.get("estimated_calories"),
                            order_method=r.get("order_method") or r.get("suggested_order_method"),
                            tags=r.get("tags", []),
                        )
                    )

        return cls(
            id=obj.id,
            user_id=obj.user_id,
            generated_at=obj.generated_at,
            location=obj.location,
            travel_context=obj.travel_context,
            window_start=obj.window_start,
            window_end=obj.window_end,
            calendar_summary=calendar_data,
            recommendations=suggestions,
            general_advice=general_advice,
            window_analyzed=window_analyzed,
        )


class LocationCreate(BaseModel):
    city: str
    address: str | None = None
    travel_note: str | None = None


class LocationResponse(BaseModel):
    id: str
    user_id: str
    city: str
    address: str | None
    travel_note: str | None
    updated_at: datetime

    model_config = {"from_attributes": True}

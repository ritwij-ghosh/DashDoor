from datetime import datetime
from pydantic import BaseModel, field_validator, model_validator
from typing import Any


class MealTemplateCreate(BaseModel):
    name: str
    description: str
    restaurant_name: str | None = None
    order_url: str | None = None
    calories: int | None = None
    tags: list[str] = []


class MealTemplateUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    restaurant_name: str | None = None
    order_url: str | None = None
    calories: int | None = None
    tags: list[str] | None = None


class MealTemplateResponse(BaseModel):
    id: str
    user_id: str
    name: str
    description: str
    restaurant_name: str | None
    order_url: str | None
    calories: int | None
    tags: list[str]
    created_at: datetime

    model_config = {"from_attributes": True}

    @model_validator(mode="before")
    @classmethod
    def parse_tags(cls, data: Any) -> Any:
        # Handle both ORM objects and dicts
        if hasattr(data, "tags"):
            raw = data.tags
        elif isinstance(data, dict):
            raw = data.get("tags")
        else:
            return data

        if isinstance(raw, str) and raw:
            # Convert comma-separated string to list
            if not isinstance(data, dict):
                # ORM object — we need to work around immutability
                return data
            data["tags"] = [t.strip() for t in raw.split(",") if t.strip()]
        elif raw is None or raw == "":
            if isinstance(data, dict):
                data["tags"] = []
        return data

    @classmethod
    def from_orm_model(cls, obj: Any) -> "MealTemplateResponse":
        tags: list[str] = []
        if obj.tags:
            tags = [t.strip() for t in obj.tags.split(",") if t.strip()]
        return cls(
            id=obj.id,
            user_id=obj.user_id,
            name=obj.name,
            description=obj.description,
            restaurant_name=obj.restaurant_name,
            order_url=obj.order_url,
            calories=obj.calories,
            tags=tags,
            created_at=obj.created_at,
        )

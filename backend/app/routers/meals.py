import datetime
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.routers.auth import get_current_user_id
from app.database import get_supabase

router = APIRouter(prefix="/meals", tags=["meals"])


class MealTemplateCreate(BaseModel):
    name: str
    description: Optional[str] = None
    restaurant_name: Optional[str] = None
    order_url: Optional[str] = None
    calories: Optional[int] = None
    tags: list[str] = []


class MealScoreCreate(BaseModel):
    meal_name: str
    score: int  # 1-5
    notes: Optional[str] = None
    recommendation_id: Optional[str] = None


@router.post("/templates", status_code=201)
async def create_template(
    body: MealTemplateCreate,
    user_id: str = Depends(get_current_user_id),
) -> dict:
    db = get_supabase()
    res = db.table("meal_templates").insert({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "name": body.name,
        "description": body.description,
        "restaurant_name": body.restaurant_name,
        "order_url": body.order_url,
        "calories": body.calories,
        "tags": body.tags,
        "created_at": datetime.datetime.utcnow().isoformat(),
    }).execute()
    return res.data[0]


@router.get("/templates")
async def list_templates(user_id: str = Depends(get_current_user_id)) -> list[dict]:
    db = get_supabase()
    res = (
        db.table("meal_templates")
        .select("*")
        .eq("user_id", user_id)
        .order("created_at", desc=True)
        .execute()
    )
    return res.data or []


@router.delete("/templates/{template_id}", status_code=204)
async def delete_template(
    template_id: str,
    user_id: str = Depends(get_current_user_id),
) -> None:
    db = get_supabase()
    db.table("meal_templates").delete().eq("id", template_id).eq("user_id", user_id).execute()


@router.post("/scores", status_code=201)
async def score_meal(
    body: MealScoreCreate,
    user_id: str = Depends(get_current_user_id),
) -> dict:
    if not 1 <= body.score <= 5:
        raise HTTPException(status_code=400, detail="Score must be between 1 and 5")
    db = get_supabase()
    res = db.table("meal_scores").insert({
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "meal_name": body.meal_name,
        "score": body.score,
        "notes": body.notes,
        "recommendation_id": body.recommendation_id,
        "eaten_at": datetime.datetime.utcnow().isoformat(),
    }).execute()
    return res.data[0]


@router.get("/scores")
async def get_scores(
    limit: int = 20,
    user_id: str = Depends(get_current_user_id),
) -> list[dict]:
    db = get_supabase()
    res = (
        db.table("meal_scores")
        .select("*")
        .eq("user_id", user_id)
        .order("eaten_at", desc=True)
        .limit(limit)
        .execute()
    )
    return res.data or []

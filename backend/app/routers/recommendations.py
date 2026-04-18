from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from app.routers.auth import get_current_user_id
from app.database import get_supabase
from app.services.recommendation_service import generate_recommendations_for_user

router = APIRouter(prefix="/recommendations", tags=["recommendations"])


class RecommendationRequest(BaseModel):
    location: Optional[str] = None
    travel_context: Optional[str] = None


@router.post("/generate", status_code=201)
async def generate(
    body: RecommendationRequest,
    user_id: str = Depends(get_current_user_id),
) -> dict:
    db = get_supabase()
    return await generate_recommendations_for_user(
        user_id=user_id,
        db=db,
        location_override=body.location,
        travel_override=body.travel_context,
    )


@router.get("")
async def list_recommendations(
    limit: int = 10,
    user_id: str = Depends(get_current_user_id),
) -> list[dict]:
    db = get_supabase()
    res = (
        db.table("recommendations")
        .select("*")
        .eq("user_id", user_id)
        .order("generated_at", desc=True)
        .limit(limit)
        .execute()
    )
    return res.data or []


@router.get("/{recommendation_id}")
async def get_recommendation(
    recommendation_id: str,
    user_id: str = Depends(get_current_user_id),
) -> dict:
    db = get_supabase()
    res = (
        db.table("recommendations")
        .select("*")
        .eq("id", recommendation_id)
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )
    if not res.data:
        raise HTTPException(status_code=404, detail="Not found")
    return res.data

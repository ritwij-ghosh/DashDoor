import asyncio
import logging
from functools import partial

import httpx

from app.config import settings

logger = logging.getLogger(__name__)


def _composio_search(city: str) -> list[dict]:
    from composio import ComposioToolSet, Action

    toolset = ComposioToolSet(api_key=settings.COMPOSIO_API_KEY)
    response = toolset.execute_action(
        action=Action.SERPAPI_SEARCH,
        params={"q": f"best restaurants near {city}", "num": 10},
    )
    data = response if isinstance(response, dict) else {}
    inner = data.get("data") or data.get("response_data") or data
    results = []
    if isinstance(inner, dict):
        results = inner.get("local_results") or inner.get("organic_results") or []
    elif isinstance(inner, list):
        results = inner

    restaurants = []
    for r in results[:8]:
        if not isinstance(r, dict):
            continue
        restaurants.append({
            "name": r.get("title") or r.get("name", ""),
            "cuisine": r.get("type") or r.get("category", ""),
            "rating": r.get("rating"),
            "address": r.get("address") or r.get("snippet", ""),
        })
    return [r for r in restaurants if r["name"]]


async def _serper_search(city: str) -> list[dict]:
    async with httpx.AsyncClient(timeout=8) as client:
        res = await client.post(
            "https://google.serper.dev/search",
            headers={"X-API-KEY": settings.SERPER_API_KEY, "Content-Type": "application/json"},
            json={"q": f"best restaurants near {city}", "num": 10, "type": "search"},
        )
        data = res.json()
    restaurants = []
    for r in (data.get("organic") or [])[:8]:
        if not isinstance(r, dict):
            continue
        restaurants.append({
            "name": r.get("title", "").split(" - ")[0].strip(),
            "cuisine": "",
            "rating": None,
            "address": r.get("snippet", ""),
        })
    return [r for r in restaurants if r["name"]]


async def search_nearby_restaurants(city: str) -> list[dict]:
    """Search for nearby restaurants using Composio/Serper. Returns [] on any failure."""
    if not city or city == "Unknown":
        return []

    # Try Composio SERPAPI (sync SDK, run in thread executor)
    try:
        loop = asyncio.get_event_loop()
        restaurants = await loop.run_in_executor(None, partial(_composio_search, city))
        if restaurants:
            logger.info("Got %d restaurants via Composio for city=%s", len(restaurants), city)
            return restaurants
    except Exception:
        logger.debug("Composio restaurant search unavailable, trying fallback")

    # Try Serper.dev (free tier, optional key)
    if settings.SERPER_API_KEY:
        try:
            restaurants = await _serper_search(city)
            if restaurants:
                logger.info("Got %d restaurants via Serper for city=%s", len(restaurants), city)
                return restaurants
        except Exception:
            logger.debug("Serper restaurant search failed")

    return []

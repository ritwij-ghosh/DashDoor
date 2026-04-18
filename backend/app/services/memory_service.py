from typing import Optional

import httpx

from app.config import settings

# Supermemory API — https://docs.supermemory.ai
_BASE = "https://api.supermemory.ai/v3"


async def add_memory(user_id: str, content: str, metadata: Optional[dict] = None) -> None:
    if not settings.SUPERMEMORY_API_KEY:
        return
    async with httpx.AsyncClient() as http:
        try:
            await http.post(
                f"{_BASE}/memories",
                headers={"Authorization": f"Bearer {settings.SUPERMEMORY_API_KEY}"},
                json={"content": content, "userId": user_id, "metadata": metadata or {}},
                timeout=10,
            )
        except Exception:
            pass  # Memory is best-effort; never fail a request over it


async def search_memories(user_id: str, query: str, limit: int = 5) -> list[str]:
    if not settings.SUPERMEMORY_API_KEY:
        return []
    async with httpx.AsyncClient() as http:
        try:
            res = await http.post(
                f"{_BASE}/search",
                headers={"Authorization": f"Bearer {settings.SUPERMEMORY_API_KEY}"},
                json={"query": query, "userId": user_id, "limit": limit},
                timeout=10,
            )
            data = res.json()
            results = data.get("results", [])
            return [r.get("content", "") for r in results if r.get("content")]
        except Exception:
            return []

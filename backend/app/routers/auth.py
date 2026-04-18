import base64
import json

import httpx
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt

from app.config import settings

security = HTTPBearer()

_JWKS_CACHE: dict | None = None


def _get_jwks() -> dict:
    global _JWKS_CACHE
    if _JWKS_CACHE is None:
        resp = httpx.get(
            f"{settings.SUPABASE_URL}/auth/v1/.well-known/jwks.json",
            timeout=10,
        )
        _JWKS_CACHE = resp.json()
    return _JWKS_CACHE


def _token_header(token: str) -> dict:
    padded = token.split(".")[0] + "=="
    return json.loads(base64.urlsafe_b64decode(padded).decode())


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> str:
    token = credentials.credentials
    try:
        header = _token_header(token)
        alg = header.get("alg", "HS256")
        kid = header.get("kid")

        if alg == "HS256":
            payload = jwt.decode(
                token,
                settings.SUPABASE_JWT_SECRET,
                algorithms=["HS256"],
                options={"verify_aud": False},
            )
        else:
            jwks = _get_jwks()
            key = next(
                (k for k in jwks.get("keys", []) if k.get("kid") == kid),
                None,
            )
            if key is None:
                # Stale cache — refetch once
                global _JWKS_CACHE
                _JWKS_CACHE = None
                jwks = _get_jwks()
                key = next(
                    (k for k in jwks.get("keys", []) if k.get("kid") == kid),
                    None,
                )
            if key is None:
                raise HTTPException(status_code=401, detail="Unknown signing key")
            payload = jwt.decode(
                token,
                key,
                algorithms=[alg],
                options={"verify_aud": False},
            )

        user_id: str | None = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

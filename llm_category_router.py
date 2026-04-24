"""
Optional LLM-based routing: map a free-text product query to one store vertical.

Uses any OpenAI-compatible Chat Completions API. If GROQ_API_KEY is set, defaults to
https://api.groq.com/openai/v1 and a Groq chat model unless overridden.

Falls back silently when disabled, misconfigured, or on error — keyword logic in categories.py still applies.

Environment:
  LLM_ROUTER_DISABLE=1          — never call the LLM
  GROQ_API_KEY                  — if set, uses Groq (preferred when present)
  LLM_ROUTER_API_KEY            — or OPENAI_API_KEY for OpenAI / other hosts
  LLM_ROUTER_BASE_URL           — default depends on provider (Groq vs OpenAI)
  LLM_ROUTER_MODEL              — default llama-3.1-8b-instant (Groq) or gpt-4o-mini (OpenAI)
  LLM_ROUTER_JSON_MODE=0        — omit response_format (e.g. for some local servers)

Loads PROJECT_ROOT/.env when python-dotenv is installed (see backend settings).
"""

from __future__ import annotations

import json
import logging
import os
import re
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).resolve().parent / ".env")
except ImportError:
    pass

ALLOWED = frozenset({"electronics", "food", "cosmetics", "pharmacy", "all"})

_SYSTEM = """You are a routing assistant for a Tunisia e-commerce product search engine.
Given the user's short product search query, pick exactly ONE category that best matches where they most likely want to shop:

- electronics — phones, laptops, PC parts, TVs, consoles, small appliances (tech), cables, gadgets sold by electronics stores
- food — groceries: milk, dairy, yogurt, cheese, snacks, drinks, rice, pasta, frozen food, etc.
- cosmetics — makeup, skincare, face wash, cleanser, shampoo, hair care, perfume, beauty (parapharmacie / beauty retailers)
- pharmacy — medicines, supplements, vitamins, dermo prescriptions vibe, medical devices sold at pharmacy-first retailers (if unsure between cosmetics vs pharmacy for a skincare product, prefer cosmetics)
- all — the query is too vague, multi-domain, or could reasonably apply to several verticals equally

Respond with a single JSON object only, no markdown, shape: {"category":"<one of electronics|food|cosmetics|pharmacy|all>","reason":"<optional short reason>"}"""


def _env_bool(name: str, default: bool = False) -> bool:
    v = (os.environ.get(name) or "").strip().lower()
    if not v:
        return default
    return v in ("1", "true", "yes", "on")


def _parse_category_from_response(data: dict[str, Any]) -> str | None:
    """Extract category from OpenAI-style chat completion JSON."""
    try:
        choices = data.get("choices") or []
        if not choices:
            return None
        content = (choices[0].get("message") or {}).get("content") or ""
        content = content.strip()
        # Model might wrap in ```json
        m = re.search(r"\{[\s\S]*\}", content)
        if m:
            content = m.group(0)
        obj = json.loads(content)
        cat = (obj.get("category") or "").strip().lower()
        if cat in ALLOWED:
            return cat
        logger.warning("LLM returned invalid category %r", cat)
        return None
    except (json.JSONDecodeError, KeyError, TypeError, IndexError) as e:
        logger.warning("LLM response parse error: %s", e)
        return None


def _resolve_llm_endpoint() -> tuple[str, str, str] | None:
    """
    Return (api_key, base_url_without_trailing_slash, model) or None if no key.
    Prefers Groq when GROQ_API_KEY is set.
    """
    groq = (os.environ.get("GROQ_API_KEY") or "").strip()
    if groq:
        base = (os.environ.get("LLM_ROUTER_BASE_URL") or "").strip().rstrip("/") or "https://api.groq.com/openai/v1"
        model = (
            (os.environ.get("LLM_ROUTER_MODEL") or os.environ.get("LLM_MODEL") or "").strip()
            or "llama-3.1-8b-instant"
        )
        return groq, base, model

    api_key = (os.environ.get("LLM_ROUTER_API_KEY") or os.environ.get("OPENAI_API_KEY") or "").strip()
    if not api_key:
        return None
    base = (os.environ.get("LLM_ROUTER_BASE_URL") or "").strip().rstrip("/") or "https://api.openai.com/v1"
    model = (os.environ.get("LLM_ROUTER_MODEL") or os.environ.get("LLM_MODEL") or "gpt-4o-mini").strip()
    return api_key, base, model


def infer_category_via_llm(query: str) -> str | None:
    """
    Return one of electronics|food|cosmetics|pharmacy|all, or None if LLM not used / failed.

    None means: fall back to keyword-based inference in categories.resolve_stores_for_search.
    """
    if _env_bool("LLM_ROUTER_DISABLE", False):
        return None

    q = (query or "").strip()
    if not q:
        return None

    resolved = _resolve_llm_endpoint()
    if not resolved:
        return None
    api_key, base, model = resolved
    # Default: JSON mode on; set LLM_ROUTER_JSON_MODE=0 for servers that reject response_format
    _jm = (os.environ.get("LLM_ROUTER_JSON_MODE") or "").strip().lower()
    use_json_mode = _jm not in ("0", "false", "no", "off")

    url = f"{base}/chat/completions"
    payload: dict[str, Any] = {
        "model": model,
        "messages": [
            {"role": "system", "content": _SYSTEM},
            {"role": "user", "content": f'User search query: "{q}"'},
        ],
        "temperature": 0,
        "max_tokens": 120,
    }
    if use_json_mode:
        payload["response_format"] = {"type": "json_object"}

    try:
        import httpx

        with httpx.Client(timeout=25.0) as client:
            r = client.post(
                url,
                headers={
                    "Authorization": f"Bearer {api_key}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        if r.status_code != 200:
            logger.warning("LLM router HTTP %s: %s", r.status_code, r.text[:500])
            return None
        data = r.json()
        cat = _parse_category_from_response(data)
        if cat:
            logger.info("LLM category router: %r -> %s", q, cat)
        return cat
    except Exception as e:
        logger.warning("LLM router request failed: %s", e)
        return None

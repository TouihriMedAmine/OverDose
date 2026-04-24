"""
Resolve which store verticals to search from the user query (auto) or an explicit category.
"""

from __future__ import annotations

import re
import logging

from config import CATEGORY_QUERY_KEYWORDS, STORES

logger = logging.getLogger(__name__)

try:
    from llm_category_router import infer_category_via_llm
except ImportError:  # pragma: no cover

    def infer_category_via_llm(query: str) -> str | None:  # type: ignore[misc]
        return None

EXPLICIT_CATEGORY_MODES = frozenset({"electronics", "food", "cosmetics", "pharmacy"})


def _keyword_in_query(q: str, kw: str) -> bool:
    kw = (kw or "").strip().lower()
    if not kw:
        return False
    if " " in kw:
        return kw in q
    if len(kw) <= 3:
        return bool(re.search(rf"\b{re.escape(kw)}\b", q))
    return kw in q


def infer_categories_from_query(query: str) -> list[str] | None:
    """
    Infer store verticals from the query text.
    Returns a non-empty list of category ids if any keyword matched, else None (search all stores).
    """
    q = " ".join((query or "").lower().split())
    if not q:
        return None
    matched: set[str] = set()
    for cat, keywords in CATEGORY_QUERY_KEYWORDS.items():
        for kw in keywords:
            if _keyword_in_query(q, kw):
                matched.add(cat)
                break
    return sorted(matched) if matched else None


def stores_for_category_ids(category_ids: list[str]) -> list[dict]:
    """Stores whose categories intersect category_ids."""
    want = set(category_ids)
    return [s for s in STORES if want & set(s.get("categories", []))]


def resolve_stores_for_search(category_mode: str, query: str) -> tuple[list[dict], list[str], str]:
    """
    Pick which store configs to scrape.

    Args:
        category_mode: "auto" | "all" | "electronics" | "food" | "cosmetics" | "pharmacy"
        query: raw search string (used when mode is auto)

    Returns:
        (stores, categories_applied, human_note)
        categories_applied is e.g. ["food"] or [] when all stores are used.
    """
    mode = (category_mode or "auto").strip().lower()

    if mode == "all":
        return list(STORES), [], "all stores"

    if mode in EXPLICIT_CATEGORY_MODES:
        stores = stores_for_category_ids([mode])
        if not stores:
            logger.warning("No stores for category %s; using all stores", mode)
            return list(STORES), [], f"{mode} (no configured stores — searched all)"
        return stores, [mode], mode

    # auto — optional LLM picks one vertical, else keyword lists, else all stores
    llm_cat = infer_category_via_llm(query)
    if llm_cat == "all":
        return list(STORES), [], "auto: LLM → all stores (ambiguous or multi-domain query)"

    if llm_cat in EXPLICIT_CATEGORY_MODES:
        stores = stores_for_category_ids([llm_cat])
        if not stores:
            logger.warning("LLM chose %s but no stores match; falling back to keywords", llm_cat)
        else:
            return stores, [llm_cat], f"auto: LLM → {llm_cat}"

    inferred = infer_categories_from_query(query)
    if inferred is None:
        return list(STORES), [], "auto: all stores (no LLM / no category keywords matched)"

    stores = stores_for_category_ids(inferred)
    if not stores:
        logger.warning("Inferred %s but no stores match; using all stores", inferred)
        return list(STORES), [], f"auto: {','.join(inferred)} (no stores — searched all)"

    tag = ",".join(inferred)
    return stores, inferred, f"auto: {tag}"


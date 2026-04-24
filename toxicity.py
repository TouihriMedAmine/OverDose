"""
Load static toxicity data and score product titles (heuristic keyword / pattern match).
"""

from __future__ import annotations

import json
import logging
import re
from functools import lru_cache
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)

_DEFAULT_DATA = Path(__file__).resolve().parent / "data" / "toxicity.json"


@lru_cache(maxsize=1)
def load_toxicity_data(path: Path | None = None) -> dict[str, Any]:
    """Load and cache JSON toxicity configuration."""
    p = path or _DEFAULT_DATA
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def _label_for_score(score: float, labels: dict[str, list[int]]) -> str:
    s = int(round(score))
    for name, bounds in labels.items():
        lo, hi = bounds[0], bounds[1]
        if lo <= s <= hi:
            return name
    return "moderate"


def _term_matches(title_lower: str, term: str) -> bool:
    t = term.strip().lower()
    if not t:
        return False
    if len(t) < 4:
        return bool(re.search(rf"\b{re.escape(t)}\b", title_lower))
    return t in title_lower


def _rule_matches_title(title_lower: str, terms: list[str]) -> bool:
    for term in terms:
        if _term_matches(title_lower, term):
            return True
    return False


def score_product_title(title: str, data: dict[str, Any] | None = None) -> dict[str, Any]:
    """
    Compute toxicity score (0–100) and label from product title using static rules.

    Returns:
        toxicity_score, toxicity_label, toxicity_matches (list of contributing rules),
        toxicity_note (short summary).
    """
    data = data or load_toxicity_data()
    settings = data.get("settings") or {}
    baseline = float(settings.get("baseline_score", 10))
    max_score = float(settings.get("max_score", 100))
    labels_cfg = settings.get("labels") or {
        "low": [0, 32],
        "moderate": [33, 65],
        "high": [66, 100],
    }

    title_lower = (title or "").lower()
    total = baseline
    matches: list[dict[str, Any]] = []

    for rule in data.get("keyword_rules") or []:
        terms = rule.get("terms") or []
        if not terms or not _rule_matches_title(title_lower, terms):
            continue
        add = float(rule.get("score", 0))
        total += add
        matches.append(
            {
                "kind": "keyword",
                "contribution": add,
                "note": rule.get("note", ""),
                "matched_terms": [x for x in terms if _term_matches(title_lower, x)][:3],
            }
        )

    for floor in data.get("product_risk_floors") or []:
        pats = floor.get("patterns") or []
        if not any(pat.lower() in title_lower for pat in pats):
            continue
        minimum = float(floor.get("minimum_score", 0))
        if total < minimum:
            delta = minimum - total
            total = minimum
            matches.append(
                {
                    "kind": "risk_floor",
                    "contribution": delta,
                    "note": floor.get("note", ""),
                    "matched_patterns": [x for x in pats if x.lower() in title_lower][:3],
                }
            )

    total = max(0.0, min(max_score, total))
    label = _label_for_score(total, labels_cfg)

    note_parts = [m.get("note") for m in matches if m.get("note")]
    short_note = note_parts[0] if note_parts else "Baseline estimate from product title only."

    return {
        "toxicity_score": round(total, 1),
        "toxicity_label": label,
        "toxicity_matches": matches,
        "toxicity_note": short_note,
    }


def enrich_product_dict(product: dict[str, Any], data: dict[str, Any] | None = None) -> dict[str, Any]:
    """Add toxicity fields to a product dict (mutates and returns same dict)."""
    title = product.get("title") or ""
    tox = score_product_title(title, data=data)
    product.update(tox)
    return product

"""
Heuristic brand extraction from product titles (cosmetics / parapharmacy style).
"""

from __future__ import annotations

import re


def normalize_brand_key(brand: str) -> str:
    s = " ".join((brand or "").upper().split())
    return s[:96] if s else ""


def extract_brand_guess(title: str) -> str:
    """
    Guess brand from leading ALL-CAPS words (common on TN parapharmacy listings).
    Falls back to the first token if needed.
    """
    if not title:
        return ""
    raw = title.strip()
    parts = re.split(r"\s+", raw)
    acc: list[str] = []
    for p in parts[:10]:
        w = re.sub(r"^[^A-Za-z0-9]+|[^A-Za-z0-9]+$", "", p)
        if not w:
            continue
        if not acc:
            if len(w) >= 2:
                acc.append(w.upper())
            continue
        if w.isalpha() and w.isupper() and len(w) >= 2:
            acc.append(w)
            if len(acc) >= 5:
                break
        else:
            break
    if acc:
        return normalize_brand_key(" ".join(acc))
    first = re.sub(r"^[^A-Za-z0-9]+|[^A-Za-z0-9]+$", "", parts[0]) if parts else ""
    return normalize_brand_key(first[:48]) if first else ""

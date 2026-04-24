"""
Incremental preference updates (EMA / bandit-style Q update).

Each click on a product is treated as reward=1 for the inferred brand arm.
This is a lightweight reinforcement-style signal (contextual bandit over brands).
"""

from __future__ import annotations

from typing import Any, Callable

# Learning rate: balance stability vs responsiveness
ALPHA = 0.2
# How much affinity affects ranking vs original order (0 = off)
RANK_WEIGHT = 4.0


def q_update(old_value: float, reward: float = 1.0, alpha: float = ALPHA) -> float:
    """Exponential moving average toward observed reward."""
    return (1.0 - alpha) * float(old_value) + alpha * float(reward)


def apply_loyalty_ranking(
    products: list[dict[str, Any]],
    affinity_by_brand: dict[str, float],
    extract_brand: Callable[[str], str],
) -> list[dict[str, Any]]:
    """
    Stable sort: higher learned affinity first; ties keep original order.
    Adds brand_guess and loyalty_boost to each product dict.
    """
    indexed: list[tuple[float, int, dict[str, Any]]] = []
    for idx, p in enumerate(products):
        title = (p.get("title") or "").strip()
        brand = extract_brand(title)
        boost = affinity_by_brand.get(brand, 0.0) if brand else 0.0
        enriched = {**p, "brand_guess": brand, "loyalty_boost": round(boost, 4)}
        indexed.append((-boost * RANK_WEIGHT, idx, enriched))
    indexed.sort(key=lambda t: (t[0], t[1]))
    return [t[2] for t in indexed]

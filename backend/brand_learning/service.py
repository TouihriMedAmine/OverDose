from __future__ import annotations

from django.contrib.auth import get_user_model

from .brand_extract import extract_brand_guess, normalize_brand_key
from .models import BrandAffinity
from .rl_update import q_update

User = get_user_model()


def affinity_map_for_user(user) -> dict[str, float]:
    return {row.brand_key: float(row.value) for row in BrandAffinity.objects.filter(user=user)}


def record_product_click(user, title: str) -> str | None:
    """
    Reward=1 for inferred brand; returns brand_key or None if skipped.
    """
    brand = extract_brand_guess(title)
    if not brand:
        return None
    brand = normalize_brand_key(brand)
    row = BrandAffinity.objects.filter(user=user, brand_key=brand).first()
    if row is None:
        BrandAffinity.objects.create(user=user, brand_key=brand, value=q_update(0.0), click_count=1)
        return brand
    row.value = q_update(row.value, reward=1.0)
    row.click_count += 1
    row.save(update_fields=["value", "click_count", "updated_at"])
    return brand


def top_brands_for_user(user, limit: int = 8) -> list[dict]:
    rows = BrandAffinity.objects.filter(user=user).order_by("-value", "-updated_at")[:limit]
    return [{"brand": r.brand_key, "score": round(r.value, 4), "clicks": r.click_count} for r in rows]

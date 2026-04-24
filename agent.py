"""
Tunisia product availability agent.
Takes a product query, scrapes configured Tunisian e-commerce sites and optional search,
returns aggregated results with prices and where to buy.
"""

import json
import logging
from dataclasses import asdict, dataclass, field
from typing import Any

from categories import resolve_stores_for_search
from config import QUERY_VARIANTS, STORES
from scraper import scrape_all_stores, ProductResult
from search_fallback import search_tunisia_product
from toxicity import enrich_product_dict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class AgentResult:
    """Structured output of the agent."""
    query: str
    products: list[dict[str, Any]]  # list of product hits with title, price, url, store_name, store_id
    search_links: list[dict[str, str]]  # optional extra links from web search (title, url, snippet)
    summary: str
    category_mode: str = "auto"
    categories_applied: list[str] = field(default_factory=list)
    search_scope_note: str = ""
    scope_widened: bool = False


def _product_to_dict(p: ProductResult) -> dict[str, Any]:
    return {
        "title": p.title,
        "price": p.price,
        "price_numeric": p.price_numeric,
        "url": p.url,
        "image_url": getattr(p, "image_url", "") or "",
        "store_name": p.store_name,
        "store_id": p.store_id,
    }


def run_agent(
    product_query: str,
    use_search_fallback: bool = True,
    category: str = "auto",
) -> AgentResult:
    """
    Run the Tunisia product availability agent.

    Args:
        product_query: Product name or search term (e.g. "iPhone 15", "Samsung Galaxy").
        use_search_fallback: If True, also run a web search for "product Tunisia" and include links.
        category: Store vertical filter: "auto" (infer from query), "all", or one of
            electronics | food | cosmetics | pharmacy.

    Returns:
        AgentResult with products (from store scrapers), search_links (from fallback), and a summary.
    """
    query = (product_query or "").strip()
    mode = (category or "auto").strip().lower()
    if not query:
        return AgentResult(
            query=query,
            products=[],
            search_links=[],
            summary="No search query provided.",
            category_mode=mode,
            categories_applied=[],
            search_scope_note="",
            scope_widened=False,
        )

    stores, categories_applied, search_scope_note = resolve_stores_for_search(mode, query)

    # Build query variants (e.g. "yogurt" -> also search "yaourt" on French sites)
    queries = [query]
    key = " ".join(query.lower().replace("-", " ").split()).strip()
    if key in QUERY_VARIANTS:
        for v in QUERY_VARIANTS[key]:
            if v and v not in queries:
                queries.append(v)

    def _collect_from_stores(store_list: list[dict]) -> list[ProductResult]:
        products_seen: set[str] = set()
        out: list[ProductResult] = []
        for q in queries:
            for p in scrape_all_stores(q, stores=store_list):
                u = (p.url or "").strip()
                if u and u not in products_seen:
                    products_seen.add(u)
                    out.append(p)
                elif not u:
                    out.append(p)
        return out

    # 1) Scrape stores in the chosen scope; if nothing is found, search all stores once
    products = _collect_from_stores(stores)
    scope_widened = False
    if not products and len(stores) < len(STORES):
        logger.info("No products in category scope; widening search to all stores")
        scope_widened = True
        search_scope_note = (
            search_scope_note
            + " No results in that scope — widened to all stores"
        )
        products = _collect_from_stores(list(STORES))

    # 2) Relevance: rank by how well the title matches the query, then by price
    def _keywords(text: str) -> set[str]:
        return set(w for w in text.lower().replace("-", " ").replace("'", " ").split() if len(w) > 1)

    query_words = _keywords(query)
    for v in (queries[1:] if len(queries) > 1 else []):
        query_words.update(_keywords(v))

    def _relevance(p: ProductResult) -> tuple[int, float]:
        title_lower = (p.title or "").lower()
        score = sum(1 for w in query_words if w in title_lower)
        price = p.price_numeric if p.price_numeric is not None else 0.0
        return (-score, price)  # higher score first, then lower price

    products.sort(key=_relevance)
    product_dicts = [enrich_product_dict(_product_to_dict(p)) for p in products]

    # 3) Optional: web search for more Tunisian store links
    search_links: list[dict[str, str]] = []
    if use_search_fallback:
        try:
            search_links = search_tunisia_product(query, max_results=5)
        except Exception as e:
            logger.warning("Search fallback error: %s", e)

    # 4) Build summary
    store_counts: dict[str, int] = {}
    for p in products:
        store_counts[p.store_name] = store_counts.get(p.store_name, 0) + 1
    parts = [
        f"Found {len(products)} product(s) in Tunisia for \"{query}\".",
        f"Stores: {search_scope_note}.",
    ]
    if scope_widened:
        parts.append(
            "(Category filter had no hits; results may include other store types.)"
        )
    if store_counts:
        parts.append("By store: " + ", ".join(f"{k}: {v}" for k, v in store_counts.items()) + ".")
    if search_links:
        parts.append(f"Also found {len(search_links)} relevant link(s) from web search.")
    summary = " ".join(parts)

    return AgentResult(
        query=query,
        products=product_dicts,
        search_links=search_links,
        summary=summary,
        category_mode=mode,
        categories_applied=categories_applied,
        search_scope_note=search_scope_note,
        scope_widened=scope_widened,
    )


def run_agent_json(
    product_query: str,
    use_search_fallback: bool = True,
    category: str = "auto",
) -> str:
    """Run agent and return JSON string (for API or piping)."""
    result = run_agent(product_query, use_search_fallback=use_search_fallback, category=category)
    return json.dumps(asdict(result), ensure_ascii=False, indent=2)

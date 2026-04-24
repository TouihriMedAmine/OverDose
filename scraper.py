"""
Web scraper for Tunisian e-commerce product search.
Fetches search results and parses product cards (title, price, link) from store configs.
"""

import re
import logging
from dataclasses import dataclass, field
from urllib.parse import urljoin, quote_plus

import requests
from bs4 import BeautifulSoup

from config import STORES, DEFAULT_HEADERS, REQUEST_TIMEOUT, MAX_RESULTS_PER_STORE

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class ProductResult:
    """Single product hit from a store."""
    title: str
    price: str
    price_numeric: float | None  # for sorting
    url: str
    image_url: str  # product image
    store_name: str
    store_id: str


def _normalize_price(text: str) -> tuple[str, float | None]:
    """Extract price string and numeric value (TND). Handles FR format: space=thousands, comma=decimal."""
    if not text:
        return "", None
    raw = text.strip().replace("\u202f", " ").replace("\xa0", " ")
    # One or more number-like parts: "3 499,000 DT" or "19,000 DT"
    match = re.search(r"([\d\s]+[,.]?\d*)\s*(?:DT|TND|€|USD)?", raw, re.I)
    if not match:
        return raw, None
    num_str = match.group(1).replace(" ", "").replace(",", ".")
    try:
        value = float(num_str)
        return raw, value
    except ValueError:
        return raw, None


def _get_text(el) -> str:
    if el is None:
        return ""
    return (el.get_text(strip=True) or "").strip()


def _get_attr(el, attr: str, default: str = "") -> str:
    if el is None:
        return default
    return el.get(attr, default) or default


def _resolve_store_url(store: dict, query: str) -> str:
    """Pick listing URL: category_routes[query] > category_url if query in category_queries > search."""
    qn = (query or "").lower().strip()
    routes = store.get("category_routes") or {}
    if qn in routes:
        return routes[qn]
    if qn in store.get("category_queries", []):
        return store.get("category_url") or store["search_url"].format(query=quote_plus(query))
    return store["search_url"].format(query=quote_plus(query))


def scrape_store(store: dict, query: str) -> list[ProductResult]:
    """
    Scrape one store's search or category listing for the given query.
    Optional ``category_routes``: map normalized query (lowercase) -> full category URL
    (used when the site's search URL returns no server-rendered products).
    """
    url = _resolve_store_url(store, query)
    results: list[ProductResult] = []
    sel = store.get("selectors", {})

    try:
        resp = requests.get(url, headers=DEFAULT_HEADERS, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
        resp.encoding = resp.apparent_encoding or "utf-8"
    except requests.RequestException as e:
        logger.warning("Request failed for %s: %s", store.get("name"), e)
        return results

    soup = BeautifulSoup(resp.text, "lxml")
    base_url = store.get("base_url", "")

    card_sel = sel.get("product_card")
    if not card_sel:
        return results

    cards = soup.select(card_sel)[:MAX_RESULTS_PER_STORE]

    price_sel = sel.get("price", ".price")
    price_selectors = [price_sel] if isinstance(price_sel, str) else list(price_sel or [".price", ".current-price"])

    for card in cards:
        title_el = card.select_one(sel.get("title", ".product-title a"))
        link_el = card.select_one(sel.get("link", "a.product-name"))
        price_el = None
        for ps in price_selectors:
            price_el = card.select_one(ps)
            if price_el and _get_text(price_el).strip():
                break
        if not price_el or not _get_text(price_el).strip():
            price_el = card.select_one(".current-price, .product-price, .price, [class*='price']")

        title = _get_text(title_el) if title_el else _get_text(link_el)
        link = _get_attr(link_el, "href") if link_el else ""
        if link and base_url and not link.startswith("http"):
            link = urljoin(base_url, link)

        img_el = card.select_one(sel.get("image", ".product-cover img, .product-thumbnail img, img"))
        img_src = ""
        if img_el:
            img_src = _get_attr(img_el, "data-src") or _get_attr(img_el, "data-lazy-src") or _get_attr(img_el, "src")
            if img_src and base_url and not img_src.startswith("http"):
                img_src = urljoin(base_url, img_src)

        price_str = _get_text(price_el) if price_el else ""
        if not price_str and card.get_text():
            match = re.search(r"[\d\s]+[,.]\d+\s*(?:TND|DT|€)", card.get_text())
            if match:
                price_str = match.group(0).strip()
        price_str, price_num = _normalize_price(price_str)

        if not title:
            continue

        results.append(
            ProductResult(
                title=title,
                price=price_str,
                price_numeric=price_num,
                url=link,
                image_url=img_src or "",
                store_name=store["name"],
                store_id=store["id"],
            )
        )

    return results


def scrape_all_stores(query: str, stores: list[dict] | None = None) -> list[ProductResult]:
    """
    Run search across Tunisian stores and return combined results.

    Args:
        query: search string passed to each store URL / category logic.
        stores: subset of STORES to query; default is all configured stores.
    """
    store_list = stores if stores is not None else STORES
    all_results: list[ProductResult] = []
    for store in store_list:
        try:
            hits = scrape_store(store, query)
            all_results.extend(hits)
            if hits:
                logger.info("Found %d results from %s", len(hits), store["name"])
        except Exception as e:
            logger.warning("Scraper error for %s: %s", store.get("name"), e)

    # Deduplicate by URL
    seen_urls: set[str] = set()
    unique: list[ProductResult] = []
    for p in all_results:
        u = (p.url or "").strip()
        if u and u not in seen_urls:
            seen_urls.add(u)
            unique.append(p)
        elif not u:
            unique.append(p)

    # Sort by price (cheapest first when available)
    def sort_key(p: ProductResult):
        if p.price_numeric is not None:
            return (0, p.price_numeric)
        return (1, 0.0)

    unique.sort(key=sort_key)
    return unique

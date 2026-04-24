"""
Fallback: search the web for "product name Tunisia" and return links that look like
Tunisian e-commerce product pages. Can be used to discover more stores or product URLs.
"""

import re
import logging
from urllib.parse import quote_plus

import requests
from bs4 import BeautifulSoup

from config import DEFAULT_HEADERS, REQUEST_TIMEOUT

logger = logging.getLogger(__name__)

# DuckDuckGo HTML search (no API key)
DDG_SEARCH = "https://html.duckduckgo.com/html/?q={query}"

# Domains we consider Tunisian e-commerce
TUNISIA_STORE_PATTERNS = [
    r"mytek\.tn",
    r"tunisianet\.com\.tn",
    r"wiki\.tn",
    r"[\w-]+\.tn",
    r"tunisia.*\.(com|tn)",
]


def _is_tunisian_store_url(url: str) -> bool:
    if not url or "duckduckgo" in url:
        return False
    lower = url.lower()
    for pat in TUNISIA_STORE_PATTERNS:
        if re.search(pat, lower):
            return True
    return False


def search_tunisia_product(query: str, max_results: int = 10) -> list[dict]:
    """
    Search DuckDuckGo for "query Tunisia" and return list of {title, url, snippet}
    for results that look like Tunisian store product pages.
    """
    search_query = f"{query} acheter Tunisie"
    url = DDG_SEARCH.format(query=quote_plus(search_query))
    results = []

    try:
        resp = requests.get(url, headers=DEFAULT_HEADERS, timeout=REQUEST_TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as e:
        logger.warning("Search fallback failed: %s", e)
        return results

    soup = BeautifulSoup(resp.text, "lxml")
    for item in soup.select(".result"):
        link_el = item.select_one(".result__a")
        snippet_el = item.select_one(".result__snippet")
        if not link_el:
            continue
        href = link_el.get("href", "")
        if not _is_tunisian_store_url(href):
            continue
        title = link_el.get_text(strip=True)
        snippet = (snippet_el.get_text(strip=True) or "").strip() if snippet_el else ""
        results.append({"title": title, "url": href, "snippet": snippet})
        if len(results) >= max_results:
            break

    return results

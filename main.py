"""
CLI for the Tunisia product availability agent.
Usage:
  python main.py "iPhone 15"
  python main.py "Samsung Galaxy" --no-search
  python main.py "écran gaming" --json
"""

import argparse
import sys

from agent import run_agent, run_agent_json


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Search for product availability and prices in Tunisia (scrapes Tunisian e-commerce sites)."
    )
    parser.add_argument(
        "product",
        type=str,
        nargs="?",
        default=None,
        help="Product to search for (e.g. 'iPhone 15', 'Samsung Galaxy')",
    )
    parser.add_argument(
        "--no-search",
        action="store_true",
        help="Disable web search fallback; only scrape configured stores",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output full result as JSON",
    )
    parser.add_argument(
        "--category",
        type=str,
        default="auto",
        metavar="MODE",
        help="Store vertical: auto (infer from query), all, electronics, food, cosmetics, pharmacy",
    )
    args = parser.parse_args()

    query = args.product
    if not query and sys.stdin.isatty():
        query = input("Enter product to search in Tunisia: ").strip()
    if not query:
        print("Error: no product query provided.", file=sys.stderr)
        sys.exit(1)

    use_fallback = not args.no_search

    cat = (args.category or "auto").strip().lower()

    if args.json:
        print(run_agent_json(query, use_search_fallback=use_fallback, category=cat))
        return

    result = run_agent(query, use_search_fallback=use_fallback, category=cat)

    print("\n" + "=" * 60)
    print(f"  Tunisia product search: \"{result.query}\"")
    print("=" * 60)
    print(result.summary)
    if result.search_scope_note:
        print(f"  (scope: {result.search_scope_note})")
    if result.scope_widened:
        print("  (search widened to all stores after no results in category scope)")
    print()

    if result.products:
        print("--- Products (price & where to buy) ---")
        for i, p in enumerate(result.products, 1):
            price = p.get("price") or "Price N/A"
            store = p.get("store_name") or "Unknown store"
            title = (p.get("title") or "No title")[:70]
            url = p.get("url") or ""
            print(f"  {i}. {title}")
            tox = p.get("toxicity_label") or "—"
            tscore = p.get("toxicity_score")
            tscore_s = f"{tscore}" if tscore is not None else "—"
            print(f"     Price: {price}  |  Store: {store}")
            print(f"     Toxicity: {tox} ({tscore_s}/100)")
            if url:
                print(f"     Link: {url}")
            print()
    else:
        print("No products found from configured stores.")

    if result.search_links:
        print("--- Additional links (Tunisia) ---")
        for link in result.search_links:
            print(f"  • {link.get('title', '')}")
            print(f"    {link.get('url', '')}")
        print()

    print("Done.")


if __name__ == "__main__":
    main()

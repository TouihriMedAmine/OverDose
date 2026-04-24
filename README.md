# Tunisia Product Availability Agent

An agent that takes **any product** (electronics, food, cosmetics, pharmacy, etc.), searches Tunisian e-commerce sites, scrapes results, and returns **prices** and **where to buy** in Tunisia.

## Features

- **Any product type**: Tech (Mytek, Tunisianet, Wiki), grocery (Géant Drive), parapharmacie/cosmetics (Cosmedic, Coquette). Add more stores in `config.py`.
- **Query variants**: e.g. "yogurt" also searches "yaourt" so French-language sites return results.
- **Structured results**: Product title, price (with numeric value for sorting), store name, and product URL.
- **Optional web search**: Fallback search for "product Tunisia" to discover additional Tunisian store links.
- **CLI and Python API**: Use from the command line or import `run_agent` in your code.

## Setup

```bash
cd D:\9raya\Sem2\Deep\try
pip install -r requirements.txt
```

## Usage

### Web app (recommended)

```bash
python app.py
```

Then open **http://127.0.0.1:5000** in your browser. Enter a product name (e.g. iPhone, yogurt, crème), click Search, and see results with prices and store links.

### React + Django API (`frontend/` + `backend/`)

Use Vite on port 5173 with the Django backend on 8000 (see `frontend/` and `backend/`).

### Mobile app — Flutter / Dart (`mobile/`)

Dart client for the same API: register with health conditions, sign in, search. See **`mobile/README.md`**. After installing Flutter, run `flutter create .` inside `mobile/` if Android/iOS folders are missing, then `flutter pub get` and `flutter run`.

### Command line

```bash
# Search for a product (interactive prompt if no argument)
python main.py "iPhone 15"

# Search without web fallback (stores only)
python main.py "Samsung Galaxy" --no-search

# Get full JSON output
python main.py "écran gaming" --json
```

### Python API

```python
from agent import run_agent, run_agent_json

# Get structured result
result = run_agent("iPhone 15")
print(result.summary)
for p in result.products:
    print(p["title"], p["price"], p["store_name"], p["url"])

# Get JSON string
json_str = run_agent_json("Samsung Galaxy")
```

### Result shape

- **products**: list of `{ title, price, price_numeric, url, store_name, store_id }`
- **search_links**: list of `{ title, url, snippet }` from web search (if enabled)
- **summary**: short text summary (e.g. count by store)

## Configuration

Edit `config.py` to:

- Add or remove stores (each needs `name`, `base_url`, `search_url`, and CSS `selectors` for product card, title, price, link).
- Change `MAX_RESULTS_PER_STORE`, `REQUEST_TIMEOUT`, or headers.

## Notes

- Scraping depends on each site’s HTML structure; if a site changes its layout, update the selectors in `config.py`.
- Some sites may block or throttle automated requests (e.g. 403/404); the agent uses browser-like headers and continues with stores that respond. You can add or fix store URLs in `config.py`.
- Prices are in the stores’ displayed format (usually TND). `price_numeric` is extracted for sorting (cheapest first when available).
- Results are deduplicated by product URL.

"""
Verify LLM category routing (Groq or OpenAI-compatible).

Usage (from repo root):
  python scripts/check_llm_router.py
  python scripts/check_llm_router.py "wireless mouse"

Requires: GROQ_API_KEY or OPENAI_API_KEY in .env or environment.
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

# Repo root = parent of scripts/
ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

try:
    from dotenv import load_dotenv

    load_dotenv(ROOT / ".env")
except ImportError:
    pass


def main() -> None:
    from categories import resolve_stores_for_search
    from llm_category_router import infer_category_via_llm

    query = (sys.argv[1] if len(sys.argv) > 1 else "lban").strip()

    has_groq = bool((os.environ.get("GROQ_API_KEY") or "").strip())
    has_openai = bool((os.environ.get("OPENAI_API_KEY") or os.environ.get("LLM_ROUTER_API_KEY") or "").strip())
    disabled = (os.environ.get("LLM_ROUTER_DISABLE") or "").lower() in ("1", "true", "yes")

    print("--- LLM router check ---")
    print(f"LLM_ROUTER_DISABLE: {disabled}")
    print(f"GROQ_API_KEY set:     {has_groq}")
    print(f"OpenAI-style key set: {has_openai}")
    if has_groq:
        print(f"LLM_ROUTER_MODEL:   {os.environ.get('LLM_ROUTER_MODEL') or 'llama-3.1-8b-instant (default)'}")

    llm_out = infer_category_via_llm(query)
    print(f"\nQuery: {query!r}")
    print(f"infer_category_via_llm() -> {llm_out!r}")
    if llm_out is None:
        print("  (None means: no key, disabled, HTTP error, or bad response - see WARNING logs above)")

    stores, cats, note = resolve_stores_for_search("auto", query)
    print(f"\nFull resolve (auto mode):")
    print(f"  Scope note: {note}")
    print(f"  Categories applied: {cats}")
    print(f"  Store count in scope: {len(stores)}")

    if llm_out is not None:
        print("\nOK: LLM returned a category (router is calling the API successfully).")
    elif not has_groq and not has_openai:
        print("\nWARN: No API key — LLM is skipped. Set GROQ_API_KEY in .env")
    elif disabled:
        print("\nWARN: LLM_ROUTER_DISABLE is set — router is off.")
    else:
        print("\nFAIL or skipped: LLM returned None — fix key (401 = invalid key) or set LLM_ROUTER_JSON_MODE=0 if Groq rejects JSON mode.")


if __name__ == "__main__":
    main()

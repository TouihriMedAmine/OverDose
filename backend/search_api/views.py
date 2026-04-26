from dataclasses import asdict

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from agent import run_agent
from brand_learning.brand_extract import extract_brand_guess
from brand_learning.rl_update import apply_loyalty_ranking
from brand_learning.service import affinity_map_for_user, top_brands_for_user

# Import new endpoints
from .chat import ChatView
from .scan import ScanRecognitionView
from .analysis import AnalysisHistoryView


class ProductSearchView(APIView):
    """Runs the Tunisia product agent; optionally re-ranks by learned brand loyalty."""

    def post(self, request):
        q = (request.data.get("q") or "").strip()
        category = (request.data.get("category") or "auto").strip().lower()
        use_fallback = request.data.get("fallback", True)
        if isinstance(use_fallback, str):
            use_fallback = use_fallback.lower() in ("1", "true", "yes")

        use_loyalty = request.data.get("use_loyalty", True)
        if isinstance(use_loyalty, str):
            use_loyalty = use_loyalty.lower() in ("1", "true", "yes")

        if not q:
            return Response({"error": "Missing query field 'q'."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            result = run_agent(q, use_search_fallback=use_fallback, category=category)
            payload = asdict(result)

            payload["brand_loyalty"] = {
                "enabled": False,
                "favorite_brands": [],
            }

            user = request.user
            if user.is_authenticated:
                fav = top_brands_for_user(user, limit=6)
                payload["brand_loyalty"]["favorite_brands"] = fav
                if use_loyalty:
                    aff = affinity_map_for_user(user)
                    payload["products"] = apply_loyalty_ranking(
                        payload["products"],
                        aff,
                        extract_brand_guess,
                    )
                    payload["brand_loyalty"]["enabled"] = True
                else:
                    payload["brand_loyalty"]["enabled"] = False

            return Response(payload)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

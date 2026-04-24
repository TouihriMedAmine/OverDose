from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .service import record_product_click, top_brands_for_user


class ProductClickView(APIView):
    """
    Record a product click; infers brand from title and applies RL-style Q update.
    """

    def post(self, request):
        title = (request.data.get("title") or "").strip()
        if not title:
            return Response({"error": "Missing title."}, status=status.HTTP_400_BAD_REQUEST)
        brand = record_product_click(request.user, title)
        return Response({"ok": True, "brand_inferred": brand})


class FavoriteBrandsView(APIView):
    """Top brands by learned affinity for suggestions."""

    def get(self, request):
        limit = int(request.query_params.get("limit", 8))
        limit = max(1, min(limit, 30))
        return Response({"brands": top_brands_for_user(request.user, limit=limit)})

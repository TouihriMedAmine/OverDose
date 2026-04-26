from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView


class AnalysisHistoryView(APIView):
    """
    Get user's search and analysis history.
    GET: Retrieve all searches with timestamps and results summary.
    POST: Save new analysis entry.
    """

    def get(self, request):
        """
        Retrieve search history for the authenticated user.
        Query params:
          - limit: max number of records (default 20, max 100)
          - offset: pagination offset (default 0)
        """
        try:
            limit = int(request.query_params.get("limit", 20))
            offset = int(request.query_params.get("offset", 0))
            limit = max(1, min(limit, 100))

            user = request.user
            if not user.is_authenticated:
                return Response(
                    {"error": "Authentication required."},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

            # TODO: Query SearchHistory model or cache
            # For now, return placeholder data
            history = _get_mock_history(user, limit, offset)

            return Response({
                "total_searches": len(history),
                "offset": offset,
                "limit": limit,
                "history": history,
            })
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

    def post(self, request):
        """
        Save a new search/analysis entry.
        POST body:
          {
            "query": "insulin",
            "category": "medications",
            "result_count": 5,
            "results_summary": [{...}]
          }
        """
        try:
            query = (request.data.get("query") or "").strip()
            category = (request.data.get("category") or "").strip()
            result_count = request.data.get("result_count", 0)
            results = request.data.get("results_summary", [])

            if not query:
                return Response(
                    {"error": "Missing 'query' field."},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            user = request.user
            if not user.is_authenticated:
                return Response(
                    {"error": "Authentication required."},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

            # TODO: Save to SearchHistory model
            # For now, return placeholder
            return Response({
                "ok": True,
                "message": f"Search '{query}' saved to analysis history.",
                "query": query,
                "category": category,
                "result_count": result_count,
            })
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


def _get_mock_history(user, limit: int, offset: int) -> list:
    """
    TODO: Replace with actual database query.
    Returns mock search history for demonstration.
    """
    return [
        {
            "id": 1,
            "query": "insulin pen",
            "category": "medications",
            "result_count": 5,
            "timestamp": "2026-04-26T10:30:00Z",
            "top_result": "Insulin Pen Model X",
        },
        {
            "id": 2,
            "query": "diabetes test strips",
            "category": "medical-devices",
            "result_count": 12,
            "timestamp": "2026-04-26T09:15:00Z",
            "top_result": "FastCheck Test Strips",
        },
        {
            "id": 3,
            "query": "blood pressure monitor",
            "category": "medical-devices",
            "result_count": 8,
            "timestamp": "2026-04-26T08:00:00Z",
            "top_result": "Digital BP Monitor Pro",
        },
    ][offset : offset + limit]

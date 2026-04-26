from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView


class ChatView(APIView):
    """
    Chat endpoint for Q&A with LLM context.
    POST: Send message and get response based on search context.
    """

    def post(self, request):
        message = (request.data.get("message") or "").strip()
        last_query = (request.data.get("last_query") or "").strip()
        products = request.data.get("products", [])

        if not message:
            return Response(
                {"error": "Missing 'message' field."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # TODO: Integrate with LLM (GPT, Claude, Ollama, etc.)
            # For now, return placeholder response
            response_text = _generate_response(message, last_query, products)
            return Response({
                "user_message": message,
                "bot_response": response_text,
                "timestamp": None,
            })
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


def _generate_response(message: str, last_query: str, products: list) -> str:
    """
    Generate placeholder response based on message and context.
    TODO: Replace with actual LLM call.
    """
    msg_lower = message.lower()

    if any(word in msg_lower for word in ["best", "top", "recommend", "which"]):
        if products:
            top_product = products[0]
            name = top_product.get("name", "Unknown")
            price = top_product.get("price", "N/A")
            return f"Based on your search for '{last_query}', I'd recommend '{name}' at {price} TND. It's one of the top results and matches your criteria."
        return f"I'd recommend checking the top results for '{last_query}'. The first product looks promising!"

    if any(word in msg_lower for word in ["price", "cost", "how much", "afford"]):
        if products:
            prices = [p.get("price") for p in products if p.get("price")]
            if prices:
                avg_price = sum(prices) / len(prices)
                return f"For '{last_query}', prices typically range from {min(prices)} to {max(prices)} TND, averaging around {avg_price:.2f} TND."
        return f"I don't have specific pricing information. Try searching to see current prices for '{last_query}'."

    if any(word in msg_lower for word in ["available", "stock", "find", "where"]):
        if products:
            return f"I found {len(products)} results for '{last_query}'. You can check the products list to see availability and details."
        return "No results found. Try searching with different keywords."

    if any(word in msg_lower for word in ["health", "disease", "condition", "medical"]):
        return "For health-related concerns, please consult a healthcare professional. I can help you find products matching your health conditions!"

    # Default response
    return f"I'm here to help you find products! Based on your search for '{last_query}', I can recommend options or answer specific questions about price, availability, or features."

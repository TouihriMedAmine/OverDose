from django.urls import path

from .views import ProductSearchView, ChatView, ScanRecognitionView, AnalysisHistoryView

urlpatterns = [
    path("search/", ProductSearchView.as_view(), name="product-search"),
    path("chat/", ChatView.as_view(), name="chat"),
    path("scan/recognize/", ScanRecognitionView.as_view(), name="scan-recognize"),
    path("analysis/history/", AnalysisHistoryView.as_view(), name="analysis-history"),
]

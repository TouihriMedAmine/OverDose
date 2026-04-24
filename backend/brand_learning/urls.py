from django.urls import path

from .views import FavoriteBrandsView, ProductClickView

urlpatterns = [
    path("click/", ProductClickView.as_view(), name="brand-click"),
    path("favorite-brands/", FavoriteBrandsView.as_view(), name="favorite-brands"),
]

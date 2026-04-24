from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls")),
    path("api/learning/", include("brand_learning.urls")),
    path("api/", include("search_api.urls")),
]

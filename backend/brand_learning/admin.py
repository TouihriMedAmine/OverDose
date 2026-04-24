from django.contrib import admin

from .models import BrandAffinity


@admin.register(BrandAffinity)
class BrandAffinityAdmin(admin.ModelAdmin):
    list_display = ("user", "brand_key", "value", "click_count", "updated_at")
    list_filter = ("updated_at",)
    search_fields = ("brand_key", "user__username")

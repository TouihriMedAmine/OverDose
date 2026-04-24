from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ("Profile", {"fields": ("date_of_birth", "gender", "diseases")}),
    )
    list_display = ("username", "email", "gender", "date_of_birth", "is_staff")
    list_filter = ("gender", "is_staff")

from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    class Gender(models.TextChoices):
        MALE = "M", "Male"
        FEMALE = "F", "Female"

    email = models.EmailField(unique=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(
        max_length=1,
        choices=Gender.choices,
        blank=True,
        null=True,
    )
    diseases = models.TextField(
        blank=True,
        help_text="Chronic conditions, allergies, or relevant health notes (optional).",
    )

    REQUIRED_FIELDS = ["email"]

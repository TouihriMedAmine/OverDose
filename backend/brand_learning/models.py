from django.conf import settings
from django.db import models


class BrandAffinity(models.Model):
    """
    Per-user estimated preference for a brand (normalized key).
    `value` is updated with an exponential moving average (bandit-style Q update)
    when the user clicks a product whose title is parsed to that brand.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="brand_affinities",
    )
    brand_key = models.CharField(max_length=96, db_index=True)
    value = models.FloatField(default=0.0)
    click_count = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ("user", "brand_key")
        ordering = ("-value", "-updated_at")

    def __str__(self):
        return f"{self.user_id}:{self.brand_key}={self.value:.3f}"

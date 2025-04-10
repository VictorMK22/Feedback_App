from django.db import models
from users.models import CustomUser

# Create your models here.

class Report(models.Model):
    TYPES = [
        ('Daily', 'Daily'),
        ('Weekly', 'Weekly'),
        ('Monthly', 'Monthly'),
    ]

    admin = models.ForeignKey(CustomUser, on_delete=models.CASCADE, limit_choices_to={'role': 'Admin'})
    report_type = models.CharField(max_length=50, choices=TYPES)
    generated_at = models.DateTimeField(auto_now_add=True)
    resolved_feedback_count = models.IntegerField()
    pending_feedback_count = models.IntegerField()
    overall_satisfaction_score = models.FloatField()

    def __str__(self):
        return f"{self.report_type} Report by {self.admin.email}"
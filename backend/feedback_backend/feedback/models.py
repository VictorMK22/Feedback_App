from django.db import models
from users.models import CustomUser

# Create your models here.

class Feedback(models.Model):
    CATEGORIES = [
        ('Positive', 'Positive'),
        ('Negative', 'Negative'),
        ('Urgent', 'Urgent'),
    ]
    STATUSES = [
        ('Pending', 'Pending'),
        ('Resolved', 'Resolved'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, limit_choices_to={'role': 'Patient'})
    category = models.CharField(max_length=50, choices=CATEGORIES)
    content = models.TextField()
    status = models.CharField(max_length=50, choices=STATUSES, default='Pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Feedback by {self.user.username} - {self.category}"

class Response(models.Model):
    feedback = models.ForeignKey(Feedback, on_delete=models.CASCADE)
    admin = models.ForeignKey(CustomUser, on_delete=models.CASCADE, limit_choices_to={'role': 'Admin'})
    response_text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Response to {self.feedback.id} by {self.admin.username}"

class Notification(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    message = models.TextField()
    status = models.CharField(
        max_length=50,
        choices=[('Unread', 'Unread'), ('Read', 'Read')],
        default='Unread'
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.username} - {self.status}"
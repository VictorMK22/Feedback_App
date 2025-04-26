from django.db import models
from users.models import CustomUser
from django.core.files.storage import default_storage
import os
from datetime import datetime

class Feedback(models.Model):
    CATEGORIES = [
        ('Complaint', 'Complaint'),
        ('Suggestion', 'Suggestion'),
        ('Praise', 'Praise'),
    ]
    STATUSES = [
        ('Pending', 'Pending'),
        ('In Progress', 'In Progress'),
        ('Resolved', 'Resolved'),
    ]

    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE, related_name='feedbacks')
    category = models.CharField(max_length=50, choices=CATEGORIES)
    content = models.TextField()
    rating = models.FloatField(default=0)
    status = models.CharField(max_length=50, choices=STATUSES, default='Pending')
    attachments = models.JSONField(default=list, blank=True)  # Stores list of file paths
    created_at = models.DateTimeField(auto_now_add=True)

    def save_attachments(self, files):
        """Helper method to save attachments and update the model"""
        saved_files = []
        for file in files:
            # Generate unique filename
            file_ext = os.path.splitext(file.name)[1]
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"feedback_{self.id}_{timestamp}{file_ext}"
            
            # Save file to storage
            filepath = default_storage.save(f"feedback_attachments/{filename}", file)
            saved_files.append(filepath)
        
        self.attachments = saved_files
        self.save()

    def __str__(self):
        return f"Feedback #{self.id} by {self.user.username} ({self.category})"

class Response(models.Model):
    feedback = models.ForeignKey(Feedback, on_delete=models.CASCADE, related_name='responses')
    responder = models.ForeignKey(
        CustomUser,
        on_delete=models.CASCADE,
        related_name='responses',
        null=True,  # Temporary
        blank=True,  # Temporary
        limit_choices_to={'role__in': ['Admin', 'Staff']}
    )
    content = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        
class Notification(models.Model):
    user = models.ForeignKey(CustomUser, on_delete=models.CASCADE)
    message = models.TextField()
    feedback = models.ForeignKey('Feedback', on_delete=models.CASCADE, null=True, blank=True)
    status = models.CharField(
        max_length=50,
        choices=[('Unread', 'Unread'), ('Read', 'Read')],
        default='Unread'
    )
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Notification for {self.user.username} - {self.status}"
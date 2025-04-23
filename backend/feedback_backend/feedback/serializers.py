from rest_framework import serializers
from .models import Feedback, Response, Notification

class ResponseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Response
        fields = ['id', 'feedback', 'admin', 'response_text', 'created_at']

class FeedbackSerializer(serializers.ModelSerializer):
    responses = ResponseSerializer(many=True, read_only=True)  # Nesting responses under feedback

    class Meta:
        model = Feedback
        fields = ['id', 'user', 'category', 'content', 'status', 'created_at', 'responses']  # Include nested responses

class NotificationSerializer(serializers.ModelSerializer):
    feedback = FeedbackSerializer(read_only=True)  # Optional: Link to feedback data

    class Meta:
        model = Notification
        fields = ['id', 'user', 'message', 'status', 'timestamp', 'feedback']  # Include feedback reference
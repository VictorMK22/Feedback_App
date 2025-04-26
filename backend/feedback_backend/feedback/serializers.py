from rest_framework import serializers
from .models import Feedback, Response, Notification
from django.urls import reverse

class ResponseSerializer(serializers.ModelSerializer):
    responder = serializers.SerializerMethodField()

    class Meta:
        model = Response
        fields = ['id', 'responder', 'content', 'created_at']
        read_only_fields = ['responder', 'created_at']

    def get_responder(self, obj):
        return {
            'id': obj.responder.id,
            'username': obj.responder.username,
            'role': obj.responder.role
        }

class FeedbackSerializer(serializers.ModelSerializer):
    responses = ResponseSerializer(many=True, read_only=True)
    attachments = serializers.SerializerMethodField()
    user = serializers.SerializerMethodField()
    feedback_text = serializers.CharField(source='content', required=True)
    
    class Meta:
        model = Feedback
        fields = [
            'id',
            'user',
            'category',
            'feedback_text',
            'rating',
            'status',
            'attachments',
            'created_at',
            'responses'
        ]
        read_only_fields = ['user', 'status', 'created_at', 'responses']

    def get_user(self, obj):
        return {
            'id': obj.user.id,
            'username': obj.user.username,
            'email': obj.user.email
        }

    def get_attachments(self, obj):
        request = self.context.get('request')
        if obj.attachments:
            return [request.build_absolute_uri(attachment) for attachment in obj.attachments]
        return []

    def validate_rating(self, value):
        if value < 0 or value > 5:
            raise serializers.ValidationError("Rating must be between 0 and 5")
        return value

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)
    
class NotificationSerializer(serializers.ModelSerializer):
    feedback = FeedbackSerializer(read_only=True)  # Optional: Link to feedback data

    class Meta:
        model = Notification
        fields = ['id', 'user', 'message', 'status', 'timestamp', 'feedback']  # Include feedback reference
from rest_framework import serializers
from .models import Report

class ReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = Report
        fields = ['id', 'admin', 'report_type', 'generated_at', 'resolved_feedback_count', 'pending_feedback_count', 'overall_satisfaction_score']
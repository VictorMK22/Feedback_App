from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Feedback, Notification, Response as FeedbackResponse
from .serializers import FeedbackSerializer, ResponseSerializer, NotificationSerializer
from rest_framework.pagination import PageNumberPagination
import os
from datetime import datetime
from django.core.files.storage import default_storage
from django.db.models import Prefetch
from django.shortcuts import get_object_or_404

# Import LibreTranslate service
from feedback_backend.services.libre_translator import translate_with_libre


class TranslateTextView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        text = request.GET.get("text", "")
        target = request.GET.get("lang") or getattr(request.user, 'preferred_language', 'en')
        source = request.GET.get("source", "en")

        if not text:
            return Response({"error": "Missing 'text' parameter"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            translated = translate_with_libre(text, target, source)
            return Response({"translated": translated}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class HomeDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            username = request.user.username
            profile_image_url = None
            if hasattr(request.user, 'profile') and request.user.profile.profile_picture:
                profile_image_url = request.build_absolute_uri(request.user.profile.profile_picture.url)

            paginator = PageNumberPagination()
            paginator.page_size = 10

            # Prefetch related responses to optimize queries
            feedbacks = Feedback.objects.filter(
                user=request.user if request.user.role == 'Patient' else None
            ).order_by('-created_at').prefetch_related(
                Prefetch('responses', queryset=FeedbackResponse.objects.order_by('created_at'))
            )

            paginated_feedbacks = paginator.paginate_queryset(feedbacks, request)

            feedback_data = []
            for feedback in paginated_feedbacks:
                feedback_data.append({
                    "feedback": FeedbackSerializer(feedback).data,
                    "responses": ResponseSerializer(feedback.responses.all(), many=True).data,
                })

            notifications = Notification.objects.filter(user=request.user).order_by('-timestamp')[:10]
            notification_serializer = NotificationSerializer(notifications, many=True)

            data = {
                "username": username,
                "profile_image_url": profile_image_url,
                "feedback": feedback_data,
                "notifications": notification_serializer.data,
            }

            return Response(data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class FeedbackCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            if request.user.role != 'Patient':
                return Response({"error": "Only patients can submit feedback!"}, status=status.HTTP_403_FORBIDDEN)

            # Process the request data to match frontend format
            data = {
                'feedback_text': request.data.get('feedback_text'),
                'rating': float(request.data.get('rating', 0)),
                'category': request.data.get('category', 'General'),
                'user': request.user.id
            }

            serializer = FeedbackSerializer(data=data)
            
            if serializer.is_valid():
                feedback = serializer.save()
                
                # Handle file attachments
                if 'attachments' in request.FILES:
                    attachments = request.FILES.getlist('attachments')
                    saved_files = []
                    
                    for file in attachments:
                        # Generate unique filename
                        file_ext = os.path.splitext(file.name)[1]
                        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                        filename = f"feedback_{feedback.id}_{timestamp}{file_ext}"
                        
                        # Save file to storage
                        filepath = default_storage.save(f"feedback_attachments/{filename}", file)
                        saved_files.append(request.build_absolute_uri(filepath))
                    
                    # Update feedback with attachments URLs
                    feedback.attachments = saved_files
                    feedback.save()
                
                # Create notifications for all admins
                admins = CustomUser.objects.filter(role='Admin')
                for admin in admins:
                    Notification.objects.create(
                        user=admin,
                        message=f"New feedback submitted by {request.user.username}",
                        feedback=feedback
                    )
                
                response_data = {
                    "message": "Feedback submitted successfully!",
                    "data": FeedbackSerializer(feedback).data
                }
                return Response(response_data, status=status.HTTP_201_CREATED)
            
            return Response({"error": serializer.errors}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class FeedbackListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            if request.user.role == 'Patient':
                feedbacks = Feedback.objects.filter(user=request.user).order_by('-created_at')
            else:
                feedbacks = Feedback.objects.all().order_by('-created_at')

            serializer = FeedbackSerializer(feedbacks, many=True)
            
            # Format response to include full URLs for attachments
            data = []
            for feedback in serializer.data:
                feedback_data = dict(feedback)
                if feedback_data['attachments']:
                    feedback_data['attachments'] = [
                        request.build_absolute_uri(attachment) 
                        for attachment in feedback_data['attachments']
                    ]
                data.append(feedback_data)
                
            return Response(data, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Create Response (Only Admins)
class ResponseCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'Admin':
            return Response({"error": "Only admins can respond to feedback!"}, status=status.HTTP_403_FORBIDDEN)

        serializer = ResponseSerializer(data=request.data)
        if serializer.is_valid():
            response = serializer.save(admin=request.user)
            
            # Create notification for the patient who submitted the feedback
            feedback = response.feedback
            Notification.objects.create(
                user=feedback.user,
                message=f"Admin has responded to your feedback",
                feedback=feedback
            )
            
            return Response({"message": "Response created successfully!", "data": serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ResponseListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        # Only admins can view all responses
        if request.user.role != 'Admin':
            return Response(
                {"error": "Only admins can view all responses!"},
                status=status.HTTP_403_FORBIDDEN
            )

        responses = FeedbackResponse.objects.all()  # Replace 'ResponseModel' with your actual model name
        serializer = ResponseSerializer(responses, many=True)

        return Response({"data": serializer.data}, status=status.HTTP_200_OK)


# List Notifications
class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        notifications = Notification.objects.filter(user=request.user).order_by('-timestamp')
        
        paginator = PageNumberPagination()
        paginator.page_size = 20  # Number of notifications per page
        paginated_notifications = paginator.paginate_queryset(notifications, request)
        
        serializer = NotificationSerializer(paginated_notifications, many=True)
        return paginator.get_paginated_response(serializer.data)


# Update Notification Status
class MarkNotificationAsReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        notification = get_object_or_404(Notification, pk=pk, user=request.user)
        notification.status = 'Read'
        notification.save()
        return Response({"message": "Notification marked as read"}, status=status.HTTP_200_OK)
    


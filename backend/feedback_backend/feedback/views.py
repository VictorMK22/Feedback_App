from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Feedback, Notification, Response as FeedbackResponse
from .serializers import FeedbackSerializer, ResponseSerializer, NotificationSerializer
from rest_framework.pagination import PageNumberPagination

# Import LibreTranslate service
from feedback_backend.services.libre_translator import translate_with_libre


# Translate text using LibreTranslate
class TranslateTextView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        text = request.GET.get("text", "")
        target = request.GET.get("lang") or request.user.preferred_language
        source = request.GET.get("source", "en")

        if not text:
            return Response({"error": "Missing 'text' parameter"}, status=status.HTTP_400_BAD_REQUEST)

        translated = translate_with_libre(text, target, source)
        return Response({"translated": translated}, status=status.HTTP_200_OK)


# Home Dashboard View
class HomeDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        username = request.user.username
        profile_image_url = request.user.profile.profile_picture.url if hasattr(request.user, 'profile') and request.user.profile.profile_picture else None

        paginator = PageNumberPagination()
        paginator.page_size = 10

        if request.user.role == 'Patient':
            feedbacks = Feedback.objects.filter(user=request.user).order_by('-created_at')
        else:
            feedbacks = Feedback.objects.all().order_by('-created_at')

        paginated_feedbacks = paginator.paginate_queryset(feedbacks, request)

        feedback_data = []
        for feedback in paginated_feedbacks:
            responses = FeedbackResponse.objects.filter(feedback=feedback)
            response_serializer = ResponseSerializer(responses, many=True)

            feedback_data.append({
                "feedback": FeedbackSerializer(feedback).data,
                "responses": response_serializer.data,
            })

        notifications = Notification.objects.filter(user=request.user).order_by('-timestamp')
        notification_serializer = NotificationSerializer(notifications, many=True)

        data = {
            "username": username,
            "profile_image_url": profile_image_url,
            "feedback": feedback_data,
            "notifications": notification_serializer.data,
        }

        return Response(data, status=status.HTTP_200_OK)


# Create Feedback (Only Patients)
class FeedbackCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'Patient':
            return Response({"error": "Only patients can submit feedback!"}, status=status.HTTP_403_FORBIDDEN)

        serializer = FeedbackSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response({"message": "Feedback submitted successfully!", "data": serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# List Feedback (All Roles)
class FeedbackListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role == 'Patient':
            feedbacks = Feedback.objects.filter(user=request.user)
        else:
            feedbacks = Feedback.objects.all()

        serializer = FeedbackSerializer(feedbacks, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# Create Response (Only Admins)
class ResponseCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'Admin':
            return Response({"error": "Only admins can respond to feedback!"}, status=status.HTTP_403_FORBIDDEN)

        serializer = ResponseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(admin=request.user)
            return Response({"message": "Response created successfully!", "data": serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# List Notifications
class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(user=request.user).order_by('-timestamp')
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# Update Notification Status
class NotificationUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request, pk):
        try:
            notification = Notification.objects.get(pk=pk, user=request.user)
        except Notification.DoesNotExist:
            return Response({"error": "Notification not found!"}, status=status.HTTP_404_NOT_FOUND)

        serializer = NotificationSerializer(notification, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Notification updated successfully!", "data": serializer.data}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    


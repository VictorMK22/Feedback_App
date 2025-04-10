from django.http import HttpResponse
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import Feedback, Response, Notification
from .serializers import FeedbackSerializer, ResponseSerializer, NotificationSerializer

# Create your views here.

def home(request):
    return HttpResponse("<h1>Welcome to the Feedback App</h1>")

# Create Feedback (Only Patients)
class FeedbackCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'Patient':  # Ensure only patients can submit feedback
            return Response({"error": "Only patients can submit feedback!"}, status=status.HTTP_403_FORBIDDEN)

        serializer = FeedbackSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user)  # Attach the logged-in user to the feedback
            return Response({"message": "Feedback submitted successfully!", "data": serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Retrieve Feedback (Authenticated Users)
class FeedbackListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role == 'Patient':  # Patients see their own feedback
            feedbacks = Feedback.objects.filter(user=request.user)
        else:  # Admins see all feedbacks
            feedbacks = Feedback.objects.all()

        serializer = FeedbackSerializer(feedbacks, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# Create Response (Only Admins)
class ResponseCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'Admin':  # Ensure only admins can respond to feedback
            return Response({"error": "Only admins can respond to feedback!"}, status=status.HTTP_403_FORBIDDEN)

        serializer = ResponseSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(admin=request.user)  # Attach the logged-in user as the responding admin
            return Response({"message": "Response created successfully!", "data": serializer.data}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# List Notifications (Authenticated Users)
class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notifications = Notification.objects.filter(user=request.user).order_by('-timestamp')
        serializer = NotificationSerializer(notifications, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


# Update Notification Status (Authenticated Users)
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
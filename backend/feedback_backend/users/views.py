from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.mail import send_mail
from django.contrib.auth import authenticate
import logging
from .models import CustomUser
from .serializers import CustomUserSerializer, ProfileSerializer

# Initialize logger
logger = logging.getLogger(__name__)

# User Registration
class RegisterView(APIView):
    def post(self, request):
        serializer = CustomUserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            # Optional: Send welcome email
            try:
                send_mail(
                    subject="Welcome to the Platform!",
                    message="Thank you for registering with us. We are excited to have you!",
                    from_email="admin@yourdomain.com",
                    recipient_list=[user.email],
                )
            except Exception as e:
                logger.error(f"Failed to send welcome email: {e}")
            return Response({"message": "User registered successfully!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# User Login


class LoginView(APIView):
    def post(self, request):
        login_identifier = request.data.get('login')  # Accept username or email
        password = request.data.get('password')
        user = authenticate(username=login_identifier, password=password)  # Use the custom backend

        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            }, status=status.HTTP_200_OK)
        return Response({"error": "Invalid email or username"}, status=status.HTTP_401_UNAUTHORIZED)

# User Profile Retrieval
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = user.profile  # Assuming a OneToOneField relationship
        user_serializer = CustomUserSerializer(user)
        profile_serializer = ProfileSerializer(profile)
        return Response({
            "user": user_serializer.data,
            "profile": profile_serializer.data,
        })

# User Profile Update
class ProfileUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        profile = request.user.profile
        serializer = ProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            # Optional validation: Prevent unverified users from updating sensitive fields
            if 'email' in serializer.validated_data and not request.user.is_verified:
                return Response({"error": "Email change is not allowed for unverified users!"}, status=status.HTTP_403_FORBIDDEN)
            serializer.save()
            return Response({"message": "Profile updated successfully!"})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
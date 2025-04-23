from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.core.mail import send_mail
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

            # Send welcome email (optional, with error handling)
            try:
                send_mail(
                    subject="Welcome to the Feedback App!",
                    message="Thanks for joining! We're excited to have you onboard.",
                    from_email="noreply@gmail.com",
                    recipient_list=[user.email],
                )
            except Exception as e:
                logger.error(f"Failed to send welcome email: {e}")

            return Response({"message": "User registered successfully!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# User Login

class LoginView(APIView):
    def post(self, request):
        login_identifier = request.data.get('username_or_email')
        password = request.data.get('password')
        print(login_identifier, password)

        if not login_identifier or not password:
            return Response(
                {"error": "Both username/email and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Authenticate user using the custom backend
        user = authenticate(username=login_identifier, password=password)
        if user:
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'email': user.email,
                'role': user.role,
                'username': user.username,
            }, status=status.HTTP_200_OK)

        return Response(
            {"error": "Invalid email/username or password."},
            status=status.HTTP_401_UNAUTHORIZED,
        )

# Password Reset View
class ResetPasswordView(APIView):
    def post(self, request):
        email = request.data.get('email')
        try:
            user = CustomUser.objects.get(email=email)
            # Send reset link logic
            send_mail(
                subject='Password Reset Request',
                message='Click the link below to reset your password.',
                from_email='noreply@gmail.com',
                recipient_list=[email],
            )
            return Response({'message': 'Password reset link sent.'}, status=status.HTTP_200_OK)
        except CustomUser.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)


# User Profile Retrieval
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = user.profile
        user_serializer = CustomUserSerializer(user)
        profile_serializer = ProfileSerializer(profile)
        return Response({
            "user": user_serializer.data,
            "profile": profile_serializer.data,
        }, status=status.HTTP_200_OK)


# User Profile Update
class ProfileUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        user = request.user
        profile = user.profile

        # Update profile fields (profile_picture, bio)
        profile_serializer = ProfileSerializer(profile, data=request.data, partial=True)

        # Update user fields (preferred_language, etc.)
        user_serializer = CustomUserSerializer(user, data=request.data, partial=True)

        if profile_serializer.is_valid() and user_serializer.is_valid():
            if 'email' in user_serializer.validated_data and not user.is_verified:
                return Response(
                    {"error": "Email change is not allowed for unverified users."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            profile_serializer.save()
            user_serializer.save()

            return Response({
                "message": "Profile updated successfully!",
                "user": user_serializer.data,
                "profile": profile_serializer.data,
            }, status=status.HTTP_200_OK)

        return Response({
            "user_errors": user_serializer.errors,
            "profile_errors": profile_serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

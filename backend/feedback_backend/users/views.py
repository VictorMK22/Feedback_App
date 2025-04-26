from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.core.exceptions import ObjectDoesNotExist
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from rest_framework.parsers import MultiPartParser, FormParser
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
@method_decorator(csrf_exempt, name='dispatch')
class ProfileUpdateView(APIView):
    permission_classes = [IsAuthenticated]

    def put(self, request):
        logger.info(f"Authenticated User: {request.user}, Authenticated: {request.user.is_authenticated}")

        # Check if the user is authenticated
        if not request.user.is_authenticated:
            return Response(
                {"error": "Authentication credentials were not provided."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        user = request.user

        # Check if Profile exists for the user
        try:
            profile = user.profile
        except ObjectDoesNotExist:
            logger.error(f"Profile not found for user: {user}")
            return Response(
                {"error": "Profile does not exist for the user."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Handle profile picture upload if it exists in the request
        if request.FILES and 'profile_picture' in request.FILES:
            try:
                profile.profile_picture = request.FILES['profile_picture']
                profile.save()
                return Response({
                    "message": "Profile picture updated successfully!",
                }, status=status.HTTP_200_OK)
            except Exception as e:
                logger.error(f"Error updating profile picture: {e}")
                return Response({
                    "error": f"Failed to update profile picture: {str(e)}"
                }, status=status.HTTP_400_BAD_REQUEST)

        # Handle regular profile data updates
        profile_serializer = ProfileSerializer(profile, data=request.data, partial=True)
        user_serializer = CustomUserSerializer(user, data=request.data, partial=True)

        if profile_serializer.is_valid() and user_serializer.is_valid():
            # Optional: Prevent email updates for unverified users
            if hasattr(user, 'is_verified') and 'email' in user_serializer.validated_data and not user.is_verified:
                return Response(
                    {"error": "Email change is not allowed for unverified users."},
                    status=status.HTTP_403_FORBIDDEN,
                )

            # Save valid changes
            profile_serializer.save()
            user_serializer.save()
            return Response({
                "message": "Profile updated successfully!",
                "user": user_serializer.data,
                "profile": profile_serializer.data,
            }, status=status.HTTP_200_OK)

        # Log errors
        logger.error(f"Validation errors - User: {user_serializer.errors}, Profile: {profile_serializer.errors}")
        return Response({
            "user_errors": user_serializer.errors,
            "profile_errors": profile_serializer.errors,
        }, status=status.HTTP_400_BAD_REQUEST)
    
    # Add support for PATCH requests as well
    def patch(self, request):
        return self.put(request)
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
import requests
from .models import CustomUser, Profile
from .serializers import (
    CustomUserSerializer,
    ProfileSerializer,
    FacebookAuthSerializer,
    GoogleAuthSerializer,
    UserAuthResponseSerializer
)
from django.conf import settings
from rest_framework.exceptions import AuthenticationFailed

logger = logging.getLogger(__name__)

class RegisterView(APIView):
    def post(self, request):
        serializer = CustomUserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()

            try:
                send_mail(
                    subject="Welcome to our App!",
                    message="Thanks for joining!",
                    from_email="noreply@example.com",
                    recipient_list=[user.email],
                )
            except Exception as e:
                logger.error(f"Failed to send welcome email: {e}")

            return Response({"message": "User registered successfully!"}, 
                          status=status.HTTP_201_CREATED)
        return Response(serializer.errors, 
                      status=status.HTTP_400_BAD_REQUEST)

class FacebookLoginView(APIView):
    def post(self, request):
        serializer = FacebookAuthSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        fb_data = serializer.validated_data
        email = fb_data.get('email')
        facebook_id = fb_data.get('id')
        
        if not email:
            return Response(
                {"error": "Email permission is required"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user, created = self._get_or_create_user(
                email=email,
                facebook_id=facebook_id,
                first_name=fb_data.get('first_name', ''),
                last_name=fb_data.get('last_name', '')
            )

            refresh = RefreshToken.for_user(user)
            response_data = self._build_response_data(user, refresh, created)
            
            return Response(response_data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Facebook login error: {str(e)}", exc_info=True)
            return Response(
                {"error": "Facebook authentication failed"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _get_or_create_user(self, email, facebook_id, first_name, last_name):
        try:
            user = CustomUser.objects.get(facebook_id=facebook_id)
            return user, False
        except CustomUser.DoesNotExist:
            try:
                user = CustomUser.objects.get(email=email)
                user.facebook_id = facebook_id
                user.auth_provider = 'facebook'
                user.save()
                return user, False
            except CustomUser.DoesNotExist:
                username = email.split('@')[0]
                while CustomUser.objects.filter(username=username).exists():
                    username = f"{username}_{CustomUser.objects.filter(username__startswith=username).count()}"
                
                user = CustomUser.objects.create(
                    email=email,
                    username=username,
                    first_name=first_name,
                    last_name=last_name,
                    facebook_id=facebook_id,
                    auth_provider='facebook',
                    is_verified=True
                )
                Profile.objects.create(user=user)
                return user, True

    def _build_response_data(self, user, refresh, created):
        return {
            'user': UserAuthResponseSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_new_user': created
        }

class GoogleLoginView(APIView):
    def post(self, request):
        serializer = GoogleAuthSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        google_data = serializer.validated_data
        email = google_data['email']
        google_id = google_data['google_id']

        try:
            user, created = self._get_or_create_user(
                email=email,
                google_id=google_id,
                first_name=google_data.get('first_name', ''),
                last_name=google_data.get('last_name', '')
            )

            refresh = RefreshToken.for_user(user)
            response_data = self._build_response_data(user, refresh, created)
            
            return Response(response_data, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Google login error: {str(e)}", exc_info=True)
            return Response(
                {"error": "Google authentication failed"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def _get_or_create_user(self, email, google_id, first_name, last_name):
        try:
            user = CustomUser.objects.get(google_id=google_id)
            return user, False
        except CustomUser.DoesNotExist:
            try:
                user = CustomUser.objects.get(email=email)
                user.google_id = google_id
                user.auth_provider = 'google'
                user.save()
                return user, False
            except CustomUser.DoesNotExist:
                username = email.split('@')[0]
                while CustomUser.objects.filter(username=username).exists():
                    username = f"{username}_{CustomUser.objects.filter(username__startswith=username).count()}"
                
                user = CustomUser.objects.create(
                    email=email,
                    username=username,
                    first_name=first_name,
                    last_name=last_name,
                    google_id=google_id,
                    auth_provider='google',
                    is_verified=True
                )
                Profile.objects.create(user=user)
                return user, True

    def _build_response_data(self, user, refresh, created):
        return {
            'user': UserAuthResponseSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'is_new_user': created
        }

# Username_Email Login View
class LoginView(APIView):
    def post(self, request):
        login_identifier = request.data.get('username_or_email')
        password = request.data.get('password')

        if not login_identifier or not password:
            return Response(
                {"error": "Both username/email and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

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


class ResetPasswordView(APIView):
    def post(self, request):
        email = request.data.get('email')
        try:
            user = CustomUser.objects.get(email=email)
            send_mail(
                subject='Password Reset Request',
                message='Click the link below to reset your password.',
                from_email='meli.victorkip17@gmail.com',
                recipient_list=[email],
            )
            return Response({'message': 'Password reset link sent.'}, 
                           status=status.HTTP_200_OK)
        except CustomUser.DoesNotExist:
            return Response({'error': 'User not found.'}, 
                           status=status.HTTP_404_NOT_FOUND)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = user.profile
        return Response({
            "user": CustomUserSerializer(user).data,
            "profile": ProfileSerializer(profile).data,
        }, status=status.HTTP_200_OK)


@method_decorator(csrf_exempt, name='dispatch')
class ProfileUpdateView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def put(self, request):
        user = request.user
        try:
            profile = user.profile
        except ObjectDoesNotExist:
            return Response(
                {"error": "Profile does not exist for the user."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Handle profile picture upload
        if 'profile_picture' in request.FILES:
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

        # Handle other profile updates
        profile_serializer = ProfileSerializer(profile, data=request.data, partial=True)
        user_serializer = CustomUserSerializer(user, data=request.data, partial=True)

        if profile_serializer.is_valid() and user_serializer.is_valid():
            profile_serializer.save()
            user_serializer.save()
            return Response({
                "message": "Profile updated successfully!",
                "user": user_serializer.data,
                "profile": profile_serializer.data,
            }, status=status.HTTP_200_OK)

        return Response({
            "user_errors": user_serializer.errors,
            "profile_errors": profile_serializer.errors,
        }, status=status.HTTP_400_BAD_REQUEST)

    def patch(self, request):
        return self.put(request)
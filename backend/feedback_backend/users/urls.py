from django.urls import path
from .views import (
    RegisterView,
    FacebookLoginView, 
    GoogleLoginView,
    LoginView, 
    ProfileView, 
    ProfileUpdateView, 
    ResetPasswordView
)
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView, TokenVerifyView

app_name = "users"
urlpatterns = [
    # Existing endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('auth/facebook/', FacebookLoginView.as_view(), name='facebook_login'),
    path('auth/google/', GoogleLoginView.as_view(), name='google-auth'),
    path('login/', LoginView.as_view(), name='login'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    path('profile/', ProfileView.as_view(), name='profile'),
    path('profile/update/', ProfileUpdateView.as_view(), name='profile_update'),

    # Token authentication endpoints
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
]
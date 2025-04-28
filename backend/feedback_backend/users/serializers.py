from rest_framework import serializers
from .models import CustomUser, Profile
from django.contrib.auth.hashers import make_password
import requests
from django.conf import settings
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

class ProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = Profile
        fields = ['phone_number', 'notification_preference', 'profile_picture', 'bio', 'date_of_birth']
        extra_kwargs = {
            'profile_picture': {'required': False},
            'bio': {'required': False, 'allow_blank': True},
            'date_of_birth': {'required': False}
        }

class CustomUserSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)
    
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'password', 'role', 'preferred_language', 
                 'auth_provider', 'is_verified', 'profile']
        extra_kwargs = {
            'password': {'write_only': True},
            'auth_provider': {'read_only': True},
            'is_verified': {'read_only': True},
        }

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            username=validated_data.get('username', validated_data['email'].split('@')[0]),
            password=password,
            role=validated_data.get('role', 'Patient'),
            preferred_language=validated_data.get('preferred_language', 'en'),
        )
        return user

    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters.")
        return value

class FacebookAuthSerializer(serializers.Serializer):
    access_token = serializers.CharField()
    
    def validate_access_token(self, value):
        try:
            response = requests.get(
                f'https://graph.facebook.com/v12.0/me?fields=id,email,first_name,last_name&access_token={value}'
            )
            data = response.json()
            
            if 'error' in data:
                raise serializers.ValidationError("Invalid Facebook access token")
                
            return data
        except requests.RequestException:
            raise serializers.ValidationError("Error verifying Facebook token")

class GoogleAuthSerializer(serializers.Serializer):
    access_token = serializers.CharField()
    id_token = serializers.CharField()
    
    def validate(self, attrs):
        try:
            id_info = id_token.verify_oauth2_token(
                attrs['id_token'],
                google_requests.Request(),
                settings.SOCIAL_AUTH_GOOGLE_OAUTH2_KEY
            )
            
            if id_info['iss'] not in ['accounts.google.com', 'https://accounts.google.com']:
                raise serializers.ValidationError("Invalid token issuer")
                
            if id_info['aud'] != settings.SOCIAL_AUTH_GOOGLE_OAUTH2_KEY:
                raise serializers.ValidationError("Invalid client ID")

            return {
                'email': id_info.get('email'),
                'google_id': id_info.get('sub'),
                'first_name': id_info.get('given_name', ''),
                'last_name': id_info.get('family_name', ''),
                'access_token': attrs['access_token'],
                'id_token': attrs['id_token']
            }
        except ValueError as e:
            raise serializers.ValidationError(str(e))
        except Exception as e:
            raise serializers.ValidationError("Google authentication failed")

class UserResponseSerializer(serializers.ModelSerializer):
    profile = ProfileSerializer(read_only=True)
    access_token = serializers.CharField(read_only=True)
    refresh_token = serializers.CharField(read_only=True)

    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'role', 'preferred_language', 
                 'auth_provider', 'is_verified', 'profile', 'access_token', 'refresh_token']

class UserAuthResponseSerializer(UserResponseSerializer):
    is_new_user = serializers.BooleanField(read_only=True)
    
    class Meta(UserResponseSerializer.Meta):
        fields = UserResponseSerializer.Meta.fields + ['is_new_user']
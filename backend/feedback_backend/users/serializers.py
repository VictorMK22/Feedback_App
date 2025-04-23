from rest_framework import serializers
from .models import CustomUser, Profile
from django.contrib.auth.hashers import make_password

class CustomUserSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['id', 'username', 'email', 'password', 'role', 'preferred_language']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        password = validated_data.pop('password')
        # Creating user with password hashing
        user = CustomUser.objects.create_user(
            email=validated_data['email'],
            username=validated_data.get('username', ''),  # Keep username optional
            password=password,
            role=validated_data.get('role', 'Patient'),  # Default role is Patient
        )
        return user

    def validate_password(self, value):
        # Add any password validation rules here (e.g., length, complexity)
        if len(value) < 8:
            raise serializers.ValidationError("Password must be at least 8 characters.")
        return value

class ProfileSerializer(serializers.ModelSerializer):
    profile_picture = serializers.ImageField(required=False)  # Ensure it's optional
    bio = serializers.CharField(required=False, allow_blank=True)  # Bio can be optional or blank

    class Meta:
        model = Profile
        fields = ['profile_picture', 'bio']

    def update(self, instance, validated_data):
        # Handle profile picture (if provided)
        profile_picture = validated_data.get('profile_picture', None)
        if profile_picture:
            instance.profile_picture = profile_picture
        
        # Handle bio (if provided)
        bio = validated_data.get('bio', None)
        if bio is not None:
            instance.bio = bio

        # Save the updated instance
        instance.save()
        return instance

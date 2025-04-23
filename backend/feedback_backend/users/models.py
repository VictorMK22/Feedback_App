from django.contrib.auth.models import AbstractUser
from django.contrib.auth.models import BaseUserManager
from django.db import models

# Create your models here.
class CustomUserManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError('Users must have an email address')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'Admin')  

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, username, password, **extra_fields)
    
class CustomUser(AbstractUser):
    ROLES = [
        ('Patient', 'Patient'),
        ('Admin', 'Admin'),
    ]
    role = models.CharField(max_length=10, choices=ROLES, default='Patient')
    preferred_language = models.CharField(
        max_length=10,
        default='en',
        help_text="User's preferred language (ISO 639-1 code, e.g., 'en', 'sw', 'fr')"
    )
    email = models.EmailField(unique=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = CustomUserManager()  # Link your custom manager here

    def __str__(self):
        return self.username

class Profile(models.Model):
    NOTIFICATION_PREFERENCES = [
        ('SMS', 'SMS'),
        ('Email', 'Email'),
        ('Both', 'Both'),
    ]

    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE)
    phone_number = models.CharField(max_length=15, blank=True, null=True)
    notification_preference = models.CharField(
        max_length=10,        
        choices=NOTIFICATION_PREFERENCES,
        default='Both'
    )
    profile_picture = models.ImageField(upload_to='profile_pictures/', blank=True, null=True)
    bio = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.user.username}'s Profile"

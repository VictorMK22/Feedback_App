from django.contrib.auth.models import AbstractUser
from django.db import models

# Create your models here.

class CustomUser(AbstractUser):
    ROLES = [
        ('Patient', 'Patient'),
        ('Admin', 'Admin'),
    ]
    role = models.CharField(max_length=10, choices=ROLES, default='Patient')
    email = models.EmailField(unique=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

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

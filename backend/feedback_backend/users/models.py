from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.utils.translation import gettext_lazy as _

class CustomUserManager(BaseUserManager):
    def create_user(self, email, username, password=None, **extra_fields):
        if not email:
            raise ValueError('Users must have an email address')
        email = self.normalize_email(email)
        user = self.model(email=email, username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_social_user(self, email, username, auth_provider, **extra_fields):
        if not email:
            raise ValueError('Social auth users must have an email address')
        email = self.normalize_email(email)
        user = self.model(
            email=email,
            username=username,
            auth_provider=auth_provider,
            is_verified=True,
            **extra_fields
        )
        user.set_unusable_password()
        user.save(using=self._db)
        Profile.objects.get_or_create(user=user)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('role', 'Admin')
        extra_fields.setdefault('is_verified', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError('Superuser must have is_staff=True.')
        if extra_fields.get('is_superuser') is not True:
            raise ValueError('Superuser must have is_superuser=True.')

        return self.create_user(email, username, password, **extra_fields)

class CustomUser(AbstractUser):
    class Role(models.TextChoices):
        PATIENT = 'Patient', _('Patient')
        ADMIN = 'Admin', _('Admin')
    
    class AuthProvider(models.TextChoices):
        EMAIL = 'email', _('Email')
        FACEBOOK = 'facebook', _('Facebook')
        GOOGLE = 'google', _('Google')
    
    email = models.EmailField(_('email address'), unique=True)
    username = models.CharField(_('username'), max_length=150, unique=True)
    role = models.CharField(_('role'), max_length=10, choices=Role.choices, default=Role.PATIENT)
    auth_provider = models.CharField(_('auth provider'), max_length=10, choices=AuthProvider.choices, default=AuthProvider.EMAIL)
    facebook_id = models.CharField(_('facebook ID'), max_length=100, blank=True, null=True, unique=True)
    google_id = models.CharField(_('google ID'), max_length=100, blank=True, null=True, unique=True)
    is_verified = models.BooleanField(_('verified'), default=False)
    preferred_language = models.CharField(_('preferred language'), max_length=10, default='en')
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']
    
    objects = CustomUserManager()

    def save(self, *args, **kwargs):
        if not self.username and self.email:
            base_username = self.email.split('@')[0]
            self.username = base_username
            counter = 1
            while CustomUser.objects.filter(username=self.username).exists():
                self.username = f"{base_username}_{counter}"
                counter += 1
        super().save(*args, **kwargs)

class Profile(models.Model):
    class NotificationPreference(models.TextChoices):
        SMS = 'SMS', _('SMS')
        EMAIL = 'Email', _('Email')
        BOTH = 'Both', _('Both')
        NONE = 'None', _('None')

    user = models.OneToOneField(CustomUser, on_delete=models.CASCADE, related_name='profile')
    phone_number = models.CharField(_('phone number'), max_length=15, blank=True, null=True)
    notification_preference = models.CharField(
        _('notification preference'), 
        max_length=10, 
        choices=NotificationPreference.choices, 
        default=NotificationPreference.BOTH
    )
    profile_picture = models.ImageField(_('profile picture'), upload_to='profile_pictures/', blank=True, null=True)
    bio = models.TextField(_('biography'), blank=True, null=True)
    date_of_birth = models.DateField(_('date of birth'), blank=True, null=True)
    created_at = models.DateTimeField(_('created at'), auto_now_add=True)
    updated_at = models.DateTimeField(_('updated at'), auto_now=True)

    def __str__(self):
        return f"{self.user.username}'s Profile"
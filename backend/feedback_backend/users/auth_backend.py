from django.contrib.auth.backends import ModelBackend
from django.contrib.auth import get_user_model

UserModel = get_user_model()

class UsernameOrEmailAuthBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        try:
            # Check if input is email
            if '@' in username and '.' in username:
                user = UserModel.objects.get(email=username)
            else:
                user = UserModel.objects.get(username=username)

            # Validate the password
            if user.check_password(password):
                return user
        except UserModel.DoesNotExist:
            return None
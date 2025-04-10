from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Feedback, Response
from users.models import CustomUser
from django.core.mail import send_mail
from django.conf import settings
import vonage

# Send SMS helper function using Vonage
def send_sms(phone_number, message):
    client = vonage.Client(key=settings.VONAGE_API_KEY, secret=settings.VONAGE_API_SECRET)
    sms = vonage.Sms(client)

    response = sms.send_message({
        "from": "VonageAPI",  # Customize the sender ID or use your registered number
        "to": phone_number,
        "text": message,
    })

    if response["messages"][0]["status"] == "0":
        print(f"SMS sent successfully to {phone_number}")
        return {"success": True, "response": response}
    else:
        print(f"Failed to send SMS: {response['messages'][0]['error-text']}")
        return {"success": False, "error": response['messages'][0]['error-text']}

# Notify Admins when Feedback is Submitted
@receiver(post_save, sender=Feedback)
def notify_admin_on_feedback(sender, instance, created, **kwargs):
    if created:
        admins = CustomUser.objects.filter(role='Admin')
        for admin in admins:
            profile = admin.profile
            message = f"New feedback from {instance.user.username}: {instance.content}"

            # Trigger email or SMS based on notification preferences
            if profile.notification_preference == 'SMS' and profile.phone_number:
                send_sms(profile.phone_number, message)
            elif profile.notification_preference == 'Email':
                send_mail(
                    subject="New Feedback Submitted",
                    message=message,
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[admin.email],
                )
            elif profile.notification_preference == 'Both' and profile.phone_number:
                send_sms(profile.phone_number, message)
                send_mail(
                    subject="New Feedback Submitted",
                    message=message,
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[admin.email],
                )

# Notify Patient when Admin Responds to Feedback
@receiver(post_save, sender=Response)
def notify_patient_on_response(sender, instance, created, **kwargs):
    if created:
        patient = instance.feedback.user
        profile = patient.profile
        message = f"Your feedback has been responded to by {instance.admin.username}: {instance.response_text}"

        # Trigger email or SMS based on notification preferences
        if profile.notification_preference == 'SMS' and profile.phone_number:
            send_sms(profile.phone_number, message)
        elif profile.notification_preference == 'Email':
            send_mail(
                subject="Your Feedback Has Been Responded To",
                message=message,
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[patient.email],
            )
        elif profile.notification_preference == 'Both' and profile.phone_number:
            send_sms(profile.phone_number, message)
            send_mail(
                subject="Your Feedback Has Been Responded To",
                message=message,
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[patient.email],
            )
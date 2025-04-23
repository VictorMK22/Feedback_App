from django.urls import path
from .views import HomeDashboardView, FeedbackCreateView, FeedbackListView, ResponseCreateView, NotificationListView, NotificationUpdateView
from .views import TranslateTextView

app_name = "feedback"
urlpatterns = [
    # Feedback APIs
    path('home-dashboard/', HomeDashboardView.as_view(), name='home-dashboard'),
    path('feedback/create/', FeedbackCreateView.as_view(), name='feedback_create'),
    path('feedback/list/', FeedbackListView.as_view(), name='feedback_list'),

    # Response API
    path('response/create/', ResponseCreateView.as_view(), name='response_create'),

    # Notification APIs
    path('notifications/', NotificationListView.as_view(), name='notification_list'),
    path('notifications/<int:pk>/update/', NotificationUpdateView.as_view(), name='notification_update'),
    path('translate/', TranslateTextView.as_view(), name='translate-text'),
]
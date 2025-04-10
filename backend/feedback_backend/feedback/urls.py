from django.urls import path
from .views import FeedbackCreateView, FeedbackListView, ResponseCreateView, NotificationListView, NotificationUpdateView

urlpatterns = [
    # Feedback APIs
    path('feedback/create/', FeedbackCreateView.as_view(), name='feedback_create'),
    path('feedback/list/', FeedbackListView.as_view(), name='feedback_list'),

    # Response API
    path('response/create/', ResponseCreateView.as_view(), name='response_create'),

    # Notification APIs
    path('notifications/', NotificationListView.as_view(), name='notification_list'),
    path('notifications/<int:pk>/update/', NotificationUpdateView.as_view(), name='notification_update'),
]
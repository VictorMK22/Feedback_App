from django.urls import path
from .views import ReportCreateView, ReportListView

app_name = "reports"
urlpatterns = [
    # Report APIs
    path('reports/create/', ReportCreateView.as_view(), name='report_create'),
    path('reports/list/', ReportListView.as_view(), name='report_list'),
]
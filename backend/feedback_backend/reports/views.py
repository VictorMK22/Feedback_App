from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated

# Create your views here.
class ReportCreateView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role != 'Admin':
            return Response({"error": "Only admins can create reports!"}, status=status.HTTP_403_FORBIDDEN)

        serializer = ReportSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(admin=request.user)
            return Response({"message": "Report created successfully!"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ReportListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if request.user.role != 'Admin':
            return Response({"error": "Only admins can view reports!"}, status=status.HTTP_403_FORBIDDEN)

        reports = Report.objects.filter(admin=request.user)
        serializer = ReportSerializer(reports, many=True)
        return Response(serializer.data)
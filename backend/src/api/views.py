from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated
from .models import Conto, Categoria, Movimento, UserProfile
from .serializers import (
    ContoListSerializer, ContoDetailSerializer, ContoEditSerializer,
    CategoriaListSerializer, CategoriaDetailSerializer, CategoriaEditSerializer,
    MovimentoListSerializer, MovimentoDetailSerializer, MovimentoEditSerializer,
    UserProfileSerializer
)
from .pagination import DefaultPagination
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from django.db import transaction
from rest_framework.permissions import AllowAny, IsAdminUser
from django.db.models.functions import TruncMonth
from django.db.models import Sum
import datetime



# ----------------- MIXIN FOR SERIALIZER CHANGE -----------------

class DynamicSerializerMixin:
    short_serializer_class = None
    detail_serializer_class = None
    edit_serializer_class = None

    def get_serializer_class(self):
        # Detail view -> detail serializer
        if getattr(self, 'action', None) == 'retrieve':
            return self.detail_serializer_class or self.serializer_class

        # Create/Update -> edit serializer
        if getattr(self, 'action', None) in ('create', 'update', 'partial_update'):
            return self.edit_serializer_class or self.serializer_class

        # List (with pagination) -> list serializer
        return self.serializer_class


# ----------------- BASE VIEWSET -----------------

class BaseModelViewSet(DynamicSerializerMixin, viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    pagination_class = DefaultPagination

    def get_queryset(self):
        # returns only the logged-in user's data
        return super().get_queryset().filter(user=self.request.user)

    def perform_create(self, serializer):
        # force user = logged-in user
        serializer.save(user=self.request.user)

# ----------------- VIEWSET FOR EACH MODEL -----------------
class ContoViewSet(BaseModelViewSet):
    queryset = Conto.objects.all().order_by("nome")
    serializer_class = ContoListSerializer
    detail_serializer_class = ContoDetailSerializer
    edit_serializer_class = ContoEditSerializer


class CategoriaViewSet(BaseModelViewSet):
    queryset = Categoria.objects.all().order_by("nome")
    serializer_class = CategoriaListSerializer
    detail_serializer_class = CategoriaDetailSerializer
    edit_serializer_class = CategoriaEditSerializer


class MovimentoViewSet(BaseModelViewSet):
    queryset = Movimento.objects.select_related("categoria", "conto").order_by("-data")
    serializer_class = MovimentoListSerializer
    detail_serializer_class = MovimentoDetailSerializer
    edit_serializer_class = MovimentoEditSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        year = self.request.query_params.get('year')
        month = self.request.query_params.get('month')
        categoria_id = self.request.query_params.get('categoria')
        conto_id = self.request.query_params.get('conto')
        tipo = self.request.query_params.get('tipo')

        if year and year != 'Totale':
            queryset = queryset.filter(data__year=year)
        if month:
            queryset = queryset.filter(data__month=month)
        if categoria_id:
            queryset = queryset.filter(categoria_id=categoria_id)
        if conto_id:
            queryset = queryset.filter(conto_id=conto_id)
        if tipo:
            queryset = queryset.filter(tipo=tipo)
            
        return queryset

    def perform_create(self, serializer):
        # Automatically set 'tipo' from category if not provided
        categoria = serializer.validated_data.get('categoria')
        tipo = categoria.tipo if categoria else 'uscita'
        serializer.save(user=self.request.user, tipo=tipo)

    def perform_update(self, serializer):
        categoria = serializer.validated_data.get('categoria')
        if categoria:
            serializer.save(tipo=categoria.tipo)
        else:
            serializer.save()


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile:
            profile = UserProfile.objects.create(user=request.user)
        serializer = UserProfileSerializer(profile)
        return Response(serializer.data)

    def patch(self, request):
        profile = getattr(request.user, 'profile', None)
        if not profile:
            profile = UserProfile.objects.create(user=request.user)
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class CustomRegistrationView(APIView):
    permission_classes = [] # Public

    def post(self, request):
        from .models import GlobalSettings
        is_first_user = not User.objects.exists()
        settings = GlobalSettings.load()
        
        if not is_first_user and not settings.allow_registration:
            return Response({"error": "Registrations are closed."}, status=status.HTTP_403_FORBIDDEN)
        
        username = request.data.get("username")
        password = request.data.get("password")
        email = request.data.get("email", "")
        encrypted_master_key = request.data.get("encrypted_master_key")
        recovery_encrypted_master_key = request.data.get("recovery_encrypted_master_key")

        if not username or not password or not encrypted_master_key or not recovery_encrypted_master_key:
            return Response({"error": "Campi mancanti."}, status=status.HTTP_400_BAD_REQUEST)

        # Check invite code if not the first user
        if not is_first_user:
            invite_code = request.data.get("invite_code")
            if settings.registration_invite_code and invite_code != settings.registration_invite_code:
                return Response({"error": "Codice d'invito non valido."}, status=status.HTTP_403_FORBIDDEN)

        if User.objects.filter(username=username).exists():
            return Response({"error": "Username già in uso."}, status=status.HTTP_400_BAD_REQUEST)

        # Atomic user creation and key saving

        with transaction.atomic():
            user = User.objects.create_user(username=username, email=email, password=password)
            if is_first_user:
                user.is_staff = True
                user.is_superuser = True
                user.save()
                
            # The profile is created by the signal
            profile = user.profile
            profile.encrypted_master_key = encrypted_master_key
            profile.recovery_encrypted_master_key = recovery_encrypted_master_key
            profile.save()

        return Response({"message": "Utente creato con successo.", "is_admin": is_first_user}, status=status.HTTP_201_CREATED)


class GlobalSettingsView(APIView):
    # GET is public to know if the button should be shown
    # PATCH is for admins only
    
    def get_permissions(self):
        if self.request.method == 'GET':
            return [AllowAny()]
        return [IsAdminUser()]

    def get(self, request):
        from .models import GlobalSettings
        settings = GlobalSettings.load()
        is_initialized = User.objects.exists()
        
        data = {
            "allow_registration": settings.allow_registration,
            "is_initialized": is_initialized
        }
        
        # Only return the invite code if the user is an admin
        if request.user.is_authenticated and request.user.is_staff:
            data["registration_invite_code"] = settings.registration_invite_code
            
        return Response(data)

    def patch(self, request):
        from .models import GlobalSettings
        settings = GlobalSettings.load()
        
        allow_registration = request.data.get("allow_registration")
        if allow_registration is not None:
            settings.allow_registration = bool(allow_registration)
            
        invite_code = request.data.get("registration_invite_code")
        if invite_code is not None:
            settings.registration_invite_code = invite_code
            
        settings.save()
        return Response({
            "allow_registration": settings.allow_registration,
            "registration_invite_code": settings.registration_invite_code
        })


class MonthlyStatsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        now = datetime.datetime.now()
        year = request.query_params.get('year', str(now.year))
        month = request.query_params.get('month')

        base_filter = {"user": request.user}
        if year != 'Totale':
            base_filter["data__year"] = year
        
        # Aggregate income by month
        income_stats = Movimento.objects.filter(
            tipo='entrata',
            **base_filter
        ).annotate(
            month=TruncMonth('data')
        ).values('month').annotate(
            total=Sum('importo')
        ).order_by('month')

        # Aggregate spending by month
        spending_stats = Movimento.objects.filter(
            tipo='uscita',
            **base_filter
        ).annotate(
            month=TruncMonth('data')
        ).values('month').annotate(
            total=Sum('importo')
        ).order_by('month')

        # Format for frontend (using short month names like 'Gen', 'Feb', etc.)
        months_it = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic']
        
        income_result = {m: 0 for m in months_it}
        for item in income_stats:
            month_idx = item['month'].month - 1
            income_result[months_it[month_idx]] += float(item['total'])

        spending_result = {m: 0 for m in months_it}
        for item in spending_stats:
            month_idx = item['month'].month - 1
            spending_result[months_it[month_idx]] += float(item['total'])

        # Calculate requested month stats or total for the period
        if month:
            # If a specific month is requested, return its stats
            current_month_income = income_result.get(months_it[int(month) - 1], 0)
            current_month_spending = spending_result.get(months_it[int(month) - 1], 0)
        else:
            # If no month is selected, return the sum of the entire period (selected year or Totale)
            current_month_income = sum(income_result.values())
            current_month_spending = sum(spending_result.values())

        return Response({
            "year": year,
            "month": month,
            "income": [{"month": m, "amount": val} for m, val in income_result.items()],
            "spending": [{"month": m, "amount": val} for m, val in spending_result.items()],
            "monthlyIncome": current_month_income,
            "monthlyExpense": current_month_spending
        })

class MetaChoicesView(APIView):
    permission_classes = [AllowAny]
    def get(self, request):
        from .models import Categoria
        return Response({
            "movement_types": [
                {"id": code, "label": label} for code, label in Categoria.TIPO_CHOICES
            ]
        })

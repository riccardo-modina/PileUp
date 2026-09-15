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
from django.db.models.functions import TruncMonth, TruncDay, TruncYear
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
        detail = request.query_params.get('detail') # 'month' for full history detail
        months_param = request.query_params.get('months') # e.g. "4,5,6,7" for visible months only
        selected_months = None
        if months_param:
            try:
                selected_months = [int(m.strip()) for m in months_param.split(',') if m.strip()]
            except ValueError:
                selected_months = None

        base_filter = {"user": request.user}
        
        # Determine aggregation level and base filter
        if year == 'Totale':
            if detail == 'month':
                trunc_func = TruncMonth
                label_format = "%m/%y" # Will be formatted in python
            else:
                trunc_func = TruncYear
                label_format = "%Y"
        elif month:
            base_filter["data__year"] = year
            base_filter["data__month"] = month
            trunc_func = TruncDay
            label_format = "%d/%m"
        else:
            base_filter["data__year"] = year
            if selected_months:
                base_filter["data__month__in"] = selected_months
            trunc_func = TruncMonth
            label_format = None # We'll use the fixed month list if it's a specific year

        # Aggregate income
        income_stats = Movimento.objects.filter(
            tipo='entrata',
            **base_filter
        ).annotate(
            period=trunc_func('data')
        ).values('period').annotate(
            total=Sum('importo')
        ).order_by('period')

        # Aggregate spending
        spending_stats = Movimento.objects.filter(
            tipo='uscita',
            **base_filter
        ).annotate(
            period=trunc_func('data')
        ).values('period').annotate(
            total=Sum('importo')
        ).order_by('period')

        months_it = ['Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu', 'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic']
        
        if year != 'Totale' and not month:
            # Traditional 12-month view or only selected visible months
            visible_names = [months_it[m - 1] for m in selected_months if 1 <= m <= 12] if selected_months else months_it
            
            income_result = {m: 0 for m in visible_names}
            for item in income_stats:
                m_idx = item['period'].month - 1
                if months_it[m_idx] in income_result:
                    income_result[months_it[m_idx]] += float(item['total'])
            
            spending_result = {m: 0 for m in visible_names}
            for item in spending_stats:
                m_idx = item['period'].month - 1
                if months_it[m_idx] in spending_result:
                    spending_result[months_it[m_idx]] += float(item['total'])

            final_income = [{"month": m, "amount": val} for m, val in income_result.items()]
            final_spending = [{"month": m, "amount": val} for m, val in spending_result.items()]
        else:
            # Dynamic periods (Totale or Month-daily)
            # We need to merge periods from both income and spending to have a consistent X-axis
            all_periods = sorted(list(set(
                [i['period'] for i in income_stats] + [s['period'] for s in spending_stats]
            )))
            
            income_map = {i['period']: float(i['total']) for i in income_stats}
            spending_map = {s['period']: float(s['total']) for s in spending_stats}
            
            final_income = []
            final_spending = []
            
            for p in all_periods:
                label = p.strftime(label_format)
                final_income.append({"month": label, "amount": income_map.get(p, 0)})
                final_spending.append({"month": label, "amount": spending_map.get(p, 0)})

        # Calculate summary stats (sum of all periods in the current view)
        current_month_income = sum(i['amount'] for i in final_income)
        current_month_spending = sum(s['amount'] for s in final_spending)

        return Response({
            "year": year,
            "month": month,
            "income": final_income,
            "spending": final_spending,
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

from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Conto, Categoria, Movimento

# -------------------------------------------------------------------
# SHORT SERIALIZERS (for nested references)
# allows for faster APIs and smaller payloads, useful for obtaining the
# essential information of an object when it's referenced in another
# -------------------------------------------------------------------
class ContoShortSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conto
        fields = "__all__"

class CategoriaShortSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = "__all__"

class MovimentoShortSerializer(serializers.ModelSerializer):
    categoria = CategoriaShortSerializer(read_only=True)
    conto = ContoShortSerializer(read_only=True)

    class Meta:
        model = Movimento
        fields = "__all__"

# -------------------------------------------------------------------
# EDIT SERIALIZERS (for creating or updating)
# for relations and foreign keys, send only the reference ID (or primary key), not the entire object
# -------------------------------------------------------------------
class ContoEditSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Conto
        fields = "__all__"

    def validate(self, data):
        user = self.context['request'].user
        nome = data.get('nome', getattr(self.instance, 'nome', None))
        
        qs = Conto.objects.filter(user=user, nome=nome)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        
        if qs.exists():
            raise serializers.ValidationError({"nome": "Un conto con questo nome esiste già."})
        return data

class CategoriaEditSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')

    class Meta:
        model = Categoria
        fields = "__all__"

    def validate(self, data):
        user = self.context['request'].user
        nome = data.get('nome', getattr(self.instance, 'nome', None))
        tipo = data.get('tipo', getattr(self.instance, 'tipo', None))
        
        qs = Categoria.objects.filter(user=user, nome=nome, tipo=tipo)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        
        if qs.exists():
            raise serializers.ValidationError({"nome": "Una categoria con questo nome esiste già per questo tipo."})
        return data

class MovimentoEditSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    categoria = serializers.PrimaryKeyRelatedField(queryset=Categoria.objects.all())
    conto = serializers.PrimaryKeyRelatedField(queryset=Conto.objects.all(), required=False)
    tipo = serializers.ReadOnlyField()

    class Meta:
        model = Movimento
        fields = "__all__"

# -------------------------------------------------------------------
# LIST SERIALIZERS (for APIs with pagination)
# -------------------------------------------------------------------
class ContoListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conto
        fields = "__all__"

class CategoriaListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = "__all__"

class MovimentoListSerializer(serializers.ModelSerializer):
    categoria = CategoriaShortSerializer(read_only=True)
    conto = ContoShortSerializer(read_only=True)

    class Meta:
        model = Movimento
        fields = "__all__"

# -------------------------------------------------------------------
# DETAIL SERIALIZERS (for detailed view)
# -------------------------------------------------------------------
class ContoDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Conto
        fields = "__all__"

class CategoriaDetailSerializer(serializers.ModelSerializer):
    class Meta:
        model = Categoria
        fields = "__all__"

class MovimentoDetailSerializer(serializers.ModelSerializer):
    categoria = CategoriaShortSerializer(read_only=True)
    conto = ContoShortSerializer(read_only=True)

    class Meta:
        model = Movimento
        fields = "__all__"

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        from .models import UserProfile
        model = UserProfile
        fields = ["encrypted_master_key", "recovery_encrypted_master_key"]

class UserMeSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'is_staff', 'is_superuser']

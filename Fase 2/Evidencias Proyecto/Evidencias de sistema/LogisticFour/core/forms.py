from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from core.models import *

class SignupUserForm(UserCreationForm):
    email = forms.EmailField(required=False, label="Email")
    first_name = forms.CharField(required=False, label="Nombre")
    last_name = forms.CharField(required=False, label="Apellido")

    class Meta:
        model = User
        fields = ("username", "first_name", "last_name", "email", "password1", "password2")

class UsuarioPerfilForm(forms.ModelForm):
    class Meta:
        model = UsuarioPerfil
        # incluimos rol para que el ADMIN asigne el rol al crear
        fields = ("telefono", "rol")
        widgets = {
            "telefono": forms.TextInput(attrs={"placeholder": "+56 9 1234 5678"}),
        }
        
class ProductoForm(forms.ModelForm):
    # Opcional: forzar empty_label más claro en los FKs opcionales
    marca = forms.ModelChoiceField(
        queryset=Marca.objects.none(),
        required=False,
        empty_label="— Selecciona una marca —"
    )
    categoria = forms.ModelChoiceField(
        queryset=CategoriaProducto.objects.none(),
        required=False,
        empty_label="— Selecciona una categoría —"
    )
    unidad_base = forms.ModelChoiceField(
        queryset=UnidadMedida.objects.none(),
        required=True,
        empty_label=None  # obligatorio: sin opción vacía
    )
    tasa_impuesto = forms.ModelChoiceField(
        queryset=TasaImpuesto.objects.none(),
        required=False,
        empty_label="— Sin impuesto —"
    )

    class Meta:
        model = Producto
        fields = [
            "sku", "nombre", "marca", "categoria",
            "unidad_base", "tasa_impuesto", "activo",
            "es_serializado", "tiene_vencimiento",
        ]
        widgets = {
            "sku": forms.TextInput(attrs={"placeholder": "SKU o código interno"}),
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre del producto"}),
        }
        help_texts = {
            "es_serializado": "Actívalo si cada unidad tiene número de serie.",
            "tiene_vencimiento": "Actívalo si el producto maneja fechas de vencimiento/lote.",
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Orden amigable en los selects
        self.fields["marca"].queryset = Marca.objects.all().order_by("nombre")
        self.fields["categoria"].queryset = CategoriaProducto.objects.all().order_by("nombre")
        self.fields["unidad_base"].queryset = UnidadMedida.objects.all().order_by("codigo")
        # Solo tasas activas (si usas el campo 'activo')
        self.fields["tasa_impuesto"].queryset = TasaImpuesto.objects.filter(activo=True).order_by("nombre")

        # Pequeños estilos genéricos (si usas tu CSS, serán inputs normales)
        for name, field in self.fields.items():
            if not isinstance(field.widget, forms.CheckboxInput):
                field.widget.attrs.setdefault("class", "form-control")
            else:
                field.widget.attrs.setdefault("class", "form-check-input")

    def clean_sku(self):
        sku = (self.cleaned_data.get("sku") or "").strip()
        return sku.upper()  # normalizamos para evitar duplicados por mayúsc/minúsc

    def clean_nombre(self):
        return (self.cleaned_data.get("nombre") or "").strip()

    def clean(self):
        cd = super().clean()
        # Ejemplo: no restringimos que sea serializado y con vencimiento a la vez,
        # pero aquí podrías advertir o validar reglas de negocio si quisieras.
        # if cd.get("es_serializado") and cd.get("tiene_vencimiento"):
        #     self.add_error("tiene_vencimiento", "No combine serie y vencimiento (regla de negocio).")
        return cd

    def save(self, commit=True):
        obj = super().save(commit=False)
        # Asegura SKU normalizado
        obj.sku = (obj.sku or "").strip().upper()
        if commit:
            obj.save()
        return obj

class BaseModelForm(forms.ModelForm):
    """Pequeña utilidad para recortar espacios en CharFields."""
    def clean(self):
        cd = super().clean()
        for name, field in self.fields.items():
            if isinstance(field, forms.CharField) and cd.get(name) is not None:
                cd[name] = " ".join(cd[name].split())  # colapsa espacios
        return cd


# ============== TasaImpuesto ==============

class TasaImpuestoForm(BaseModelForm):
    class Meta:
        model = TasaImpuesto
        fields = ["nombre", "porcentaje", "activo"]
        widgets = {
            "nombre": forms.TextInput(attrs={"placeholder": "IVA, Exento, etc."}),
        }
        help_texts = {
            "porcentaje": "Ej: 19.000 para 19%. Usa 3 decimales.",
        }

    def clean_porcentaje(self):
        p = self.cleaned_data.get("porcentaje")
        # Acepta entre 0 y 1000 por seguridad (19.000 es típico)
        if p is None or p < 0 or p > 1000:
            raise forms.ValidationError("Porcentaje fuera de rango válido.")
        return p


# ============== UnidadMedida ==============

class UnidadMedidaForm(BaseModelForm):
    class Meta:
        model = UnidadMedida
        fields = ["codigo", "descripcion"]
        widgets = {
            "codigo": forms.TextInput(attrs={"placeholder": "EA, KG, LT…"}),
        }

    def clean_codigo(self):
        code = (self.cleaned_data.get("codigo") or "").strip()
        return code.upper()  # normalizamos a mayúsculas


# ============== ConversionUM ==============

class ConversionUMForm(BaseModelForm):
    class Meta:
        model = ConversionUM
        fields = ["unidad_desde", "unidad_hasta", "factor"]
        help_texts = {
            "factor": "Factor de conversión (ej: 1000 para KG→G si defines desde=KG, hasta=G).",
        }

    def clean(self):
        cd = super().clean()
        u_from = cd.get("unidad_desde")
        u_to = cd.get("unidad_hasta")
        factor = cd.get("factor")

        if u_from and u_to and u_from == u_to:
            self.add_error("unidad_hasta", "La unidad destino debe ser distinta a la unidad origen.")
        if factor is None or factor <= 0:
            self.add_error("factor", "El factor debe ser mayor a 0.")
        return cd


# ============== Marca ==============

class MarcaForm(BaseModelForm):
    class Meta:
        model = Marca
        fields = ["nombre"]
        widgets = {
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre de la marca"}),
        }

    def clean_nombre(self):
        # Normaliza: quita espacios adicionales y aplica "title"
        nombre = (self.cleaned_data.get("nombre") or "").strip()
        # Si prefieres mantener mayúsculas exactas del usuario, quita la siguiente línea:
        nombre = " ".join(nombre.split())
        return nombre


# ============== CategoriaProducto ==============

class CategoriaProductoForm(BaseModelForm):
    padre = forms.ModelChoiceField(
        queryset=CategoriaProducto.objects.none(),
        required=False,
        empty_label="— Sin categoría padre —"
    )

    class Meta:
        model = CategoriaProducto
        fields = ["padre", "nombre", "codigo"]
        widgets = {
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre de la categoría"}),
            "codigo": forms.TextInput(attrs={"placeholder": "Código interno opcional"}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        qs = CategoriaProducto.objects.all().order_by("nombre")
        # Evitar que elija a sí misma como padre al editar:
        if self.instance and self.instance.pk:
            qs = qs.exclude(pk=self.instance.pk)
        self.fields["padre"].queryset = qs

    def clean_nombre(self):
        return (self.cleaned_data.get("nombre") or "").strip()

    def clean_codigo(self):
        return (self.cleaned_data.get("codigo") or "").strip()


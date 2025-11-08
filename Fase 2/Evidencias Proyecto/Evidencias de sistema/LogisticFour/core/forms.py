# forms.py
from django import forms
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.models import User
from django.core.exceptions import ValidationError
from core.models import Bodega, UsuarioPerfil
from django.db.models import Q
from core.models import (
    # usuarios
    UsuarioPerfil,
    # catálogos
    TasaImpuesto, UnidadMedida, ConversionUM, Marca, CategoriaProducto, TipoUbicacion,
    # org
    Sucursal, Bodega, UbicacionBodega, UbicacionSucursal,
    # productos
    Producto, LoteProducto, SerieProducto,
)


# =========================================================
#  Usuarios
# =========================================================
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
        # el admin puede elegir rol
        fields = ("telefono", "rol")
        widgets = {
            "telefono": forms.TextInput(attrs={"placeholder": "+56 9 1234 5678"}),
        }


class UserEditForm(forms.ModelForm):
    is_active = forms.BooleanField(required=False, label="Activo")

    class Meta:
        model = User
        fields = ("username", "first_name", "last_name", "email", "is_active")
        widgets = {
            "username":   forms.TextInput(attrs={"class": "form-control"}),
            "first_name": forms.TextInput(attrs={"class": "form-control"}),
            "last_name":  forms.TextInput(attrs={"class": "form-control"}),
            "email":      forms.EmailInput(attrs={"class": "form-control"}),
        }


class UsuarioPerfilEditForm(forms.ModelForm):
    class Meta:
        model = UsuarioPerfil
        fields = ("telefono", "rol")
        widgets = {
            "telefono": forms.TextInput(attrs={"placeholder": "+56 9 1234 5678", "class": "form-control"}),
            "rol": forms.Select(attrs={"class": "form-select"}),
        }


# =========================================================
#  Producto
#  (sin el campo ubicacion porque ya no existe en el modelo)
# =========================================================
class ProductoForm(forms.ModelForm):
    marca = forms.ModelChoiceField(queryset=Marca.objects.none(), required=False, empty_label="— Selecciona una marca —")
    categoria = forms.ModelChoiceField(queryset=CategoriaProducto.objects.none(), required=False, empty_label="— Selecciona una categoría —")
    unidad_base = forms.ModelChoiceField(queryset=UnidadMedida.objects.none(), required=True, empty_label=None)
    tasa_impuesto = forms.ModelChoiceField(queryset=TasaImpuesto.objects.none(), required=False, empty_label="— Sin impuesto —")

    class Meta:
        model = Producto
        fields = [
            "sku", "nombre",
            "marca", "categoria",
            "unidad_base", "tasa_impuesto",
            "activo", "es_serializado", "tiene_vencimiento",
            "precio",
        ]
        widgets = {
            "sku": forms.TextInput(attrs={"placeholder": "SKU o código interno"}),
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre del producto"}),
            "precio": forms.NumberInput(attrs={"min": 0, "step": 1}),
        }

    def __init__(self, *args, include_stock: bool = False, **kwargs):
        super().__init__(*args, **kwargs)

        self.fields["marca"].queryset = Marca.objects.all().order_by("nombre")
        self.fields["categoria"].queryset = CategoriaProducto.objects.all().order_by("nombre")
        self.fields["unidad_base"].queryset = UnidadMedida.objects.all().order_by("codigo")
        self.fields["tasa_impuesto"].queryset = TasaImpuesto.objects.filter(activo=True).order_by("nombre")

        # APLICAR CLASES CORRECTAS POR TIPO DE WIDGET
        for name, field in self.fields.items():
            w = field.widget
            if isinstance(w, (forms.Select, forms.SelectMultiple)):
                w.attrs.setdefault("class", "form-select")
            elif isinstance(w, forms.CheckboxInput):
                w.attrs.setdefault("class", "form-check-input")
            else:
                w.attrs.setdefault("class", "form-control")


 # donde tengas StockInlineForm (en views.py o forms.py)
class StockInlineForm(forms.Form):
    bodega = forms.ModelChoiceField(queryset=Bodega.objects.all(), required=True, label="Bodega destino",
                                    widget=forms.Select(attrs={"class":"form-select"}))
    cantidad_inicial = forms.IntegerField(min_value=0, required=True, label="Cantidad inicial",
                                          widget=forms.NumberInput(attrs={"class":"form-control"}))
    costo_unitario = forms.DecimalField(max_digits=12, decimal_places=2, required=False, label="Costo unitario",
                                        widget=forms.NumberInput(attrs={"class":"form-control"}))
    lote = forms.CharField(max_length=100, required=False, label="Lote",
                           widget=forms.TextInput(attrs={"class":"form-control"}))
    fecha_vencimiento = forms.DateField(required=False, label="Fecha de vencimiento",
                                        widget=forms.DateInput(attrs={"type":"date","class":"form-control"}))

               



# =========================================================
#  Base para forms simples
# =========================================================
class BaseModelForm(forms.ModelForm):
    def clean(self):
        cd = super().clean()
        for name, field in self.fields.items():
            if isinstance(field, forms.CharField) and cd.get(name) is not None:
                cd[name] = " ".join(cd[name].split())
        return cd


# =========================================================
#  TasaImpuesto
# =========================================================
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
        if p is None or p < 0 or p > 1000:
            raise forms.ValidationError("Porcentaje fuera de rango válido.")
        return p


# =========================================================
#  UnidadMedida
# =========================================================
class UnidadMedidaForm(BaseModelForm):
    class Meta:
        model = UnidadMedida
        fields = ["codigo", "descripcion"]
        widgets = {
            "codigo": forms.TextInput(attrs={"placeholder": "EA, KG, LT…"}),
        }

    def clean_codigo(self):
        code = (self.cleaned_data.get("codigo") or "").strip()
        return code.upper()


# =========================================================
#  ConversionUM
# =========================================================
class ConversionUMForm(BaseModelForm):
    class Meta:
        model = ConversionUM
        fields = ["unidad_desde", "unidad_hasta", "factor"]
        help_texts = {
            "factor": "Factor de conversión (ej: 1000 para KG→G).",
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


# =========================================================
#  Marca
# =========================================================
class MarcaForm(BaseModelForm):
    class Meta:
        model = Marca
        fields = ["nombre"]
        widgets = {
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre de la marca"}),
        }

    def clean_nombre(self):
        nombre = (self.cleaned_data.get("nombre") or "").strip()
        nombre = " ".join(nombre.split())
        return nombre


# =========================================================
#  Categoría
# =========================================================
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
        if self.instance and self.instance.pk:
            qs = qs.exclude(pk=self.instance.pk)
        self.fields["padre"].queryset = qs

    def clean_nombre(self):
        return (self.cleaned_data.get("nombre") or "").strip()

    def clean_codigo(self):
        return (self.cleaned_data.get("codigo") or "").strip()


# =========================================================
#  Sucursal
# =========================================================
class SucursalForm(forms.ModelForm):
    class Meta:
        model = Sucursal
        # ahora la sucursal SÍ tiene FK a bodega
        fields = ["codigo", "nombre", "bodega", "direccion", "ciudad", "region", "pais", "activo"]
        labels = {
            "codigo": "Código",
            "nombre": "Nombre de la sucursal",
            "bodega": "Bodega padre",
            "direccion": "Dirección",
            "ciudad": "Ciudad",
            "region": "Región / Estado",
            "pais": "País",
            "activo": "Activa",
        }
        widgets = {
            "codigo": forms.TextInput(attrs={
                "class": "form-control",
                "maxlength": "20",
                "placeholder": "Ej: SCL-01",
                "autocomplete": "off",
            }),
            "nombre": forms.TextInput(attrs={
                "class": "form-control",
                "placeholder": "Nombre comercial de la sucursal",
            }),
            "bodega": forms.Select(attrs={"class": "form-select"}),
            "direccion": forms.TextInput(attrs={
                "class": "form-control",
                "placeholder": "Calle, número, comuna/barrio",
            }),
            "ciudad": forms.TextInput(attrs={
                "class": "form-control",
                "placeholder": "Ej: Santiago",
            }),
            "region": forms.TextInput(attrs={
                "class": "form-control",
                "placeholder": "Ej: Metropolitana",
            }),
            "pais": forms.TextInput(attrs={
                "class": "form-control",
                "placeholder": "Ej: Chile",
            }),
            "activo": forms.CheckboxInput(attrs={
                "class": "form-check-input",
            }),
        }

    def clean_codigo(self):
        codigo = (self.cleaned_data.get("codigo") or "").strip().upper()
        if " " in codigo:
            raise ValidationError("El código no debe contener espacios.")
        return codigo

    def clean_nombre(self):
        nombre = (self.cleaned_data.get("nombre") or "").strip()
        if len(nombre) < 3:
            raise ValidationError("El nombre debe tener al menos 3 caracteres.")
        return nombre


# =========================================================
#  Bodega
# =========================================================
class BodegaForm(forms.ModelForm):
    class Meta:
        model = Bodega
        fields = ["codigo", "nombre", "descripcion", "activo"]
        labels = {
            "codigo": "Código de bodega",
            "nombre": "Nombre de la bodega",
            "descripcion": "Descripción",
            "activo": "Activa",
        }
        widgets = {
            "codigo": forms.TextInput(attrs={
                "class": "form-control", "maxlength": "20", "placeholder": "Ej: BOD-01",
            }),
            "nombre": forms.TextInput(attrs={
                "class": "form-control", "placeholder": "Nombre visible de la bodega",
            }),
            "descripcion": forms.Textarea(attrs={
                "class": "form-control", "rows": 3, "placeholder": "Opcional",
            }),
            "activo": forms.CheckboxInput(attrs={"class": "form-check-input"}),
        }

    def clean_codigo(self):
        codigo = (self.cleaned_data.get("codigo") or "").strip().upper()
        if " " in codigo:
            raise ValidationError("El código no debe contener espacios.")
        return codigo

    def clean_nombre(self):
        nombre = (self.cleaned_data.get("nombre") or "").strip()
        if len(nombre) < 3:
            raise ValidationError("El nombre debe tener al menos 3 caracteres.")
        return nombre


# =========================================================
#  TipoUbicacion
# =========================================================
class TipoUbicacionForm(forms.ModelForm):
    class Meta:
        model = TipoUbicacion
        fields = ["codigo", "descripcion"]
        widgets = {
            "codigo": forms.TextInput(attrs={"placeholder": "BIN, RACK, FLOOR, STAGE…"}),
            "descripcion": forms.TextInput(attrs={"placeholder": "Descripción corta"}),
        }


# =========================================================
#  Ubicaciones NUEVAS
# =========================================================
class UbicacionBodegaForm(forms.ModelForm):
    class Meta:
        model = UbicacionBodega
        fields = ["bodega", "codigo", "nombre", "area", "tipo", "pickeable", "almacenable", "activo"]
        widgets = {
            "bodega": forms.Select(attrs={"class": "form-select"}),
            "codigo": forms.TextInput(attrs={"placeholder": "Ej: PAS-01-N2", "class": "form-control"}),
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre visible (opcional)", "class": "form-control"}),
            "area": forms.TextInput(attrs={"placeholder": "Zona / Pasillo / Sector", "class": "form-control"}),
            "tipo": forms.Select(attrs={"class": "form-select"}),
            "pickeable": forms.CheckboxInput(attrs={"class": "form-check-input"}),
            "almacenable": forms.CheckboxInput(attrs={"class": "form-check-input"}),
            "activo": forms.CheckboxInput(attrs={"class": "form-check-input"}),
        }

    def clean_codigo(self):
        codigo = (self.cleaned_data.get("codigo") or "").strip()
        return codigo.upper()


class UbicacionSucursalForm(forms.ModelForm):
    class Meta:
        model = UbicacionSucursal
        fields = ["sucursal", "codigo", "nombre", "area", "tipo", "pickeable", "almacenable", "activo"]
        widgets = {
            "sucursal": forms.Select(attrs={"class": "form-select"}),
            "codigo": forms.TextInput(attrs={"placeholder": "Ej: ANDEN-01", "class": "form-control"}),
            "nombre": forms.TextInput(attrs={"placeholder": "Nombre visible (opcional)", "class": "form-control"}),
            "area": forms.TextInput(attrs={"placeholder": "Zona / Sector", "class": "form-control"}),
            "tipo": forms.Select(attrs={"class": "form-select"}),
            "pickeable": forms.CheckboxInput(attrs={"class": "form-check-input"}),
            "almacenable": forms.CheckboxInput(attrs={"class": "form-check-input"}),
            "activo": forms.CheckboxInput(attrs={"class": "form-check-input"}),
        }

    def clean_codigo(self):
        codigo = (self.cleaned_data.get("codigo") or "").strip()
        return codigo.upper()


# =========================================================
#  Lotes
# =========================================================
class LoteProductoForm(forms.ModelForm):
    class Meta:
        model = LoteProducto
        fields = ["producto", "codigo_lote", "fecha_fabricacion", "fecha_vencimiento"]
        widgets = {
            "codigo_lote": forms.TextInput(attrs={"placeholder": "Código de lote"}),
            "fecha_fabricacion": forms.DateInput(attrs={"type": "date"}),
            "fecha_vencimiento": forms.DateInput(attrs={"type": "date"}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for name, field in self.fields.items():
            field.widget.attrs.setdefault(
                "class", "form-control" if not isinstance(field.widget, forms.CheckboxInput) else "form-check-input"
            )

    def clean(self):
        cd = super().clean()
        prod = cd.get("producto")
        codigo = (cd.get("codigo_lote") or "").strip()
        if prod and codigo:
            qs = LoteProducto.objects.filter(producto=prod, codigo_lote=codigo)
            if self.instance.pk:
                qs = qs.exclude(pk=self.instance.pk)
            if qs.exists():
                self.add_error("codigo_lote", "Ya existe un lote con ese código para el producto seleccionado.")
        return cd


class FinanzasReporteForm(forms.Form):
    bodega = forms.ModelChoiceField(
        queryset=Bodega.objects.all().order_by("codigo"),
        required=False, label="Bodega", empty_label="---------",
    )
    proveedor = forms.ModelChoiceField(
        queryset=User.objects.filter(
            perfil__rol=UsuarioPerfil.Rol.PROVEEDOR,
            is_active=True
        ).order_by("username"),
        required=False, label="Proveedor", empty_label="---------",
    )
    fecha_desde = forms.DateField(
        required=False,
        widget=forms.DateInput(attrs={"type": "date"}),
        label="Desde",
    )
    fecha_hasta = forms.DateField(
        required=False,
        widget=forms.DateInput(attrs={"type": "date"}),
        label="Hasta",
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        # Etiquetas legibles
        self.fields["bodega"].label_from_instance = lambda b: f"{b.codigo} - {b.nombre}"
        self.fields["proveedor"].label_from_instance = lambda u: (u.get_full_name() or u.username)

        # Filtro correcto: solo usuarios con rol PROVEEDOR y activos
        self.fields["proveedor"].queryset = User.objects.filter(
            perfil__rol=UsuarioPerfil.Rol.PROVEEDOR,
            is_active=True
        ).order_by("username")

    def clean(self):
        data = super().clean()
        d, h = data.get("fecha_desde"), data.get("fecha_hasta")
        if d and h and d > h:
            self.add_error("fecha_hasta", "La fecha hasta no puede ser menor que la fecha desde.")
        return data
# =========================================================
#  Series
# =========================================================
class SerieProductoForm(forms.ModelForm):
    class Meta:
        model = SerieProducto
        fields = ["producto", "numero_serie", "lote"]
        widgets = {
            "numero_serie": forms.TextInput(attrs={"placeholder": "Número de serie"}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        producto = None
        if self.instance and self.instance.pk:
            producto = self.instance.producto
        else:
            pid = self.data.get("producto") or self.initial.get("producto")
            if pid:
                try:
                    producto = Producto.objects.get(pk=pid)
                except Producto.DoesNotExist:
                    producto = None

        if producto:
            self.fields["lote"].queryset = LoteProducto.objects.filter(producto=producto).order_by("codigo_lote")
        else:
            self.fields["lote"].queryset = LoteProducto.objects.none()

        for name, field in self.fields.items():
            field.widget.attrs.setdefault(
                "class", "form-control" if not isinstance(field.widget, forms.CheckboxInput) else "form-check-input"
            )

    def clean(self):
        cd = super().clean()
        prod = cd.get("producto")
        ns = (cd.get("numero_serie") or "").strip()
        if prod and ns:
            qs = SerieProducto.objects.filter(producto=prod, numero_serie=ns)
            if self.instance.pk:
                qs = qs.exclude(pk=self.instance.pk)
            if qs.exists():
                self.add_error("numero_serie", "Ya existe una serie con ese número para el producto seleccionado.")

        lote = cd.get("lote")
        if lote and prod and lote.producto_id != prod.id:
            self.add_error("lote", "El lote seleccionado no pertenece a este producto.")
        return cd


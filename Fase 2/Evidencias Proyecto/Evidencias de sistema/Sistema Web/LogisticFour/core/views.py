# =============================================
#  LIBRERÍAS ESTÁNDAR DE PYTHON
# =============================================
import csv
from io import BytesIO
import requests
import csv
import json
import logging
from datetime import datetime, timezone


from decimal import Decimal, InvalidOperation
from django.db.models.signals import pre_save, post_save
from django.dispatch import receiver
from django.utils import timezone
# core/views.py  (arriba con el resto de imports)
from django.shortcuts import render

# =============================================
#  LIBRERÍAS DE DJANGO
# =============================================
from django import apps, forms
from django.conf import settings
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required, user_passes_test
from django.contrib.auth.forms import UserCreationForm
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.contrib.auth.models import User, Group
from django.contrib.messages.views import SuccessMessageMixin
from django.core.paginator import Paginator
from django.db import IntegrityError, transaction
from django.db.models import (
    Q, Sum, F, Value, Count, DecimalField, ExpressionWrapper
)
from django.db.models.functions import Coalesce, Lower
from django.http import (
    HttpResponse, Http404, JsonResponse,
    HttpResponseBadRequest, HttpResponseRedirect
)
from django.shortcuts import render, redirect, get_object_or_404
from django.urls import reverse, reverse_lazy, NoReverseMatch
from django.views import View
from django.views.decorators.http import require_POST, require_GET
from django.views.generic import (
    ListView, CreateView, UpdateView,
    DeleteView, DetailView
)

# =============================================
#  MÓDULOS DEL PROYECTO (CORE)
# =============================================
from core.forms import *
from core.forms import SignupUserForm, UsuarioPerfilForm
from core.models import *
from core.models import Producto, UsuarioPerfil
from core.utils import ensure_ubicacion_sucursal, qr_url, barcode_url
from django.db import models as djmodels

from core.forms import SignupUserForm, UsuarioPerfilForm, FinanzasReporteForm
from core.models import UsuarioPerfil, OrdenCompra, RecepcionMercaderia, FacturaProveedor, UsuarioPerfil, Producto, Stock

# Si tu modelo TipoMovimiento tiene un campo NOT NULL 'direccion',
# definimos un default por código:
def _direccion_default_value():
    """
    Devuelve el valor por defecto correcto para TipoMovimiento.direccion
    según su tipo: 0 si es IntegerField, "NEUTRO" si es CharField.
    """
    field = TipoMovimiento._meta.get_field("direccion")
    if isinstance(field, djmodels.IntegerField):
        return 0   # neutro numérico
    return "NEUTRO"  # neutro texto

def _tm(codigo: str) -> TipoMovimiento:
    """
    Devuelve (o crea) un TipoMovimiento con 'direccion' y 'nombre' completos,
    evitando IntegrityError por NOT NULL y el error de tipos.
    """
    codigo_up = (codigo or "").upper()
    defaults = {
        "nombre": codigo_up.replace("_", " ").title(),
        "direccion": _direccion_default_value(),
    }
    obj, created = TipoMovimiento.objects.get_or_create(codigo=codigo_up, defaults=defaults)

    # Completar si faltan valores o están vacíos
    to_update = []
    if getattr(obj, "direccion", None) in (None, ""):
        obj.direccion = defaults["direccion"]
        to_update.append("direccion")
    if not getattr(obj, "nombre", None):
        obj.nombre = defaults["nombre"]
        to_update.append("nombre")
    if to_update:
        obj.save(update_fields=to_update)

    return obj

def _unidad_default() -> UnidadMedida | None:
    return (
        UnidadMedida.objects.filter(codigo="UN").first()
        or UnidadMedida.objects.order_by("id").first()
    )
# ==== /Helpers Kardex ====
# ==== /Helpers Kardex ====
def dashboard(request):
    return render(request, "core/dashboard.html")

@login_required
def products(request):
    q = (request.GET.get("q") or "").strip()

    queryset = (
        Producto.objects.select_related("marca", "categoria", "unidad_base", "tasa_impuesto")
        .annotate(
            proveedores_count=Count("usuarios_proveedor", distinct=True),
            lotes_count=Count("lotes", distinct=True),
            series_count=Count("series", distinct=True),
            total_stock=Coalesce(
                Sum("stocks__cantidad_disponible"),
                Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
            ),
        )
        .order_by("nombre", "sku")
    )

    if q:
        terms = [t for t in q.replace("-", " ").split() if t]
        for t in terms:
            queryset = queryset.filter(
                Q(sku__icontains=t)
                | Q(nombre__icontains=t)
                | Q(marca__nombre__icontains=t)
                | Q(categoria__nombre__icontains=t)
            )

    paginator = Paginator(queryset, 20)
    page_number = request.GET.get("page")
    page_obj = paginator.get_page(page_number)

    return render(
        request,
        "core/products.html",
        {
            "q": q,
            "productos": page_obj.object_list,
            "page_obj": page_obj,
            "is_paginated": page_obj.has_other_pages(),
        },
    )

@login_required
def category(request, slug):
    return render(request, "core/category.html", {"category_name": slug.replace("-", " ").title()})


@login_required
def product_add(request):
    """
    versión nueva: el form de producto YA NO trae campo ubicacion.
    así que solo creamos el producto y listo.
    si quieres stock inicial por ubicación, hazlo en otra vista.
    """
    if request.method == "POST":
        form = ProductoForm(request.POST)
        if form.is_valid():
            producto = form.save()
            messages.success(request, "Producto creado.")
            return redirect("products")
    else:
        form = ProductoForm()

    return render(request, "core/product_add.html", {"form": form})


def _get_or_create_default_location(bodega):
    """
    Si el proyecto NO tiene Stock.bodega, pero SÍ trabaja con ubicacion_bodega,
    buscamos (o creamos) una ubicación por defecto en esa bodega.
    """
    # intenta resolver el modelo UbicacionBodega de tu app (ajusta 'core' si tu app se llama distinto)
    UbicacionBodega = None
    for app_label in ("core",):  # agrega otros app_labels si aplica
        try:
            UbicacionBodega = apps.get_model(app_label, "UbicacionBodega")
            break
        except LookupError:
            continue

    if UbicacionBodega is None:
        return None  # no existe ese modelo → no podemos setear ubicación

    # Busca / crea ubicación por defecto
    ubi, _ = UbicacionBodega.objects.get_or_create(
        bodega=bodega,
        codigo="DEF",
        defaults={"nombre": "General"}
    )
    return ubi


@login_required
@transaction.atomic
def product_add_combined(request):
    if request.method == "POST":
        pform = ProductoForm(request.POST, include_stock=False)
        sform = StockInlineForm(request.POST)

        if pform.is_valid() and sform.is_valid():
            # si marca vencimiento, exige fecha
            if pform.cleaned_data.get("tiene_vencimiento") and not sform.cleaned_data.get("fecha_vencimiento"):
                sform.add_error("fecha_vencimiento", "Debes indicar una fecha de vencimiento para este producto.")
            else:
                # 1) Producto
                producto = pform.save()

                # 2) Stock inicial + bodega seleccionada
                bodega = sform.cleaned_data["bodega"]
                cantidad = sform.cleaned_data["cantidad_inicial"] or 0

                stock_field_names = {f.name for f in Stock._meta.get_fields()}
                stock_kwargs = dict(
                    producto=producto,
                    cantidad_disponible=cantidad,
                )

                if "bodega" in stock_field_names:
                    # Caso 1: FK directa a Bodega
                    stock_kwargs["bodega"] = bodega
                else:
                    # Caso 2: usar ubicacion_bodega por defecto en esa bodega
                    ubi = _get_or_create_default_location(bodega)
                    if ubi and "ubicacion_bodega" in stock_field_names:
                        stock_kwargs["ubicacion_bodega"] = ubi

                # extras si existen en el modelo
                if "costo_unitario" in stock_field_names:
                    stock_kwargs["costo_unitario"] = sform.cleaned_data.get("costo_unitario") or 0
                if "lote" in stock_field_names:
                    stock_kwargs["lote"] = sform.cleaned_data.get("lote") or ""
                if "fecha_vencimiento" in stock_field_names:
                    stock_kwargs["fecha_vencimiento"] = sform.cleaned_data.get("fecha_vencimiento")

                # crea el stock solo con claves válidas
                valid_names = {f.name for f in Stock._meta.get_fields()}
                clean_kwargs = {k: v for k, v in stock_kwargs.items() if k in valid_names}
                Stock.objects.create(**clean_kwargs)

                # (opcional) recalcula stock global
                try:
                    total = (Stock.objects
                             .filter(producto=producto)
                             .aggregate(total=Sum("cantidad_disponible"))["total"]) or 0
                    producto.stock = total
                    producto.save(update_fields=["stock"])
                except Exception:
                    pass

                messages.success(request, "Producto y stock inicial registrados correctamente.")
                return redirect(reverse("producto-detail", args=[producto.id]))
    else:
        pform = ProductoForm(include_stock=False)
        sform = StockInlineForm()

    return render(request, "core/product_add.html", {"pform": pform, "sform": sform})


# -------------------- Login Helpers --------------------
def _redirect_url_by_role(perfil):
    if not perfil or not perfil.rol:
        return reverse('dashboard')
    mapping = {
        'ADMIN': reverse('dashboard'),
        'BODEGUERO': reverse('products'),
    }
    return mapping.get(perfil.rol, reverse('dashboard'))


# -------------------- Login / Logout --------------------
def login_view(request):
    # Si ya estÃ¡ logueado, redirige segÃºn su rol
    if request.user.is_authenticated:
        perfil = getattr(request.user, 'perfil', None)
        return redirect(_redirect_url_by_role(perfil))

    next_url = request.GET.get('next') or request.POST.get('next')

    if request.method == 'POST':
        username = request.POST.get('username', '').strip()
        password = request.POST.get('password', '')
        remember = request.POST.get('remember') == 'on'

        user = authenticate(request, username=username, password=password)
        if user is not None and user.is_active:
            login(request, user)

            # "Recordarme": si NO marca, expira al cerrar el navegador
            if not remember:
                request.session.set_expiry(0)

            perfil = getattr(user, 'perfil', None)
            return redirect(next_url or _redirect_url_by_role(perfil))
        else:
            return render(request, 'accounts/login.html', {
                'error': 'Usuario o contraseÃ±a incorrectos',
                'next': next_url,
            })

    return render(request, 'accounts/login.html', {'next': next_url})

def logout_view(request):
    logout(request)
    return redirect('login')


@login_required
def dashboard_view(request):
    perfil = getattr(request.user, 'perfil', None)
    return redirect(_redirect_url_by_role(perfil))



# -------------------- Signup (opcional, solo ADMIN) --------------------
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
        fields = ("telefono",)  # aÃ±ade mÃ¡s campos si quieres capturarlos al alta


def _is_admin(user: User) -> bool:
    try:
        if not user or not user.is_authenticated:
            return False
        # Superusuario del sistema siempre tiene permisos de ADMIN
        if getattr(user, 'is_superuser', False):
            return True
        # Asegura que exista perfil para usuarios creados de forma externa
        perfil, _ = UsuarioPerfil.objects.get_or_create(usuario=user)
        return perfil.rol == UsuarioPerfil.Rol.ADMIN
    except Exception:
        return False
    
def _sync_user_groups_by_profile(user: User):
    """
    Sincroniza el Group del usuario segÃºn su perfil.rol.
    """
    try:
        perfil = user.perfil
        if perfil and perfil.rol:
            # Asegura que existan todos los grupos
            for code, _ in UsuarioPerfil.Rol.choices:
                Group.objects.get_or_create(name=code)
            user.groups.clear()
            user.groups.add(Group.objects.get(name=perfil.rol))
    except Exception:
        pass


def admin_required(view_func):
    """Decorador para views basadas en funciones que redirige con mensaje si no es admin."""
    def _wrapped(request, *args, **kwargs):
        if not _is_admin(request.user):
            messages.error(request, "No tienes permisos para realizar esa acciÃ³n.")
            return redirect('dashboard')
        return view_func(request, *args, **kwargs)
    return _wrapped

@admin_required
@transaction.atomic
def signup(request):
    if request.method == "POST":
        user_form = SignupUserForm(request.POST)
        perfil_form = UsuarioPerfilForm(request.POST)

        if user_form.is_valid() and perfil_form.is_valid():
            user = user_form.save(commit=True)
            perfil, _ = UsuarioPerfil.objects.get_or_create(usuario=user)

            for field, value in perfil_form.cleaned_data.items():
                setattr(perfil, field, value)
            perfil.save()

            login(request, user)
            messages.success(request, "âœ… Usuario creado correctamente.")
            try:
                return redirect(reverse("usuario-list"))
            except NoReverseMatch:
                return redirect("dashboard")
        else:
            messages.error(request, "âŒ Revisa los errores del formulario.")
    else:
        user_form = SignupUserForm()
        perfil_form = UsuarioPerfilForm()

    return render(request, "accounts/sign.html", {"user_form": user_form, "perfil_form": perfil_form})
@admin_required
@transaction.atomic
def user_create(request):
    """
    Alta de usuario (User + UsuarioPerfil).
    Usa: accounts/sign.html (tu formulario existente).
    Si viene ?role=PROVEEDOR, se preselecciona ese rol.
    """
    preset_role = request.GET.get("role")
    if request.method == "POST":
        user_form = SignupUserForm(request.POST)
        perfil_form = UsuarioPerfilForm(request.POST)
        if user_form.is_valid() and perfil_form.is_valid():
            user = user_form.save(commit=True)

            perfil, _ = UsuarioPerfil.objects.get_or_create(usuario=user)
            # copiar campos del form al perfil
            for field, value in perfil_form.cleaned_data.items():
                setattr(perfil, field, value)

            # si vino role por query y no se cambiÃ³ en el form, respÃ©talo
            if preset_role and not perfil_form.cleaned_data.get("rol"):
                perfil.rol = preset_role

            perfil.save()
            _sync_user_groups_by_profile(user)

            messages.success(request, "âœ… Usuario creado correctamente.")
            return redirect("usuario-list")
        messages.error(request, "âŒ Revisa los errores del formulario.")
    else:
        user_form = SignupUserForm()
        # inicializa el rol si viene por query
        initial = {}
        if preset_role in dict(UsuarioPerfil.Rol.choices):
            initial["rol"] = preset_role
        perfil_form = UsuarioPerfilForm(initial=initial)

    return render(request, "accounts/sign.html", {
        "user_form": user_form,
        "perfil_form": perfil_form,
    })

@admin_required
@transaction.atomic
def user_edit(request, user_id: int):
    obj = get_object_or_404(User.objects.select_related("perfil"), pk=user_id)

    # Evitar que un admin se desactive/elimine a sÃ­ mismo por accidente (opcional)
    editing_self = (request.user.pk == obj.pk)

    # Asegurar que tenga perfil
    perfil, _ = UsuarioPerfil.objects.get_or_create(usuario=obj)

    if request.method == "POST":
        uform = UserEditForm(request.POST, instance=obj)
        pform = UsuarioPerfilEditForm(request.POST, instance=perfil)

        if uform.is_valid() and pform.is_valid():
            # No permitir que un usuario se desactive a sÃ­ mismo (opcional, seguridad)
            if editing_self and not uform.cleaned_data.get("is_active", True):
                messages.error(request, "No puedes desactivar tu propio usuario.")
            else:
                uform.save()
                pform.save()
                _sync_user_groups_by_profile(obj)
                messages.success(request, "âœ… Usuario actualizado.")
                return redirect("usuario-list")
        else:
            messages.error(request, "âŒ Revisa los errores del formulario.")
    else:
        uform = UserEditForm(instance=obj)
        pform = UsuarioPerfilEditForm(instance=perfil)

    return render(request, "accounts/user_form.html", {
        "obj": obj,
        "user_form": uform,
        "perfil_form": pform,
    })

@admin_required
@transaction.atomic
def user_delete(request, user_id: int):
    obj = get_object_or_404(User, pk=user_id)

    # Reglas de seguridad Ãºtiles:
    if request.user.pk == obj.pk:
        messages.error(request, "No puedes eliminar tu propio usuario.")
        return redirect("usuario-list")
    if obj.is_superuser:
        messages.error(request, "No puedes eliminar un superusuario.")
        return redirect("usuario-list")

    if request.method == "POST":
        obj.delete()
        messages.success(request, "ðŸ—‘ï¸ Usuario eliminado.")
        return redirect("usuario-list")

    return render(request, "accounts/user_confirm_delete.html", {"obj": obj})

@admin_required
@login_required
def user_list(request):
    """
    Listado con bÃºsqueda y filtro por rol.
    Template: accounts/user_list.html
    """
    q = (request.GET.get("q") or "").strip()
    rol = (request.GET.get("rol") or "").strip()

    qs = User.objects.select_related("perfil").order_by("username")

    if q:
        qs = qs.filter(
            Q(username__icontains=q)
            | Q(first_name__icontains=q)
            | Q(last_name__icontains=q)
            | Q(email__icontains=q)
        )

    if rol:
        # rol es un CharField con choices en UsuarioPerfil
        qs = qs.filter(perfil__rol=rol)

    paginator = Paginator(qs, 20)
    page = request.GET.get("page", 1)
    users_page = paginator.get_page(page)

    return render(
        request,
        "accounts/user_list.html",
        {
            "users": users_page,
            "q": q,
            "rol": rol,
            "roles": UsuarioPerfil.Rol.choices,  # (code, label)
        },
    )


@admin_required
@login_required
@require_POST
def usuario_set_rol(request, user_id: int):
    """
    Cambia el rol (perfil.rol) de un usuario vÃ­a fetch POST JSON.
    Espera: {"rol": "<CODE>"}   (donde CODE es uno de UsuarioPerfil.Rol.choices)
    Responde: {"ok": true, "rol_label": "<Etiqueta>"}  o {"ok": false, "error": "..."}
    """
    import json

    try:
        payload = json.loads(request.body or "{}")
        code = (payload.get("rol") or "").strip()
        if not code:
            return JsonResponse({"ok": False, "error": "Rol no especificado."}, status=400)

        # Validar que el code estÃ© en choices
        valid_map = dict(UsuarioPerfil.Rol.choices)   # {code: label}
        if code not in valid_map:
            return JsonResponse({"ok": False, "error": "CÃ³digo de rol invÃ¡lido."}, status=400)

        target = get_object_or_404(User, pk=user_id)

        # Protecciones: no tocar superuser ni al propio usuario
        if target.is_superuser or target.id == request.user.id:
            return JsonResponse({"ok": False, "error": "No puedes cambiar este rol."}, status=403)

        perfil = getattr(target, "perfil", None)
        if perfil is None:
            return JsonResponse({"ok": False, "error": "El usuario no tiene perfil."}, status=400)

        # Guardar el CharField
        perfil.rol = code
        perfil.save(update_fields=["rol"])

        return JsonResponse({"ok": True, "rol_label": valid_map[code]})
    except Exception as e:
        return JsonResponse({"ok": False, "error": str(e)}, status=400)

# -------------------- CRUD Sucursal / Bodega --------------------
class AdminOnlyMixin(UserPassesTestMixin):
    """Mixin para CBV que deja pasar sÃ³lo a ADMIN."""
    def test_func(self):
        return _is_admin(self.request.user)
    
    def handle_no_permission(self):
        # Redirige a dashboard con mensaje en lugar de mostrar 403
        messages.error(self.request, "No tienes permisos para realizar esa acciÃ³n.")
        return redirect('dashboard')


class BodegaPermissionMixin(UserPassesTestMixin):
    """Permite acceso si es ADMIN o BODEGUERO (validaciÃ³n por objeto aparte)."""
    def test_func(self):
        try:
            perfil = getattr(self.request.user, 'perfil', None)
            if not self.request.user.is_authenticated:
                return False
            if perfil and perfil.rol == UsuarioPerfil.Rol.ADMIN:
                return True
            if perfil and perfil.rol == UsuarioPerfil.Rol.BODEGUERO:
                return True
            return False
        except Exception:
            return False

    def handle_no_permission(self):
        messages.error(self.request, "No tienes permisos para realizar esa acciÃ³n.")
        return redirect('dashboard')


def admin_required(view_func):
    """Decorador para views basadas en funciones que redirige con mensaje si no es admin."""
    def _wrapped(request, *args, **kwargs):
        if not _is_admin(request.user):
            messages.error(request, "No tienes permisos para realizar esa acciÃ³n.")
            return redirect('dashboard')
        return view_func(request, *args, **kwargs)
    return _wrapped

class SucursalListView(LoginRequiredMixin, ListView):
    model = Sucursal
    template_name = "core/sucursal_list.html"
    context_object_name = "sucursales"
    paginate_by = 20  # por defecto

    def get_paginate_by(self, queryset):
        """
        Permite ?page_size= en la URL (mÃ¡x 100).
        """
        try:
            size = int(self.request.GET.get("page_size", self.paginate_by))
        except (TypeError, ValueError):
            size = self.paginate_by
        return max(1, min(size, 100))

    def get_queryset(self):
        q = (self.request.GET.get("q") or "").strip()

        # OJO con los related_name que tÃº dejaste en tus modelos:
        #   Sucursal  -> ubicaciones_sucursal   (FK en Ubicacion)
        #   Ubicacion -> stocks_ubicacion       (FK en Stock)
        #
        # Entonces el stock total por sucursal se puede sacar asÃ­:
        qs = (
            Sucursal.objects
            .select_related("bodega")  # para mostrar cÃ³digo/nombre de la bodega
            .prefetch_related(
                "ubicaciones",            # lista de ubicaciones de esa sucursal
                "ubicaciones__stocks",  # stocks por ubicación
            )
            .annotate(
                # suma de todas las cantidades en ESE sucursal
                total_stock=Coalesce(
                    Sum("ubicaciones__stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                ),
                # cuÃ¡ntas ubicaciones tiene esa sucursal
                ubicaciones_count=Count("ubicaciones", distinct=True),
                # cuÃ¡ntos productos tiene linkeados por M2M
                productos_count=Count("productos", distinct=True),
            )
            .only("id", "codigo", "nombre", "ciudad", "region", "pais", "activo", "bodega__codigo", "bodega__nombre")
            .order_by(Lower("codigo").asc())
        )

        if q:
            qs = qs.filter(
                Q(codigo__icontains=q) |
                Q(nombre__icontains=q) |
                Q(ciudad__icontains=q) |
                Q(region__icontains=q) |
                Q(bodega__codigo__icontains=q) |
                Q(bodega__nombre__icontains=q)
            )

        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        q = (self.request.GET.get("q") or "").strip()
        ctx["q"] = q
        ctx["has_filters"] = bool(q)
        ctx["total"] = self.get_queryset().count()
        ctx["page_size"] = self.get_paginate_by(self.get_queryset())
        return ctx

class SucursalCreateView(LoginRequiredMixin, AdminOnlyMixin, SuccessMessageMixin, CreateView):
    model = Sucursal
    form_class = SucursalForm
    template_name = "core/sucursal_form.html"
    success_message = "Sucursal creada correctamente."

    def get_success_url(self):
        return reverse_lazy("sucursal-list")


class SucursalUpdateView(LoginRequiredMixin, AdminOnlyMixin, SuccessMessageMixin, UpdateView):
    model = Sucursal
    form_class = SucursalForm
    template_name = "core/sucursal_form.html"
    success_message = "Sucursal actualizada correctamente."

    def get_success_url(self):
        return reverse_lazy("sucursal-list")


class SucursalDeleteView(LoginRequiredMixin, AdminOnlyMixin, SuccessMessageMixin, DeleteView):
    model = Sucursal
    template_name = "core/sucursal_confirm_delete.html"
    success_url = reverse_lazy("sucursal-list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Sucursal eliminada correctamente.")
        return super().delete(request, *args, **kwargs)

class BodegaListView(LoginRequiredMixin, ListView):
    model = Bodega
    template_name = "core/bodega_list.html"
    context_object_name = "bodegas"
    paginate_by = 20

    def get_paginate_by(self, queryset):
        try:
            size = int(self.request.GET.get("page_size", self.paginate_by))
        except (TypeError, ValueError):
            size = self.paginate_by
        return max(1, min(size, 100))

    def get_queryset(self):
        q = (self.request.GET.get("q") or "").strip()

        qs = (
            Bodega.objects
            .prefetch_related("ubicaciones", "sucursales")
            .order_by(Lower("codigo").asc())
        )

        if q:
            qs = qs.filter(
                Q(codigo__icontains=q) |
                Q(nombre__icontains=q) |
                Q(descripcion__icontains=q) |
                Q(sucursales__nombre__icontains=q)
            ).distinct()

        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)

        page_obj = ctx["page_obj"]
        bodegas_page = list(page_obj.object_list)

        # todas las ubicaciones de las bodegas de esta página
        ubi_ids = []
        for b in bodegas_page:
            for u in b.ubicaciones.all():
                ubi_ids.append(u.id)

        # traemos el stock de esas ubicaciones
        stock_qs = (
            Stock.objects
            .filter(ubicacion_bodega_id__in=ubi_ids)
            .select_related("producto", "ubicacion_bodega")
        )

        # indexar por id de ubicacion
        stock_por_ubi = {}
        for s in stock_qs:
            stock_por_ubi.setdefault(s.ubicacion_bodega_id, []).append(s)

        # inyectar a cada bodega
        for b in bodegas_page:
            detalle = []
            for u in b.ubicaciones.all():
                detalle.extend(stock_por_ubi.get(u.id, []))

            b.productos_con_stock = detalle
            b.total_stock = sum(d.cantidad_disponible for d in detalle)
            b.sucursales_count = b.sucursales.count()
            b.ubicaciones_count = b.ubicaciones.count()
            b.productos_count = len({d.producto_id for d in detalle})

        # para el <select> del modal
        ctx["productos"] = (
            Producto.objects
            .only("id", "sku", "nombre")
            .order_by("nombre")
        )

        ctx["q"] = (self.request.GET.get("q") or "").strip()
        return ctx

class BodegaCreateView(LoginRequiredMixin, BodegaPermissionMixin, SuccessMessageMixin, CreateView):
    model = Bodega
    form_class = BodegaForm
    template_name = "core/bodega_form.html"
    success_message = "Bodega creada correctamente."

    def get_success_url(self):
        return reverse_lazy("bodega-list")

    def get_form(self, form_class=None):
        """Restringe 'sucursal' para BODEGUERO (no para ADMIN/superuser)."""
        form = super().get_form(form_class)
        perfil = getattr(self.request.user, "perfil", None)

        # Superusuario o ADMIN: sin restricciÃ³n
        if self.request.user.is_superuser or (perfil and perfil.rol == UsuarioPerfil.Rol.ADMIN):
            return form

        # BODEGUERO: limitar queryset a su sucursal (o ninguno si no tiene)
        if perfil and perfil.rol == UsuarioPerfil.Rol.BODEGUERO:
            if getattr(perfil, "sucursal", None):
                form.fields["sucursal"].queryset = Sucursal.objects.filter(pk=perfil.sucursal.pk)
            else:
                form.fields["sucursal"].queryset = Sucursal.objects.none()
        return form

    def form_valid(self, form):
        """Fuerza la sucursal del BODEGUERO en el servidor (anti-manipulaciÃ³n)."""
        perfil = getattr(self.request.user, "perfil", None)
        if not self.request.user.is_superuser and perfil and perfil.rol == UsuarioPerfil.Rol.BODEGUERO:
            if getattr(perfil, "sucursal", None):
                form.instance.sucursal = perfil.sucursal
            else:
                messages.error(self.request, "No tienes una sucursal asignada.")
                return super().form_invalid(form)
        return super().form_valid(form)


class BodegaUpdateView(LoginRequiredMixin, BodegaPermissionMixin, SuccessMessageMixin, UpdateView):
    model = Bodega
    form_class = BodegaForm
    template_name = "core/bodega_form.html"
    success_message = "Bodega actualizada correctamente."

    def get_success_url(self):
        return reverse_lazy("bodega-list")

    def dispatch(self, request, *args, **kwargs):
        """BODEGUERO solo puede editar bodegas (salvo superuser)."""
        perfil = getattr(request.user, "perfil", None)
        if not request.user.is_superuser and perfil and perfil.rol == UsuarioPerfil.Rol.BODEGUERO:
            obj = self.get_object()
            if not obj or obj.sucursal_id != (perfil.sucursal.id if getattr(perfil, "sucursal", None) else None):
                messages.error(request, "No tienes permisos para editar esta bodega.")
                return redirect("bodega-list")
        return super().dispatch(request, *args, **kwargs)

    def get_form(self, form_class=None):
        """Restringe select de 'sucursal' para BODEGUERO; ADMIN/superuser ven todo."""
        form = super().get_form(form_class)
        perfil = getattr(self.request.user, "perfil", None)

        if self.request.user.is_superuser or (perfil and perfil.rol == UsuarioPerfil.Rol.ADMIN):
            return form

        if perfil and perfil.rol == UsuarioPerfil.Rol.BODEGUERO:
            if getattr(perfil, "sucursal", None):
                form.fields["sucursal"].queryset = Sucursal.objects.filter(pk=perfil.sucursal.pk)
            else:
                form.fields["sucursal"].queryset = Sucursal.objects.none()
        return form

class BodegaDeleteView(LoginRequiredMixin, BodegaPermissionMixin, SuccessMessageMixin, DeleteView):
    model = Bodega
    template_name = "core/bodega_confirm_delete.html"
    success_url = reverse_lazy("bodega-list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Bodega eliminada correctamente.")
        return super().delete(request, *args, **kwargs)

    def dispatch(self, request, *args, **kwargs):
        """BODEGUERO solo puede eliminar bodegas de su sucursal (salvo superuser)."""
        perfil = getattr(request.user, "perfil", None)
        if not request.user.is_superuser and perfil and perfil.rol == UsuarioPerfil.Rol.BODEGUERO:
            obj = self.get_object()
            if not obj or obj.sucursal_id != (perfil.sucursal.id if getattr(perfil, "sucursal", None) else None):
                messages.error(request, "No tienes permisos para eliminar esta bodega.")
                return redirect("bodega-list")
        return super().dispatch(request, *args, **kwargs)


class BodegaDetailView(LoginRequiredMixin, DetailView):
    model = Bodega
    template_name = "core/bodega_detail.html"
    context_object_name = "bodega"

#Area de productos

from core.indicadores import get_eur_clp, get_utm_clp  # Importamos las funciones para obtener las tasas


class ProductsListView(LoginRequiredMixin, ListView):
    model = Producto
    template_name = "core/products.html"
    context_object_name = "productos"
    paginate_by = 20

    def get_queryset(self):
        q = (self.request.GET.get("q") or "").strip()

        qs = (
            Producto.objects
            .select_related("marca", "categoria", "unidad_base")
            .prefetch_related(
                "stocks_producto",
                "stocks_producto__ubicacion",
                "stocks_producto__ubicacion__bodega",
                "stocks_producto__ubicacion__sucursal",
            )
            .annotate(
                total_stock=Coalesce(
                    Sum("stocks_producto__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                ),
                proveedores_count=Count("usuarios_proveedor", distinct=True),
                lotes_count=Count("lotes", distinct=True),
                series_count=Count("series", distinct=True),
            )
            .order_by("nombre")
        )

        if q:
            qs = qs.filter(
                Q(sku__icontains=q)
                | Q(nombre__icontains=q)
                | Q(marca__nombre__icontains=q)
                | Q(categoria__nombre__icontains=q)
            )

        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["q"] = (self.request.GET.get("q") or "").strip()

        # Obtener las tasas de cambio de mindicador.cl
        eur = get_eur_clp()  # CLP por 1 EUR
        utm = get_utm_clp()  # CLP por 1 UTM

        # Calculamos el precio en EUR y UTM en la vista, no en el template
        try:
            ctx["productos"] = [
                {
                    "producto": producto,
                    "precio_eur": round(producto.precio / eur, 2) if eur else None,
                    "precio_utm": round(producto.precio / utm, 4) if utm else None,
                }
                for producto in self.get_queryset()
            ]
        except Exception as e:
            print(f"Error calculando los precios: {e}")
            # En caso de error dejamos los valores en None
            ctx["productos"] = self.get_queryset()

        return ctx



class ProductCreateView(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = Producto
    form_class = ProductoForm
    template_name = "core/product_add.html"
    success_message = "Producto creado correctamente."

    def get_success_url(self):
        return reverse_lazy("products")


class ProductUpdateView(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = Producto
    form_class = ProductoForm
    template_name = "core/product_add.html"
    success_message = "Producto actualizado correctamente."

    def form_valid(self, form):
        resp = super().form_valid(form)
        nxt = self.request.POST.get("next") or self.request.GET.get("next")
        if nxt:
            return redirect(nxt)
        return resp

    def get_success_url(self):
        return reverse_lazy("products")

class ProductUpdateView(LoginRequiredMixin, SuccessMessageMixin, UpdateView):

    model = Producto
    form_class = ProductoForm
    template_name = "core/product_update.html"
    context_object_name = "producto"
    success_message = "Producto actualizado correctamente."

    # ---------- Queryset “rápido” ----------
    def get_queryset(self):
        return (Producto.objects
                .select_related("marca", "categoria", "unidad_base", "tasa_impuesto"))

  
    pk_url_kwarg = "pk"
    slug_url_kwarg = "sku"
    slug_field = "sku"

    def get_object(self, queryset=None):
        qs = queryset or self.get_queryset()
        # 1) Prioridad: si hay <pk> en la URL, úsalo
        pk = self.kwargs.get(self.pk_url_kwarg)
        if pk is not None:
            try:
                return qs.get(pk=pk)
            except Producto.DoesNotExist:
                raise Http404("Producto no encontrado.")
        # 2) Si hay <sku> en la URL, úsalo
        sku_kw = self.kwargs.get(self.slug_url_kwarg)
        if sku_kw:
            try:
                return qs.get(sku=str(sku_kw).upper())
            except Producto.DoesNotExist:
                raise Http404("Producto no encontrado.")
        # 3) Fallback: si llega ?sku= en querystring
        sku_qs = (self.request.GET.get("sku") or "").strip().upper()
        if sku_qs:
            try:
                return qs.get(sku=sku_qs)
            except Producto.DoesNotExist:
                raise Http404("Producto no encontrado.")
        return super().get_object(qs)

    # ---------- Pasar flag al form ----------
    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        # Editar solo metadatos del producto (no stock)
        kwargs["include_stock"] = False
        return kwargs

    # ---------- UX de errores ----------
    def form_invalid(self, form):
        # muestra un resumen arriba sin obligarte a inspeccionar campo por campo
        errors = []
        for name, field_errors in form.errors.items():
            for e in field_errors:
                errors.append(f"{name}: {e}")
        if errors:
            messages.error(self.request, "No se pudo actualizar el producto. Revisa los campos.")
        return super().form_invalid(form)

    # ---------- Redirecciones ----------
    def form_valid(self, form):
        resp = super().form_valid(form)
        nxt = self.request.POST.get("next") or self.request.GET.get("next")
        if nxt:
            return redirect(nxt)
        return resp

    def get_success_url(self):
        # Si hay ?next= úsalo, si no, vuelve al detalle del propio producto
        nxt = self.request.POST.get("next") or self.request.GET.get("next")
        if nxt:
            return nxt
        try:
            return reverse("producto-detail", args=[self.object.pk])
        except Exception:
            return reverse_lazy("products")



class ProductDeleteView(LoginRequiredMixin, DeleteView):
    model = Producto
    template_name = "core/product_confirm_delete.html"  # fallback si navegas directo
    success_url = reverse_lazy("products")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Producto eliminado correctamente.")
        return super().delete(request, *args, **kwargs)


class ProductDetailView(LoginRequiredMixin, DetailView):
    """
    Detalle de producto con:
      - info general del producto
      - métricas (stock total disponible, precio, estado)
      - desglose de stock por sucursal/bodega/ubicación
    """
    model = Producto
    template_name = "core/product_detail.html"
    context_object_name = "producto"

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        producto = self.object

        # Totales (si no hay reservas, neto = disponible)
        agg = (
            Stock.objects
            .filter(producto=producto)
            .aggregate(
                total_disponible=Coalesce(
                    Sum("cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                )
            )
        )
        total_disponible = agg["total_disponible"] or 0
        ctx["totales"] = {
            "total_disponible": total_disponible,
            "total_neto": total_disponible,
        }

        # Desglose por sucursal/bodega/ubicación (campos opcionales seguros)
        resumen = (
            Stock.objects
            .filter(producto=producto)
            .annotate(
                sucursal_codigo=Case(
                    When(ubicacion_sucursal__isnull=False, then=F("ubicacion_sucursal__sucursal__codigo")),
                    default=Value("", output_field=CharField()),
                ),
                sucursal_nombre=Case(
                    When(ubicacion_sucursal__isnull=False, then=F("ubicacion_sucursal__sucursal__nombre")),
                    default=Value("", output_field=CharField()),
                ),
                bodega_codigo=Case(
                    When(ubicacion_bodega__isnull=False, then=F("ubicacion_bodega__bodega__codigo")),
                    default=Value("", output_field=CharField()),
                ),
                bodega_nombre=Case(
                    When(ubicacion_bodega__isnull=False, then=F("ubicacion_bodega__bodega__nombre")),
                    default=Value("", output_field=CharField()),
                ),
                # ubicación física (si existen esos campos)
                sucursal_ubi_codigo=Case(
                    When(ubicacion_sucursal__isnull=False, then=F("ubicacion_sucursal__codigo")),
                    default=Value("", output_field=CharField()),
                ),
                sucursal_ubi_nombre=Case(
                    When(ubicacion_sucursal__isnull=False, then=F("ubicacion_sucursal__nombre")),
                    default=Value("", output_field=CharField()),
                ),
                bodega_ubi_codigo=Case(
                    When(ubicacion_bodega__isnull=False, then=F("ubicacion_bodega__codigo")),
                    default=Value("", output_field=CharField()),
                ),
                bodega_ubi_nombre=Case(
                    When(ubicacion_bodega__isnull=False, then=F("ubicacion_bodega__nombre")),
                    default=Value("", output_field=CharField()),
                ),
            )
            .values(
                "sucursal_codigo", "sucursal_nombre",
                "bodega_codigo", "bodega_nombre",
                "sucursal_ubi_codigo", "sucursal_ubi_nombre",
                "bodega_ubi_codigo", "bodega_ubi_nombre",
            )
            .annotate(
                total_disponible=Coalesce(
                    Sum("cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                ),
                total_neto=F("total_disponible"),
            )
            .order_by(
                "sucursal_codigo",
                "bodega_codigo",
                "sucursal_ubi_codigo",
                "bodega_ubi_codigo",
            )
        )

        ctx["resumen_sucursales"] = resumen
        return ctx
# ----------------------
# CRUD Ubicacion (pÃ¡ginas)
# ----------------------
class UbicacionBodegaListView(LoginRequiredMixin, ListView):
    model = UbicacionBodega
    template_name = "core/ubicacion_bodega_list.html"
    context_object_name = "ubicaciones"
    paginate_by = 20

    def get_queryset(self):
        q = (self.request.GET.get("q") or "").strip()
        bodega_id = (self.request.GET.get("bodega") or "").strip()

        qs = (
            UbicacionBodega.objects.select_related("bodega", "tipo")
            .annotate(
                total_stock=Coalesce(
                    Sum("stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                )
            )
            .order_by("bodega__codigo", "codigo")
        )

        if q:
            qs = qs.filter(Q(codigo__icontains=q) | Q(nombre__icontains=q) | Q(area__icontains=q))

        if bodega_id:
            qs = qs.filter(bodega_id=bodega_id)

        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["bodegas"] = Bodega.objects.all().order_by("codigo")
        ctx["q"] = (self.request.GET.get("q") or "").strip()
        ctx["f_bodega"] = (self.request.GET.get("bodega") or "").strip()
        return ctx


class UbicacionSucursalListView(LoginRequiredMixin, ListView):
    model = UbicacionSucursal
    template_name = "core/ubicacion_sucursal_list.html"
    context_object_name = "ubicaciones"
    paginate_by = 20

    def get_queryset(self):
        q = (self.request.GET.get("q") or "").strip()
        sucursal_id = (self.request.GET.get("sucursal") or "").strip()

        qs = (
            UbicacionSucursal.objects.select_related("sucursal", "tipo")
            .annotate(
                total_stock=Coalesce(
                    Sum("stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                )
            )
            .order_by("sucursal__codigo", "codigo")
        )

        if q:
            qs = qs.filter(Q(codigo__icontains=q) | Q(nombre__icontains=q) | Q(area__icontains=q))

        if sucursal_id:
            qs = qs.filter(sucursal_id=sucursal_id)

        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx["sucursales"] = Sucursal.objects.all().order_by("codigo")
        ctx["q"] = (self.request.GET.get("q") or "").strip()
        ctx["f_sucursal"] = (self.request.GET.get("sucursal") or "").strip()
        return ctx


class UbicacionBodegaCreateView(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = UbicacionBodega
    form_class = UbicacionBodegaForm
    template_name = "core/ubicacion_form.html"
    success_message = "Ubicación de bodega creada."
    success_url = reverse_lazy("ubicacion-bodega-list")


class UbicacionBodegaUpdateView(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = UbicacionBodega
    form_class = UbicacionBodegaForm
    template_name = "core/ubicacion_form.html"
    success_message = "Ubicación de bodega actualizada."
    success_url = reverse_lazy("ubicacion-bodega-list")


class UbicacionBodegaDeleteView(LoginRequiredMixin, DeleteView):
    model = UbicacionBodega
    template_name = "core/confirm_delete.html"
    success_url = reverse_lazy("ubicacion-bodega-list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Ubicación eliminada.")
        return super().delete(request, *args, **kwargs)


class UbicacionSucursalCreateView(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = UbicacionSucursal
    form_class = UbicacionSucursalForm
    template_name = "core/ubicacion_form.html"
    success_message = "Ubicación de sucursal creada."
    success_url = reverse_lazy("ubicacion-sucursal-list")


class UbicacionSucursalUpdateView(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = UbicacionSucursal
    form_class = UbicacionSucursalForm
    template_name = "core/ubicacion_form.html"
    success_message = "Ubicación de sucursal actualizada."
    success_url = reverse_lazy("ubicacion-sucursal-list")


class UbicacionSucursalDeleteView(LoginRequiredMixin, DeleteView):
    model = UbicacionSucursal
    template_name = "core/confirm_delete.html"
    success_url = reverse_lazy("ubicacion-sucursal-list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Ubicación eliminada.")
        return super().delete(request, *args, **kwargs)

# ------------------------------------
#   TipoUbicacion con modal
# ------------------------------------
# Los modales usan <dialog> y cargan estas vistas que devuelven la pÃ¡gina completa,
# pero con templates chicos pensados para presentarse en un modal.

class TipoUbicacionCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = TipoUbicacion
    form_class = TipoUbicacionForm
    template_name = "core/partials/tipo_form_modal.html"
    success_message = "Tipo de ubicaciÃ³n creado."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("bodega-list")


class TipoUbicacionUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = TipoUbicacion
    form_class = TipoUbicacionForm
    template_name = "core/partials/tipo_form_modal.html"
    success_message = "Tipo de ubicaciÃ³n actualizado."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("bodega-list")


class TipoUbicacionDeleteModal(LoginRequiredMixin, DeleteView):
    model = TipoUbicacion
    template_name = "core/partials/confirm_modal.html"
    success_url = reverse_lazy("bodega-list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Tipo de ubicaciÃ³n eliminado.")
        return super().delete(request, *args, **kwargs)

# ======================
# Marca
# ======================
class MarcaCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = Marca
    form_class = MarcaForm
    template_name = "core/partials/marca_form_modal.html"
    success_message = "Marca creada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class MarcaUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = Marca
    form_class = MarcaForm
    template_name = "core/partials/marca_form_modal.html"
    success_message = "Marca actualizada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class MarcaDeleteModal(LoginRequiredMixin, DeleteView):
    model = Marca
    template_name = "core/partials/confirm_modal.html"
    success_url = reverse_lazy("products")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Marca eliminada.")
        return super().delete(request, *args, **kwargs)

# ======================
# Unidad de Medida
# ======================
class UnidadMedidaCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = UnidadMedida
    form_class = UnidadMedidaForm
    template_name = "core/partials/unidad_form_modal.html"
    success_message = "Unidad de medida creada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class UnidadMedidaUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = UnidadMedida
    form_class = UnidadMedidaForm
    template_name = "core/partials/unidad_form_modal.html"
    success_message = "Unidad de medida actualizada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class UnidadMedidaDeleteModal(LoginRequiredMixin, DeleteView):
    model = UnidadMedida
    template_name = "core/partials/confirm_modal.html"
    success_url = reverse_lazy("products")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Unidad de medida eliminada.")
        return super().delete(request, *args, **kwargs)

# ======================
# Tasa de Impuesto
# ======================
class TasaImpuestoCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = TasaImpuesto
    form_class = TasaImpuestoForm
    template_name = "core/partials/tasa_form_modal.html"
    success_message = "Tasa de impuesto creada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class TasaImpuestoUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = TasaImpuesto
    form_class = TasaImpuestoForm
    template_name = "core/partials/tasa_form_modal.html"
    success_message = "Tasa de impuesto actualizada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class TasaImpuestoDeleteModal(LoginRequiredMixin, DeleteView):
    model = TasaImpuesto
    template_name = "core/partials/confirm_modal.html"
    success_url = reverse_lazy("products")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Tasa de impuesto eliminada.")
        return super().delete(request, *args, **kwargs)

# ======================
# CategorÃ­a de Producto
# ======================
class CategoriaProductoCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = CategoriaProducto
    form_class = CategoriaProductoForm
    template_name = "core/partials/categoria_form_modal.html"
    success_message = "CategorÃ­a creada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class CategoriaProductoUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = CategoriaProducto
    form_class = CategoriaProductoForm
    template_name = "core/partials/categoria_form_modal.html"
    success_message = "CategorÃ­a actualizada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")


class CategoriaProductoDeleteModal(LoginRequiredMixin, DeleteView):
    model = CategoriaProducto
    template_name = "core/partials/confirm_modal.html"
    success_url = reverse_lazy("products")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "CategorÃ­a eliminada.")
        return super().delete(request, *args, **kwargs)
    
# ===== LoteProducto (modales) =====
class LoteCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = LoteProducto
    form_class = LoteProductoForm
    template_name = "core/partials/lote_form_modal.html"
    success_message = "Lote creado."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")

class LoteUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = LoteProducto
    form_class = LoteProductoForm
    template_name = "core/partials/lote_form_modal.html"
    success_message = "Lote actualizado."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")

class LoteDeleteModal(LoginRequiredMixin, SuccessMessageMixin, DeleteView):
    model = LoteProducto
    template_name = "core/partials/confirm_delete_modal.html"
    success_message = "Lote eliminado."
    # messages en DeleteView requieren manejo en form_valid o post_delete signal; si usas messages en template, puedes mostrar el texto allÃ­.

# ===== SerieProducto (modales) =====
class SerieCreateModal(LoginRequiredMixin, SuccessMessageMixin, CreateView):
    model = SerieProducto
    form_class = SerieProductoForm
    template_name = "core/partials/serie_form_modal.html"
    success_message = "Serie creada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")

class SerieUpdateModal(LoginRequiredMixin, SuccessMessageMixin, UpdateView):
    model = SerieProducto
    form_class = SerieProductoForm
    template_name = "core/partials/serie_form_modal.html"
    success_message = "Serie actualizada."

    def get_success_url(self):
        return self.request.GET.get("next") or reverse_lazy("products")

class SerieDeleteModal(LoginRequiredMixin, SuccessMessageMixin, DeleteView):
    model = SerieProducto
    template_name = "core/partials/confirm_delete_modal.html"
    success_message = "Serie eliminada."

def test_scanner(request):
    return render(request, "core/test_scanner.html")


@login_required
def products(request):
    productos = (
        Producto.objects
        .select_related("marca", "categoria", "unidad_base", "tasa_impuesto")
        .annotate(
            lotes_count=Count("lotes", distinct=True),
            series_count=Count("series", distinct=True),
            proveedores_count=Count("productousuarioproveedor", distinct=True),
        )
        .order_by("nombre")
    )
    return render(request, "core/products.html", {
        "productos": productos,
        "q": (request.GET.get("q") or "").strip(),
    })

@login_required
def productos_por_bodega(request, bodega_id):
    try:
        bodega = Bodega.objects.get(id=bodega_id)
    except Bodega.DoesNotExist:
        return render(request, "core/error.html", {"error": "Bodega no encontrada."})

    # ubicaciones de esa bodega
    ubicaciones_en_bodega = bodega.ubicaciones.all()

    if not ubicaciones_en_bodega:
        return render(
            request,
            "core/error.html",
            {"error": "No se encontraron ubicaciones asociadas a esta bodega."},
        )

    # productos que tienen stock en alguna de esas ubicaciones
    productos = (
        Producto.objects.filter(stocks__ubicacion_bodega__bodega=bodega)
        .distinct()
        .annotate(
            stock_total=Coalesce(
                Sum("stocks__cantidad_disponible"),
                Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
            )
        )
    )

    return render(
        request,
        "core/productos_por_bodega.html",
        {
            "bodega": bodega,
            "ubicaciones_en_bodega": ubicaciones_en_bodega,
            "productos": productos,
        },
    )


@login_required
def product_list(request):
    q = (request.GET.get("q") or "").strip()

    qs = (
        Producto.objects
        .all()
        .annotate(
            # usa los nombres REALES que tienes en el modelo
            proveedores_count=Count("usuarios_proveedor", distinct=True),
            lotes_count=Count("lotes", distinct=True),
            series_count=Count("series", distinct=True),
        )
        .order_by("sku")
    )

    if q:
        qs = qs.filter(
            Q(sku__icontains=q) |
            Q(nombre__icontains=q) |
            Q(marca__nombre__icontains=q) |
            Q(categoria__nombre__icontains=q)
        )

    paginator = Paginator(qs, 20)
    page_number = request.GET.get("page")
    page_obj = paginator.get_page(page_number)

    return render(
        request,
        "core/products.html",     # tu template
        {
            "q": q,
            "productos": page_obj.object_list,
            "page_obj": page_obj,
            "is_paginated": page_obj.has_other_pages(),
        },
    )

# ---------- Utilidades comunes ----------

def _is_fetch(request):
    # Tu helper JS manda 'X-Requested-With: fetch'
    return request.headers.get("X-Requested-With") == "fetch"

def _json_or_redirect(request, ok: bool, msg: str, redirect_to: str = None, extra: dict | None = None):
    payload = {"ok": ok, "message": msg}
    if extra:
        payload.update(extra)
    if _is_fetch(request):
        status = 200 if ok else 400
        return JsonResponse(payload, status=status)
    if ok:
        messages.success(request, msg)
    else:
        messages.error(request, msg)
    return redirect(redirect_to or request.META.get("HTTP_REFERER", "/"))
from decimal import Decimal

# === Config: pon aquÃ­ el nombre real del campo de reserva en Producto (si existe)
RESERVA_FIELD = "reserva"   # ej. "reservado" si tu modelo lo llama asÃ­


def _get_reserva(producto):
    """Obtiene la reserva desde Producto (0 si no existe el campo)."""
    return Decimal(getattr(producto, RESERVA_FIELD, 0) or 0)


def _set_reserva(producto, value):
    """Setea la reserva en Producto (si el campo existe). Ignora si no existe."""
    if hasattr(producto, RESERVA_FIELD):
        setattr(producto, RESERVA_FIELD, Decimal(value or 0))


def _recalcular_total_producto(producto):
    """
    VersiÃ³n sin tabla Stock.
    Asegura que 'stock' y 'reserva' existan y sean decimales >= 0.
    Ãštil como 'normalizador' tras operaciones.
    """
    disponible = Decimal(getattr(producto, "stock", 0) or 0)
    reservado  = _get_reserva(producto)

    if disponible < 0:
        disponible = Decimal(0)
    if reservado < 0:
        reservado = Decimal(0)

    producto.stock = disponible
    _set_reserva(producto, reservado)

    # Guardar solo los campos que existan
    update_fields = ["stock"]
    if hasattr(producto, RESERVA_FIELD):
        update_fields.append(RESERVA_FIELD)
    producto.save(update_fields=update_fields)


class _ProductoStockProxy:
    """
    Proxy de compatibilidad para cÃ³digo legacy que esperaba un objeto Stock.
    Lee/escribe directamente en Producto.stock y Producto.<RESERVA_FIELD>.
    Tiene un mÃ©todo .save(update_fields=...) para imitar la API.
    """
    def __init__(self, producto):
        self._p = producto

    @property
    def producto(self):
        return self._p

    @property
    def cantidad_disponible(self):
        return Decimal(self._p.stock or 0)

    @cantidad_disponible.setter
    def cantidad_disponible(self, value):
        self._p.stock = Decimal(value or 0)

    @property
    def cantidad_reservada(self):
        return _get_reserva(self._p)

    @cantidad_reservada.setter
    def cantidad_reservada(self, value):
        _set_reserva(self._p, value)

    def save(self, update_fields=None):
        # Mapea update_fields del "Stock" a campos reales de Producto
        fields = set(update_fields or [])
        mapped = set()
        if not fields:
            # Guardar ambos si existen
            mapped.add("stock")
            if hasattr(self._p, RESERVA_FIELD):
                mapped.add(RESERVA_FIELD)
        else:
            if "cantidad_disponible" in fields or "stock" in fields:
                mapped.add("stock")
            if "cantidad_reservada" in fields or RESERVA_FIELD in fields:
                if hasattr(self._p, RESERVA_FIELD):
                    mapped.add(RESERVA_FIELD)

        if not mapped:
            # fallback por seguridad
            mapped.add("stock")
            if hasattr(self._p, RESERVA_FIELD):
                mapped.add(RESERVA_FIELD)

        self._p.save(update_fields=list(mapped))


def _get_or_create_stock(producto, ubicacion_id: int | None = None):
    """
    Compatibilidad sin tabla Stock:
    Ignora la ubicaciÃ³n y devuelve un proxy ligado al Producto.
    AsÃ­ tu cÃ³digo legacy (que hacÃ­a .cantidad_disponible += x; .save()) sigue funcionando.
    """
    return _ProductoStockProxy(producto)


# ====== Helpers â€œnuevosâ€ para operar stock directamente en Producto ======

def ajustar_stock(producto, delta_disponible=0, delta_reservado=0, guardar=True):
    """
    Suma/resta cantidades directamente en Producto.
    Uso:
      ajustar_stock(prod, delta_disponible=+5)       # entrada de stock
      ajustar_stock(prod, delta_disponible=-2)       # salida de stock
      ajustar_stock(prod, delta_reservado=+3)        # reservar 3
      ajustar_stock(prod, delta_reservado=-1)        # liberar 1 de reserva
    """
    disponible = Decimal(getattr(producto, "stock", 0) or 0) + Decimal(delta_disponible or 0)
    reservado  = _get_reserva(producto) + Decimal(delta_reservado or 0)

    if disponible < 0:
        disponible = Decimal(0)
    if reservado < 0:
        reservado = Decimal(0)

    producto.stock = disponible
    _set_reserva(producto, reservado)

    if guardar:
        update_fields = ["stock"]
        if hasattr(producto, RESERVA_FIELD):
            update_fields.append(RESERVA_FIELD)
        producto.save(update_fields=update_fields)
    return producto


def set_stock(producto, disponible=None, reservado=None, guardar=True):
    """
    Seteo directo (absoluto) de stock/reserva en Producto.
    """
    if disponible is not None:
        d = Decimal(disponible or 0)
        producto.stock = d if d > 0 else Decimal(0)

    if reservado is not None and hasattr(producto, RESERVA_FIELD):
        r = Decimal(reservado or 0)
        _set_reserva(producto, r if r > 0 else Decimal(0))

    if guardar:
        update_fields = ["stock"]
        if hasattr(producto, RESERVA_FIELD):
            update_fields.append(RESERVA_FIELD)
        producto.save(update_fields=update_fields)
    return producto

# ---------- Consulta: ver stock por producto (tu lÃ³gica, con pequeÃ±os ajustes) ----------
from django.db.models import Sum, F



from django.db.models import (
    Sum, Value, DecimalField, F, Case, When, CharField
)
from django.db.models.functions import Coalesce


@login_required
def stock_por_producto(request):
    """
    Consulta de stock por SKU.
    Muestra:
      - totales globales
      - desglose por sucursal (si viene de ubicacion_sucursal)
      - desglose por bodega (si viene de ubicacion_bodega)
    """
    sku = (request.GET.get("sku") or "").strip().upper()
    producto = None
    totales = None
    resumen_sucursales = []

    if sku:
        try:
            producto = (
                Producto.objects
                .select_related("marca", "categoria")
                .get(sku=sku)
            )

            # 1) TOTAL GLOBAL DEL PRODUCTO
            agg = (
                Stock.objects
                .filter(producto=producto)
                .aggregate(
                    total_disponible=Coalesce(
                        Sum("cantidad_disponible"),
                        Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                    )
                )
            )
            disponible = agg["total_disponible"] or 0

            totales = {
                "total_disponible": disponible,
                # como no tienes reservas en Stock, el neto es igual al disponible
                "total_neto": disponible,
            }

            # 2) DESGLOSE POR ORIGEN DE LA UBICACIÓN
            # Creamos columnas "virtuales" para poder agrupar aunque haya
            # registros que vienen SOLO de bodega o SOLO de sucursal
            resumen_sucursales = (
                Stock.objects
                .filter(producto=producto)
                .annotate(
                    # si viene de sucursal
                    sucursal_codigo=Case(
                        When(ubicacion_sucursal__isnull=False,
                             then=F("ubicacion_sucursal__sucursal__codigo")),
                        default=Value("", output_field=CharField()),
                    ),
                    sucursal_nombre=Case(
                        When(ubicacion_sucursal__isnull=False,
                             then=F("ubicacion_sucursal__sucursal__nombre")),
                        default=Value("", output_field=CharField()),
                    ),
                    # si viene de bodega
                    bodega_codigo=Case(
                        When(ubicacion_bodega__isnull=False,
                             then=F("ubicacion_bodega__bodega__codigo")),
                        default=Value("", output_field=CharField()),
                    ),
                    bodega_nombre=Case(
                        When(ubicacion_bodega__isnull=False,
                             then=F("ubicacion_bodega__bodega__nombre")),
                        default=Value("", output_field=CharField()),
                    ),
                )
                .values(
                    "sucursal_codigo",
                    "sucursal_nombre",
                    "bodega_codigo",
                    "bodega_nombre",
                )
                .annotate(
                    total_disponible=Coalesce(
                        Sum("cantidad_disponible"),
                        Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                    ),
                    # neto = disponible, porque no hay reservas en el modelo
                    total_neto=F("total_disponible"),
                )
                .order_by("sucursal_codigo", "bodega_codigo")
            )

        except Producto.DoesNotExist:
            messages.error(request, f"No se encontró ningún producto con SKU '{sku}'.")

    return render(
        request,
        "core/stock_producto.html",
        {
            "sku": sku,
            "producto": producto,
            "totales": totales,
            "resumen_sucursales": resumen_sucursales,
        },
    )





@login_required
@transaction.atomic
def stock_ajuste(request):
    if request.method != "POST":
        return HttpResponseBadRequest("Método no permitido")

    try:
        pid = int(request.POST.get("producto_id"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Producto inválido.")

    try:
        cantidad = float(request.POST.get("cantidad"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Cantidad inválida.")

    ubicacion_id = request.POST.get("ubicacion")  # puede ser de bodega o de sucursal
    producto = get_object_or_404(Producto, pk=pid)

    if ubicacion_id:
        stock, _, _, _ = _get_or_create_stock(producto, int(ubicacion_id))
        stock.cantidad_disponible = F("cantidad_disponible") + Decimal(cantidad)
        stock.save(update_fields=["cantidad_disponible"])
    else:
        # sin ubicación → directo al producto
        producto.stock = max(0, int((producto.stock or 0) + cantidad))
        producto.save(update_fields=["stock"])

    _recalcular_stock_global(producto)

    return _json_or_redirect(
        request,
        True,
        f"Ajuste aplicado: {cantidad:+g} {producto.sku}",
        redirect_to=reverse("products"),
    )


@login_required
@transaction.atomic
def stock_entrada(request):
    if request.method != "POST":
        return HttpResponseBadRequest("Método no permitido")

    try:
        pid = int(request.POST.get("producto_id"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Producto inválido.")

    try:
        cantidad = float(request.POST.get("cantidad"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Cantidad inválida.")

    if cantidad <= 0:
        return _json_or_redirect(request, False, "La cantidad debe ser mayor a 0.")

    ubicacion_id = request.POST.get("ubicacion")
    producto = get_object_or_404(Producto, pk=pid)

    if ubicacion_id:
        stock, _, _, _ = _get_or_create_stock(producto, int(ubicacion_id))
        stock.cantidad_disponible = F("cantidad_disponible") + Decimal(cantidad)
        stock.save(update_fields=["cantidad_disponible"])
    else:
        producto.stock = max(0, int((producto.stock or 0) + cantidad))
        producto.save(update_fields=["stock"])

    _recalcular_stock_global(producto)

    return _json_or_redirect(
        request,
        True,
        f"Entrada registrada (+{cantidad:g}) para {producto.sku}",
        redirect_to=reverse("products"),
    )


@login_required
@transaction.atomic
def stock_transferir(request):
    """
    Transfiere stock entre ubicaciones (pueden ser de tablas distintas).
    """
    if request.method != "POST":
        return HttpResponseBadRequest("Método no permitido")

    try:
        pid = int(request.POST.get("producto_id"))
        origen = int(request.POST.get("origen"))
        destino = int(request.POST.get("destino"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Parámetros inválidos.")

    if origen == destino:
        return _json_or_redirect(request, False, "Origen y destino no pueden ser iguales.")

    try:
        cantidad = float(request.POST.get("cantidad"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Cantidad inválida.")

    if cantidad <= 0:
        return _json_or_redirect(request, False, "La cantidad debe ser mayor a 0.")

    producto = get_object_or_404(Producto, pk=pid)

    stock_origen, _, _, _ = _get_or_create_stock(producto, origen)
    stock_destino, _, _, _ = _get_or_create_stock(producto, destino)

    # necesitamos el valor real
    stock_origen.refresh_from_db()

    if stock_origen.cantidad_disponible < cantidad:
        return _json_or_redirect(request, False, "Stock insuficiente en origen.")

    stock_origen.cantidad_disponible = Decimal(stock_origen.cantidad_disponible) - Decimal(cantidad)
    stock_origen.save(update_fields=["cantidad_disponible"])

    stock_destino.cantidad_disponible = Decimal(stock_destino.cantidad_disponible) + Decimal(cantidad)
    stock_destino.save(update_fields=["cantidad_disponible"])

    _recalcular_stock_global(producto)

    return _json_or_redirect(
        request,
        True,
        f"Transferidos {cantidad:g} de {producto.sku}",
        redirect_to=reverse("products"),
    )


@login_required
@transaction.atomic
def stock_recuento(request):
    if request.method != "POST":
        return HttpResponseBadRequest("Método no permitido")

    try:
        pid = int(request.POST.get("producto_id"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Producto inválido.")

    try:
        cantidad_real = float(request.POST.get("cantidad_real"))
    except (TypeError, ValueError):
        return _json_or_redirect(request, False, "Cantidad inválida.")

    ubicacion_id = request.POST.get("ubicacion")
    producto = get_object_or_404(Producto, pk=pid)

    if ubicacion_id:
        stock, _, _, _ = _get_or_create_stock(producto, int(ubicacion_id))
        stock.cantidad_disponible = Decimal(cantidad_real)
        stock.save(update_fields=["cantidad_disponible"])
    else:
        producto.stock = max(0, int(cantidad_real))
        producto.save(update_fields=["stock"])

    _recalcular_stock_global(producto)

    return _json_or_redirect(
        request,
        True,
        f"Recuento guardado ({cantidad_real:g}) para {producto.sku}",
        redirect_to=reverse("products"),
    )

# Configurar el logger
logger = logging.getLogger(__name__)


def _recalcular_stock_global(producto: Producto) -> None:
    """
    Suma TODO el stock por ubicaciones y lo deja en producto.stock.
    Evita el error de 'mixed types' forzando DecimalField.
    """
    agg = (
        Stock.objects
        .filter(producto=producto)
        .aggregate(
            total=Coalesce(
                Sum("cantidad_disponible"),
                Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
            )
        )
    )
    total = agg["total"] or 0
    producto.stock = int(total)
    producto.save(update_fields=["stock"])


@require_GET
def ajax_sucursales_y_productos(request):
    bodega_id = request.GET.get("bodega_id")
    if not bodega_id:
        return JsonResponse({"error": "Falta bodega_id"}, status=400)

    try:
        bodega = Bodega.objects.get(pk=bodega_id)
    except Bodega.DoesNotExist:
        return JsonResponse({"error": "Bodega no encontrada"}, status=404)

    sucursales = list(
        bodega.sucursales.all()
        .order_by("codigo")
        .values("id", "codigo", "nombre")
    )

    productos = (
        Producto.objects.filter(stocks__ubicacion_bodega__bodega=bodega)
        .annotate(
            stock_total=Coalesce(
                Sum("stocks__cantidad_disponible"),
                Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
            )
        )
        .values("id", "sku", "nombre", "stock_total")
        .distinct()
    )

    return JsonResponse({"sucursales": sucursales, "productos": list(productos)})


def _resolver_ubicacion(pk: int):
    """
    Recibe un PK y trata de adivinar si es una ubicacion de bodega o de sucursal.
    Devuelve ('bodega', obj) o ('sucursal', obj).
    Lanza Http404 si no existe.
    """
    try:
        ub_bod = UbicacionBodega.objects.get(pk=pk)
        return "bodega", ub_bod
    except UbicacionBodega.DoesNotExist:
        pass
    try:
        ub_suc = UbicacionSucursal.objects.get(pk=pk)
        return "sucursal", ub_suc
    except UbicacionSucursal.DoesNotExist:
        raise Http404("Ubicación no encontrada")


def _get_or_create_stock(producto: Producto, ubicacion_pk: int | None = None):
    """
    Devuelve (stock, creado, tipo, ubicacion_instance)
    - si viene ubicacion_pk, intenta en bodega, luego sucursal
    - si NO viene ubicacion_pk → trabajamos solo en producto.stock (compat)
    """
    if ubicacion_pk is None:
        # modo compat: no hay ubicación → operamos en el campo producto.stock
        # devolvemos un "fake" con la misma API que Stock
        class _Proxy:
            def __init__(self, prod):
                self._p = prod

            @property
            def cantidad_disponible(self):
                return Decimal(self._p.stock or 0)

            @cantidad_disponible.setter
            def cantidad_disponible(self, val):
                self._p.stock = int(Decimal(val or 0))
                self._p.save(update_fields=["stock"])

            def save(self, update_fields=None):
                self._p.save(update_fields=["stock"])

        return _Proxy(producto), False, "producto", producto

    tipo, ubi = _resolver_ubicacion(ubicacion_pk)
    if tipo == "bodega":
        stock, created = Stock.objects.get_or_create(
            producto=producto,
            ubicacion_bodega=ubi,
            defaults={"cantidad_disponible": 0},
        )
        return stock, created, tipo, ubi
    else:
        stock, created = Stock.objects.get_or_create(
            producto=producto,
            ubicacion_sucursal=ubi,
            defaults={"cantidad_disponible": 0},
        )
        return stock, created, tipo, ubi


def _recalcular_stock_global(producto: Producto) -> None:
    """
    Suma TODO el stock por ubicaciones (bodega + sucursal) y lo deja en producto.stock.
    """
    agg = (
        Stock.objects.filter(producto=producto)
        .aggregate(
            total=Coalesce(
                Sum("cantidad_disponible"),
                Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
            )
        )
    )
    total = agg["total"] or 0
    producto.stock = int(total)
    producto.save(update_fields=["stock"])

@login_required
def bodega_a_sucursal(request):
    bodegas = (
        Bodega.objects.prefetch_related("sucursales", "ubicaciones").order_by("codigo")
    )

    if request.method == "POST":
        bodega_id = request.POST.get("bodega")
        sucursal_id = request.POST.get("sucursal")
        producto_id = request.POST.get("producto")
        cantidad_raw = request.POST.get("cantidad")

        if not all([bodega_id, sucursal_id, producto_id, cantidad_raw]):
            return render(request, "core/Movimientos/bodega_a_sucursal.html",
                          {"bodegas": bodegas, "error": "Faltan datos en el formulario."})

        try:
            cantidad = int(cantidad_raw)
        except (ValueError, TypeError):
            return render(request, "core/Movimientos/bodega_a_sucursal.html",
                          {"bodegas": bodegas, "error": "La cantidad debe ser un número entero."})

        if cantidad <= 0:
            return render(request, "core/Movimientos/bodega_a_sucursal.html",
                          {"bodegas": bodegas, "error": "La cantidad debe ser mayor que 0."})

        try:
            bodega = Bodega.objects.get(pk=bodega_id)
            sucursal = Sucursal.objects.get(pk=sucursal_id, bodega=bodega)
            producto = Producto.objects.get(pk=producto_id)
        except (Bodega.DoesNotExist, Sucursal.DoesNotExist, Producto.DoesNotExist):
            return render(request, "core/Movimientos/bodega_a_sucursal.html",
                          {"bodegas": bodegas, "error": "Alguna entidad seleccionada no existe."})

        ubi_origen = bodega.ubicaciones.first()
        ubi_destino = sucursal.ubicaciones.first()
        if not ubi_origen or not ubi_destino:
            return render(request, "core/Movimientos/bodega_a_sucursal.html",
                          {"bodegas": bodegas, "error": "Faltan ubicaciones en bodega o sucursal."})

        with transaction.atomic():
            # ORIGEN (bodega)
            stock_origen = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_bodega=ubi_origen).first()
            )
            if not stock_origen:
                stock_origen = Stock.objects.create(
                    producto=producto, ubicacion_bodega=ubi_origen,
                    cantidad_disponible=Decimal("0"),
                )

            if stock_origen.cantidad_disponible < cantidad:
                return render(request, "core/Movimientos/bodega_a_sucursal.html",
                              {"bodegas": bodegas,
                               "error": f"No hay stock suficiente en la bodega. Disponible: {stock_origen.cantidad_disponible}."})

            # DESTINO (sucursal)
            stock_destino = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_sucursal=ubi_destino).first()
            )

            if stock_destino and stock_destino.id == stock_origen.id:
                stock_origen.ubicacion_sucursal = None
                stock_origen.save(update_fields=["ubicacion_sucursal"])
                stock_destino = Stock.objects.create(
                    producto=producto, ubicacion_sucursal=ubi_destino,
                    cantidad_disponible=Decimal("0"),
                )
            elif not stock_destino:
                stock_destino = Stock.objects.create(
                    producto=producto, ubicacion_sucursal=ubi_destino,
                    cantidad_disponible=Decimal("0"),
                )

            # aplicar movimiento (tu lógica de stock)
            stock_origen.cantidad_disponible -= Decimal(cantidad)
            stock_origen.save(update_fields=["cantidad_disponible"])
            stock_destino.cantidad_disponible += Decimal(cantidad)
            stock_destino.save(update_fields=["cantidad_disponible"])

            # === KÁRDEX: crear MovimientoStock TRANSFERENCIA ===
            try:
                MovimientoStock.objects.create(
                    tipo_movimiento=_tm("TRANSFERENCIA"),
                    producto=producto,
                    ubicacion_bodega_desde=ubi_origen,
                    ubicacion_sucursal_desde=None,
                    ubicacion_bodega_hasta=None,
                    ubicacion_sucursal_hasta=ubi_destino,
                    lote=None,  # ajusta si manejas lotes/series
                    serie=None,
                    cantidad=Decimal(cantidad),
                    unidad=_unidad_default(),
                    tabla_referencia="vista:bodega_a_sucursal",
                    referencia_id=None,
                    creado_por=request.user,
                    notas=f"Bodega {bodega.codigo} → Sucursal {sucursal.codigo}",
                )
            except TipoMovimiento.DoesNotExist:
                pass

        # recalcular stock global (tu lógica)
        total_prod = (
            Stock.objects.filter(producto=producto).aggregate(
                t=Coalesce(Sum("cantidad_disponible"),
                           Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)))
            )["t"]
        ) or 0
        producto.stock = int(total_prod)
        producto.save(update_fields=["stock"])

        sucursales_de_bodega = bodega.sucursales.all().order_by("codigo")
        productos_de_bodega = (
            Producto.objects.filter(stocks__ubicacion_bodega__bodega=bodega)
            .annotate(
                stock_total=Coalesce(
                    Sum("stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                )
            ).distinct()
        )

        return render(request, "core/Movimientos/bodega_a_sucursal.html", {
            "bodegas": bodegas,
            "sucursales": sucursales_de_bodega,
            "productos": productos_de_bodega,
            "success": f"Movimiento realizado: {cantidad} de {producto.nombre} → {sucursal.nombre}.",
            "bodega_sel": bodega.id,
        })

    return render(request, "core/Movimientos/bodega_a_sucursal.html", {"bodegas": bodegas})





from .utils import ensure_ubicacion_sucursal



@login_required
def sucursal_a_sucursal(request):
    sucursales = Sucursal.objects.prefetch_related("ubicaciones").order_by("nombre")
    suc_origen_id = request.GET.get("sucursal_origen") or request.POST.get("sucursal_origen")

    sucursales_destino = None
    productos_de_origen = None
    suc_origen = None

    if suc_origen_id:
        try:
            suc_origen = Sucursal.objects.get(pk=suc_origen_id)
        except Sucursal.DoesNotExist:
            suc_origen = None
        else:
            # asegúrate de que exista ubicacion
            from .utils import ensure_ubicacion_sucursal
            ensure_ubicacion_sucursal(suc_origen)

            sucursales_destino = Sucursal.objects.exclude(pk=suc_origen.pk).order_by("nombre")
            productos_de_origen = (
                Producto.objects.filter(
                    stocks__ubicacion_sucursal__sucursal=suc_origen,
                    stocks__cantidad_disponible__gt=0,
                )
                .annotate(
                    stock_total=Coalesce(
                        Sum("stocks__cantidad_disponible"),
                        Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                    )
                ).distinct()
            )

    if request.method == "POST":
        suc_destino_id = request.POST.get("sucursal_destino")
        producto_id = request.POST.get("producto")
        cantidad_raw = request.POST.get("cantidad")

        if not all([suc_origen_id, suc_destino_id, producto_id, cantidad_raw]):
            return render(request, "core/Movimientos/sucursal_a_sucursal.html", {
                "sucursales": sucursales,
                "sucursal_sel": suc_origen_id,
                "sucursales_destino": sucursales_destino,
                "productos": productos_de_origen,
                "error": "Faltan datos en el formulario.",
            })

        if suc_origen_id == suc_destino_id:
            return render(request, "core/Movimientos/sucursal_a_sucursal.html", {
                "sucursales": sucursales,
                "sucursal_sel": suc_origen_id,
                "sucursales_destino": sucursales_destino,
                "productos": productos_de_origen,
                "error": "La sucursal de origen y destino no pueden ser la misma.",
            })

        try:
            cantidad = int(cantidad_raw)
        except (ValueError, TypeError):
            cantidad = 0

        if cantidad <= 0:
            return render(request, "core/Movimientos/sucursal_a_sucursal.html", {
                "sucursales": sucursales,
                "sucursal_sel": suc_origen_id,
                "sucursales_destino": sucursales_destino,
                "productos": productos_de_origen,
                "error": "La cantidad debe ser mayor que 0.",
            })

        suc_origen = get_object_or_404(Sucursal, pk=suc_origen_id)
        suc_destino = get_object_or_404(Sucursal, pk=suc_destino_id)
        producto = get_object_or_404(Producto, pk=producto_id)

        from .utils import ensure_ubicacion_sucursal
        ubi_origen = ensure_ubicacion_sucursal(suc_origen)
        ubi_destino = ensure_ubicacion_sucursal(suc_destino)

        with transaction.atomic():
            stock_origen = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_sucursal=ubi_origen).first()
            )
            if not stock_origen or stock_origen.cantidad_disponible < cantidad:
                return render(request, "core/Movimientos/sucursal_a_sucursal.html", {
                    "sucursales": sucursales,
                    "sucursal_sel": suc_origen_id,
                    "sucursales_destino": sucursales_destino,
                    "productos": productos_de_origen,
                    "error": f"No hay stock suficiente en {suc_origen.nombre}.",
                })

            stock_destino, _ = (
                Stock.objects.select_for_update().get_or_create(
                    producto=producto, ubicacion_sucursal=ubi_destino,
                    defaults={"cantidad_disponible": Decimal("0")},
                )
            )

            stock_origen.cantidad_disponible -= Decimal(cantidad)
            stock_origen.save(update_fields=["cantidad_disponible"])
            stock_destino.cantidad_disponible += Decimal(cantidad)
            stock_destino.save(update_fields=["cantidad_disponible"])

            # === KÁRDEX ===
            try:
                MovimientoStock.objects.create(
                    tipo_movimiento=_tm("TRANSFERENCIA"),
                    producto=producto,
                    ubicacion_bodega_desde=None,
                    ubicacion_sucursal_desde=ubi_origen,
                    ubicacion_bodega_hasta=None,
                    ubicacion_sucursal_hasta=ubi_destino,
                    lote=None, serie=None,
                    cantidad=Decimal(cantidad),
                    unidad=_unidad_default(),
                    tabla_referencia="vista:sucursal_a_sucursal",
                    referencia_id=None,
                    creado_por=request.user,
                    notas=f"Suc {suc_origen.codigo} → Suc {suc_destino.codigo}",
                )
            except TipoMovimiento.DoesNotExist:
                pass

        total_prod = (
            Stock.objects.filter(producto=producto).aggregate(
                total=Coalesce(Sum("cantidad_disponible"),
                               Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)))
            )["total"]
        ) or 0
        producto.stock = int(total_prod)
        producto.save(update_fields=["stock"])

        sucursales_destino = Sucursal.objects.exclude(pk=suc_origen.pk).order_by("nombre")
        productos_de_origen = (
            Producto.objects.filter(
                stocks__ubicacion_sucursal__sucursal=suc_origen,
                stocks__cantidad_disponible__gt=0,
            )
            .annotate(
                stock_total=Coalesce(
                    Sum("stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                )
            ).distinct()
        )

        return render(request, "core/Movimientos/sucursal_a_sucursal.html", {
            "sucursales": sucursales,
            "sucursal_sel": suc_origen.id,
            "sucursales_destino": sucursales_destino,
            "productos": productos_de_origen,
            "success": "Movimiento realizado.",
        })

    return render(request, "core/Movimientos/sucursal_a_sucursal.html", {
        "sucursales": sucursales,
        "sucursal_sel": suc_origen_id,
        "sucursales_destino": sucursales_destino,
        "productos": productos_de_origen,
    })




@login_required
def bodega_a_bodega(request):
    bodegas = Bodega.objects.prefetch_related("ubicaciones").order_by("codigo")

    if request.method == "POST":
        bodega_origen_id = request.POST.get("bodega_origen")
        bodega_destino_id = request.POST.get("bodega_destino")
        producto_id = request.POST.get("producto")
        cantidad_raw = request.POST.get("cantidad")

        if not all([bodega_origen_id, bodega_destino_id, producto_id, cantidad_raw]):
            return render(request, "core/Movimientos/bodega_a_bodega.html",
                          {"bodegas": bodegas, "error": "Faltan datos en el formulario."})

        if bodega_origen_id == bodega_destino_id:
            return render(request, "core/Movimientos/bodega_a_bodega.html",
                          {"bodegas": bodegas, "error": "La bodega de origen y destino no pueden ser la misma."})

        try:
            cantidad = int(cantidad_raw)
        except (ValueError, TypeError):
            return render(request, "core/Movimientos/bodega_a_bodega.html",
                          {"bodegas": bodegas, "error": "La cantidad debe ser un número entero."})

        if cantidad <= 0:
            return render(request, "core/Movimientos/bodega_a_bodega.html",
                          {"bodegas": bodegas, "error": "La cantidad debe ser mayor que 0."})

        try:
            bodega_origen = Bodega.objects.get(pk=bodega_origen_id)
            bodega_destino = Bodega.objects.get(pk=bodega_destino_id)
            producto = Producto.objects.get(pk=producto_id)
        except (Bodega.DoesNotExist, Producto.DoesNotExist):
            return render(request, "core/Movimientos/bodega_a_bodega.html",
                          {"bodegas": bodegas, "error": "Alguna entidad no existe."})

        ubi_origen = bodega_origen.ubicaciones.first()
        ubi_destino = bodega_destino.ubicaciones.first()
        if not ubi_origen or not ubi_destino:
            return render(request, "core/Movimientos/bodega_a_bodega.html",
                          {"bodegas": bodegas, "error": "Faltan ubicaciones en alguna bodega."})

        with transaction.atomic():
            stock_origen = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_bodega=ubi_origen).first()
            )
            if not stock_origen:
                stock_origen = Stock.objects.create(
                    producto=producto, ubicacion_bodega=ubi_origen,
                    cantidad_disponible=Decimal("0"),
                )

            if stock_origen.cantidad_disponible < cantidad:
                return render(request, "core/Movimientos/bodega_a_bodega.html",
                              {"bodegas": bodegas,
                               "error": f"No hay stock suficiente en la bodega de origen. Disponible: {stock_origen.cantidad_disponible}."})

            stock_destino = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_bodega=ubi_destino).first()
            )

            if stock_destino and stock_destino.id == stock_origen.id:
                stock_origen.ubicacion_sucursal = None
                stock_origen.save(update_fields=["ubicacion_sucursal"])
                stock_destino = Stock.objects.create(
                    producto=producto, ubicacion_bodega=ubi_destino,
                    cantidad_disponible=Decimal("0"),
                )
            elif not stock_destino:
                stock_destino = Stock.objects.create(
                    producto=producto, ubicacion_bodega=ubi_destino,
                    cantidad_disponible=Decimal("0"),
                )

            stock_origen.cantidad_disponible -= Decimal(cantidad)
            stock_origen.save(update_fields=["cantidad_disponible"])
            stock_destino.cantidad_disponible += Decimal(cantidad)
            stock_destino.save(update_fields=["cantidad_disponible"])

            # === KÁRDEX ===
            try:
                MovimientoStock.objects.create(
                    tipo_movimiento=_tm("TRANSFERENCIA"),
                    producto=producto,
                    ubicacion_bodega_desde=ubi_origen,
                    ubicacion_sucursal_desde=None,
                    ubicacion_bodega_hasta=ubi_destino,
                    ubicacion_sucursal_hasta=None,
                    lote=None, serie=None,
                    cantidad=Decimal(cantidad),
                    unidad=_unidad_default(),
                    tabla_referencia="vista:bodega_a_bodega",
                    referencia_id=None,
                    creado_por=request.user,
                    notas=f"Bod {bodega_origen.codigo} → Bod {bodega_destino.codigo}",
                )
            except TipoMovimiento.DoesNotExist:
                pass

        total_prod = (
            Stock.objects.filter(producto=producto).aggregate(
                t=Coalesce(Sum("cantidad_disponible"),
                           Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)))
            )["t"]
        ) or 0
        producto.stock = int(total_prod)
        producto.save(update_fields=["stock"])

        productos_de_origen = (
            Producto.objects.filter(stocks__ubicacion_bodega__bodega=bodega_origen)
            .annotate(
                stock_total=Coalesce(
                    Sum("stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                )
            ).distinct()
        )

        return render(request, "core/Movimientos/bodega_a_bodega.html", {
            "bodegas": bodegas,
            "productos": productos_de_origen,
            "success": f"Movimiento realizado: {cantidad} de {producto.nombre} → {bodega_destino.nombre}.",
            "bodega_sel": bodega_origen.id,
        })

    return render(request, "core/Movimientos/bodega_a_bodega.html", {"bodegas": bodegas})







@login_required
def sucursal_a_bodega(request):
    bodegas = (
        Bodega.objects.prefetch_related("sucursales", "ubicaciones").order_by("codigo")
    )

    if request.method == "POST":
        sucursal_id = request.POST.get("sucursal")
        bodega_id = request.POST.get("bodega")
        producto_id = request.POST.get("producto")
        cantidad_raw = request.POST.get("cantidad")

        if not all([sucursal_id, bodega_id, producto_id, cantidad_raw]):
            return render(request, "core/Movimientos/sucursal_a_bodega.html",
                          {"bodegas": bodegas, "error": "Faltan datos en el formulario."})

        try:
            cantidad = int(cantidad_raw)
        except (ValueError, TypeError):
            return render(request, "core/Movimientos/sucursal_a_bodega.html",
                          {"bodegas": bodegas, "error": "La cantidad debe ser un número entero."})

        if cantidad <= 0:
            return render(request, "core/Movimientos/sucursal_a_bodega.html",
                          {"bodegas": bodegas, "error": "La cantidad debe ser mayor que 0."})

        try:
            bodega = Bodega.objects.get(pk=bodega_id)
            sucursal = Sucursal.objects.get(pk=sucursal_id, bodega=bodega)
            producto = Producto.objects.get(pk=producto_id)
        except (Bodega.DoesNotExist, Sucursal.DoesNotExist, Producto.DoesNotExist):
            return render(request, "core/Movimientos/sucursal_a_bodega.html",
                          {"bodegas": bodegas, "error": "Alguna entidad seleccionada no existe."})

        ubi_origen = sucursal.ubicaciones.first()
        ubi_destino = bodega.ubicaciones.first()
        if not ubi_origen or not ubi_destino:
            return render(request, "core/Movimientos/sucursal_a_bodega.html",
                          {"bodegas": bodegas, "error": "Faltan ubicaciones en bodega o sucursal."})

        with transaction.atomic():
            stock_origen = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_sucursal=ubi_origen).first()
            )
            if not stock_origen:
                stock_origen = Stock.objects.create(
                    producto=producto, ubicacion_sucursal=ubi_origen,
                    cantidad_disponible=Decimal("0"),
                )

            if stock_origen.cantidad_disponible < cantidad:
                return render(request, "core/Movimientos/sucursal_a_bodega.html",
                              {"bodegas": bodegas,
                               "error": f"No hay stock suficiente en la sucursal. Disponible: {stock_origen.cantidad_disponible}."})

            stock_destino = (
                Stock.objects.select_for_update()
                .filter(producto=producto, ubicacion_bodega=ubi_destino).first()
            )

            if stock_destino and stock_destino.id == stock_origen.id:
                stock_origen.ubicacion_bodega = None
                stock_origen.save(update_fields=["ubicacion_bodega"])
                stock_destino = Stock.objects.create(
                    producto=producto, ubicacion_bodega=ubi_destino,
                    cantidad_disponible=Decimal("0"),
                )
            elif not stock_destino:
                stock_destino = Stock.objects.create(
                    producto=producto, ubicacion_bodega=ubi_destino,
                    cantidad_disponible=Decimal("0"),
                )

            stock_origen.cantidad_disponible -= Decimal(cantidad)
            stock_origen.save(update_fields=["cantidad_disponible"])
            stock_destino.cantidad_disponible += Decimal(cantidad)
            stock_destino.save(update_fields=["cantidad_disponible"])

            # === KÁRDEX ===
            try:
                MovimientoStock.objects.create(
                    tipo_movimiento=_tm("TRANSFERENCIA"),
                    producto=producto,
                    # ORIGEN: SUCURSAL
                    ubicacion_bodega_desde=None,
                    ubicacion_sucursal_desde=ubi_origen,
                    # DESTINO: BODEGA
                    ubicacion_bodega_hasta=ubi_destino,
                    ubicacion_sucursal_hasta=None,
                    lote=None, serie=None,
                    cantidad=Decimal(cantidad),
                    unidad=_unidad_default(),
                    tabla_referencia="vista:sucursal_a_bodega",
                    referencia_id=None,
                    creado_por=request.user,
                    notas=f"Suc {sucursal.codigo} → Bod {bodega.codigo}",
                )
            except TipoMovimiento.DoesNotExist:
                pass

        total_prod = (
            Stock.objects.filter(producto=producto).aggregate(
                t=Coalesce(Sum("cantidad_disponible"),
                           Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)))
            )["t"]
        ) or 0
        producto.stock = int(total_prod)
        producto.save(update_fields=["stock"])

        sucursales_de_bodega = bodega.sucursales.all().order_by("codigo")
        productos_de_sucursal = (
            Producto.objects.filter(stocks__ubicacion_sucursal__sucursal=sucursal)
            .annotate(
                stock_total=Coalesce(
                    Sum("stocks__cantidad_disponible"),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6)),
                )
            ).distinct()
        )

        return render(request, "core/Movimientos/sucursal_a_bodega.html", {
            "bodegas": bodegas,
            "sucursales": sucursales_de_bodega,
            "productos": productos_de_sucursal,
            "success": f"Movimiento realizado: {cantidad} de {producto.nombre} → {bodega.nombre}.",
            "bodega_sel": bodega.id,
        })

    return render(request, "core/Movimientos/sucursal_a_bodega.html", {"bodegas": bodegas})



def movimientos_index(request):
    return render(request, "core/Movimientos/movimientos_index.html")


import requests
from django.http import JsonResponse
from django.views.decorators.http import require_GET



@require_GET
def geocode(request):
    q = (request.GET.get("q") or "").strip()
    if not q:
        return JsonResponse({"error": "missing query"}, status=400)

    url = "https://nominatim.openstreetmap.org/search"
    params = {
        "format": "json",
        "limit": 1,
        "q": q,
        "countrycodes": "cl",
    }
    headers = {
        # Nominatim pide User-Agent
        "User-Agent": "LogisticFour/1.0 (https://example.com)"
    }

    try:
        r = requests.get(url, params=params, headers=headers, timeout=5)
        r.raise_for_status()
    except requests.RequestException as e:
        return JsonResponse({"error": "upstream_error", "detail": str(e)}, status=502)

    data = r.json()
    if not data:
        return JsonResponse({"error": "not_found"}, status=404)

    item = data[0]
    return JsonResponse({
        "lat": item["lat"],
        "lon": item["lon"],
        "display_name": item.get("display_name", q),
    })
    
from django.utils import timezone
@require_POST
@login_required
@transaction.atomic
def paypal_stock_in(request):
    """
    Llega desde el JS de PayPal cuando el pago fue APROBADO.
    Hace TODO automático y si algo falla devuelve el error en JSON.
    """
    try:
        # -------------------------------------------------
        # 1) leer JSON
        # -------------------------------------------------
        try:
            data = json.loads(request.body.decode("utf-8"))
        except Exception as e:
            return JsonResponse({"ok": False, "error": f"JSON inválido: {e}"}, status=400)

        bodega_id = data.get("bodega_id")
        producto_id = data.get("producto_id")
        cantidad_raw = data.get("cantidad")
        paypal_id = data.get("paypal_id") or "SIN-ID"
        monto_usd_raw = data.get("monto_usd") or "0"

        if not bodega_id or not producto_id or not cantidad_raw:
            return JsonResponse({"ok": False, "error": "Faltan datos"}, status=400)

        # -------------------------------------------------
        # 2) cantidad válida
        # -------------------------------------------------
        try:
            cantidad = Decimal(str(cantidad_raw))
            if cantidad <= 0:
                raise ValueError
        except Exception:
            return JsonResponse({"ok": False, "error": "Cantidad inválida"}, status=400)

        # -------------------------------------------------
        # 3) buscar bodega y producto
        # -------------------------------------------------
        try:
            bodega = Bodega.objects.get(pk=bodega_id)
            producto = Producto.objects.get(pk=producto_id)
        except Bodega.DoesNotExist:
            return JsonResponse({"ok": False, "error": "Bodega no encontrada"}, status=404)
        except Producto.DoesNotExist:
            return JsonResponse({"ok": False, "error": "Producto no encontrado"}, status=404)

        # -------------------------------------------------
        # 4) asegurar UNA ubicación en esa bodega
        # -------------------------------------------------
        ubi = bodega.ubicaciones.filter(activo=True).order_by("id").first()
        if not ubi:
            ubi = UbicacionBodega.objects.create(
                bodega=bodega,
                codigo="AUTO-PP",
                nombre="Ubicación generada por PayPal",
                activo=True,
            )

        # -------------------------------------------------
        # 5) sumar stock en ESA ubicación
        # -------------------------------------------------
        stock_obj, created = Stock.objects.get_or_create(
            producto=producto,
            ubicacion_bodega=ubi,
            defaults={"cantidad_disponible": Decimal("0")}
        )
        Stock.objects.filter(pk=stock_obj.pk).update(
            cantidad_disponible=F("cantidad_disponible") + cantidad
        )
        stock_obj.refresh_from_db()

        # -------------------------------------------------
        # 6) usuario proveedor PayPal (rol = PROVEEDOR)
        # -------------------------------------------------
        proveedor_user, _ = User.objects.get_or_create(
            username="paypal_proveedor",
            defaults={
                "first_name": "Proveedor",
                "last_name": "PayPal",
                "email": "paypal@example.com",
            },
        )
        UsuarioPerfil.objects.get_or_create(
            usuario=proveedor_user,
            defaults={"rol": UsuarioPerfil.Rol.PROVEEDOR},
        )

        # -------------------------------------------------
        # 7) unidad de medida segura
        # -------------------------------------------------
        um = getattr(producto, "unidad_base", None)
        if not um:
            # intentamos agarrar una existente
            um = UnidadMedida.objects.first()
        if not um:
            # si no hay ninguna en la bd, creamos una por defecto
            um, _ = UnidadMedida.objects.get_or_create(
                codigo="UN-PP",
                defaults={"descripcion": "Unidad por PayPal"},
            )

        # -------------------------------------------------
        # 8) crear ORDEN DE COMPRA
        # -------------------------------------------------
        numero_orden = f"OC-PAYPAL-{timezone.now().strftime('%Y%m%d%H%M%S')}"
        oc = OrdenCompra.objects.create(
            proveedor=proveedor_user,
            tasa_impuesto=None,
            bodega=bodega,
            numero_orden=numero_orden,
            estado="COMPLETED",
            fecha_esperada=timezone.now().date(),
            creado_por=request.user,
        )

        # monto
        try:
            monto_usd = Decimal(str(monto_usd_raw))
        except Exception:
            monto_usd = Decimal("0")

        LineaOrdenCompra.objects.create(
            orden_compra=oc,
            producto=producto,
            descripcion=f"Compra PayPal #{paypal_id}",
            cantidad_pedida=cantidad,
            unidad=um,
            precio=monto_usd,
        )

        # -------------------------------------------------
        # 9) crear RECEPCIÓN
        # -------------------------------------------------
        rec = RecepcionMercaderia.objects.create(
            orden_compra=oc,
            bodega=bodega,
            numero_recepcion=f"RC-PAYPAL-{timezone.now().strftime('%Y%m%d%H%M%S')}",
            estado="CLOSED",
            recibido_por=request.user,
        )
        LineaRecepcionMercaderia.objects.create(
            recepcion=rec,
            producto=producto,
            cantidad_recibida=cantidad,
            unidad=um,
        )

        # -------------------------------------------------
        # 10) crear FACTURA (cuidando el unique)
        # -------------------------------------------------
        base_numero_factura = f"FP-PAYPAL-{paypal_id}"
        try:
            FacturaProveedor.objects.create(
                proveedor=proveedor_user,
                numero_factura=base_numero_factura,
                monto_total=monto_usd,
                fecha_factura=timezone.now().date(),
                estado="PAID",
            )
        except IntegrityError:
            # si ya existía una factura con ese número, le metemos sufijo de tiempo
            FacturaProveedor.objects.create(
                proveedor=proveedor_user,
                numero_factura=f"{base_numero_factura}-{timezone.now().strftime('%H%M%S')}",
                monto_total=monto_usd,
                fecha_factura=timezone.now().date(),
                estado="PAID",
            )

        # -------------------------------------------------
        # LISTO
        # -------------------------------------------------
        return JsonResponse({
            "ok": True,
            "msg": "Pago registrado y stock sumado.",
            "nuevo_stock": str(stock_obj.cantidad_disponible),
            "orden": oc.numero_orden,
        })

    except Exception as e:
        # 👇 esto es para que AHORA sí veas el error real en el popup
        return JsonResponse({"ok": False, "error": str(e)}, status=400)


@login_required
def paypal_ingresos_view(request):
    ordenes = (
        OrdenCompra.objects
        .filter(numero_orden__startswith="OC-PAYPAL-")
        .prefetch_related("lineas", "bodega", "proveedor")
        .order_by("-creado_en")[:50]
    )
    return render(request, "core/paypal_ingresos.html", {"ordenes": ordenes})

def _parse_contada_from_notas(notas: str | None):
    """
    Para RECUENTO_CIERRE: acepta 'contada=12.5' en notas.
    """
    if not notas:
        return None
    for part in notas.strip().split():
        if part.lower().startswith("contada="):
            try:
                return Decimal(part.split("=", 1)[1])
            except Exception:
                return None
    return None

@receiver(post_save, sender=MovimientoStock)
def rellenar_tablas_por_movimiento(sender, instance: MovimientoStock, created, **kwargs):
    """
    Se ejecuta SOLO cuando se CREA un MovimientoStock.
    - AJUSTE           -> crea AjusteInventario + LineaAjusteInventario
    - RECUENTO_CIERRE  -> crea RecuentoInventario + LineaRecuentoInventario (si hay 'contada=XX' en notas)
    - RESERVA          -> crea Reserva
    - LIBERAR_RESERVA  -> resta a la última Reserva coincidente (o por referencia)
    - TRANSFERENCIA / ENTRADA / SALIDA -> no hacen nada extra aquí (solo kárdex)
    IMPORTANTE: aquí NO se modifica la tabla Stock.
    """
    if not created:
        return

    codigo = (instance.tipo_movimiento.codigo or "").upper()

    with transaction.atomic():
        # ======================
        # AJUSTE
        # ======================
        if codigo == "AJUSTE":
            # Deducir bodega desde alguna ubicación
            bodega: Bodega | None = None
            for ub in (
                instance.ubicacion_bodega_hasta,
                instance.ubicacion_bodega_desde,
                instance.ubicacion_sucursal_hasta,
                instance.ubicacion_sucursal_desde,
            ):
                if ub is not None and hasattr(ub, "bodega"):
                    bodega = ub.bodega
                    break

            cab = AjusteInventario.objects.create(
                bodega=bodega,
                motivo=(instance.notas or "Ajuste inventario"),
                estado="CLOSED",
                creado_por=instance.creado_por,
            )
            LineaAjusteInventario.objects.create(
                ajuste=cab,
                producto=instance.producto,
                ubicacion_bodega=instance.ubicacion_bodega_hasta or instance.ubicacion_bodega_desde,
                ubicacion_sucursal=instance.ubicacion_sucursal_hasta or instance.ubicacion_sucursal_desde,
                lote=instance.lote,
                serie=instance.serie,
                cantidad_delta=Decimal(instance.cantidad),
                motivo=(instance.notas or ""),
            )
            return

        # ======================
        # RECUENTO_CIERRE
        # ======================
        if codigo == "RECUENTO_CIERRE":
            contada = _parse_contada_from_notas(instance.notas)
            if contada is None:
                return

            ub_bod = instance.ubicacion_bodega_hasta or instance.ubicacion_bodega_desde
            ub_suc = instance.ubicacion_sucursal_hasta or instance.ubicacion_sucursal_desde

            # Solo LECTURA para mostrar “cantidad_sistema” en la línea del recuento
            cant_sistema = Decimal("0")
            st = Stock.objects.filter(
                producto=instance.producto,
                ubicacion_bodega=ub_bod,
                ubicacion_sucursal=ub_suc,
            ).first()
            if st and st.cantidad_disponible is not None:
                cant_sistema = Decimal(st.cantidad_disponible)

            diferencia = Decimal(contada) - cant_sistema

            bodega: Bodega | None = None
            for ub in (ub_bod, ub_suc):
                if ub is not None and hasattr(ub, "bodega"):
                    bodega = ub.bodega
                    break

            rec = RecuentoInventario.objects.create(
                bodega=bodega,
                codigo_ciclo=timezone.now().strftime("C-%Y%m%d%H%M"),
                estado="CLOSED",
                creado_por=instance.creado_por,
            )
            LineaRecuentoInventario.objects.create(
                recuento=rec,
                producto=instance.producto,
                ubicacion_bodega=ub_bod,
                ubicacion_sucursal=ub_suc,
                lote=instance.lote,
                serie=instance.serie,
                cantidad_sistema=cant_sistema,
                cantidad_contada=contada,
                contado_por=instance.creado_por,
                diferencia=diferencia,
            )
            return

        # ======================
        # RESERVA
        # ======================
        if codigo == "RESERVA":
            Reserva.objects.create(
                producto=instance.producto,
                ubicacion_bodega=instance.ubicacion_bodega_hasta,
                ubicacion_sucursal=instance.ubicacion_sucursal_hasta,
                lote=instance.lote,
                serie=instance.serie,
                cantidad_reservada=Decimal(instance.cantidad),
                tabla_referencia=instance.tabla_referencia or "",
                referencia_id=instance.referencia_id,
            )
            return

        # ======================
        # LIBERAR_RESERVA
        # ======================
        if codigo == "LIBERAR_RESERVA":
            q = Reserva.objects.filter(
                producto=instance.producto,
                ubicacion_bodega=instance.ubicacion_bodega_hasta,
                ubicacion_sucursal=instance.ubicacion_sucursal_hasta,
            )
            if instance.referencia_id:
                q = q.filter(
                    tabla_referencia=instance.tabla_referencia or "",
                    referencia_id=instance.referencia_id,
                )
            r = q.order_by("-id").first()
            if r:
                nueva = (r.cantidad_reservada or Decimal("0")) - Decimal(instance.cantidad)
                r.cantidad_reservada = (nueva if nueva > 0 else Decimal("0"))
                r.save()
            return

        # TRANSFERENCIA / ENTRADA / SALIDA → no-ops aquí (solo guardamos el kárdex en tus vistas).
        return
    
@login_required
def auditoria_inventario(request):
    """
    Visual para inspeccionar lo que se rellena automáticamente desde MovimientoStock (por señales).
    Filtros:
      - ?desde=YYYY-MM-DD
      - ?hasta=YYYY-MM-DD
      - ?producto_id=123
    Por defecto: hoy.
    """
    hoy = timezone.localdate()
    desde_str = request.GET.get("desde")
    hasta_str = request.GET.get("hasta")
    producto_id = request.GET.get("producto_id")

    try:
        desde = datetime.fromisoformat(desde_str).date() if desde_str else hoy
    except Exception:
        desde = hoy
    try:
        hasta = datetime.fromisoformat(hasta_str).date() if hasta_str else hoy
    except Exception:
        hasta = hoy

    prod_filter = Q()
    if producto_id:
        prod_filter = Q(producto_id=producto_id)

    # MOVS (solo por fecha, ignorando hora)
    movimientos = (
        MovimientoStock.objects
        .select_related("tipo_movimiento", "producto", "unidad",
                        "ubicacion_bodega_desde", "ubicacion_bodega_hasta",
                        "ubicacion_sucursal_desde", "ubicacion_sucursal_hasta",
                        "creado_por")
        .filter(ocurrido_en__date__range=(desde, hasta))
        .filter(prod_filter)
        .order_by("-ocurrido_en")[:500]
    )

    # AJUSTES
    ajustes = (
        AjusteInventario.objects
        .select_related("bodega", "creado_por")
        .filter(creado_en__date__range=(desde, hasta))
        .order_by("-creado_en")[:200]
    )
    lineas_ajuste = (
        LineaAjusteInventario.objects
        .select_related("ajuste", "producto", "ubicacion_bodega", "ubicacion_sucursal", "lote", "serie")
        .filter(ajuste__creado_en__date__range=(desde, hasta))
        .filter(prod_filter)
        .order_by("-ajuste__creado_en")[:1000]
    )

    # RECUENTOS
    recuentos = (
        RecuentoInventario.objects
        .select_related("bodega", "creado_por")
        .filter(creado_en__date__range=(desde, hasta))
        .order_by("-creado_en")[:200]
    )
    lineas_recuento = (
        LineaRecuentoInventario.objects
        .select_related("recuento", "producto", "ubicacion_bodega", "ubicacion_sucursal", "lote", "serie", "contado_por")
        .filter(recuento__creado_en__date__range=(desde, hasta))
        .filter(prod_filter)
        .order_by("-recuento__creado_en")[:1000]
    )

    # RESERVAS
    reservas = (
        Reserva.objects
        .select_related("producto", "ubicacion_bodega", "ubicacion_sucursal", "lote", "serie")
        .filter(creado_en__date__range=(desde, hasta))
        .filter(prod_filter)
        .order_by("-creado_en")[:500]
    )

    productos = Producto.objects.only("id", "nombre").order_by("nombre")[:1000]

    ctx = {
        "desde": desde,
        "hasta": hasta,
        "movimientos": movimientos,
        "ajustes": ajustes,
        "lineas_ajuste": lineas_ajuste,
        "recuentos": recuentos,
        "lineas_recuento": lineas_recuento,
        "reservas": reservas,
        "productos": productos,
        "producto_id": int(producto_id) if producto_id else None,
    }
    return render(request, "core/auditoria_inventario.html", ctx)

def _bodega_from_stock(stock: Stock):
    """
    Retorna la bodega asociada al stock, ya sea:
    - Por su ubicación_bodega
    - O por la bodega que cuelga de la sucursal
    """
    if stock.ubicacion_bodega:
        return stock.ubicacion_bodega.bodega
    if stock.ubicacion_sucursal:
        suc = stock.ubicacion_sucursal.sucursal
        return suc.bodega if suc and suc.bodega else None
    return None


# ============================================================
#   PRE-SAVE: Guardar valor anterior
# ============================================================
@receiver(pre_save, sender=Stock)
def _record_prev_stock(sender, instance: Stock, **kwargs):
    """
    Guarda el valor anterior de cantidad_disponible antes del save()
    para poder comparar en el post_save.
    """
    if instance.pk:
        try:
            old = Stock.objects.get(pk=instance.pk)
            instance._prev_cantidad = old.cantidad_disponible or Decimal("0")
        except Stock.DoesNotExist:
            instance._prev_cantidad = Decimal("0")
    else:
        instance._prev_cantidad = Decimal("0")


# ============================================================
#   POST-SAVE: Generar recuento cuando cambia el stock
# ============================================================
@receiver(post_save, sender=Stock)
def _crear_recuento_auto(sender, instance: Stock, created, **kwargs):
    """
    Cada vez que cambia la cantidad_disponible en Stock (suba o baje),
    crea automáticamente una línea en RecuentoInventario.
    """
    prev = getattr(instance, "_prev_cantidad", Decimal("0"))
    actual = instance.cantidad_disponible or Decimal("0")

    # Solo si hay diferencia
    if prev == actual:
        return

    bodega = _bodega_from_stock(instance)
    if not bodega:
        return  # no se puede asociar bodega ⇒ no se registra

    diff = actual - prev
    hoy = timezone.localdate()

    # Cabecera de recuento automática por día
    recuento, _ = RecuentoInventario.objects.get_or_create(
        bodega=bodega,
        codigo_ciclo=f"AUTO-{hoy.strftime('%Y%m%d')}",
        defaults={"estado": "OPEN"},
    )

    # Línea de detalle
    LineaRecuentoInventario.objects.create(
        recuento=recuento,
        producto=instance.producto,
        ubicacion_bodega=instance.ubicacion_bodega,
        ubicacion_sucursal=instance.ubicacion_sucursal,
        cantidad_sistema=prev,
        cantidad_contada=actual,
        diferencia=diff,
    )

# --- Finanzas: Vistas de reporte ---

# ---------- helpers ----------
def _auto_width(ws):
    """
    Ajusta el ancho de cada columna en una hoja de openpyxl
    según el texto más largo. Límite de ancho = 50.
    """
    from openpyxl.utils import get_column_letter
    for i, col in enumerate(ws.columns, start=1):
        max_len = 0
        for cell in col:
            val = cell.value
            try:
                s = str(val) if val is not None else ""
            except Exception:
                s = ""
            if len(s) > max_len:
                max_len = len(s)
        ws.column_dimensions[get_column_letter(i)].width = min(max_len + 2, 50)

#----------------------------
# --- Finanzas: helpers comunes ---
from django.contrib.auth.decorators import login_required, user_passes_test
from django.http import HttpResponse
from django.db.models import Q, Sum, Value, DecimalField
from django.db.models.functions import Coalesce
from django.contrib.auth.models import User
from io import BytesIO

from core.forms import FinanzasReporteForm
from core.models import (
    UsuarioPerfil, Bodega, Producto,
    OrdenCompra, RecepcionMercaderia, FacturaProveedor, Stock
)
def _is_auditor(user):
    """Permite AUDITOR, ADMIN y superuser."""
    try:
        if not user.is_authenticated:
            return False
        if getattr(user, "is_superuser", False):
            return True
        rol = getattr(getattr(user, "perfil", None), "rol", None)
        return rol in (UsuarioPerfil.Rol.AUDITOR, UsuarioPerfil.Rol.ADMIN)
    except Exception:
        return False

def _auto_width(ws):
    """Auto-anchos para openpyxl."""
    from openpyxl.utils import get_column_letter
    for i, col in enumerate(ws.columns, start=1):
        max_len = 0
        for cell in col:
            val = cell.value
            s = str(val) if val is not None else ""
            max_len = max(max_len, len(s))
        ws.column_dimensions[get_column_letter(i)].width = min(max_len + 2, 50)

def _build_finanzas_querysets(cleaned):
    """
    Devuelve (ordenes, recepciones, facturas, productos, resumen) aplicando los
    filtros del formulario ya limpiado.
    """
    bodega     = cleaned.get("bodega")
    proveedor  = cleaned.get("proveedor")
    fecha_desde = cleaned.get("fecha_desde")
    fecha_hasta = cleaned.get("fecha_hasta")

    # bases
    ordenes = OrdenCompra.objects.select_related("proveedor", "bodega").all()
    recepciones = RecepcionMercaderia.objects.select_related("bodega", "orden_compra").all()
    facturas = FacturaProveedor.objects.select_related("proveedor").all()
    productos = Producto.objects.all()

    # filtros por bodega
    if bodega:
        ordenes = ordenes.filter(bodega=bodega)
        recepciones = recepciones.filter(bodega=bodega)

        # productos con stock en esa bodega (ya sea en ubicación de bodega
        # o en sucursales que cuelgan de esa bodega)
        productos = (
            productos.filter(
                Q(stocks__ubicacion_bodega__bodega=bodega) |
                Q(stocks__ubicacion_sucursal__sucursal__bodega=bodega)
            )
            .annotate(
                stock_filtrado=Coalesce(
                    Sum(
                        "stocks__cantidad_disponible",
                        filter=Q(stocks__ubicacion_bodega__bodega=bodega) |
                                Q(stocks__ubicacion_sucursal__sucursal__bodega=bodega),
                    ),
                    Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
                )
            )
            .distinct()
        )
    else:
        # sin bodega, stock agregado general
        productos = productos.annotate(
            stock_filtrado=Coalesce(
                Sum("stocks__cantidad_disponible"),
                Value(0, output_field=DecimalField(max_digits=20, decimal_places=6))
            )
        )

    # filtros por proveedor
    if proveedor:
        ordenes = ordenes.filter(proveedor=proveedor)
        facturas = facturas.filter(proveedor=proveedor)
        # relación M2M Producto <-> Proveedor (ajusta related_name si varía)
        productos = productos.filter(usuarios_proveedor__proveedor=proveedor).distinct()

    # filtros por fecha
    if fecha_desde:
        ordenes = ordenes.filter(creado_en__date__gte=fecha_desde)
        recepciones = recepciones.filter(creado_en__date__gte=fecha_desde)
        facturas = facturas.filter(fecha_factura__gte=fecha_desde)
    if fecha_hasta:
        ordenes = ordenes.filter(creado_en__date__lte=fecha_hasta)
        recepciones = recepciones.filter(creado_en__date__lte=fecha_hasta)
        facturas = facturas.filter(fecha_factura__lte=fecha_hasta)

    resumen = {
        "ordenes_count": ordenes.count(),
        "recepciones_count": recepciones.count(),
        "facturas_count": facturas.count(),
        "productos_count": productos.count(),
        "stock_total": productos.aggregate(s=Sum("stock_filtrado"))["s"] or 0,
    }
    return (
        ordenes.order_by("-creado_en"),
        recepciones.order_by("-creado_en"),
        facturas.order_by("-fecha_factura"),
        productos.order_by("nombre"),
        resumen,
    )

# --- Página de reporte ---
@login_required
@user_passes_test(_is_auditor)
def finanzas_reporte(request):
    form = FinanzasReporteForm(request.GET or None)

    # poblar combos (por si el form se instanció sin queryset)
    form.fields["bodega"].queryset = Bodega.objects.all().order_by("codigo")
    form.fields["proveedor"].queryset = User.objects.filter(
        perfil__rol=UsuarioPerfil.Rol.PROVEEDOR, is_active=True
    ).order_by("username")

    # ¿se aplicaron filtros?
    has_filters = any([
        request.GET.get("bodega"),
        request.GET.get("proveedor"),
        request.GET.get("fecha_desde"),
        request.GET.get("fecha_hasta"),
    ])

    if not has_filters:
        return render(request, "core/finanzas_reporte.html", {
            "form": form,
            "ordenes": OrdenCompra.objects.none(),
            "recepciones": RecepcionMercaderia.objects.none(),
            "facturas": FacturaProveedor.objects.none(),
            "productos": Producto.objects.none(),
            "has_filters": False,
            "resumen": {},
        })

    if not form.is_valid():
        # mostrar vacío si los filtros no son válidos
        return render(request, "core/finanzas_reporte.html", {
            "form": form,
            "ordenes": OrdenCompra.objects.none(),
            "recepciones": RecepcionMercaderia.objects.none(),
            "facturas": FacturaProveedor.objects.none(),
            "productos": Producto.objects.none(),
            "has_filters": True,
            "resumen": {},
        })

    ordenes, recepciones, facturas, productos, resumen = _build_finanzas_querysets(form.cleaned_data)
    return render(request, "core/finanzas_reporte.html", {
        "form": form,
        "ordenes": ordenes,
        "recepciones": recepciones,
        "facturas": facturas,
        "productos": productos,
        "has_filters": True,
        "resumen": resumen,
    })

# --- Export: Excel (.xlsx) ---
@login_required
@user_passes_test(_is_auditor)
def finanzas_export_excel(request):
    form = FinanzasReporteForm(request.GET or None)
    if not form.is_valid():
        return HttpResponse("Filtros inválidos.", status=400)

    ordenes, recepciones, facturas, productos, resumen = _build_finanzas_querysets(form.cleaned_data)

    try:
        from openpyxl import Workbook
        from openpyxl.styles import Font, Alignment, Border, Side
    except Exception:
        return HttpResponse("Falta instalar openpyxl (pip install openpyxl)", status=500)

    wb = Workbook()
    ws = wb.active
    ws.title = "Reporte Finanzas"

    bold = Font(bold=True)
    center = Alignment(horizontal="center")
    thin = Side(style="thin")
    border = Border(left=thin, right=thin, top=thin, bottom=thin)

    row = 1
    ws.cell(row=row, column=1, value="Reporte de Finanzas").font = Font(bold=True, size=14); row += 2

    # Órdenes
    ws.cell(row=row, column=1, value="Órdenes de compra").font = bold; row += 1
    headers = ["N° OC", "Proveedor", "Bodega", "Estado", "Fecha Esperada", "Creada"]
    for c, h in enumerate(headers, 1):
        cell = ws.cell(row=row, column=c, value=h); cell.font = bold; cell.alignment = center; cell.border = border
    row += 1
    for oc in ordenes:
        ws.cell(row=row, column=1, value=oc.numero_orden).border = border
        ws.cell(row=row, column=2, value=(oc.proveedor.get_full_name() or oc.proveedor.username)).border = border
        ws.cell(row=row, column=3, value=f"{oc.bodega.codigo} - {oc.bodega.nombre}").border = border
        ws.cell(row=row, column=4, value=oc.estado).border = border
        ws.cell(row=row, column=5, value=(oc.fecha_esperada or "")).border = border
        ws.cell(row=row, column=6, value=oc.creado_en.strftime("%Y-%m-%d %H:%M")).border = border
        row += 1
    row += 1

    # Facturas
    ws.cell(row=row, column=1, value="Facturas proveedor").font = bold; row += 1
    headers = ["N°", "Proveedor", "Monto", "Fecha", "Estado"]
    for c, h in enumerate(headers, 1):
        cell = ws.cell(row=row, column=c, value=h); cell.font = bold; cell.alignment = center; cell.border = border
    row += 1
    for f in facturas:
        ws.cell(row=row, column=1, value=f.numero_factura).border = border
        ws.cell(row=row, column=2, value=(f.proveedor.get_full_name() or f.proveedor.username)).border = border
        ws.cell(row=row, column=3, value=float(f.monto_total or 0)).border = border
        ws.cell(row=row, column=4, value=f.fecha_factura).border = border
        ws.cell(row=row, column=5, value=f.estado).border = border
        row += 1
    row += 1

    # Recepciones
    ws.cell(row=row, column=1, value="Recepciones").font = bold; row += 1
    headers = ["N°", "Bodega", "Estado", "Recibido en"]
    for c, h in enumerate(headers, 1):
        cell = ws.cell(row=row, column=c, value=h); cell.font = bold; cell.alignment = center; cell.border = border
    row += 1
    for r in recepciones:
        ws.cell(row=row, column=1, value=r.numero_recepcion).border = border
        ws.cell(row=row, column=2, value=f"{r.bodega.codigo} - {r.bodega.nombre}").border = border
        ws.cell(row=row, column=3, value=r.estado).border = border
        ws.cell(row=row, column=4, value=(r.recibido_en.strftime("%Y-%m-%d %H:%M") if r.recibido_en else "")).border = border
        row += 1
    row += 1

    # Productos
    ws.cell(row=row, column=1, value="Productos (según filtros)").font = bold; row += 1
    headers = ["SKU", "Nombre", "Stock"]
    for c, h in enumerate(headers, 1):
        cell = ws.cell(row=row, column=c, value=h); cell.font = bold; cell.alignment = center; cell.border = border
    row += 1
    for p in productos:
        ws.cell(row=row, column=1, value=p.sku).border = border
        ws.cell(row=row, column=2, value=p.nombre).border = border
        ws.cell(row=row, column=3, value=float(getattr(p, "stock_filtrado", 0) or 0)).border = border
        row += 1

    _auto_width(ws)

    bio = BytesIO()
    wb.save(bio)
    bio.seek(0)

    resp = HttpResponse(
        bio.getvalue(),
        content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    )
    resp['Content-Disposition'] = 'attachment; filename="reporte_finanzas.xlsx"'
    return resp

# --- Export: PDF (con tablas y columnas de productos más anchas) ---
@login_required
@user_passes_test(_is_auditor)
def finanzas_export_pdf(request):
    form = FinanzasReporteForm(request.GET or None)
    if not form.is_valid():
        return HttpResponse("Filtros inválidos.", status=400)

    ordenes, recepciones, facturas, productos, resumen = _build_finanzas_querysets(form.cleaned_data)

    try:
        from reportlab.lib.pagesizes import A4
        from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
        from reportlab.lib import colors
        from reportlab.lib.styles import getSampleStyleSheet
    except Exception:
        return HttpResponse("Falta instalar reportlab (pip install reportlab)", status=500)

    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=36, rightMargin=36, topMargin=36, bottomMargin=36)
    styles = getSampleStyleSheet()
    story = []

    title = Paragraph("<b>Reporte de Finanzas</b>", styles["Title"])
    story += [title, Spacer(1, 10)]

    def section(title_txt, headers, rows, col_widths=None):
        story.append(Paragraph(f"<b>{title_txt}</b>", styles["Heading4"]))
        data = [headers] + (rows if rows else [[""] * len(headers)])
        tbl = Table(data, colWidths=col_widths)
        tbl.setStyle(TableStyle([
            ("GRID", (0,0), (-1,-1), 1, colors.black),
            ("BACKGROUND", (0,0), (-1,0), colors.lightgrey),
            ("ALIGN", (0,0), (-1,0), "CENTER"),
            ("VALIGN", (0,0), (-1,-1), "MIDDLE"),
        ]))
        story.extend([tbl, Spacer(1, 12)])

    # Órdenes
    section(
        "Órdenes de compra",
        ["N° OC", "Proveedor", "Bodega", "Estado", "Fecha Esperada", "Creada"],
        [[
            oc.numero_orden,
            (oc.proveedor.get_full_name() or oc.proveedor.username),
            f"{oc.bodega.codigo} - {oc.bodega.nombre}",
            oc.estado,
            (oc.fecha_esperada or ""),
            oc.creado_en.strftime("%Y-%m-%d %H:%M"),
        ] for oc in ordenes]
    )

    # Facturas
    section(
        "Facturas proveedor",
        ["N°", "Proveedor", "Monto", "Fecha", "Estado"],
        [[
            f.numero_factura,
            (f.proveedor.get_full_name() or f.proveedor.username),
            f"{f.monto_total}",
            f.fecha_factura.strftime("%Y-%m-%d"),
            f.estado,
        ] for f in facturas]
    )

    # Recepciones
    section(
        "Recepciones",
        ["N°", "Bodega", "Estado", "Recibido en"],
        [[
            r.numero_recepcion,
            f"{r.bodega.codigo} - {r.bodega.nombre}",
            r.estado,
            (r.recibido_en.strftime("%Y-%m-%d %H:%M") if r.recibido_en else ""),
        ] for r in recepciones]
    )

    # Productos (SKU y Nombre con más ancho para que no se solapen)
    section(
        "Productos (según filtros)",
        ["SKU", "Nombre", "Stock"],
        [[
            p.sku,
            p.nombre,
            f"{getattr(p, 'stock_filtrado', 0) or 0}",
        ] for p in productos],
        col_widths=[120, 320, 60],  # ← ajustado para evitar solapes
    )

    doc.build(story)
    pdf = buffer.getvalue()
    buffer.close()

    resp = HttpResponse(pdf, content_type="application/pdf")
    resp['Content-Disposition'] = 'attachment; filename="reporte_finanzas.pdf"'
    return resp

# --- Cambio de moneda en sesión ---
def set_currency(request):
    cur = (request.GET.get("c") or "").upper()
    if cur in ("CLP", "USD"):
        request.session["currency"] = cur
    next_url = request.GET.get("next") or request.META.get("HTTP_REFERER") or reverse("products")
    return HttpResponseRedirect(next_url)

#--- Etiqueta de producto con código de barras y QR ---
def etiqueta_producto(request, pk):
    p = get_object_or_404(Producto, pk=pk)
    # QR abre el detalle del producto; ajusta a tu ruta real
    link_detalle = request.build_absolute_uri(f"/productos/{p.pk}/")
    ctx = {
        "producto": p,
        "qr": qr_url(link_detalle, size="220x220"),
        "barcode": barcode_url(p.sku, bcid="code128", scale=4, height=14, includetext=True),
    }
    return render(request, "core/etiqueta_producto.html", ctx)
# core/alerts/services.py
from django.conf import settings
from django.core.mail import send_mass_mail
from django.db import transaction
from django.utils import timezone

from django.contrib.auth.models import User

from core.models import (
    Producto,
    UbicacionBodega,
    UbicacionSucursal,
    ReglaAlerta,
    Alerta,
    Notificacion,
    UsuarioPerfil,
)

REGLA_CODIGO = "STOCK_BAJO_10"


def _get_or_create_regla_stock_bajo():
    """
    Crea la regla una sola vez si no existe.
    configuracion = {"umbral": 10, "aplica": ["bodega", "sucursal"]}
    """
    regla, _ = ReglaAlerta.objects.get_or_create(
        codigo=REGLA_CODIGO,
        defaults={
            "nombre": "Stock bajo (≤10)",
            "configuracion": {"umbral": 10, "aplica": ["bodega", "sucursal"]},
            "activo": True,
        },
    )
    return regla


def _bodegueros_activos_qs():
    return (
        User.objects.filter(
            is_active=True,
            perfil__rol=UsuarioPerfil.Rol.BODEGUERO,
        )
        .exclude(email__isnull=True)
        .exclude(email__exact="")
        .select_related("perfil")
    )


def _ya_existe_alerta_abierta(producto, ubicacion_bodega=None, ubicacion_sucursal=None):
    """
    Evita duplicar alertas iguales si ya existe una sin reconocer.
    """
    qs = Alerta.objects.filter(
        producto=producto,
        regla__codigo=REGLA_CODIGO,
        reconocida_por__isnull=True,
        reconocida_en__isnull=True,
    )
    if ubicacion_bodega:
        qs = qs.filter(ubicacion_bodega=ubicacion_bodega, ubicacion_sucursal__isnull=True)
    if ubicacion_sucursal:
        qs = qs.filter(ubicacion_sucursal=ubicacion_sucursal, ubicacion_bodega__isnull=True)
    return qs.exists()


@transaction.atomic
def trigger_low_stock_alert(
    *,
    producto: Producto,
    stock_actual: int,
    ubicacion_bodega: UbicacionBodega | None = None,
    ubicacion_sucursal: UbicacionSucursal | None = None,
):
    """
    Llamar a esta función cada vez que actualices stock por movimiento.
    - producto: Producto afectado
    - stock_actual: stock resultante en esa ubicación
    - ubicacion_bodega: usar si aplica a bodega
    - ubicacion_sucursal: usar si aplica a sucursal
    """
    regla = _get_or_create_regla_stock_bajo()
    if not regla.activo:
        return  # regla desactivada

    umbral = int(regla.configuracion.get("umbral", 10))
    aplica = regla.configuracion.get("aplica", ["bodega", "sucursal"])

    # Determinar ámbito válido
    is_bodega = ubicacion_bodega is not None and "bodega" in aplica
    is_sucursal = ubicacion_sucursal is not None and "sucursal" in aplica
    if not (is_bodega or is_sucursal):
        return

    # ¿Está bajo o igual al umbral?
    if stock_actual > umbral:
        return

    # Evita duplicados abiertos
    if _ya_existe_alerta_abierta(
        producto=producto,
        ubicacion_bodega=ubicacion_bodega if is_bodega else None,
        ubicacion_sucursal=ubicacion_sucursal if is_sucursal else None,
    ):
        return

    # Crear alerta
    ubic_txt = ""
    if is_bodega:
        ubic_txt = f"Bodega: {ubicacion_bodega}"
    elif is_sucursal:
        ubic_txt = f"Sucursal: {ubicacion_sucursal}"

    mensaje = (
        f"El stock de '{producto}' bajó a {stock_actual} (≤{umbral}). {ubic_txt}."
    )

    alerta = Alerta.objects.create(
        regla=regla,
        producto=producto,
        ubicacion_bodega=ubicacion_bodega if is_bodega else None,
        ubicacion_sucursal=ubicacion_sucursal if is_sucursal else None,
        severidad="WARN",
        mensaje=mensaje,
    )

    # Notificaciones internas + emails a bodegueros
    bodegueros = list(_bodegueros_activos_qs())

    # Notificaciones internas
    notifs = [
        Notificacion(
            usuario=u,
            titulo="Stock bajo",
            cuerpo=mensaje,
        )
        for u in bodegueros
    ]
    if notifs:
        Notificacion.objects.bulk_create(notifs)

    # Emails
    if bodegueros:
        subject = "⚠ Stock bajo"
        body = (
            f"{mensaje}\n\n"
            f"Producto: {producto}\n"
            f"Fecha: {timezone.localtime(timezone.now()).strftime('%Y-%m-%d %H:%M')}\n"
            f"Alerta ID: {alerta.id}"
        )
        datatuples = []
        from_email = getattr(settings, "DEFAULT_FROM_EMAIL", None)
        for u in bodegueros:
            datatuples.append((subject, body, from_email, [u.email]))
        # Un envío por destinatario (permite mostrar TO correcto por cada usuario)
        send_mass_mail(datatuples, fail_silently=False)
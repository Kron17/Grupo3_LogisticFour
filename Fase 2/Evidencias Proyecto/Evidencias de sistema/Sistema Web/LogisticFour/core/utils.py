# core/utils.py
from urllib.parse import quote_plus
# core/utils.py

from django.db.models import Q   


from .models import (
    Sucursal,
    Bodega,
    UbicacionSucursal,
    UbicacionBodega,
)



def ensure_ubicacion_sucursal(sucursal: Sucursal) -> UbicacionSucursal:
    """
    Devuelve la ubicación 'SIN UBICACIÓN' de una sucursal.
    Si no existe, la crea como <COD-SUC>-000-000.
    Siempre será la ubicación por defecto para movimientos que llegan a sucursal.
    """
    ubi_default = (
        UbicacionSucursal.objects
        .filter(sucursal=sucursal)
        .filter(
            Q(codigo__endswith="-000-000") |
            Q(area__iexact="SIN UBICACION") |
            Q(area__iexact="SIN UBICACIÓN")
        )
        .order_by("id")
        .first()
    )
    if ubi_default:
        return ubi_default

    # Crear la default si no existe
    area_cod = "000"
    estante_cod = "000"

    ubi_default = UbicacionSucursal(
        sucursal=sucursal,
        area_codigo=area_cod,
        estante_codigo=estante_cod,
        area="SIN UBICACIÓN",
        activo=True,
    )

    # Si tu modelo tiene set_codigo, úsalo
    if hasattr(ubi_default, "set_codigo"):
        ubi_default.set_codigo(area_cod, estante_cod)
    else:
        # fallback si no existe set_codigo
        prefijo = getattr(sucursal, "codigo", str(sucursal.id)).upper()
        ubi_default.codigo = f"{prefijo}-{area_cod}-{estante_cod}"

    ubi_default.save()
    return ubi_default


def ensure_ubicacion_bodega(bodega: Bodega) -> UbicacionBodega:
    """
    Devuelve la primera ubicación de la bodega.
    Si no tiene, crea una ubicación predefinida.
    """
    ubi = bodega.ubicaciones.first()
    if ubi:
        return ubi

    return UbicacionBodega.objects.create(
        bodega=bodega,
        nombre="GENERAL",
        codigo=f"BOD-{bodega.id}-GEN",
    )

# Generación de URLs para códigos QR y de barras usando APIs públicas
def qr_url(data: str, size="180x180"):
    # API pública de QR (PNG), sin token
    return f"https://api.qrserver.com/v1/create-qr-code/?size={size}&data={quote_plus(data)}"

def barcode_url(text: str, bcid="code128", scale=3, height=12, includetext=True):
    # API pública de código de barras (bwip-js), sin token
    it = "y" if includetext else "n"
    return (
        "https://bwipjs-api.metafloor.com/?"
        f"bcid={quote_plus(bcid)}&text={quote_plus(text)}"
        f"&scale={scale}&height={height}&includetext={it}"
    )
# core/utils.py
from urllib.parse import quote_plus

from .models import (
    Sucursal,
    Bodega,
    UbicacionSucursal,
    UbicacionBodega,
)


def ensure_ubicacion_sucursal(sucursal: Sucursal) -> UbicacionSucursal:
    """
    Devuelve la primera ubicación de la sucursal.
    Si no tiene, crea una ubicación predefinida.
    """
    ubi = sucursal.ubicaciones.first()
    if ubi:
        return ubi

    # crea la ubicación DEFAULT para esa sucursal
    return UbicacionSucursal.objects.create(
        sucursal=sucursal,
        nombre="GENERAL",
        codigo=f"SUC-{sucursal.id}-GEN",
    )


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
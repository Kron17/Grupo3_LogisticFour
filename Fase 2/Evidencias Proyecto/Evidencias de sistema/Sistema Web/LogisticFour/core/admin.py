# apps/inventario/admin.py (o core/admin.py)
from django import forms
from django.contrib import admin
from django.contrib.auth.models import User

from .models import (
    # usuarios
    UsuarioPerfil,

    # catálogos
    TasaImpuesto,
    UnidadMedida,             # 👈 IMPORTANTE: la agregamos
    ConversionUM,
    Marca,
    CategoriaProducto,
    TipoUbicacion,

    # org
    Bodega,
    Sucursal,
    UbicacionBodega,
    UbicacionSucursal,

    # productos y stock
    Producto,
    LoteProducto,
    SerieProducto,
    Stock,

    # inventario / movimientos
    TipoMovimiento,
    MovimientoStock,
    AjusteInventario,
    LineaAjusteInventario,
    RecuentoInventario,
    LineaRecuentoInventario,
    Reserva,
    PoliticaReabastecimiento,

    # transferencias / devoluciones
    Transferencia,
    LineaTransferencia,
    DevolucionProveedor,
    LineaDevolucionProveedor,

    # compras
    OrdenCompra,
    LineaOrdenCompra,
    RecepcionMercaderia,
    LineaRecepcionMercaderia,
    FacturaProveedor,

    # alertas / docs
    ReglaAlerta,
    Alerta,
    Notificacion,
    Documento,
    Adjunto,
)

# ==========================
# Ajustes generales
# ==========================
admin.site.site_header = "Logistic — Administración"
admin.site.site_title = "Logistic Admin"
admin.site.index_title = "Panel de Control"


# ==========================
# Usuario + Perfil
# ==========================
@admin.register(UsuarioPerfil)
class UsuarioPerfilAdmin(admin.ModelAdmin):
    list_display = ("usuario", "telefono", "rol", "sucursal")
    search_fields = (
        "usuario__username",
        "usuario__first_name",
        "usuario__last_name",
        "telefono",
    )
    list_filter = ("rol", "sucursal")


# ==========================
# Unidad de Medida  👈 NUEVO
# ==========================
@admin.register(UnidadMedida)
class UnidadMedidaAdmin(admin.ModelAdmin):
    list_display = ("codigo", "descripcion")
    search_fields = ("codigo", "descripcion")


# ==========================
# Producto
# ==========================
@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = (
        "sku",
        "nombre",
        "marca",
        "categoria",
        "stock",
        "unidad_base",
        "precio",   # 👈 sin coma dentro
        "activo",
    )
    search_fields = ("sku", "nombre", "marca__nombre", "categoria__nombre")
    list_filter = ("activo", "marca", "categoria")


# ==========================
# Bodega
# ==========================
@admin.register(Bodega)
class BodegaAdmin(admin.ModelAdmin):
    list_display = ("codigo", "nombre", "direccion", "activo")
    search_fields = ("codigo", "nombre", "direccion")
    list_filter = ("activo",)


# ==========================
# Sucursal
# ==========================
@admin.register(Sucursal)
class SucursalAdmin(admin.ModelAdmin):
    list_display = ("codigo", "nombre", "bodega", "ciudad", "pais", "activo")
    search_fields = ("codigo", "nombre", "direccion", "ciudad", "pais")
    list_filter = ("activo", "bodega")


# ==========================
# TipoUbicacion
# ==========================
@admin.register(TipoUbicacion)
class TipoUbicacionAdmin(admin.ModelAdmin):
    search_fields = ("codigo", "descripcion")


# ==========================
# Ubicaciones separadas
# ==========================
@admin.register(UbicacionBodega)
class UbicacionBodegaAdmin(admin.ModelAdmin):
    list_display = ("bodega", "codigo", "nombre", "area", "tipo", "pickeable", "almacenable", "activo")
    search_fields = ("codigo", "nombre", "area", "bodega__codigo", "bodega__nombre")
    list_filter = ("bodega", "pickeable", "almacenable", "activo")
    autocomplete_fields = ["bodega", "tipo"]


@admin.register(UbicacionSucursal)
class UbicacionSucursalAdmin(admin.ModelAdmin):
    list_display = ("sucursal", "codigo", "nombre", "area", "tipo", "pickeable", "almacenable", "activo")
    search_fields = ("codigo", "nombre", "area", "sucursal__codigo", "sucursal__nombre")
    list_filter = ("sucursal", "pickeable", "almacenable", "activo")
    autocomplete_fields = ["sucursal", "tipo"]


# ==========================
# Marca
# ==========================
@admin.register(Marca)
class MarcaAdmin(admin.ModelAdmin):
    list_display = ("nombre",)
    search_fields = ("nombre",)


# ==========================
# Categoría
# ==========================
@admin.register(CategoriaProducto)
class CategoriaProductoAdmin(admin.ModelAdmin):
    list_display = ("nombre", "codigo", "padre")
    search_fields = ("nombre", "codigo")
    list_filter = ("padre",)


# ==========================
# Tasa impuesto
# ==========================
@admin.register(TasaImpuesto)
class TasaImpuestoAdmin(admin.ModelAdmin):
    list_display = ("nombre", "porcentaje", "activo")
    search_fields = ("nombre",)
    list_filter = ("activo",)


# ==========================
# Lotes
# ==========================
@admin.register(LoteProducto)
class LoteProductoAdmin(admin.ModelAdmin):
    list_display = ("producto", "codigo_lote", "fecha_fabricacion", "fecha_vencimiento")
    search_fields = ("producto__nombre", "codigo_lote")
    list_filter = ("fecha_fabricacion", "fecha_vencimiento")


# ==========================
# Series
# ==========================
@admin.register(SerieProducto)
class SerieProductoAdmin(admin.ModelAdmin):
    list_display = ("producto", "numero_serie", "lote")
    search_fields = ("producto__nombre", "numero_serie")
    list_filter = ("lote",)


# ==========================
# Conversión UM
# ==========================
@admin.register(ConversionUM)
class ConversionUMAdmin(admin.ModelAdmin):
    list_display = ("unidad_desde", "unidad_hasta", "factor")
    search_fields = ("unidad_desde__codigo", "unidad_hasta__codigo")


# ==========================
# Stock
# ==========================
@admin.register(Stock)
class StockAdmin(admin.ModelAdmin):
    list_display = (
        "producto",
        "ubicacion_bodega",
        "ubicacion_sucursal",
        "cantidad_disponible",
    )
    list_filter = ("ubicacion_bodega__bodega", "ubicacion_sucursal__sucursal")
    search_fields = (
        "producto__sku",
        "producto__nombre",
        "ubicacion_bodega__codigo",
        "ubicacion_sucursal__codigo",
    )
    autocomplete_fields = ["producto", "ubicacion_bodega", "ubicacion_sucursal"]


# ==========================
# Movimiento de stock
# ==========================
@admin.register(TipoMovimiento)
class TipoMovimientoAdmin(admin.ModelAdmin):
    list_display = ("codigo", "nombre", "direccion", "afecta_costo")
    search_fields = ("codigo", "nombre")


@admin.register(MovimientoStock)
class MovimientoStockAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "tipo_movimiento",
        "producto",
        "ubicacion_bodega_desde",
        "ubicacion_sucursal_desde",
        "ubicacion_bodega_hasta",
        "ubicacion_sucursal_hasta",
        "cantidad",
        "ocurrido_en",
    )
    list_filter = ("tipo_movimiento", "ocurrido_en")
    search_fields = (
        "producto__sku",
        "producto__nombre",
        "ubicacion_bodega_desde__codigo",
        "ubicacion_sucursal_desde__codigo",
    )
    autocomplete_fields = [
        "producto",
        "ubicacion_bodega_desde",
        "ubicacion_sucursal_desde",
        "ubicacion_bodega_hasta",
        "ubicacion_sucursal_hasta",
    ]


# ==========================
# Ajustes
# ==========================
@admin.register(AjusteInventario)
class AjusteInventarioAdmin(admin.ModelAdmin):
    list_display = ("id", "bodega", "motivo", "estado", "creado_por", "creado_en")
    list_filter = ("estado", "bodega")
    search_fields = ("motivo", "bodega__codigo")
    autocomplete_fields = ["bodega", "creado_por"]


@admin.register(LineaAjusteInventario)
class LineaAjusteInventarioAdmin(admin.ModelAdmin):
    list_display = (
        "ajuste",
        "producto",
        "ubicacion_bodega",
        "ubicacion_sucursal",
        "cantidad_delta",
    )
    autocomplete_fields = ["ajuste", "producto", "ubicacion_bodega", "ubicacion_sucursal"]


# ==========================
# Recuentos
# ==========================
@admin.register(RecuentoInventario)
class RecuentoInventarioAdmin(admin.ModelAdmin):
    list_display = ("id", "bodega", "codigo_ciclo", "estado", "creado_por", "creado_en")
    list_filter = ("estado", "bodega")
    search_fields = ("codigo_ciclo", "bodega__codigo")
    autocomplete_fields = ["bodega", "creado_por"]


@admin.register(LineaRecuentoInventario)
class LineaRecuentoInventarioAdmin(admin.ModelAdmin):
    list_display = (
        "recuento",
        "producto",
        "ubicacion_bodega",
        "ubicacion_sucursal",
        "cantidad_sistema",
        "cantidad_contada",
    )
    autocomplete_fields = ["recuento", "producto", "ubicacion_bodega", "ubicacion_sucursal"]


# ==========================
# Reserva
# ==========================
@admin.register(Reserva)
class ReservaAdmin(admin.ModelAdmin):
    list_display = (
        "producto",
        "ubicacion_bodega",
        "ubicacion_sucursal",
        "cantidad_reservada",
        "tabla_referencia",
        "referencia_id",
    )
    autocomplete_fields = ["producto", "ubicacion_bodega", "ubicacion_sucursal"]


# ==========================
# Política de reabastecimiento
# ==========================
@admin.register(PoliticaReabastecimiento)
class PoliticaReabastecimientoAdmin(admin.ModelAdmin):
    list_display = (
        "producto",
        "ubicacion_bodega",
        "ubicacion_sucursal",
        "cantidad_min",
        "cantidad_max",
        "cantidad_reorden",
        "activo",
    )
    list_filter = ("activo",)
    autocomplete_fields = ["producto", "ubicacion_bodega", "ubicacion_sucursal"]


# ==========================
# Transferencias
# ==========================
@admin.register(Transferencia)
class TransferenciaAdmin(admin.ModelAdmin):
    list_display = ("bodega_origen", "sucursal_destino", "estado", "creado_por", "creado_en")
    search_fields = ("bodega_origen__codigo", "sucursal_destino__codigo", "estado")
    list_filter = ("estado",)
    autocomplete_fields = ["bodega_origen", "sucursal_destino", "creado_por"]


@admin.register(LineaTransferencia)
class LineaTransferenciaAdmin(admin.ModelAdmin):
    list_display = ("transferencia", "producto", "cantidad",)
    autocomplete_fields = ["transferencia", "producto"]


# ============== Devolución a Proveedor ==============
@admin.register(DevolucionProveedor)
class DevolucionProveedorAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "proveedor",
        "bodega",
        "estado",
        "creado_en",
    )
    search_fields = (
        "proveedor__username",
        "proveedor__first_name",
        "proveedor__last_name",
        "bodega__codigo",
        "bodega__nombre",
        "estado",
    )
    list_filter = (
        "estado",
        "bodega",
        "creado_en",
    )
    autocomplete_fields = (
        "proveedor",
        "bodega",
        "creado_por",
    )


# ============== Líneas de Devolución a Proveedor ==============
@admin.register(LineaDevolucionProveedor)
class LineaDevolucionProveedorAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "devolucion",
        "producto",
        "cantidad",
    )
    search_fields = (
        "devolucion__id",
        "devolucion__proveedor__username",
        "devolucion__proveedor__first_name",
        "devolucion__proveedor__last_name",
        "producto__sku",
        "producto__nombre",
    )
    autocomplete_fields = (
        "devolucion",
        "producto",
        "lote",
        "serie",
        "unidad",    # 👈 ya NO dará error porque arriba registramos UnidadMedida
    )


# ==========================
# Compras
# ==========================
@admin.register(OrdenCompra)
class OrdenCompraAdmin(admin.ModelAdmin):
    list_display = ("numero_orden", "proveedor", "bodega", "estado", "fecha_esperada")
    list_filter = ("estado", "bodega")
    search_fields = ("numero_orden", "proveedor__username")
    autocomplete_fields = ["proveedor", "bodega"]


@admin.register(LineaOrdenCompra)
class LineaOrdenCompraAdmin(admin.ModelAdmin):
    list_display = ("orden_compra", "producto", "cantidad_pedida", "precio")
    autocomplete_fields = ["orden_compra", "producto"]


@admin.register(RecepcionMercaderia)
class RecepcionMercaderiaAdmin(admin.ModelAdmin):
    list_display = ("numero_recepcion", "bodega", "estado", "recibido_por", "recibido_en")
    list_filter = ("estado", "bodega")
    search_fields = ("numero_recepcion",)
    autocomplete_fields = ["bodega", "orden_compra", "recibido_por"]


@admin.register(LineaRecepcionMercaderia)
class LineaRecepcionMercaderiaAdmin(admin.ModelAdmin):
    list_display = ("recepcion", "producto", "cantidad_recibida")
    autocomplete_fields = ["recepcion", "producto"]


@admin.register(FacturaProveedor)
class FacturaProveedorAdmin(admin.ModelAdmin):
    list_display = ("proveedor", "numero_factura", "monto_total", "estado", "fecha_factura")
    list_filter = ("estado",)
    search_fields = ("numero_factura", "proveedor__username")
    autocomplete_fields = ["proveedor"]


# ==========================
# Alertas / Notificaciones
# ==========================
@admin.register(ReglaAlerta)
class ReglaAlertaAdmin(admin.ModelAdmin):
    list_display = ("codigo", "nombre", "activo")
    search_fields = ("codigo", "nombre")
    list_filter = ("activo",)


@admin.register(Alerta)
class AlertaAdmin(admin.ModelAdmin):
    list_display = ("regla", "producto", "ubicacion_bodega", "ubicacion_sucursal", "severidad", "mensaje", "reconocida_por")
    list_filter = ("severidad", "regla")
    search_fields = ("mensaje", "producto__nombre")
    autocomplete_fields = ["regla", "producto", "ubicacion_bodega", "ubicacion_sucursal", "reconocida_por"]


@admin.register(Notificacion)
class NotificacionAdmin(admin.ModelAdmin):
    list_display = ("usuario", "titulo", "leida", "creado_en")
    list_filter = ("leida",)
    search_fields = ("titulo", "usuario__username")
    autocomplete_fields = ["usuario"]


# ==========================
# Documentos
# ==========================
@admin.register(Documento)
class DocumentoAdmin(admin.ModelAdmin):
    list_display = ("tipo", "titulo", "creado_por", "creado_en")
    search_fields = ("titulo", "tipo")
    list_filter = ("tipo",)
    autocomplete_fields = ["creado_por"]


@admin.register(Adjunto)
class AdjuntoAdmin(admin.ModelAdmin):
    list_display = ("documento", "producto", "proveedor", "url_archivo", "nombre_archivo")
    search_fields = ("documento__titulo", "producto__nombre", "proveedor__username")
    list_filter = ("documento",)
    autocomplete_fields = ["documento", "producto", "proveedor"]

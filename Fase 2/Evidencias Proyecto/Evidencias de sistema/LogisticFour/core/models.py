# apps/inventario/models.py
from django.db import models
from django.contrib.auth.models import User, Group
from django.core.exceptions import ValidationError
from django.db.models.signals import post_save
from django.dispatch import receiver
import segno
from django.urls import reverse
from django.conf import settings


# =============================================
# Helpers
# =============================================

class MarcaTiempo(models.Model):
    creado_en = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True


# =============================================
# Usuario base de Django + Perfil (rol/dirección/proveedor)
# =============================================

class UsuarioPerfil(MarcaTiempo):
    class Rol(models.TextChoices):
        ADMIN = "ADMIN", "Administrador"
        BODEGUERO = "BODEGUERO", "Bodeguero"
        AUDITOR = "AUDITOR", "Auditor"
        PROVEEDOR = "PROVEEDOR", "Proveedor"

    usuario = models.OneToOneField(User, on_delete=models.CASCADE, related_name="perfil")

    rut = models.CharField(max_length=20, blank=True)
    telefono = models.CharField(max_length=50, blank=True)
    rol = models.CharField(max_length=20, choices=Rol.choices, default=Rol.BODEGUERO)

    class Meta:
        db_table = "usuarios_perfil"

    def __str__(self):
        return f"{self.usuario.get_full_name() or self.usuario.username} ({self.rol})"


@receiver(post_save, sender=User)
def crear_o_actualizar_perfil(sender, instance, created, **kwargs):
    if created:
        UsuarioPerfil.objects.create(usuario=instance)
    else:
        UsuarioPerfil.objects.get_or_create(usuario=instance)

    # sincronizar Group según rol (útil para permisos por grupos)
    perfil = instance.perfil
    if perfil.rol:
        for code, _ in UsuarioPerfil.Rol.choices:
            Group.objects.get_or_create(name=code)
        instance.groups.clear()
        instance.groups.add(Group.objects.get(name=perfil.rol))


# =============================================
# 0) Catálogos / Utilidades
# =============================================

class TasaImpuesto(MarcaTiempo):
    nombre = models.CharField(max_length=100)
    porcentaje = models.DecimalField(max_digits=6, decimal_places=3)  # 19.000
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "tasas_impuesto"

    def __str__(self):
        return f"{self.nombre} ({self.porcentaje}%)"


class UnidadMedida(MarcaTiempo):
    codigo = models.CharField(max_length=20, unique=True)  # EA, KG, LT
    descripcion = models.CharField(max_length=200)

    class Meta:
        db_table = "unidades_medida"

    def __str__(self):
        return self.codigo


class ConversionUM(models.Model):
    unidad_desde = models.ForeignKey(UnidadMedida, on_delete=models.CASCADE, related_name="conversiones_desde")
    unidad_hasta = models.ForeignKey(UnidadMedida, on_delete=models.CASCADE, related_name="conversiones_hasta")
    factor = models.DecimalField(max_digits=20, decimal_places=6)

    class Meta:
        db_table = "conversiones_um"
        constraints = [
            models.UniqueConstraint(fields=["unidad_desde", "unidad_hasta"], name="uq_conversion_um")
        ]


class Marca(MarcaTiempo):
    nombre = models.CharField(max_length=150, unique=True)

    class Meta:
        db_table = "marcas"

    def __str__(self):
        return self.nombre


class CategoriaProducto(MarcaTiempo):
    padre = models.ForeignKey("self", on_delete=models.SET_NULL, null=True, blank=True)
    nombre = models.CharField(max_length=150)
    codigo = models.CharField(max_length=50, blank=True)

    class Meta:
        db_table = "categorias_productos"

    def __str__(self):
        return self.nombre


# =============================================
# 1) Organización / Ubicaciones
# =============================================

class Sucursal(MarcaTiempo):
    codigo = models.CharField(max_length=30, unique=True)
    nombre = models.CharField(max_length=150)
    direccion = models.TextField(blank=True)
    ciudad = models.CharField(max_length=120, blank=True)
    region = models.CharField(max_length=120, blank=True)
    pais = models.CharField(max_length=120, default="Chile")
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "sucursales"

    def __str__(self):
        return f"{self.codigo} - {self.nombre}"


class Bodega(MarcaTiempo):
    sucursal = models.ForeignKey(Sucursal, on_delete=models.CASCADE, related_name="bodegas")
    codigo = models.CharField(max_length=30)
    nombre = models.CharField(max_length=150)
    descripcion = models.TextField(blank=True)
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "bodegas"
        constraints = [
            models.UniqueConstraint(fields=["sucursal", "codigo"], name="uq_bodega_sucursal_codigo")
        ]

    def __str__(self):
        return f"{self.sucursal.codigo}:{self.codigo}"


class AreaBodega(models.Model):
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE, related_name="areas")
    codigo = models.CharField(max_length=30)
    nombre = models.CharField(max_length=150)

    class Meta:
        db_table = "areas_bodega"
        constraints = [
            models.UniqueConstraint(fields=["bodega", "codigo"], name="uq_area_bodega_codigo")
        ]


class TipoUbicacion(models.Model):
    codigo = models.CharField(max_length=30, unique=True)  # BIN, RACK, FLOOR, STAGE
    descripcion = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = "tipos_ubicacion"


class Ubicacion(MarcaTiempo):
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE, related_name="ubicaciones")
    area = models.ForeignKey(AreaBodega, on_delete=models.SET_NULL, null=True, blank=True)
    tipo = models.ForeignKey(TipoUbicacion, on_delete=models.SET_NULL, null=True, blank=True)
    codigo = models.CharField(max_length=60)  # R01-A2-B3
    nombre = models.CharField(max_length=150, blank=True)
    pickeable = models.BooleanField(default=True)
    almacenable = models.BooleanField(default=True)

    class Meta:
        db_table = "ubicaciones"
        constraints = [
            models.UniqueConstraint(fields=["bodega", "codigo"], name="uq_ubicacion_bodega_codigo")
        ]

    def __str__(self):
        return f"{self.bodega}:{self.codigo}"


# =============================================
# 2) Bitácora de Auditoría
# =============================================

class BitacoraAuditoria(MarcaTiempo):
    usuario = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    accion = models.CharField(max_length=100)
    tabla = models.CharField(max_length=100, blank=True)
    entidad_id = models.BigIntegerField(null=True, blank=True)
    detalle = models.JSONField(null=True, blank=True)

    class Meta:
        db_table = "bitacora_auditoria"


# =============================================
# 3) Productos y Datos Maestros
# =============================================

class Producto(MarcaTiempo):
    sku = models.CharField(max_length=100, unique=True)
    nombre = models.CharField(max_length=200)
    marca = models.ForeignKey(Marca, on_delete=models.SET_NULL, null=True, blank=True)
    categoria = models.ForeignKey(CategoriaProducto, on_delete=models.SET_NULL, null=True, blank=True)
    unidad_base = models.ForeignKey(UnidadMedida, on_delete=models.CASCADE)
    tasa_impuesto = models.ForeignKey(TasaImpuesto, on_delete=models.SET_NULL, null=True, blank=True)
    activo = models.BooleanField(default=True)
    es_serializado = models.BooleanField(default=False)
    tiene_vencimiento = models.BooleanField(default=False)


    @property
    def qr_svg(self):
        """
        Devuelve un SVG embebible con el QR del producto.
        El payload apunta al detalle del producto.
        """
        path = reverse("core:producto-detail", kwargs={"pk": self.pk})
        base = getattr(settings, "SITE_URL", "").rstrip("/")
        payload = f"{base}{path}" if base else path
        qr = segno.make(payload)
        return qr.svg_inline(scale=4)  # ajusta scale si lo quieres más grande/pequeño

    class Meta:
        db_table = "productos"

    def __str__(self):
        return f"{self.sku} - {self.nombre}"


class ProductoUsuarioProveedor(models.Model):
    """
    Relación Producto ↔ Usuario con rol PROVEEDOR
    """
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="usuarios_proveedor")
    proveedor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="productos_suministrados")
    sku_proveedor = models.CharField(max_length=100, blank=True)
    tiempo_entrega_dias = models.IntegerField(default=7)
    cantidad_min_pedido = models.DecimalField(max_digits=20, decimal_places=6, default=1)

    class Meta:
        db_table = "productos_usuarios_proveedor"
        constraints = [
            models.UniqueConstraint(fields=["producto", "proveedor"], name="uq_producto_usuario_proveedor")
        ]

    def clean(self):
        perfil = getattr(self.proveedor, "perfil", None)
        if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
            raise ValidationError("El usuario seleccionado debe tener rol PROVEEDOR.")


class ImagenProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="imagenes")
    url = models.URLField()
    texto_alternativo = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = "imagenes_producto"


class PrecioProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="precios")
    precio = models.DecimalField(max_digits=14, decimal_places=4)
    vigente_desde = models.DateField(auto_now_add=True)
    vigente_hasta = models.DateField(null=True, blank=True)
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "precios_producto"


class DefinicionAtributo(models.Model):
    codigo = models.CharField(max_length=50, unique=True)    # COLOR, TALLA
    nombre = models.CharField(max_length=100)
    tipo_dato = models.CharField(max_length=20)              # TEXT, NUMBER, BOOLEAN, DATE

    class Meta:
        db_table = "definiciones_atributos"


class AtributoProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="atributos")
    atributo = models.ForeignKey(DefinicionAtributo, on_delete=models.CASCADE)
    valor_texto = models.TextField(null=True, blank=True)
    valor_numero = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)
    valor_booleano = models.BooleanField(null=True, blank=True)
    valor_fecha = models.DateField(null=True, blank=True)

    class Meta:
        db_table = "atributos_producto"
        constraints = [
            models.UniqueConstraint(fields=["producto", "atributo"], name="uq_producto_atributo")
        ]


class LoteProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="lotes")
    codigo_lote = models.CharField(max_length=100)
    fecha_vencimiento = models.DateField(null=True, blank=True)
    fecha_fabricacion = models.DateField(null=True, blank=True)

    class Meta:
        db_table = "lotes_producto"
        constraints = [
            models.UniqueConstraint(fields=["producto", "codigo_lote"], name="uq_producto_lote")
        ]


class SerieProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="series")
    numero_serie = models.CharField(max_length=150)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "series_producto"
        constraints = [
            models.UniqueConstraint(fields=["producto", "numero_serie"], name="uq_producto_numero_serie")
        ]


# =============================================
# 4) Inventario (Stock, Movimientos, Recuentos)
# =============================================

class Stock(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="stocks")
    ubicacion = models.ForeignKey(Ubicacion, on_delete=models.CASCADE, related_name="stocks")
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_disponible = models.DecimalField(max_digits=20, decimal_places=6, default=0)
    cantidad_reservada = models.DecimalField(max_digits=20, decimal_places=6, default=0)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "stock"
        constraints = [
            models.UniqueConstraint(fields=["producto", "ubicacion", "lote", "serie"], name="uq_stock_prod_ubi_lote_serie")
        ]
        indexes = [
            models.Index(fields=["producto"], name="idx_stock_producto"),
            models.Index(fields=["ubicacion"], name="idx_stock_ubicacion"),
        ]


class TipoMovimiento(models.Model):
    codigo = models.CharField(max_length=30, unique=True)  # IN, OUT, TRANSFER, ADJUST_POS, ADJUST_NEG, RETURN_SUPPLIER
    nombre = models.CharField(max_length=100)
    direccion = models.SmallIntegerField()                 # +1, -1, 0
    afecta_costo = models.BooleanField(default=True)

    class Meta:
        db_table = "tipos_movimiento"


class MovimientoStock(models.Model):
    tipo_movimiento = models.ForeignKey(TipoMovimiento, on_delete=models.CASCADE)
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    ubicacion_desde = models.ForeignKey(Ubicacion, on_delete=models.SET_NULL, null=True, blank=True, related_name="movimientos_desde")
    ubicacion_hasta = models.ForeignKey(Ubicacion, on_delete=models.SET_NULL, null=True, blank=True, related_name="movimientos_hasta")
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad = models.DecimalField(max_digits=20, decimal_places=6)
    unidad = models.ForeignKey(UnidadMedida, on_delete=models.SET_NULL, null=True, blank=True)
    tabla_referencia = models.CharField(max_length=100, blank=True)
    referencia_id = models.BigIntegerField(null=True, blank=True)
    ocurrido_en = models.DateTimeField(auto_now_add=True)
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    notas = models.TextField(blank=True)

    class Meta:
        db_table = "movimientos_stock"
        indexes = [
            models.Index(fields=["producto", "ocurrido_en"], name="idx_mov_stock_prod_fecha"),
        ]


class AjusteInventario(MarcaTiempo):
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    motivo = models.CharField(max_length=120)                      # MERMA, RECUENTO, CORRECCION
    estado = models.CharField(max_length=30, default="OPEN")       # OPEN, APPROVED, POSTED, VOID
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "ajustes_inventario"


class LineaAjusteInventario(models.Model):
    ajuste = models.ForeignKey(AjusteInventario, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    ubicacion = models.ForeignKey(Ubicacion, on_delete=models.CASCADE)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_delta = models.DecimalField(max_digits=20, decimal_places=6)  # + agrega, - resta
    motivo = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = "lineas_ajuste_inventario"


class RecuentoInventario(MarcaTiempo):
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    codigo_ciclo = models.CharField(max_length=60, blank=True)     # p.ej. CYCLE-SEP-2025
    estado = models.CharField(max_length=30, default="OPEN")       # OPEN, COUNTING, REVIEW, POSTED
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "recuentos_inventario"


class LineaRecuentoInventario(models.Model):
    recuento = models.ForeignKey(RecuentoInventario, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    ubicacion = models.ForeignKey(Ubicacion, on_delete=models.CASCADE)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_sistema = models.DecimalField(max_digits=20, decimal_places=6, default=0)
    cantidad_contada = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)
    contado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    diferencia = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)

    class Meta:
        db_table = "lineas_recuento_inventario"


class Reserva(MarcaTiempo):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    ubicacion = models.ForeignKey(Ubicacion, on_delete=models.CASCADE)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_reservada = models.DecimalField(max_digits=20, decimal_places=6)
    tabla_referencia = models.CharField(max_length=100, blank=True)
    referencia_id = models.BigIntegerField(null=True, blank=True)

    class Meta:
        db_table = "reservas"


class PoliticaReabastecimiento(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    ubicacion = models.ForeignKey(Ubicacion, on_delete=models.CASCADE, null=True, blank=True)
    cantidad_min = models.DecimalField(max_digits=20, decimal_places=6, default=0)
    cantidad_max = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)
    cantidad_reorden = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)
    dias_cobertura = models.IntegerField(null=True, blank=True)
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "politicas_reabastecimiento"
        constraints = [
            models.UniqueConstraint(fields=["producto", "ubicacion"], name="uq_politica_reabastecimiento")
        ]


# =============================================
# 5) Transferencias & Devoluciones a Proveedor
# =============================================

class Transferencia(MarcaTiempo):
    bodega_origen = models.ForeignKey(Bodega, on_delete=models.CASCADE, related_name="transferencias_salida")
    bodega_destino = models.ForeignKey(Bodega, on_delete=models.CASCADE, related_name="transferencias_entrada")
    estado = models.CharField(max_length=30, default="DRAFT")  # DRAFT, IN_TRANSIT, RECEIVED, CANCELED
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "transferencias"


class LineaTransferencia(models.Model):
    transferencia = models.ForeignKey(Transferencia, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad = models.DecimalField(max_digits=20, decimal_places=6)
    unidad = models.ForeignKey(UnidadMedida, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "lineas_transferencia"


class DevolucionProveedor(MarcaTiempo):
    proveedor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="devoluciones_recibidas")
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    estado = models.CharField(max_length=30, default="DRAFT")  # DRAFT, SENT, RECEIVED, CANCELED
    motivo = models.CharField(max_length=200, blank=True)
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "devoluciones_proveedor"

    def clean(self):
        perfil = getattr(self.proveedor, "perfil", None)
        if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
            raise ValidationError("El proveedor debe ser un Usuario con rol PROVEEDOR.")


class LineaDevolucionProveedor(models.Model):
    devolucion = models.ForeignKey(DevolucionProveedor, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad = models.DecimalField(max_digits=20, decimal_places=6)
    unidad = models.ForeignKey(UnidadMedida, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "lineas_devolucion_proveedor"


# =============================================
# 6) Compras (OC / Recepciones / Facturas Proveedor)
# =============================================

class OrdenCompra(MarcaTiempo):
    proveedor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="ordenes_compra_proveedor")
    tasa_impuesto = models.ForeignKey(TasaImpuesto, on_delete=models.SET_NULL, null=True, blank=True)
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    numero_orden = models.CharField(max_length=60, unique=True)
    estado = models.CharField(max_length=30, default="DRAFT")  # DRAFT, APPROVED, PARTIAL, RECEIVED, CLOSED, CANCELED
    fecha_esperada = models.DateField(null=True, blank=True)
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "ordenes_compra"

    def __str__(self):
        return self.numero_orden

    def clean(self):
        perfil = getattr(self.proveedor, "perfil", None)
        if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
            raise ValidationError("El proveedor debe ser un Usuario con rol PROVEEDOR.")


class LineaOrdenCompra(models.Model):
    orden_compra = models.ForeignKey(OrdenCompra, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    descripcion = models.TextField(blank=True)
    cantidad_pedida = models.DecimalField(max_digits=20, decimal_places=6)
    unidad = models.ForeignKey(UnidadMedida, on_delete=models.CASCADE)
    precio = models.DecimalField(max_digits=14, decimal_places=4)
    descuento_pct = models.DecimalField(max_digits=6, decimal_places=3, default=0)

    class Meta:
        db_table = "lineas_orden_compra"


class RecepcionMercaderia(MarcaTiempo):
    orden_compra = models.ForeignKey(OrdenCompra, on_delete=models.SET_NULL, null=True, blank=True)
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    numero_recepcion = models.CharField(max_length=60, unique=True)
    estado = models.CharField(max_length=30, default="OPEN")  # OPEN, POSTED, CANCELED
    recibido_en = models.DateTimeField(auto_now_add=True)
    recibido_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "recepciones_mercaderia"


class LineaRecepcionMercaderia(models.Model):
    recepcion = models.ForeignKey(RecepcionMercaderia, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)
    cantidad_recibida = models.DecimalField(max_digits=20, decimal_places=6)
    unidad = models.ForeignKey(UnidadMedida, on_delete=models.SET_NULL, null=True, blank=True)
    fecha_vencimiento = models.DateField(null=True, blank=True)

    class Meta:
        db_table = "lineas_recepcion_mercaderia"


class FacturaProveedor(models.Model):
    proveedor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="facturas_emitidas")
    numero_factura = models.CharField(max_length=80)
    tasa_impuesto = models.ForeignKey(TasaImpuesto, on_delete=models.SET_NULL, null=True, blank=True)
    monto_total = models.DecimalField(max_digits=14, decimal_places=4)
    fecha_factura = models.DateField()
    fecha_vencimiento = models.DateField(null=True, blank=True)
    estado = models.CharField(max_length=30, default="OPEN")  # OPEN, PAID, CANCELED

    class Meta:
        db_table = "facturas_proveedor"
        constraints = [
            models.UniqueConstraint(fields=["proveedor", "numero_factura"], name="uq_proveedor_numero_factura")
        ]

    def clean(self):
        perfil = getattr(self.proveedor, "perfil", None)
        if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
            raise ValidationError("El proveedor debe ser un Usuario con rol PROVEEDOR.")


# =============================================
# 7) Reportes / Alertas / Notificaciones
# =============================================

class ReglaAlerta(MarcaTiempo):
    codigo = models.CharField(max_length=50, unique=True)       # LOW_STOCK
    nombre = models.CharField(max_length=150)
    configuracion = models.JSONField()                          # ej: {"min_qty": 10, "scope": "ubicacion|bodega|global"}
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "reglas_alerta"


class Alerta(MarcaTiempo):
    regla = models.ForeignKey(ReglaAlerta, on_delete=models.SET_NULL, null=True, blank=True)
    producto = models.ForeignKey(Producto, on_delete=models.SET_NULL, null=True, blank=True)
    ubicacion = models.ForeignKey(Ubicacion, on_delete=models.SET_NULL, null=True, blank=True)
    severidad = models.CharField(max_length=20, default="INFO")  # INFO, WARN, CRITICAL
    mensaje = models.TextField()
    reconocida_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="alertas_reconocidas")
    reconocida_en = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = "alertas"


class Notificacion(MarcaTiempo):
    usuario = models.ForeignKey(User, on_delete=models.CASCADE, related_name="notificaciones")
    titulo = models.CharField(max_length=200)
    cuerpo = models.TextField(blank=True)
    leida = models.BooleanField(default=False)

    class Meta:
        db_table = "notificaciones"


# =============================================
# 8) Documentos / Adjuntos
# =============================================

class Documento(MarcaTiempo):
    tipo = models.CharField(max_length=60)   # SDS, Manual, Política, etc.
    titulo = models.CharField(max_length=200)
    descripcion = models.TextField(blank=True)
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "documentos"


class Adjunto(MarcaTiempo):
    documento = models.ForeignKey(Documento, on_delete=models.SET_NULL, null=True, blank=True, related_name="adjuntos")
    producto = models.ForeignKey(Producto, on_delete=models.SET_NULL, null=True, blank=True, related_name="adjuntos")
    proveedor = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="adjuntos_usuario_proveedor")
    url_archivo = models.URLField()
    nombre_archivo = models.CharField(max_length=200, blank=True)
    tipo_contenido = models.CharField(max_length=100, blank=True)

    class Meta:
        db_table = "adjuntos"

    def clean(self):
        if self.proveedor:
            perfil = getattr(self.proveedor, "perfil", None)
            if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
                raise ValidationError("El proveedor del adjunto debe ser un Usuario con rol PROVEEDOR.")
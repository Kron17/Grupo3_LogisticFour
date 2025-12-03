# core/models.py  (o apps/inventario/models.py)
from django.db import models
from django.contrib.auth.models import User, Group
from django.core.exceptions import ValidationError
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings


# ============================================================
#  HELPER BASE
# ============================================================
class MarcaTiempo(models.Model):
    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


# ============================================================
#  USUARIOS / PERFIL
# ============================================================
class UsuarioPerfil(MarcaTiempo):
    class Rol(models.TextChoices):
        ADMIN = "ADMIN", "Administrador"
        BODEGUERO = "BODEGUERO", "Bodeguero"
        AUDITOR = "AUDITOR", "Auditor"
        PROVEEDOR = "PROVEEDOR", "Proveedor"

    usuario = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name="perfil",
    )
    rut = models.CharField(max_length=20, blank=True)
    telefono = models.CharField(max_length=50, blank=True)
    # si quieres fijar a una sucursal
    sucursal = models.ForeignKey(
        "Sucursal",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="usuarios",
    )
    rol = models.CharField(
        max_length=20,
        choices=Rol.choices,
        default=Rol.ADMIN,
    )

    class Meta:
        db_table = "usuarios_perfil"

    def __str__(self):
        return f"{self.usuario.get_full_name() or self.usuario.username} ({self.rol})"


@receiver(post_save, sender=User)
def crear_o_actualizar_perfil(sender, instance, created, **kwargs):
    # crear perfil
    if created:
        UsuarioPerfil.objects.create(usuario=instance)
    else:
        UsuarioPerfil.objects.get_or_create(usuario=instance)

    # sincronizar GRUPO con el rol
    perfil = instance.perfil
    if perfil.rol:
        # asegurar que existen los grupos
        for code, _ in UsuarioPerfil.Rol.choices:
            Group.objects.get_or_create(name=code)

        instance.groups.clear()
        instance.groups.add(Group.objects.get(name=perfil.rol))


# ============================================================
#  CATÁLOGOS
# ============================================================
class TasaImpuesto(MarcaTiempo):
    nombre = models.CharField(max_length=100)
    porcentaje = models.DecimalField(max_digits=6, decimal_places=3)  # 19.000
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "tasas_impuesto"

    def __str__(self):
        return f"{self.nombre} ({self.porcentaje}%)"


class UnidadMedida(MarcaTiempo):
    codigo = models.CharField(max_length=20, unique=True)
    descripcion = models.CharField(max_length=200)

    class Meta:
        db_table = "unidades_medida"

    def __str__(self):
        return self.codigo


class ConversionUM(models.Model):
    unidad_desde = models.ForeignKey(
        UnidadMedida,
        on_delete=models.CASCADE,
        related_name="conversiones_desde",
    )
    unidad_hasta = models.ForeignKey(
        UnidadMedida,
        on_delete=models.CASCADE,
        related_name="conversiones_hasta",
    )
    factor = models.DecimalField(max_digits=20, decimal_places=6)

    class Meta:
        db_table = "conversiones_um"
        constraints = [
            models.UniqueConstraint(
                fields=["unidad_desde", "unidad_hasta"],
                name="uq_conversion_um",
            )
        ]


class Marca(MarcaTiempo):
    nombre = models.CharField(max_length=150, unique=True)

    class Meta:
        db_table = "marcas"

    def __str__(self):
        return self.nombre


class CategoriaProducto(MarcaTiempo):
    padre = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    nombre = models.CharField(max_length=150)
    codigo = models.CharField(max_length=50, blank=True)

    class Meta:
        db_table = "categorias_productos"

    def __str__(self):
        return self.nombre




class BitacoraAuditoria(MarcaTiempo):
    usuario = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    accion = models.CharField(max_length=100)
    tabla = models.CharField(max_length=100, blank=True)
    entidad_id = models.BigIntegerField(null=True, blank=True)
    detalle = models.JSONField(null=True, blank=True)

    class Meta:
        db_table = "bitacora_auditoria"

# ============================================================
# UBICACIONES (SEPARADAS)
# ============================================================
class TipoUbicacion(models.Model):
    codigo = models.CharField(max_length=30, unique=True)  
    descripcion = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = "tipos_ubicacion"

    def __str__(self):
        return f"{self.codigo} — {self.descripcion or ''}".strip(" —")



class UbicacionBodega(models.Model):
    bodega = models.ForeignKey(
        'Bodega',
        on_delete=models.CASCADE,
        related_name="ubicaciones",
    )
    codigo = models.CharField(max_length=60)  # "031-003-001"
    area_codigo = models.CharField(max_length=20, blank=True)
    estante_codigo = models.CharField(max_length=20, blank=True)

    area = models.CharField(max_length=150, null=True, blank=True)
    tipo = models.ForeignKey(TipoUbicacion, on_delete=models.SET_NULL, null=True, blank=True)

    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "ubicaciones_bodega"
        constraints = [
            models.UniqueConstraint(
                fields=["bodega", "codigo"],
                name="uq_ubi_bodega_codigo",
            )
        ]

    def __str__(self):
        return f"{self.bodega.codigo} / {self.codigo}"

    # 👇 AHORA SOLO RECIBE area_cod y estante_cod
    def set_codigo(self, area_cod, estante_cod):
        """Arma el código usando el código de la bodega como prefijo."""
        prefijo = (self.bodega.codigo or "").strip().upper()
        area_cod = (area_cod or "").strip().upper()
        estante_cod = (estante_cod or "").strip().upper()

        self.codigo = f"{prefijo}-{area_cod}-{estante_cod}"
        self.area_codigo = area_cod
        self.estante_codigo = estante_cod

    def get_codigo_separado(self):
        return {
            "bodega_codigo": (self.bodega.codigo or "").strip().upper(),
            "area_codigo": self.area_codigo,
            "estante_codigo": self.estante_codigo,
        }

class UbicacionSucursal(models.Model):
    sucursal = models.ForeignKey(
        "Sucursal",
        on_delete=models.CASCADE,
        related_name="ubicaciones",
    )
    codigo = models.CharField(max_length=60)  # "SUC01-003-001"
    area_codigo = models.CharField(max_length=20, blank=True)
    estante_codigo = models.CharField(max_length=20, blank=True)

    area = models.CharField(max_length=150, null=True, blank=True)
    tipo = models.ForeignKey(TipoUbicacion, on_delete=models.SET_NULL, null=True, blank=True)

    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "ubicaciones_sucursal"
        constraints = [
            models.UniqueConstraint(
                fields=["sucursal", "codigo"],
                name="uq_ubi_sucursal_codigo",
            )
        ]

    def __str__(self):
        return f"{self.sucursal.codigo} / {self.codigo}"

    def set_codigo(self, area_codigo: str, estante_codigo: str, prefijo: str | None = None):
        """
        Construye `codigo` con:
        - prefijo: código de la sucursal (por defecto self.sucursal.codigo)
        - area_codigo
        - estante_codigo
        """
        area_codigo = (area_codigo or "").strip().upper()
        estante_codigo = (estante_codigo or "").strip().upper()
        if prefijo is None:
            prefijo = (self.sucursal.codigo or "").strip().upper()

        self.area_codigo = area_codigo
        self.estante_codigo = estante_codigo
        self.codigo = f"{prefijo}-{area_codigo}-{estante_codigo}"

    def get_codigo_separado(self) -> dict:
        partes = (self.codigo or "").split("-")
        prefijo = partes[0] if len(partes) > 0 else ""
        area = partes[1] if len(partes) > 1 else ""
        estante = partes[2] if len(partes) > 2 else ""

        return {
            "sucursal_codigo": prefijo,
            "area_codigo": area,
            "estante_codigo": estante,
        }

# ============================================================
# PRODUCTOS
# ============================================================
class Producto(models.Model):
    sku = models.CharField(max_length=100, unique=True)
    nombre = models.CharField(max_length=200)

    marca = models.ForeignKey('Marca', on_delete=models.SET_NULL, null=True, blank=True)
    categoria = models.ForeignKey('CategoriaProducto', on_delete=models.SET_NULL, null=True, blank=True)
    unidad_base = models.ForeignKey('UnidadMedida', on_delete=models.CASCADE)
    tasa_impuesto = models.ForeignKey('TasaImpuesto', on_delete=models.SET_NULL, null=True, blank=True)

    activo = models.BooleanField(default=True)
    es_serializado = models.BooleanField(default=False)
    tiene_vencimiento = models.BooleanField(default=False)

    precio = models.PositiveIntegerField(default=0)
    stock = models.PositiveIntegerField(default=0)

    # Relación muchos a muchos con UbicacionBodega y UbicacionSucursal
    ubicaciones_bodega = models.ManyToManyField(UbicacionBodega, related_name="productos_bodega", blank=True)
    ubicaciones_sucursal = models.ManyToManyField(UbicacionSucursal, related_name="productos_sucursal", blank=True)

    class Meta:
        db_table = "productos"

    def __str__(self):
        return f"{self.sku} - {self.nombre}"



# ============================================================
# BODEGA / SUCURSAL
# ============================================================
class Bodega(MarcaTiempo):
    codigo = models.CharField(max_length=30)
    nombre = models.CharField(max_length=150)
    direccion = models.CharField(blank=True, max_length=255)
    descripcion = models.TextField(blank=True)
    activo = models.BooleanField(default=True)

    productos = models.ManyToManyField(Producto, blank=True, related_name="bodegas")

    class Meta:
        db_table = "bodegas"

    def __str__(self):
        return f"{self.codigo}: {self.nombre}"


class Sucursal(MarcaTiempo):
    codigo = models.CharField(max_length=30, unique=True)
    nombre = models.CharField(max_length=150)
    direccion = models.TextField(blank=True)
    ciudad = models.CharField(max_length=120, blank=True)
    region = models.CharField(max_length=120, blank=True)
    pais = models.CharField(max_length=120, default="Chile")
    activo = models.BooleanField(default=True)

    bodega = models.ForeignKey(
        Bodega,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="sucursales",
    )

    productos = models.ManyToManyField(Producto, blank=True, related_name="sucursales")

    class Meta:
        db_table = "sucursales"

    def __str__(self):
        return f"{self.codigo} - {self.nombre}"

# ============================================================
#  STOCK
# ============================================================ubicaciones_sucursal
class Stock(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="stocks")
    ubicacion_bodega = models.ForeignKey(
        UbicacionBodega,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="stocks",
    )
    ubicacion_sucursal = models.ForeignKey(
        UbicacionSucursal,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="stocks",
    )

    cantidad_disponible = models.DecimalField(max_digits=20, decimal_places=6, default=0)

    # NUEVO: cupo de stock validado para movimientos
    cantidad_validada = models.DecimalField(
        max_digits=20,
        decimal_places=6,
        default=0,
        help_text="Cantidad validada para movimientos desde esta ubicación."
    )

    class Meta:
        db_table = "stock"
        constraints = [
            models.UniqueConstraint(
                fields=["producto", "ubicacion_bodega"],
                name="uq_stock_prod_ubi_bodega",
            ),
            models.UniqueConstraint(
                fields=["producto", "ubicacion_sucursal"],
                name="uq_stock_prod_ubi_sucursal",
            ),
        ]

# ============================================================
#  PROVEEDORES / LOTES / SERIES
# ============================================================
class ProductoUsuarioProveedor(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="usuarios_proveedor")
    proveedor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="productos_suministrados")
    sku_proveedor = models.CharField(max_length=100, blank=True)
    tiempo_entrega_dias = models.IntegerField(default=7)
    cantidad_min_pedido = models.DecimalField(max_digits=20, decimal_places=6, default=1)

    class Meta:
        db_table = "productos_usuarios_proveedor"
        constraints = [
            models.UniqueConstraint(
                fields=["producto", "proveedor"],
                name="uq_producto_usuario_proveedor",
            )
        ]

    def clean(self):
        perfil = getattr(self.proveedor, "perfil", None)
        if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
            raise ValidationError("El usuario seleccionado debe tener rol PROVEEDOR.")


class LoteProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="lotes")
    codigo_lote = models.CharField(max_length=100)
    fecha_vencimiento = models.DateField(null=True, blank=True)
    fecha_fabricacion = models.DateField(null=True, blank=True)

    class Meta:
        db_table = "lotes_producto"
        constraints = [
            models.UniqueConstraint(
                fields=["producto", "codigo_lote"],
                name="uq_producto_lote",
            )
        ]


class SerieProducto(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE, related_name="series")
    numero_serie = models.CharField(max_length=150)
    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "series_producto"
        constraints = [
            models.UniqueConstraint(
                fields=["producto", "numero_serie"],
                name="uq_producto_numero_serie",
            )
        ]


# ============================================================
#  TIPOS DE MOVIMIENTO
# ============================================================
class TipoMovimiento(models.Model):
    codigo = models.CharField(max_length=30, unique=True)
    nombre = models.CharField(max_length=100)
    direccion = models.SmallIntegerField()  # +1, -1, 0
    afecta_costo = models.BooleanField(default=True)

    class Meta:
        db_table = "tipos_movimiento"

    def __str__(self):
        return self.nombre


# ============================================================
#  MOVIMIENTO DE STOCK (con 4 FKs)
# ============================================================
class MovimientoStock(models.Model):
    tipo_movimiento = models.ForeignKey(TipoMovimiento, on_delete=models.CASCADE)
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)

    # ORIGEN
    ubicacion_bodega_desde = models.ForeignKey(
        UbicacionBodega,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="movimientos_salida_desde_bodega",
    )
    ubicacion_sucursal_desde = models.ForeignKey(
        UbicacionSucursal,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="movimientos_salida_desde_sucursal",
    )

    # DESTINO
    ubicacion_bodega_hasta = models.ForeignKey(
        UbicacionBodega,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="movimientos_entrada_a_bodega",
    )
    ubicacion_sucursal_hasta = models.ForeignKey(
        UbicacionSucursal,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="movimientos_entrada_a_sucursal",
    )

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

    def __str__(self):
        return f"Mov {self.pk} {self.producto} {self.cantidad}"


# ============================================================
#  AJUSTES / RECUENTOS / RESERVAS
# ============================================================
class AjusteInventario(MarcaTiempo):
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    motivo = models.CharField(max_length=120)
    estado = models.CharField(max_length=30, default="OPEN")
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "ajustes_inventario"


class LineaAjusteInventario(models.Model):
    ajuste = models.ForeignKey(AjusteInventario, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)

    # ahora dos opciones:
    ubicacion_bodega = models.ForeignKey(UbicacionBodega, on_delete=models.CASCADE, null=True, blank=True)
    ubicacion_sucursal = models.ForeignKey(UbicacionSucursal, on_delete=models.CASCADE, null=True, blank=True)

    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)

    cantidad_delta = models.DecimalField(max_digits=20, decimal_places=6)
    motivo = models.CharField(max_length=200, blank=True)

    class Meta:
        db_table = "lineas_ajuste_inventario"


class RecuentoInventario(MarcaTiempo):
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    codigo_ciclo = models.CharField(max_length=60, blank=True)
    estado = models.CharField(max_length=30, default="OPEN")
    creado_por = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)

    class Meta:
        db_table = "recuentos_inventario"


class LineaRecuentoInventario(models.Model):
    recuento = models.ForeignKey(RecuentoInventario, on_delete=models.CASCADE, related_name="lineas")
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)

    ubicacion_bodega = models.ForeignKey(UbicacionBodega, on_delete=models.CASCADE, null=True, blank=True)
    ubicacion_sucursal = models.ForeignKey(UbicacionSucursal, on_delete=models.CASCADE, null=True, blank=True)

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

    ubicacion_bodega = models.ForeignKey(UbicacionBodega, on_delete=models.CASCADE, null=True, blank=True)
    ubicacion_sucursal = models.ForeignKey(UbicacionSucursal, on_delete=models.CASCADE, null=True, blank=True)

    lote = models.ForeignKey(LoteProducto, on_delete=models.SET_NULL, null=True, blank=True)
    serie = models.ForeignKey(SerieProducto, on_delete=models.SET_NULL, null=True, blank=True)

    cantidad_reservada = models.DecimalField(max_digits=20, decimal_places=6)
    tabla_referencia = models.CharField(max_length=100, blank=True)
    referencia_id = models.BigIntegerField(null=True, blank=True)

    class Meta:
        db_table = "reservas"

class PoliticaReabastecimiento(models.Model):
    producto = models.ForeignKey(Producto, on_delete=models.CASCADE)
    ubicacion_bodega = models.ForeignKey(UbicacionBodega, on_delete=models.CASCADE, null=True, blank=True)
    ubicacion_sucursal = models.ForeignKey(UbicacionSucursal, on_delete=models.CASCADE, null=True, blank=True)
    cantidad_min = models.DecimalField(max_digits=20, decimal_places=6, default=0)
    cantidad_max = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)
    cantidad_reorden = models.DecimalField(max_digits=20, decimal_places=6, null=True, blank=True)
    dias_cobertura = models.IntegerField(null=True, blank=True)
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "politicas_reabastecimiento"
        constraints = [
            models.UniqueConstraint(
                fields=["producto", "ubicacion_bodega", "ubicacion_sucursal"],
                name="uq_politica_reabastecimiento",
            )
        ]


# ============================================================
#  TRANSFERENCIAS / DEVOLUCIONES
# ============================================================
class Transferencia(MarcaTiempo):
    TIPO_CHOICES = [
        ("BOD_BOD", "Bodega → Bodega"),
        ("BOD_SUC", "Bodega → Sucursal"),
        ("SUC_BOD", "Sucursal → Bodega"),
        ("SUC_SUC", "Sucursal ↔ Sucursal"),
    ]

    tipo_movimiento = models.CharField(
        max_length=20,
        choices=TIPO_CHOICES,
        default="BOD_BOD",
    )

    bodega_origen = models.ForeignKey(
        Bodega,
        on_delete=models.CASCADE,
        related_name="transferencias_origen",
        null=True,
        blank=True,
    )

    bodega_destino = models.ForeignKey(
        Bodega,
        on_delete=models.CASCADE,
        related_name="transferencias_destino",
        null=True,
        blank=True,
    )

    # NUEVO: sucursal origen
    sucursal_origen = models.ForeignKey(
        Sucursal,
        on_delete=models.CASCADE,
        related_name="transferencias_sucursal_origen",
        null=True,
        blank=True,
    )

    # ya la tenías:
    sucursal_destino = models.ForeignKey(
        Sucursal,
        on_delete=models.CASCADE,
        related_name="transferencias_sucursal_destino",
        null=True,
        blank=True,
    )

    numero_guia = models.CharField(max_length=20, null=True, blank=True)
    fecha_emision = models.DateField(null=True, blank=True)

    estado = models.CharField(max_length=30, default="DRAFT")
    creado_por = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )

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
    estado = models.CharField(max_length=30, default="DRAFT")
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


# ============================================================
#  COMPRAS
# ============================================================
class OrdenCompra(MarcaTiempo):
    class EstadoOC(models.TextChoices):
        DRAFT = "DRAFT", "Borrador"
        APROBADA = "APROBADA", "Aprobada"
        CERRADA = "CERRADA", "Cerrada"
        PARTIAL = "PARTIAL", "Recepción parcial"
        RECEIVED = "RECEIVED", "Recepcionada"
        CANCELLED = "CANCELLED", "Cancelada"

    proveedor = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="ordenes_compra_proveedor",
    )
    tasa_impuesto = models.ForeignKey(
        TasaImpuesto,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )
    bodega = models.ForeignKey(Bodega, on_delete=models.CASCADE)
    numero_orden = models.CharField(max_length=60, unique=True)

    # ⬇️ ahora con choices y default usando la clase interna
    estado = models.CharField(
        max_length=30,
        choices=EstadoOC.choices,
        default=EstadoOC.DRAFT,
    )

    fecha_esperada = models.DateField(null=True, blank=True)
    creado_por = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
    )

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
    estado = models.CharField(max_length=30, default="OPEN")
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
    class EstadoFactura(models.TextChoices):
        OPEN = "OPEN", "Abierta"
        PAGADA = "PAGADA", "Pagada"
        ANULADA = "ANULADA", "Anulada"
    proveedor = models.ForeignKey(User, on_delete=models.CASCADE, related_name="facturas_emitidas")
    numero_factura = models.CharField(max_length=80)
    tasa_impuesto = models.ForeignKey(TasaImpuesto, on_delete=models.SET_NULL, null=True, blank=True)
    monto_total = models.DecimalField(max_digits=14, decimal_places=4)
    fecha_factura = models.DateField()
    fecha_vencimiento = models.DateField(null=True, blank=True)
    # 🔹 Ahora usa choices, pero mantiene max_length y default que ya tenías
    estado = models.CharField(
        max_length=30,
        choices=EstadoFactura.choices,
        default=EstadoFactura.OPEN,
    )

    class Meta:
        db_table = "facturas_proveedor"
        constraints = [
            models.UniqueConstraint(
                fields=["proveedor", "numero_factura"],
                name="uq_proveedor_numero_factura",
            )
        ]

    def clean(self):
        perfil = getattr(self.proveedor, "perfil", None)
        if not perfil or perfil.rol != UsuarioPerfil.Rol.PROVEEDOR:
            raise ValidationError("El proveedor debe ser un Usuario con rol PROVEEDOR.")


# ============================================================
#  ALERTAS / NOTIFS / DOCS
# ============================================================
class ReglaAlerta(MarcaTiempo):
    codigo = models.CharField(max_length=50, unique=True)
    nombre = models.CharField(max_length=150)
    configuracion = models.JSONField()
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = "reglas_alerta"


class Alerta(MarcaTiempo):
    regla = models.ForeignKey(ReglaAlerta, on_delete=models.SET_NULL, null=True, blank=True)
    producto = models.ForeignKey(Producto, on_delete=models.SET_NULL, null=True, blank=True)

    # ahora dos posibles ubicaciones:
    ubicacion_bodega = models.ForeignKey(UbicacionBodega, on_delete=models.SET_NULL, null=True, blank=True)
    ubicacion_sucursal = models.ForeignKey(UbicacionSucursal, on_delete=models.SET_NULL, null=True, blank=True)

    severidad = models.CharField(max_length=20, default="INFO")
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


class Documento(MarcaTiempo):
    tipo = models.CharField(max_length=60)
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

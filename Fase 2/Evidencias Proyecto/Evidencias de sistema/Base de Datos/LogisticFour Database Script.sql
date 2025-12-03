CREATE TABLE "django_migrations" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "app" varchar(255) NOT NULL, "name" varchar(255) NOT NULL, "applied" datetime NOT NULL);

CREATE TABLE "auth_group_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "auth_user_groups" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "group_id" integer NOT NULL REFERENCES "auth_group" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "auth_user_user_permissions" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "permission_id" integer NOT NULL REFERENCES "auth_permission" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "django_admin_log" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "object_id" text NULL, "object_repr" varchar(200) NOT NULL, "action_flag" smallint unsigned NOT NULL CHECK ("action_flag" >= 0), "change_message" text NOT NULL, "content_type_id" integer NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "user_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "action_time" datetime NOT NULL);

CREATE TABLE "django_content_type" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "app_label" varchar(100) NOT NULL, "model" varchar(100) NOT NULL);

CREATE TABLE "auth_permission" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "content_type_id" integer NOT NULL REFERENCES "django_content_type" ("id") DEFERRABLE INITIALLY DEFERRED, "codename" varchar(100) NOT NULL, "name" varchar(255) NOT NULL);

CREATE TABLE "auth_group" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(150) NOT NULL UNIQUE);

CREATE TABLE "auth_user" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "password" varchar(128) NOT NULL, "last_login" datetime NULL, "is_superuser" bool NOT NULL, "username" varchar(150) NOT NULL UNIQUE, "last_name" varchar(150) NOT NULL, "email" varchar(254) NOT NULL, "is_staff" bool NOT NULL, "is_active" bool NOT NULL, "date_joined" datetime NOT NULL, "first_name" varchar(150) NOT NULL);

CREATE TABLE "bodegas" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "codigo" varchar(30) NOT NULL, "nombre" varchar(150) NOT NULL, "direccion" varchar(255) NOT NULL, "descripcion" text NOT NULL, "activo" bool NOT NULL);

CREATE TABLE "marcas" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "nombre" varchar(150) NOT NULL UNIQUE);

CREATE TABLE "reglas_alerta" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "codigo" varchar(50) NOT NULL UNIQUE, "nombre" varchar(150) NOT NULL, "configuracion" text NOT NULL CHECK ((JSON_VALID("configuracion") OR "configuracion" IS NULL)), "activo" bool NOT NULL);

CREATE TABLE "tasas_impuesto" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "nombre" varchar(100) NOT NULL, "porcentaje" decimal NOT NULL, "activo" bool NOT NULL);

CREATE TABLE "tipos_movimiento" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "codigo" varchar(30) NOT NULL UNIQUE, "nombre" varchar(100) NOT NULL, "direccion" smallint NOT NULL, "afecta_costo" bool NOT NULL);

CREATE TABLE "tipos_ubicacion" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "codigo" varchar(30) NOT NULL UNIQUE, "descripcion" varchar(200) NOT NULL);

CREATE TABLE "unidades_medida" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "codigo" varchar(20) NOT NULL UNIQUE, "descripcion" varchar(200) NOT NULL);

CREATE TABLE "bitacora_auditoria" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "accion" varchar(100) NOT NULL, "tabla" varchar(100) NOT NULL, "entidad_id" bigint NULL, "detalle" text NULL CHECK ((JSON_VALID("detalle") OR "detalle" IS NULL)), "usuario_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "ajustes_inventario" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "motivo" varchar(120) NOT NULL, "estado" varchar(30) NOT NULL, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "categorias_productos" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "nombre" varchar(150) NOT NULL, "codigo" varchar(50) NOT NULL, "padre_id" bigint NULL REFERENCES "categorias_productos" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "devoluciones_proveedor" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "estado" varchar(30) NOT NULL, "motivo" varchar(200) NOT NULL, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "proveedor_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "documentos" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "tipo" varchar(60) NOT NULL, "titulo" varchar(200) NOT NULL, "descripcion" text NOT NULL, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "notificaciones" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "titulo" varchar(200) NOT NULL, "cuerpo" text NOT NULL, "leida" bool NOT NULL, "usuario_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "ordenes_compra" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "numero_orden" varchar(60) NOT NULL UNIQUE, "estado" varchar(30) NOT NULL, "fecha_esperada" date NULL, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "proveedor_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "tasa_impuesto_id" bigint NULL REFERENCES "tasas_impuesto" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "bodegas_productos" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "adjuntos" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "url_archivo" varchar(200) NOT NULL, "nombre_archivo" varchar(200) NOT NULL, "tipo_contenido" varchar(100) NOT NULL, "proveedor_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "documento_id" bigint NULL REFERENCES "documentos" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "recepciones_mercaderia" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "numero_recepcion" varchar(60) NOT NULL UNIQUE, "estado" varchar(30) NOT NULL, "recibido_en" datetime NOT NULL, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "orden_compra_id" bigint NULL REFERENCES "ordenes_compra" ("id") DEFERRABLE INITIALLY DEFERRED, "recibido_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "recuentos_inventario" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "codigo_ciclo" varchar(60) NOT NULL, "estado" varchar(30) NOT NULL, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "sucursales" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "codigo" varchar(30) NOT NULL UNIQUE, "nombre" varchar(150) NOT NULL, "direccion" text NOT NULL, "ciudad" varchar(120) NOT NULL, "region" varchar(120) NOT NULL, "pais" varchar(120) NOT NULL, "activo" bool NOT NULL, "bodega_id" bigint NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "sucursales_productos" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "sucursal_id" bigint NOT NULL REFERENCES "sucursales" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "reservas" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "cantidad_reservada" decimal NOT NULL, "tabla_referencia" varchar(100) NOT NULL, "referencia_id" bigint NULL, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lineas_recuento_inventario" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad_sistema" decimal NOT NULL, "cantidad_contada" decimal NULL, "diferencia" decimal NULL, "contado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "recuento_id" bigint NOT NULL REFERENCES "recuentos_inventario" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lineas_ajuste_inventario" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad_delta" decimal NOT NULL, "motivo" varchar(200) NOT NULL, "ajuste_id" bigint NOT NULL REFERENCES "ajustes_inventario" ("id") DEFERRABLE INITIALLY DEFERRED, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "alertas" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "severidad" varchar(20) NOT NULL, "mensaje" text NOT NULL, "reconocida_en" datetime NULL, "reconocida_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "regla_id" bigint NULL REFERENCES "reglas_alerta" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "movimientos_stock" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad" decimal NOT NULL, "tabla_referencia" varchar(100) NOT NULL, "referencia_id" bigint NULL, "ocurrido_en" datetime NOT NULL, "notas" text NOT NULL, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "tipo_movimiento_id" bigint NOT NULL REFERENCES "tipos_movimiento" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_desde_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_hasta_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_desde_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_hasta_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_id" bigint NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lineas_transferencia" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad" decimal NOT NULL, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "transferencia_id" bigint NOT NULL REFERENCES "transferencias" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_id" bigint NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lineas_recepcion_mercaderia" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad_recibida" decimal NOT NULL, "fecha_vencimiento" date NULL, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "recepcion_id" bigint NOT NULL REFERENCES "recepciones_mercaderia" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_id" bigint NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lineas_orden_compra" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "descripcion" text NOT NULL, "cantidad_pedida" decimal NOT NULL, "precio" decimal NOT NULL, "descuento_pct" decimal NOT NULL, "orden_compra_id" bigint NOT NULL REFERENCES "ordenes_compra" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_id" bigint NOT NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lineas_devolucion_proveedor" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad" decimal NOT NULL, "devolucion_id" bigint NOT NULL REFERENCES "devoluciones_proveedor" ("id") DEFERRABLE INITIALLY DEFERRED, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "serie_id" bigint NULL REFERENCES "series_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_id" bigint NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "usuarios_perfil" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "rut" varchar(20) NOT NULL, "telefono" varchar(50) NOT NULL, "rol" varchar(20) NOT NULL, "sucursal_id" bigint NULL REFERENCES "sucursales" ("id") DEFERRABLE INITIALLY DEFERRED, "usuario_id" integer NOT NULL UNIQUE REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "lotes_producto" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "codigo_lote" varchar(100) NOT NULL, "fecha_vencimiento" date NULL, "fecha_fabricacion" date NULL, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uq_producto_lote" UNIQUE ("producto_id", "codigo_lote"));

CREATE TABLE "productos_usuarios_proveedor" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "sku_proveedor" varchar(100) NOT NULL, "tiempo_entrega_dias" integer NOT NULL, "cantidad_min_pedido" decimal NOT NULL, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "proveedor_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uq_producto_usuario_proveedor" UNIQUE ("producto_id", "proveedor_id"));

CREATE TABLE "series_producto" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "numero_serie" varchar(150) NOT NULL, "lote_id" bigint NULL REFERENCES "lotes_producto" ("id") DEFERRABLE INITIALLY DEFERRED, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uq_producto_numero_serie" UNIQUE ("producto_id", "numero_serie"));

CREATE TABLE "facturas_proveedor" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "numero_factura" varchar(80) NOT NULL, "monto_total" decimal NOT NULL, "fecha_factura" date NOT NULL, "fecha_vencimiento" date NULL, "estado" varchar(30) NOT NULL, "proveedor_id" integer NOT NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "tasa_impuesto_id" bigint NULL REFERENCES "tasas_impuesto" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uq_proveedor_numero_factura" UNIQUE ("proveedor_id", "numero_factura"));

CREATE TABLE "politicas_reabastecimiento" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad_min" decimal NOT NULL, "cantidad_max" decimal NULL, "cantidad_reorden" decimal NULL, "dias_cobertura" integer NULL, "activo" bool NOT NULL, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uq_politica_reabastecimiento" UNIQUE ("producto_id", "ubicacion_bodega_id", "ubicacion_sucursal_id"));

CREATE TABLE "conversiones_um" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "factor" decimal NOT NULL, "unidad_desde_id" bigint NOT NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_hasta_id" bigint NOT NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED, CONSTRAINT "uq_conversion_um" UNIQUE ("unidad_desde_id", "unidad_hasta_id"));

CREATE TABLE "django_session" ("session_key" varchar(40) NOT NULL PRIMARY KEY, "session_data" text NOT NULL, "expire_date" datetime NOT NULL);

CREATE TABLE "django_site" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "name" varchar(50) NOT NULL, "domain" varchar(100) NOT NULL UNIQUE);

CREATE TABLE "transferencias" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "creado_en" datetime NOT NULL, "actualizado_en" datetime NOT NULL, "estado" varchar(30) NOT NULL, "bodega_origen_id" bigint NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "creado_por_id" integer NULL REFERENCES "auth_user" ("id") DEFERRABLE INITIALLY DEFERRED, "sucursal_destino_id" bigint NULL REFERENCES "sucursales" ("id") DEFERRABLE INITIALLY DEFERRED, "fecha_emision" date NULL, "numero_guia" varchar(20) NULL, "bodega_destino_id" bigint NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "sucursal_origen_id" bigint NULL REFERENCES "sucursales" ("id") DEFERRABLE INITIALLY DEFERRED, "tipo_movimiento" varchar(20) NOT NULL);

CREATE TABLE "ubicaciones_bodega" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "codigo" varchar(60) NOT NULL, "area" varchar(150) NULL, "activo" bool NOT NULL, "bodega_id" bigint NOT NULL REFERENCES "bodegas" ("id") DEFERRABLE INITIALLY DEFERRED, "tipo_id" bigint NULL REFERENCES "tipos_ubicacion" ("id") DEFERRABLE INITIALLY DEFERRED, "area_codigo" varchar(20) NOT NULL, "estante_codigo" varchar(20) NOT NULL, CONSTRAINT "uq_ubi_bodega_codigo" UNIQUE ("bodega_id", "codigo"));

CREATE TABLE "ubicaciones_sucursal" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "codigo" varchar(60) NOT NULL, "area" varchar(150) NULL, "activo" bool NOT NULL, "sucursal_id" bigint NOT NULL REFERENCES "sucursales" ("id") DEFERRABLE INITIALLY DEFERRED, "tipo_id" bigint NULL REFERENCES "tipos_ubicacion" ("id") DEFERRABLE INITIALLY DEFERRED, "area_codigo" varchar(20) NOT NULL, "estante_codigo" varchar(20) NOT NULL, CONSTRAINT "uq_ubi_sucursal_codigo" UNIQUE ("sucursal_id", "codigo"));

CREATE TABLE "productos_ubicaciones_bodega" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacionbodega_id" bigint NOT NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "productos_ubicaciones_sucursal" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacionsucursal_id" bigint NOT NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED);

CREATE TABLE "stock" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "cantidad_disponible" decimal NOT NULL, "producto_id" bigint NOT NULL REFERENCES "productos" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_bodega_id" bigint NULL REFERENCES "ubicaciones_bodega" ("id") DEFERRABLE INITIALLY DEFERRED, "ubicacion_sucursal_id" bigint NULL REFERENCES "ubicaciones_sucursal" ("id") DEFERRABLE INITIALLY DEFERRED, "cantidad_validada" decimal NOT NULL, CONSTRAINT "uq_stock_prod_ubi_bodega" UNIQUE ("producto_id", "ubicacion_bodega_id"), CONSTRAINT "uq_stock_prod_ubi_sucursal" UNIQUE ("producto_id", "ubicacion_sucursal_id"));

CREATE TABLE "productos" ("id" integer NOT NULL PRIMARY KEY AUTOINCREMENT, "sku" varchar(100) NOT NULL UNIQUE, "nombre" varchar(200) NOT NULL, "activo" bool NOT NULL, "es_serializado" bool NOT NULL, "tiene_vencimiento" bool NOT NULL, "precio" integer unsigned NOT NULL CHECK ("precio" >= 0), "stock" integer unsigned NOT NULL CHECK ("stock" >= 0), "categoria_id" bigint NULL REFERENCES "categorias_productos" ("id") DEFERRABLE INITIALLY DEFERRED, "marca_id" bigint NULL REFERENCES "marcas" ("id") DEFERRABLE INITIALLY DEFERRED, "tasa_impuesto_id" bigint NULL REFERENCES "tasas_impuesto" ("id") DEFERRABLE INITIALLY DEFERRED, "unidad_base_id" bigint NOT NULL REFERENCES "unidades_medida" ("id") DEFERRABLE INITIALLY DEFERRED);

INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (1, 'contenttypes', '0001_initial', '2025-11-02 02:51:37.118046')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (2, 'auth', '0001_initial', '2025-11-02 02:51:37.143976')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (3, 'admin', '0001_initial', '2025-11-02 02:51:37.159840')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (4, 'admin', '0002_logentry_remove_auto_add', '2025-11-02 02:51:37.177794')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (5, 'admin', '0003_logentry_add_action_flag_choices', '2025-11-02 02:51:37.187766')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (6, 'contenttypes', '0002_remove_content_type_name', '2025-11-02 02:51:37.207711')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (7, 'auth', '0002_alter_permission_name_max_length', '2025-11-02 02:51:37.219680')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (8, 'auth', '0003_alter_user_email_max_length', '2025-11-02 02:51:37.234641')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (9, 'auth', '0004_alter_user_username_opts', '2025-11-02 02:51:37.247605')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (10, 'auth', '0005_alter_user_last_login_null', '2025-11-02 02:51:37.260570')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (11, 'auth', '0006_require_contenttypes_0002', '2025-11-02 02:51:37.265565')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (12, 'auth', '0007_alter_validators_add_error_messages', '2025-11-02 02:51:37.276528')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (13, 'auth', '0008_alter_user_username_max_length', '2025-11-02 02:51:37.289493')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (14, 'auth', '0009_alter_user_last_name_max_length', '2025-11-02 02:51:37.301476')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (15, 'auth', '0010_alter_group_name_max_length', '2025-11-02 02:51:37.320106')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (16, 'auth', '0011_update_proxy_permissions', '2025-11-02 02:51:37.329105')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (17, 'auth', '0012_alter_user_first_name_max_length', '2025-11-02 02:51:37.342072')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (18, 'core', '0001_initial', '2025-11-02 02:51:38.284046')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (19, 'sessions', '0001_initial', '2025-11-02 02:51:38.299998')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (20, 'sites', '0001_initial', '2025-11-02 02:51:38.305633')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (21, 'sites', '0002_alter_domain_unique', '2025-11-02 02:51:38.315375')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (22, 'core', '0002_transferencia_fecha_emision_and_more', '2025-11-25 00:48:09.324509')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (23, 'core', '0003_transferencia_bodega_destino_and_more', '2025-11-25 04:38:08.647681')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (24, 'core', '0004_remove_transferencia_observaciones_and_more', '2025-11-25 21:12:15.047329')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (25, 'core', '0005_remove_ubicacionbodega_almacenable_and_more', '2025-11-27 02:27:09.840563')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (26, 'core', '0006_remove_ubicacionbodega_nombre_and_more', '2025-11-27 02:36:07.849934')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (27, 'core', '0007_remove_producto_actualizado_en_and_more', '2025-11-27 03:26:43.861364')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (28, 'core', '0008_remove_ubicacionbodega_bodega_codigo_and_more', '2025-11-27 04:50:46.131628')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (29, 'core', '0009_stock_cantidad_validada', '2025-11-27 23:57:00.610052')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (30, 'core', '0005_producto_descripcion', '2025-12-02 02:31:14.871303')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (31, 'core', '0006_alter_facturaproveedor_estado_and_more', '2025-12-02 02:31:14.920400')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (32, 'core', '0010_merge_20251201_2330', '2025-12-02 02:31:14.924902')
INSERT INTO django_migrations VALUES (?, ?, ?, ?);
    (33, 'core', '0011_remove_producto_descripcion', '2025-12-02 02:31:14.955866')
INSERT INTO auth_user_groups VALUES (?, ?, ?);
    (5, 2, 1)
INSERT INTO auth_user_groups VALUES (?, ?, ?);
    (12, 4, 1)
INSERT INTO auth_user_groups VALUES (?, ?, ?);
    (66, 6, 3)
INSERT INTO auth_user_groups VALUES (?, ?, ?);
    (76, 5, 1)
INSERT INTO auth_user_groups VALUES (?, ?, ?);
    (90, 7, 1)
INSERT INTO auth_user_groups VALUES (?, ?, ?);
    (92, 1, 1)
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (1, '3', 'PROD003-1762054060-3 - Cemento demo', 2, '[{"changed": {"fields": ["Marca", "Categoria"]}}]', 21, 1, '2025-11-02 03:36:25.135385')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (2, '1', 'PROD001-1762054060-1 → BOD BOD-01 / UBI-BOD-01 = 7.000000', 2, '[{"changed": {"fields": ["Ubicacion bodega", "Ubicacion sucursal"]}}]', 33, 1, '2025-11-02 03:36:38.532991')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (3, '1', 'SUC-01 - Sucursal Centro', 2, '[{"changed": {"fields": ["Bodega"]}}]', 28, 1, '2025-11-02 23:34:03.908173')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (4, '2', '01122335544 - sucursal plaza puente alto', 2, '[{"changed": {"fields": ["Bodega"]}}]', 28, 1, '2025-11-03 01:15:23.160452')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (5, '1', 'SUC-01 - Sucursal Centro', 2, '[{"changed": {"fields": ["Bodega"]}}]', 28, 1, '2025-11-03 02:10:17.296735')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (6, '3', 'waltmart', 1, '[{"added": {}}]', 4, 1, '2025-11-03 22:08:24.970997')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (7, '3', 'waltmart', 2, '[{"changed": {"fields": ["Groups"]}}]', 4, 1, '2025-11-03 22:08:33.800890')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (8, '33', 'Transferencia object (33)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (9, '32', 'Transferencia object (32)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (10, '31', 'Transferencia object (31)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (11, '30', 'Transferencia object (30)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (12, '29', 'Transferencia object (29)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (13, '28', 'Transferencia object (28)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (14, '27', 'Transferencia object (27)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (15, '26', 'Transferencia object (26)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (16, '25', 'Transferencia object (25)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (17, '24', 'Transferencia object (24)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (18, '23', 'Transferencia object (23)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (19, '22', 'Transferencia object (22)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (20, '21', 'Transferencia object (21)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (21, '20', 'Transferencia object (20)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (22, '19', 'Transferencia object (19)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (23, '18', 'Transferencia object (18)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (24, '17', 'Transferencia object (17)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (25, '16', 'Transferencia object (16)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (26, '15', 'Transferencia object (15)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (27, '14', 'Transferencia object (14)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (28, '13', 'Transferencia object (13)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (29, '12', 'Transferencia object (12)', 3, '', 30, 1, '2025-11-25 23:30:28.710022')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (30, '11', 'Transferencia object (11)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (31, '10', 'Transferencia object (10)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (32, '9', 'Transferencia object (9)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (33, '8', 'Transferencia object (8)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (34, '7', 'Transferencia object (7)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (35, '6', 'Transferencia object (6)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (36, '5', 'Transferencia object (5)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (37, '4', 'Transferencia object (4)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (38, '3', 'Transferencia object (3)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (39, '2', 'Transferencia object (2)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (40, '1', 'Transferencia object (1)', 3, '', 30, 1, '2025-11-25 23:30:28.711019')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (41, '2', 'PROD002-1762054060-2 - Taladro demo', 2, '[{"changed": {"fields": ["Ubicaciones sucursal"]}}]', 21, 1, '2025-11-27 05:32:14.706044')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (42, '2', 'PROD002-1762054060-2 - Taladro demo', 2, '[{"changed": {"fields": ["Ubicaciones sucursal"]}}]', 21, 1, '2025-11-27 05:32:37.894623')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (43, '5', '212321 / 212321-654645-645645', 3, '', 31, 1, '2025-11-27 05:44:58.152165')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (44, '4', '212321 / ', 3, '', 31, 1, '2025-11-27 05:44:58.152165')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (45, '3', '212321 / BOD-2-GEN', 3, '', 31, 1, '2025-11-27 05:44:58.152165')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (46, '2', 'BOD-01 / DEF', 3, '', 31, 1, '2025-11-27 05:44:58.152165')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (47, '1', 'BOD-01 / UBI-BOD-01', 3, '', 31, 1, '2025-11-27 05:44:58.152165')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (48, '4', '001-002-117543 - bodega par', 2, '[{"changed": {"fields": ["Ubicaciones bodega"]}}]', 21, 1, '2025-11-27 05:47:57.068020')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (49, '4', '001-002-117543 - bodega par', 2, '[{"changed": {"fields": ["Ubicaciones bodega", "Ubicaciones sucursal"]}}]', 21, 1, '2025-11-27 05:51:28.574744')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (50, '3', '01122335544 / 01122335544-24234324234-5345435', 3, '', 32, 1, '2025-11-28 23:27:09.881443')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (51, '2', '01122335544 / SUC-2-GEN', 3, '', 32, 1, '2025-11-28 23:27:09.881443')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (52, '1', 'SUC-01 / UBI-SUC-01', 3, '', 32, 1, '2025-11-28 23:27:09.881443')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (53, '4', 'SUC-01 / SUC-01-24234324234-645645', 3, '', 32, 1, '2025-11-28 23:51:47.362543')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (54, '51', 'Stock object (51)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (55, '50', 'Stock object (50)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (56, '49', 'Stock object (49)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (57, '48', 'Stock object (48)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (58, '41', 'Stock object (41)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (59, '40', 'Stock object (40)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (60, '39', 'Stock object (39)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (61, '38', 'Stock object (38)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_admin_log VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (62, '37', 'Stock object (37)', 3, '', 33, 1, '2025-11-29 04:18:24.699520')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (1, 'admin', 'logentry')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (2, 'auth', 'permission')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (3, 'auth', 'group')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (4, 'auth', 'user')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (5, 'contenttypes', 'contenttype')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (6, 'sessions', 'session')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (7, 'core', 'bodega')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (8, 'core', 'marca')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (9, 'core', 'reglaalerta')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (10, 'core', 'tasaimpuesto')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (11, 'core', 'tipomovimiento')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (12, 'core', 'tipoubicacion')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (13, 'core', 'unidadmedida')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (14, 'core', 'bitacoraauditoria')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (15, 'core', 'ajusteinventario')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (16, 'core', 'categoriaproducto')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (17, 'core', 'devolucionproveedor')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (18, 'core', 'documento')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (19, 'core', 'notificacion')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (20, 'core', 'ordencompra')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (21, 'core', 'producto')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (22, 'core', 'loteproducto')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (23, 'core', 'adjunto')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (24, 'core', 'productousuarioproveedor')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (25, 'core', 'recepcionmercaderia')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (26, 'core', 'recuentoinventario')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (27, 'core', 'serieproducto')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (28, 'core', 'sucursal')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (29, 'core', 'facturaproveedor')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (30, 'core', 'transferencia')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (31, 'core', 'ubicacionbodega')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (32, 'core', 'ubicacionsucursal')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (33, 'core', 'stock')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (34, 'core', 'reserva')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (35, 'core', 'politicareabastecimiento')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (36, 'core', 'linearecuentoinventario')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (37, 'core', 'lineaajusteinventario')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (38, 'core', 'alerta')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (39, 'core', 'movimientostock')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (40, 'core', 'lineatransferencia')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (41, 'core', 'linearecepcionmercaderia')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (42, 'core', 'lineaordencompra')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (43, 'core', 'lineadevolucionproveedor')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (44, 'core', 'conversionum')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (45, 'core', 'usuarioperfil')
INSERT INTO django_content_type VALUES (?, ?, ?);
    (46, 'sites', 'site')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (1, 1, 'add_logentry', 'Can add log entry')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (2, 1, 'change_logentry', 'Can change log entry')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (3, 1, 'delete_logentry', 'Can delete log entry')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (4, 1, 'view_logentry', 'Can view log entry')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (5, 2, 'add_permission', 'Can add permission')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (6, 2, 'change_permission', 'Can change permission')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (7, 2, 'delete_permission', 'Can delete permission')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (8, 2, 'view_permission', 'Can view permission')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (9, 3, 'add_group', 'Can add group')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (10, 3, 'change_group', 'Can change group')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (11, 3, 'delete_group', 'Can delete group')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (12, 3, 'view_group', 'Can view group')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (13, 4, 'add_user', 'Can add user')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (14, 4, 'change_user', 'Can change user')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (15, 4, 'delete_user', 'Can delete user')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (16, 4, 'view_user', 'Can view user')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (17, 5, 'add_contenttype', 'Can add content type')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (18, 5, 'change_contenttype', 'Can change content type')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (19, 5, 'delete_contenttype', 'Can delete content type')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (20, 5, 'view_contenttype', 'Can view content type')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (21, 6, 'add_session', 'Can add session')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (22, 6, 'change_session', 'Can change session')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (23, 6, 'delete_session', 'Can delete session')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (24, 6, 'view_session', 'Can view session')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (25, 7, 'add_bodega', 'Can add bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (26, 7, 'change_bodega', 'Can change bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (27, 7, 'delete_bodega', 'Can delete bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (28, 7, 'view_bodega', 'Can view bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (29, 8, 'add_marca', 'Can add marca')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (30, 8, 'change_marca', 'Can change marca')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (31, 8, 'delete_marca', 'Can delete marca')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (32, 8, 'view_marca', 'Can view marca')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (33, 9, 'add_reglaalerta', 'Can add regla alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (34, 9, 'change_reglaalerta', 'Can change regla alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (35, 9, 'delete_reglaalerta', 'Can delete regla alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (36, 9, 'view_reglaalerta', 'Can view regla alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (37, 10, 'add_tasaimpuesto', 'Can add tasa impuesto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (38, 10, 'change_tasaimpuesto', 'Can change tasa impuesto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (39, 10, 'delete_tasaimpuesto', 'Can delete tasa impuesto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (40, 10, 'view_tasaimpuesto', 'Can view tasa impuesto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (41, 11, 'add_tipomovimiento', 'Can add tipo movimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (42, 11, 'change_tipomovimiento', 'Can change tipo movimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (43, 11, 'delete_tipomovimiento', 'Can delete tipo movimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (44, 11, 'view_tipomovimiento', 'Can view tipo movimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (45, 12, 'add_tipoubicacion', 'Can add tipo ubicacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (46, 12, 'change_tipoubicacion', 'Can change tipo ubicacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (47, 12, 'delete_tipoubicacion', 'Can delete tipo ubicacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (48, 12, 'view_tipoubicacion', 'Can view tipo ubicacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (49, 13, 'add_unidadmedida', 'Can add unidad medida')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (50, 13, 'change_unidadmedida', 'Can change unidad medida')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (51, 13, 'delete_unidadmedida', 'Can delete unidad medida')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (52, 13, 'view_unidadmedida', 'Can view unidad medida')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (53, 14, 'add_bitacoraauditoria', 'Can add bitacora auditoria')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (54, 14, 'change_bitacoraauditoria', 'Can change bitacora auditoria')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (55, 14, 'delete_bitacoraauditoria', 'Can delete bitacora auditoria')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (56, 14, 'view_bitacoraauditoria', 'Can view bitacora auditoria')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (57, 15, 'add_ajusteinventario', 'Can add ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (58, 15, 'change_ajusteinventario', 'Can change ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (59, 15, 'delete_ajusteinventario', 'Can delete ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (60, 15, 'view_ajusteinventario', 'Can view ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (61, 16, 'add_categoriaproducto', 'Can add categoria producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (62, 16, 'change_categoriaproducto', 'Can change categoria producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (63, 16, 'delete_categoriaproducto', 'Can delete categoria producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (64, 16, 'view_categoriaproducto', 'Can view categoria producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (65, 17, 'add_devolucionproveedor', 'Can add devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (66, 17, 'change_devolucionproveedor', 'Can change devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (67, 17, 'delete_devolucionproveedor', 'Can delete devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (68, 17, 'view_devolucionproveedor', 'Can view devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (69, 18, 'add_documento', 'Can add documento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (70, 18, 'change_documento', 'Can change documento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (71, 18, 'delete_documento', 'Can delete documento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (72, 18, 'view_documento', 'Can view documento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (73, 19, 'add_notificacion', 'Can add notificacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (74, 19, 'change_notificacion', 'Can change notificacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (75, 19, 'delete_notificacion', 'Can delete notificacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (76, 19, 'view_notificacion', 'Can view notificacion')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (77, 20, 'add_ordencompra', 'Can add orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (78, 20, 'change_ordencompra', 'Can change orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (79, 20, 'delete_ordencompra', 'Can delete orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (80, 20, 'view_ordencompra', 'Can view orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (81, 21, 'add_producto', 'Can add producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (82, 21, 'change_producto', 'Can change producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (83, 21, 'delete_producto', 'Can delete producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (84, 21, 'view_producto', 'Can view producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (85, 22, 'add_loteproducto', 'Can add lote producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (86, 22, 'change_loteproducto', 'Can change lote producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (87, 22, 'delete_loteproducto', 'Can delete lote producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (88, 22, 'view_loteproducto', 'Can view lote producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (89, 23, 'add_adjunto', 'Can add adjunto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (90, 23, 'change_adjunto', 'Can change adjunto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (91, 23, 'delete_adjunto', 'Can delete adjunto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (92, 23, 'view_adjunto', 'Can view adjunto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (93, 24, 'add_productousuarioproveedor', 'Can add producto usuario proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (94, 24, 'change_productousuarioproveedor', 'Can change producto usuario proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (95, 24, 'delete_productousuarioproveedor', 'Can delete producto usuario proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (96, 24, 'view_productousuarioproveedor', 'Can view producto usuario proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (97, 25, 'add_recepcionmercaderia', 'Can add recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (98, 25, 'change_recepcionmercaderia', 'Can change recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (99, 25, 'delete_recepcionmercaderia', 'Can delete recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (100, 25, 'view_recepcionmercaderia', 'Can view recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (101, 26, 'add_recuentoinventario', 'Can add recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (102, 26, 'change_recuentoinventario', 'Can change recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (103, 26, 'delete_recuentoinventario', 'Can delete recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (104, 26, 'view_recuentoinventario', 'Can view recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (105, 27, 'add_serieproducto', 'Can add serie producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (106, 27, 'change_serieproducto', 'Can change serie producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (107, 27, 'delete_serieproducto', 'Can delete serie producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (108, 27, 'view_serieproducto', 'Can view serie producto')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (109, 28, 'add_sucursal', 'Can add sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (110, 28, 'change_sucursal', 'Can change sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (111, 28, 'delete_sucursal', 'Can delete sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (112, 28, 'view_sucursal', 'Can view sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (113, 29, 'add_facturaproveedor', 'Can add factura proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (114, 29, 'change_facturaproveedor', 'Can change factura proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (115, 29, 'delete_facturaproveedor', 'Can delete factura proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (116, 29, 'view_facturaproveedor', 'Can view factura proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (117, 30, 'add_transferencia', 'Can add transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (118, 30, 'change_transferencia', 'Can change transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (119, 30, 'delete_transferencia', 'Can delete transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (120, 30, 'view_transferencia', 'Can view transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (121, 31, 'add_ubicacionbodega', 'Can add ubicacion bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (122, 31, 'change_ubicacionbodega', 'Can change ubicacion bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (123, 31, 'delete_ubicacionbodega', 'Can delete ubicacion bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (124, 31, 'view_ubicacionbodega', 'Can view ubicacion bodega')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (125, 32, 'add_ubicacionsucursal', 'Can add ubicacion sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (126, 32, 'change_ubicacionsucursal', 'Can change ubicacion sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (127, 32, 'delete_ubicacionsucursal', 'Can delete ubicacion sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (128, 32, 'view_ubicacionsucursal', 'Can view ubicacion sucursal')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (129, 33, 'add_stock', 'Can add stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (130, 33, 'change_stock', 'Can change stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (131, 33, 'delete_stock', 'Can delete stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (132, 33, 'view_stock', 'Can view stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (133, 34, 'add_reserva', 'Can add reserva')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (134, 34, 'change_reserva', 'Can change reserva')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (135, 34, 'delete_reserva', 'Can delete reserva')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (136, 34, 'view_reserva', 'Can view reserva')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (137, 35, 'add_politicareabastecimiento', 'Can add politica reabastecimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (138, 35, 'change_politicareabastecimiento', 'Can change politica reabastecimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (139, 35, 'delete_politicareabastecimiento', 'Can delete politica reabastecimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (140, 35, 'view_politicareabastecimiento', 'Can view politica reabastecimiento')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (141, 36, 'add_linearecuentoinventario', 'Can add linea recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (142, 36, 'change_linearecuentoinventario', 'Can change linea recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (143, 36, 'delete_linearecuentoinventario', 'Can delete linea recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (144, 36, 'view_linearecuentoinventario', 'Can view linea recuento inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (145, 37, 'add_lineaajusteinventario', 'Can add linea ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (146, 37, 'change_lineaajusteinventario', 'Can change linea ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (147, 37, 'delete_lineaajusteinventario', 'Can delete linea ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (148, 37, 'view_lineaajusteinventario', 'Can view linea ajuste inventario')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (149, 38, 'add_alerta', 'Can add alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (150, 38, 'change_alerta', 'Can change alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (151, 38, 'delete_alerta', 'Can delete alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (152, 38, 'view_alerta', 'Can view alerta')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (153, 39, 'add_movimientostock', 'Can add movimiento stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (154, 39, 'change_movimientostock', 'Can change movimiento stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (155, 39, 'delete_movimientostock', 'Can delete movimiento stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (156, 39, 'view_movimientostock', 'Can view movimiento stock')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (157, 40, 'add_lineatransferencia', 'Can add linea transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (158, 40, 'change_lineatransferencia', 'Can change linea transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (159, 40, 'delete_lineatransferencia', 'Can delete linea transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (160, 40, 'view_lineatransferencia', 'Can view linea transferencia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (161, 41, 'add_linearecepcionmercaderia', 'Can add linea recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (162, 41, 'change_linearecepcionmercaderia', 'Can change linea recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (163, 41, 'delete_linearecepcionmercaderia', 'Can delete linea recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (164, 41, 'view_linearecepcionmercaderia', 'Can view linea recepcion mercaderia')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (165, 42, 'add_lineaordencompra', 'Can add linea orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (166, 42, 'change_lineaordencompra', 'Can change linea orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (167, 42, 'delete_lineaordencompra', 'Can delete linea orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (168, 42, 'view_lineaordencompra', 'Can view linea orden compra')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (169, 43, 'add_lineadevolucionproveedor', 'Can add linea devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (170, 43, 'change_lineadevolucionproveedor', 'Can change linea devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (171, 43, 'delete_lineadevolucionproveedor', 'Can delete linea devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (172, 43, 'view_lineadevolucionproveedor', 'Can view linea devolucion proveedor')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (173, 44, 'add_conversionum', 'Can add conversion um')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (174, 44, 'change_conversionum', 'Can change conversion um')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (175, 44, 'delete_conversionum', 'Can delete conversion um')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (176, 44, 'view_conversionum', 'Can view conversion um')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (177, 45, 'add_usuarioperfil', 'Can add usuario perfil')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (178, 45, 'change_usuarioperfil', 'Can change usuario perfil')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (179, 45, 'delete_usuarioperfil', 'Can delete usuario perfil')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (180, 45, 'view_usuarioperfil', 'Can view usuario perfil')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (181, 46, 'add_site', 'Can add site')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (182, 46, 'change_site', 'Can change site')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (183, 46, 'delete_site', 'Can delete site')
INSERT INTO auth_permission VALUES (?, ?, ?, ?);
    (184, 46, 'view_site', 'Can view site')
INSERT INTO auth_group VALUES (?, ?);
    (1, 'ADMIN')
INSERT INTO auth_group VALUES (?, ?);
    (2, 'BODEGUERO')
INSERT INTO auth_group VALUES (?, ?);
    (3, 'AUDITOR')
INSERT INTO auth_group VALUES (?, ?);
    (4, 'PROVEEDOR')
INSERT INTO auth_user VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (1, 'pbkdf2_sha256$1000000$vhPIFM8ouGeI0nKqOK0d90$0/z1TZR8lud5iqcLgk013fOTrN6FDZO+kKAid2Zh45M=', '2025-12-02 17:03:43.666910', 1, 'admin', '', 'admin@gmail.com', 1, 1, '2025-11-02 02:52:45.015430', '')
INSERT INTO auth_user VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (2, '', None, 0, 'paypal_proveedor', 'PayPal', 'paypal@example.com', 0, 1, '2025-11-03 03:40:25.213830', 'Proveedor')
INSERT INTO auth_user VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (4, 'pbkdf2_sha256$1000000$Qon7w3N8fQT30kplJG1jqH$2PXvSFQkPv+QGus1HfCWtglXmCiSFa5OSHlTR7MEL84=', None, 0, 'waltmart2', 'chile', 'luxho@gmail.com', 0, 1, '2025-11-03 22:13:56.001186', 'waltmart')
INSERT INTO auth_user VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (5, 'pbkdf2_sha256$1000000$RDVA4yIFypKzYnn2woexcm$2x6vgxnd3GZwYyDm7h5bb/bU6bbS5URFd2sdyH4Ds40=', '2025-12-02 02:43:33.053285', 0, 'freddy', 'cardenas', 'freddyacr02@gmail.com', 0, 1, '2025-11-04 14:29:04.081466', 'freddy')
INSERT INTO auth_user VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (6, 'pbkdf2_sha256$600000$FxHx1dY5yfSKSl5CWQiaPZ$BX+F6NzcOwbYFjoB0NrBc0je+kIsLBDQhCcNaK9W144=', '2025-11-05 16:23:30.799740', 0, 'kevin', 'Bustos', 'kevinxmatias@gmail.com', 0, 1, '2025-11-04 14:31:08.831164', 'Kevin')
INSERT INTO auth_user VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (7, 'pbkdf2_sha256$1000000$cCDcF7tiffJ0CdcnRYQymk$fBD9ZbfbTQaFg2YFMD7xtkt9eX5urLcm6KocYiJUx70=', None, 0, 'andres', 'casdsad', 'Crazyfamilychile@gmail.com', 0, 1, '2025-12-02 13:46:21.768384', 'andres')
INSERT INTO bodegas VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-02 03:32:04.308787', '2025-11-02 03:32:04.308787', 'BOD-01', 'Bodega Principal', 'Av. Bodega 123', 'Bodega de pruebas', 1)
INSERT INTO bodegas VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (3, '2025-11-27 17:39:55.814387', '2025-11-27 17:39:55.814387', 'BOD-0024', 'Bodega test', '', 'fmdsf', 1)
INSERT INTO marcas VALUES (?, ?, ?, ?);
    (1, '2025-11-02 03:32:03.913311', '2025-11-02 03:32:03.913311', 'Genérica')
INSERT INTO reglas_alerta VALUES (?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-24 04:29:04.921491', '2025-11-24 04:29:04.921491', 'STOCK_BAJO_10', 'Stock bajo (≤10)', '{"umbral": 10, "aplica": ["bodega", "sucursal"]}', 1)
INSERT INTO tasas_impuesto VALUES (?, ?, ?, ?, ?, ?);
    (1, '2025-11-03 05:50:26.034075', '2025-11-03 05:50:26.034092', 'bodega par', 12, 1)
INSERT INTO tipos_movimiento VALUES (?, ?, ?, ?, ?);
    (1, 'TRANSFERENCIA', 'Transferencia', 0, 1)
INSERT INTO tipos_ubicacion VALUES (?, ?, ?);
    (1, 'EST', 'Estantería')
INSERT INTO unidades_medida VALUES (?, ?, ?, ?, ?);
    (1, '2025-11-02 03:27:40.551223', '2025-11-02 03:27:40.551223', 'DEMO', 'DEMO')
INSERT INTO unidades_medida VALUES (?, ?, ?, ?, ?);
    (2, '2025-11-02 03:32:03.831453', '2025-11-02 03:32:03.831453', 'UN', '')
INSERT INTO categorias_productos VALUES (?, ?, ?, ?, ?, ?);
    (1, '2025-11-02 03:32:03.980245', '2025-11-02 03:32:03.980245', 'Materiales', '', None)
INSERT INTO ordenes_compra VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-03 03:47:40.629680', '2025-11-03 03:47:40.629697', 'OC-PAYPAL-20251103034740', 'COMPLETED', '2025-11-03', 1, 1, 2, None)
INSERT INTO ordenes_compra VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (2, '2025-12-02 03:42:54.280843', '2025-12-02 03:42:54.280843', 'sss', 'PARTIAL', '2025-10-13', 3, None, 5, None)
INSERT INTO recepciones_mercaderia VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-03 03:47:40.630815', '2025-11-03 03:47:40.630828', 'RC-PAYPAL-20251103034740', 'CLOSED', '2025-11-03 03:47:40.630841', 1, 1, 1)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-04 13:23:43.685093', '2025-11-04 13:23:43.685114', 'AUTO-20251104', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (2, '2025-11-24 03:58:56.557594', '2025-11-24 03:58:56.557594', 'AUTO-20251124', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (3, '2025-11-25 03:12:03.068183', '2025-11-25 03:12:03.068183', 'AUTO-20251125', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (5, '2025-11-26 03:17:23.551370', '2025-11-26 03:17:23.551370', 'AUTO-20251126', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (8, '2025-11-27 05:54:49.460268', '2025-11-27 05:54:49.460268', 'AUTO-20251127', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (9, '2025-11-27 18:31:48.691614', '2025-11-27 18:31:48.691614', 'AUTO-20251127', 'OPEN', 3, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (10, '2025-11-28 03:19:12.489139', '2025-11-28 03:19:12.489139', 'AUTO-20251128', 'OPEN', 3, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (11, '2025-11-28 03:19:12.493128', '2025-11-28 03:19:12.493128', 'AUTO-20251128', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (12, '2025-11-29 03:03:16.526675', '2025-11-29 03:03:16.526675', 'AUTO-20251129', 'OPEN', 3, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (13, '2025-11-29 03:37:50.583105', '2025-11-29 03:37:50.583105', 'AUTO-20251129', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (14, '2025-12-01 05:18:22.877897', '2025-12-01 05:18:22.877897', 'AUTO-20251201', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (15, '2025-12-01 05:18:22.880888', '2025-12-01 05:18:22.880888', 'AUTO-20251201', 'OPEN', 3, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (16, '2025-12-02 03:48:41.866028', '2025-12-02 03:48:41.866028', 'AUTO-20251202', 'OPEN', 1, None)
INSERT INTO recuentos_inventario VALUES (?, ?, ?, ?, ?, ?, ?);
    (17, '2025-12-02 03:50:38.860840', '2025-12-02 03:50:38.860840', 'AUTO-20251202', 'OPEN', 3, None)
INSERT INTO sucursales VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-02 03:32:04.551762', '2025-11-03 02:10:17.294896', 'SUC-01', 'Sucursal Centro', 'Duoc puente alto', 'Santiago', 'RM', 'Chile', 1, 3)
INSERT INTO sucursales VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (2, '2025-11-03 01:14:22.593959', '2025-11-03 01:15:23.158485', '01122335544', 'sucursal plaza puente alto', 'santo domingo puente alto', 'santiago', 'Metropolitana', 'Chile', 1, 1)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (179, 0, 17, 17, None, None, 1, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (180, 0, 432, 432, None, None, 5, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (181, 0, 432, 432, None, None, 6, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (182, 0, 432, 432, None, None, 7, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (183, 0, 432, 432, None, None, 8, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (184, 0, 432, 432, None, None, 9, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (185, 0, 14, 14, None, None, 9, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (186, 14, 1000, 986, None, None, 9, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (187, 432, 407, -25, None, None, 8, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (188, 0, 25, 25, None, None, 8, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (189, 432, 378, -54, None, None, 5, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (190, 0, 54, 54, None, None, 5, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (191, 407, 384, -23, None, None, 8, 8, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (192, 25, 48, 23, None, None, 8, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (193, 0, 32, 32, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (194, 32, 17, -15, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (195, 0, 15, 15, None, None, 10, 9, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (196, 17, 1, -16, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (197, 0, 16, 16, None, None, 10, 9, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (198, 1, 0, -1, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (199, 0, 1, 1, None, None, 10, 9, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (200, 16, 0, -16, None, None, 10, 9, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (201, 15, 5, -10, None, None, 10, 9, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (202, 0, 26, 26, None, None, 10, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (203, 26, 0, -26, None, None, 10, 8, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (204, 0, 26, 26, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (205, 26, 11, -15, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (206, 5, 20, 15, None, None, 10, 9, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (207, 11, 0, -11, None, None, 10, 9, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (208, 0, 11, 11, None, None, 10, 9, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (209, 11, 9, -2, None, None, 10, 9, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (211, 9, 8, -1, None, None, 10, 9, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (213, 20, 14, -6, None, None, 10, 9, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (215, 14, 10, -4, None, None, 10, 9, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (216, 8, 6, -2, None, None, 10, 9, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (217, 1, 0, -1, None, None, 10, 9, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (219, 10, 5, -5, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (220, 0, 5, 5, None, None, 10, 11, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (221, 6, 1, -5, None, None, 10, 10, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (224, 0, 15, 15, None, None, 10, 10, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (231, 5, 5643, 5638, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (232, 1, 15, 14, None, None, 10, 10, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (233, 5643, 4108, -1535, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (235, 4108, 4057, -51, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (237, 4057, 4042, -15, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (238, 5, 20, 15, None, None, 10, 11, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (239, 0, 654645, 654645, None, None, 6, 11, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (240, 0, 43, 43, None, None, 7, 11, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (241, 4042, 3619, -423, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (242, 0, 423, 423, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (243, 423, 398, -25, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (244, 0, 25, 25, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (245, 3619, 323, -3296, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (246, 25, 21, -4, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (247, 0, 4, 4, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (248, 21, 20, -1, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (249, 4, 5, 1, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (250, 20, 0, -20, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (251, 5, 25, 20, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (252, 398, 388, -10, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (253, 0, 10, 10, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (254, 10, 5, -5, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (255, 25, 30, 5, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (256, 323, 432432, 432109, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (257, 5, 0, -5, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (258, 0, 10, 10, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (259, 10, 0, -10, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (260, 30, 40, 10, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (261, 388, 288, -100, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (262, 0, 100, 100, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (263, 0, 15, 15, None, None, 10, 10, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (264, 432432, 50, -432382, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (265, 15, 5646, 5631, None, None, 10, 10, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (266, 100, 50, -50, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (267, 40, 90, 50, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (268, 50, 25, -25, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (269, 25, 75, 50, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (270, 75, 70, -5, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (271, 90, 95, 5, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (272, 70, 0, -70, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (273, 95, 165, 70, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (274, 165, 150, -15, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (275, 0, 15, 15, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (276, 150, 139, -11, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (277, 288, 299, 11, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (278, 299, 149, -150, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (279, 0, 150, 150, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (280, 150, 100, -50, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (281, 15, 65, 50, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (282, 100, 0, -100, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (283, 139, 0, -139, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (284, 149, 49, -100, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (285, 0, 100, 100, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (286, 100, 90, -10, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (287, 0, 10, 10, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (288, 90, 0, -90, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (289, 65, 0, -65, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (290, 49, 19, -30, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (291, 0, 30, 30, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (292, 30, 20, -10, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (293, 10, 20, 10, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (294, 20, 18, -2, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (295, 20, 22, 2, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (296, 18, 13, -5, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (297, 0, 5, 5, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (298, 13, 0, -13, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (299, 22, 20, -2, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (300, 5, 20, 15, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (301, 20, 10, -10, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (302, 20, 30, 10, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (303, 19, 10, -9, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (304, 0, 9, 9, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (305, 9, 0, -9, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (306, 10, 0, -10, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (307, 30, 15, -15, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (308, 0, 15, 15, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (309, 15, 13, -2, None, None, 10, 11, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (310, 15, 17, 2, None, None, 10, 11, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (311, 10, 0, -10, None, None, 10, 10, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (312, 0, 10, 10, None, None, 10, 11, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (313, 50, 654564, 654514, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (314, 15, 53453, 53438, None, None, 10, 10, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (315, 654564, 1, -654563, None, None, 10, 10, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (316, 5646, 1, -5645, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (317, 1, 56, 55, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (318, 56, 51, -5, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (319, 53453, 53458, 5, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (320, 51, 45, -6, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (321, 53458, 53464, 6, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (322, 15, 5, -10, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (323, 45, 55, 10, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (324, 5, 3, -2, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (325, 1, 3, 2, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (326, 3, 0, -3, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (327, 55, 0, -55, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (328, 53464, 51177, -2287, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (329, 3, 2348, 2345, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (330, 10, 5, -5, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (331, 13, 18, 5, None, None, 10, 13, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (332, 5, 3, -2, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (333, 3, 7, 4, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (334, 7, 0, -7, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (335, 17, 24, 7, None, None, 10, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (336, 24, 20, -4, None, None, 10, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (337, 18, 22, 4, None, None, 10, 13, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (338, 2348, 2298, -50, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (339, 0, 50, 50, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (340, 50, 20, -30, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (341, 0, 30, 30, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (342, 20, 0, -20, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (343, 2298, 1754, -544, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (344, 30, 594, 564, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (345, 594, 593, -1, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (346, 1754, 1755, 1, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (347, 593, 578, -15, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (348, 1755, 1770, 15, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (349, 578, 568, -10, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (350, 1770, 1780, 10, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (351, 568, 0, -568, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (352, 1780, 0, -1780, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (353, 51177, 49180, -1997, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (354, 0, 4345, 4345, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (355, 49180, 49100, -80, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (356, 4345, 4425, 80, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (357, 4425, 3425, -1000, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (358, 0, 1000, 1000, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (359, 3425, 425, -3000, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (360, 0, 3000, 3000, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (361, 425, 1, -424, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (362, 49100, 49524, 424, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (363, 1, 0, -1, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (364, 1000, 959, -41, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (365, 49524, 49566, 42, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (366, 959, 935, -24, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (367, 0, 24, 24, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (368, 24, 0, -24, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (369, 3000, 2994, -6, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (370, 935, 965, 30, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (371, 965, 0, -965, None, None, 10, 12, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (372, 2994, 2965, -29, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (373, 0, 994, 994, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (374, 20, 0, -20, None, None, 10, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (375, 0, 20, 20, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (376, 20, 5, -15, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (377, 0, 15, 15, None, None, 10, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (378, 5, 0, -5, None, None, 10, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (379, 15, 0, -15, None, None, 10, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (380, 22, 42, 20, None, None, 10, 13, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (381, 432, 0, -432, None, None, 6, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (382, 654645, 655077, 432, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (383, 49566, 35339, -14227, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (384, 994, 15221, 14227, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (385, 655077, 654646, -431, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (386, 378, 0, -378, None, None, 5, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (387, 432, 382, -50, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (388, 1000, 1050, 50, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (389, 1050, 1001, -49, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (390, 42, 37, -5, None, None, 10, 13, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (391, 0, 5, 5, None, None, 10, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (392, 15221, 979, -14242, None, None, 10, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (393, 2965, 0, -2965, None, None, 10, 12, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (394, 35339, 35328, -11, None, None, 10, 12, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (395, 0, 11, 11, None, None, 10, 12, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (396, 382, 283, -99, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (397, 1001, 1100, 99, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (398, 17, 0, -17, None, None, 1, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (399, 0, 17, 17, None, None, 1, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (400, 17, 10, -7, None, None, 1, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (401, 0, 7, 7, None, None, 1, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (402, 10, 0, -10, None, None, 1, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (403, 0, 10, 10, None, None, 1, 13, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (404, 1100, 1000, -100, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (405, 0, 100, 100, None, None, 9, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (406, 100, 50, -50, None, None, 9, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (407, 0, 50, 50, None, None, 9, 13, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (408, 48, 0, -48, None, None, 8, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (409, 654646, 654645, -1, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (410, 0, 1, 1, None, None, 6, 12, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (411, 283, 133, -150, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (412, 1000, 1150, 150, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (413, 1150, 1001, -149, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (414, 133, 0, -133, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (415, 384, 359, -25, None, None, 8, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (416, 0, 25, 25, None, None, 8, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (417, 25, 0, -25, None, None, 8, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (418, 43, 0, -43, None, None, 7, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (419, 359, 344, -15, None, None, 8, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (420, 0, 15, 15, None, None, 8, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (421, 15, 0, -15, None, None, 8, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (422, 344, 359, 15, None, None, 8, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (423, 359, 345, -14, None, None, 8, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (424, 50, 10, -40, None, None, 9, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (425, 0, 40, 40, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (426, 1001, 981, -20, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (427, 40, 60, 20, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (428, 654645, 654602, -43, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (429, 654602, 654562, -40, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (430, 654562, 654020, -542, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (431, 654020, 653478, -542, None, None, 6, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (432, 54, 40, -14, None, None, 5, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (433, 0, 14, 14, None, None, 5, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (434, 10, 0, -10, None, None, 9, 13, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (435, 60, 20, -40, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (436, 981, 1031, 50, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (437, 1031, 1000, -31, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (438, 20, 51, 31, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (439, 51, 30, -21, None, None, 9, 13, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (440, 1000, 1021, 21, None, None, 9, 13, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (441, 10, 6, -4, None, None, 1, 14, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (442, 0, 4, 4, None, None, 1, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (443, 50, 5, -45, None, None, 9, 14, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (444, 0, 45, 45, None, None, 9, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (445, 40, 17, -23, None, None, 5, 14, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (446, 0, 23, 23, None, None, 5, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (447, 17, 2, -15, None, None, 5, 14, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (448, 0, 15, 15, None, None, 5, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (449, 15, 0, -15, None, None, 5, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (450, 0, 15, 15, None, None, 5, 14, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (451, 45, 37, -8, None, None, 9, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (452, 0, 8, 8, None, None, 9, 15, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (453, 15, 2, -13, None, None, 5, 14, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (454, 0, 13, 13, None, None, 5, 14, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (455, 345, 330, -15, None, None, 8, 14, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (456, 0, 15, 15, None, None, 8, 14, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (457, 0, 52, 52, None, None, 11, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (458, 0, 199, 199, None, None, 12, 14, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (459, 52, 42, -10, None, None, 11, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (460, 0, 10, 10, None, None, 11, 15, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (461, 42, 12, -30, None, None, 11, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (462, 0, 30, 30, None, None, 11, 15, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (463, 12, 0, -12, None, None, 11, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (464, 0, 12, 12, None, None, 11, 15, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (465, 30, 0, -30, None, None, 11, 15, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (466, 0, 30, 30, None, None, 11, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (467, 30, 15, -15, None, None, 11, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (468, 0, 15, 15, None, None, 11, 15, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (469, 15, 14, -1, None, None, 11, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (470, 0, 1, 1, None, None, 11, 15, None, None, 11)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (471, 15, 5, -10, None, None, 11, 15, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (472, 0, 10, 10, None, None, 11, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (473, 10, 6, -4, None, None, 11, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (474, 0, 4, 4, None, None, 11, 14, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (475, 6, 3, -3, None, None, 11, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (476, 0, 3, 3, None, None, 11, 14, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (477, 3, 2, -1, None, None, 11, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (478, 0, 1, 1, None, None, 11, 14, None, None, 9)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (479, 2, 0, -2, None, None, 11, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (480, 1, 3, 2, None, None, 11, 14, None, None, 9)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (481, 3, 0, -3, None, None, 11, 14, None, None, 9)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (482, 4, 3, -1, None, None, 11, 14, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (483, 0, 4, 4, None, None, 11, 14, None, None, 12)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (484, 4, 0, -4, None, None, 11, 14, None, None, 12)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (485, 14, 18, 4, None, None, 11, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (486, 0, 243, 243, None, None, 13, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (487, 243, 143, -100, None, None, 13, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (488, 0, 100, 100, None, None, 13, 15, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (489, 143, 93, -50, None, None, 13, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (490, 0, 50, 50, None, None, 13, 15, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (491, 93, 0, -93, None, None, 13, 15, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (492, 0, 93, 93, None, None, 13, 15, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (493, 93, 43, -50, None, None, 13, 15, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (494, 50, 100, 50, None, None, 13, 15, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (495, 100, 50, -50, None, None, 13, 15, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (496, 0, 50, 50, None, None, 13, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (497, 50, 35, -15, None, None, 13, 15, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (498, 0, 15, 15, None, None, 13, 15, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (499, 0, 25, 25, None, None, 14, 14, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (500, 25, 5, -20, None, None, 14, 14, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (501, 0, 20, 20, None, None, 14, 14, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (502, 5, 0, -5, None, None, 14, 14, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (503, 0, 5, 5, None, None, 14, 14, None, 13, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (504, 20, 8, -12, None, None, 14, 14, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (505, 0, 12, 12, None, None, 14, 14, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (506, 0, 4234, 4234, None, None, 15, 16, None, 8, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (507, 0, 21232, 21232, None, None, 16, 17, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (508, 21232, 21132, -100, None, None, 16, 17, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (509, 0, 100, 100, None, None, 16, 17, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (510, 21132, 18132, -3000, None, None, 16, 17, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (511, 100, 3100, 3000, None, None, 16, 17, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (512, 18132, 16920, -1212, None, None, 16, 17, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (513, 0, 1212, 1212, None, None, 16, 17, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (514, 16920, 11920, -5000, None, None, 16, 17, None, 9, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (515, 0, 5000, 5000, None, None, 16, 17, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (516, 3100, 2290, -810, None, None, 16, 17, None, 10, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (517, 5000, 4600, -400, None, None, 16, 17, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (518, 1212, 1211, -1, None, None, 16, 17, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (519, 0, 1, 1, None, None, 16, 17, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (520, 12, 0, -12, None, None, 11, 17, None, 11, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (521, 18, 30, 12, None, None, 11, 17, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (522, 13, 1, -12, None, None, 5, 16, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (523, 2, 0, -2, None, None, 5, 16, None, None, 7)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (524, 0, 14, 14, None, None, 5, 17, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (525, 14, 4, -10, None, None, 5, 17, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (526, 0, 10, 10, None, None, 5, 17, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (527, 1, 0, -1, None, None, 16, 17, None, None, 5)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (528, 0, 1, 1, None, None, 16, 17, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (529, 1, 0, -1, None, None, 16, 17, None, None, 10)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (530, 0, 1, 1, None, None, 16, 16, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (531, 4600, 3400, -1200, None, None, 16, 17, None, 12, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (532, 0, 1200, 1200, None, None, 16, 16, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (533, 1200, 768, -432, None, None, 16, 16, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (534, 0, 432, 432, None, None, 16, 16, None, 13, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (535, 432, 0, -432, None, None, 16, 16, None, 13, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (536, 768, 1200, 432, None, None, 16, 16, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (537, 1200, 0, -1200, None, None, 16, 16, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (538, 1, 1201, 1200, None, None, 16, 16, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (539, 1201, 1, -1200, None, None, 16, 16, None, None, 6)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (540, 0, 1200, 1200, None, None, 16, 16, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (541, 1200, 100, -1100, None, None, 16, 16, None, None, 8)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (542, 0, 1100, 1100, None, None, 16, 16, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (543, 653478, 653472, -6, None, None, 6, 16, None, 7, None)
INSERT INTO lineas_recuento_inventario VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (544, 0, 6, 6, None, None, 6, 16, None, None, 6)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (1, 1, 'vista:bodega_a_sucursal', None, '2025-11-03 16:56:36.583302', 'Bodega BOD-01 → Sucursal SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (2, 12, 'vista:sucursal_a_sucursal', None, '2025-11-03 17:00:16.704736', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (3, 1, 'vista:bodega_a_sucursal', None, '2025-11-04 13:23:43.689804', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (4, 12, 'vista:bodega_a_sucursal', None, '2025-11-04 14:34:16.347845', 'Bodega BOD-01 → Sucursal SUC-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (5, 10, 'vista:bodega_a_sucursal', None, '2025-11-24 03:58:56.564575', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (6, 15, 'vista:bodega_a_sucursal', None, '2025-11-24 04:05:31.677868', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (7, 45, 'vista:sucursal_a_sucursal', None, '2025-11-24 04:06:55.894243', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (8, 65, 'vista:sucursal_a_sucursal', None, '2025-11-24 04:07:20.305177', 'Suc SUC-01 → Suc 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (9, 240, 'vista:bodega_a_sucursal', None, '2025-11-24 04:29:31.002518', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (10, 2, 'transferencias', 1, '2025-11-25 00:42:11.510245', 'Bodega BOD-01 → Sucursal SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (11, 1, 'transferencias', 2, '2025-11-25 01:01:42.023281', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (12, 1, 'transferencias', 3, '2025-11-25 01:05:39.662184', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (13, 1, 'transferencias', 4, '2025-11-25 02:56:41.706921', 'Suc SUC-01 → Suc 01122335544', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (14, 1, 'transferencias', 5, '2025-11-25 03:12:03.073146', 'Suc SUC-01 → Suc 01122335544', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (15, 1, 'transferencias', 6, '2025-11-25 03:12:14.476560', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (16, 1, 'transferencias', 7, '2025-11-25 03:28:50.956168', 'Bod BOD-01 → Bod 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (17, 1, 'transferencias', 8, '2025-11-25 04:00:06.041605', 'Suc SUC-01 → Bod BOD-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (18, 1, 'transferencias', 9, '2025-11-25 04:04:36.811392', 'Suc SUC-01 → Bod BOD-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (19, 1, 'transferencias', 10, '2025-11-25 04:04:38.703181', 'Suc SUC-01 → Bod BOD-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (20, 1, 'transferencias', 11, '2025-11-25 04:08:51.132310', 'Suc SUC-01 → Bod BOD-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (21, 1, 'transferencias', 12, '2025-11-25 04:09:05.100540', 'Suc SUC-01 → Bod BOD-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (22, 1, 'transferencias', 13, '2025-11-25 04:12:54.811444', 'Suc SUC-01 → Bod BOD-01', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (23, 100, 'transferencias', 14, '2025-11-25 04:15:48.089948', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (24, 50, 'transferencias', 15, '2025-11-25 04:23:19.717236', 'Bod BOD-01 → Bod 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (25, 1, 'transferencias', 16, '2025-11-25 04:38:21.348200', 'Bod 212321 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (26, 1, 'transferencias', 17, '2025-11-25 04:45:20.492165', 'Bod 212321 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (27, 1, 'transferencias', 18, '2025-11-25 04:46:01.825763', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (28, 1, 'transferencias', 19, '2025-11-25 04:55:15.221138', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (29, 1, 'transferencias', 20, '2025-11-25 04:55:29.654309', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (30, 1, 'transferencias', 21, '2025-11-25 05:02:13.824026', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (31, 1, 'transferencias', 22, '2025-11-25 05:02:27.683829', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (32, 1, 'transferencias', 23, '2025-11-25 05:07:37.382573', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (33, 1, 'transferencias', 24, '2025-11-25 05:07:38.095886', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (34, 1, 'transferencias', 25, '2025-11-25 05:07:49.401608', 'Bodega BOD-01 → Bodega 212321', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (35, 1, 'transferencias', 26, '2025-11-25 05:10:39.205648', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (36, 1, 'transferencias', 27, '2025-11-25 05:11:09.240249', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (37, 1, 'transferencias', 28, '2025-11-25 05:11:26.891648', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (38, 1, 'transferencias', 29, '2025-11-25 05:11:55.722579', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (39, 1, 'transferencias', 30, '2025-11-25 05:12:53.202077', 'Suc 01122335544 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (40, 1, 'transferencias', 31, '2025-11-25 21:01:27.776557', 'Suc SUC-01 → Suc 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (41, 15, 'transferencias', 32, '2025-11-25 21:17:03.878958', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (42, 1, 'transferencias', 33, '2025-11-25 23:02:44.904534', 'Suc SUC-01 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (43, 3, 'transferencias', 34, '2025-11-25 23:31:21.105059', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (44, 4, 'transferencias', 35, '2025-11-25 23:31:38.256677', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (45, 5, 'transferencias', 36, '2025-11-25 23:32:26.998514', 'Bodega BOD-01 → Bodega 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (46, 9, 'transferencias', 37, '2025-11-25 23:32:59.402586', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (47, 15, 'transferencias', 38, '2025-11-25 23:44:36.309781', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (48, 1, 'transferencias', 39, '2025-11-25 23:47:52.424239', 'Bodega BOD-01 → Bodega 212321', 1, None, 3, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (49, 1, 'transferencias', 40, '2025-11-25 23:49:45.337381', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (50, 1, 'transferencias', 41, '2025-11-25 23:50:00.940978', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (51, 1, 'transferencias', 42, '2025-11-25 23:50:33.626777', 'Bodega BOD-01 → Bodega 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (52, 1, 'transferencias', 43, '2025-11-25 23:59:21.900693', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (53, 1, 'transferencias', 44, '2025-11-25 23:59:57.317598', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (54, 1, 'transferencias', 45, '2025-11-26 00:07:00.740337', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (55, 1, 'transferencias', 46, '2025-11-26 00:10:58.586155', 'Bodega BOD-01 → Bodega 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (56, 1, 'transferencias', 47, '2025-11-26 00:11:14.746723', 'Bodega BOD-01 → Bodega 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (57, 1, 'transferencias', 48, '2025-11-26 00:18:03.828884', 'Bodega BOD-01 → Bodega 212321', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (58, 1, 'transferencias', 49, '2025-11-26 00:46:19.880156', 'Suc SUC-01 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (59, 1, 'transferencias', 50, '2025-11-26 00:50:43.099142', 'Suc SUC-01 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (60, 1, 'transferencias', 51, '2025-11-26 01:04:02.950457', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (61, 12, 'transferencias', 52, '2025-11-26 03:17:23.559386', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (62, 12, 'transferencias', 53, '2025-11-26 03:20:13.214935', 'Suc SUC-01 → Suc 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (63, 25, 'transferencias', 54, '2025-11-26 03:20:28.467270', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (64, 10, 'transferencias', 55, '2025-11-26 03:20:51.899795', 'Suc SUC-01 → Suc 01122335544', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (65, 5, 'transferencias', 56, '2025-11-26 03:21:04.912473', 'Suc SUC-01 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (66, 5, 'transferencias', 57, '2025-11-26 03:21:06.208646', 'Suc SUC-01 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (67, 5, 'transferencias', 58, '2025-11-26 03:21:22.773994', 'Bodega 212321 → Bodega BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (68, 2, 'transferencias', 59, '2025-11-26 03:25:18.338503', 'Bodega BOD-01 → Bodega 212321', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (69, 1, 'transferencias', 60, '2025-11-26 03:25:35.481551', 'Bodega BOD-01 → Bodega 212321', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (70, 10, 'transferencias', 61, '2025-11-26 03:27:02.404940', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (71, 5, 'transferencias', 62, '2025-11-26 03:27:11.161822', 'Suc 01122335544 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (72, 3, 'transferencias', 63, '2025-11-26 03:27:15.998817', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (73, 7, 'transferencias', 64, '2025-11-26 03:27:21.554671', 'Suc 01122335544 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (74, 4, 'transferencias', 65, '2025-11-26 03:27:26.879682', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (75, 1, 'transferencias', 66, '2025-11-26 03:27:32.364456', 'Suc 01122335544 → Bod BOD-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (76, 2, 'transferencias', 67, '2025-11-26 03:27:39.456238', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (77, 3, 'transferencias', 68, '2025-11-26 03:27:50.192556', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (78, 4, 'transferencias', 69, '2025-11-26 03:28:38.575290', 'Suc 01122335544 → Bod BOD-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (79, 12, 'transferencias', 70, '2025-11-26 03:29:07.129913', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (80, 3, 'transferencias', 71, '2025-11-26 03:29:16.551340', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (81, 1, 'transferencias', 72, '2025-11-26 03:29:21.114054', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (82, 1, 'transferencias', 73, '2025-11-26 03:29:28.696297', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (83, 1, 'transferencias', 74, '2025-11-26 03:29:33.905876', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (84, 1, 'transferencias', 75, '2025-11-26 03:29:43.190183', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (85, 1, 'transferencias', 76, '2025-11-26 03:29:53.943248', 'Suc 01122335544 → Suc SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (86, 1, 'transferencias', 77, '2025-11-26 03:58:45.318995', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (87, 2, 'transferencias', 78, '2025-11-26 04:08:34.991017', 'Bodega BOD-01 → Sucursal SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (88, 4, 'transferencias', 79, '2025-11-26 04:08:46.722742', 'Bodega BOD-01 → Sucursal SUC-01', 1, None, 4, None, 1, None, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (89, 17, 'transferencias', 80, '2025-11-27 05:54:49.466251', 'Suc 01122335544 → Bod BOD-01', 1, None, 1, None, 1, None, 7, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (90, 26, 'transferencias', 81, '2025-11-27 18:36:54.356097', 'Bodega BOD-0024 → Bodega BOD-01', 1, None, 10, None, 1, 9, 7, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (91, 26, 'transferencias', 82, '2025-11-27 18:42:49.768388', 'Bodega BOD-01 → Bodega BOD-0024', 1, None, 10, None, 1, 7, 9, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (92, 2, 'transferencias', 83, '2025-11-28 02:12:17.316871', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (93, 1, 'transferencias', 84, '2025-11-28 02:23:27.435779', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (94, 6, 'transferencias', 85, '2025-11-28 02:24:42.019253', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (95, 7, 'transferencias', 86, '2025-11-28 02:26:22.252717', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (96, 5, 'transferencias', 87, '2025-11-28 03:19:12.497118', 'Bodega BOD-0024 → Bodega BOD-01', 1, None, 10, None, 1, 9, 7, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (97, 5, 'transferencias', 88, '2025-11-28 03:22:20.475360', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (98, 15, 'transferencias', 89, '2025-11-28 03:25:17.940718', 'Suc SUC-01 → Bod BOD-0024', 1, None, 10, None, 1, None, 9, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (99, 1535, 'transferencias', 90, '2025-11-28 23:33:07.371067', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (100, 51, 'transferencias', 91, '2025-11-28 23:51:04.684263', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (101, 15, 'transferencias', 92, '2025-11-28 23:52:51.086992', 'Bodega BOD-0024 → Bodega BOD-01', 1, None, 10, None, 1, 9, 7, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (102, 423, 'transferencias', 93, '2025-11-29 01:18:11.091673', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (103, 25, 'transferencias', 94, '2025-11-29 01:32:36.282060', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (104, 10, 'transferencias', 95, '2025-11-29 02:09:13.281362', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (105, 100, 'transferencias', 96, '2025-11-29 02:28:38.413425', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (106, 11, 'transferencias', 97, '2025-11-29 02:40:51.512832', 'Suc 01122335544 → Suc SUC-01', 1, None, 10, None, 1, None, None, 6, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (107, 150, 'transferencias', 98, '2025-11-29 02:41:54.777407', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (108, 100, 'transferencias', 99, '2025-11-29 02:43:38.007620', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (109, 30, 'transferencias', 100, '2025-11-29 02:45:28.241071', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (110, 9, 'transferencias', 101, '2025-11-29 02:46:43.606097', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (111, 10, 'transferencias', 102, '2025-11-29 02:50:16.920351', 'Suc SUC-01 → Suc 01122335544', 1, None, 10, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (112, 17887, 'transferencias', 103, '2025-11-29 04:13:49.478244', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 10, None, 1, 9, None, None, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (113, 17, 'transferencias', 104, '2025-11-29 04:21:07.500819', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 1, None, 1, 7, None, None, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (114, 100, 'transferencias', 105, '2025-11-29 04:22:26.882521', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 9, None, 1, 7, None, None, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (115, 1, 'transferencias', 106, '2025-11-29 18:00:49.980208', 'Bodega BOD-01 → Bodega BOD-0024', 1, None, 6, None, 1, 7, 9, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (116, 4, 'transferencias', 107, '2025-12-01 05:18:22.881886', 'Suc 01122335544 → Suc SUC-01', 1, None, 1, None, 1, None, None, 6, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (117, 45, 'transferencias', 108, '2025-12-01 05:18:37.399912', 'Suc 01122335544 → Suc SUC-01', 1, None, 9, None, 1, None, None, 6, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (118, 23, 'transferencias', 109, '2025-12-01 05:22:49.003668', 'Bodega BOD-01 → Bodega BOD-0024', 1, None, 5, None, 1, 7, 9, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (119, 15, 'transferencias', 110, '2025-12-01 05:32:09.717977', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 5, None, 1, 7, None, None, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (120, 30, 'transferencias', 111, '2025-12-01 21:53:50.743713', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 11, None, 1, 9, None, None, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (121, 10, 'transferencias', 112, '2025-12-01 22:00:27.587671', 'Suc SUC-01 → Suc 01122335544', 1, None, 11, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (122, 4, 'transferencias', 113, '2025-12-02 00:15:58.828735', 'Suc 01122335544 → Suc SUC-01', 1, None, 11, None, 1, None, None, 6, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (123, 50, 'transferencias', 114, '2025-12-02 00:35:37.791252', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 13, None, 1, 9, None, None, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (124, 12, 'transferencias', 115, '2025-12-02 02:38:39.308432', 'Bodega BOD-01 → Sucursal 01122335544', 5, None, 14, None, 1, 7, None, None, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (125, 1211, 'transferencias', 116, '2025-12-02 04:16:06.540772', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 16, None, 1, 9, None, None, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (126, 12, 'transferencias', 117, '2025-12-02 04:17:46.327534', 'Bodega BOD-0024 → Sucursal SUC-01', 1, None, 11, None, 1, 9, None, None, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (127, 14, 'transferencias', 118, '2025-12-02 04:22:06.154025', 'Suc 01122335544 → Suc SUC-01', 1, None, 5, None, 1, None, None, 6, 5, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (128, 1, 'transferencias', 119, '2025-12-02 04:26:46.658501', 'Suc SUC-01 → Suc 01122335544', 1, None, 16, None, 1, None, None, 5, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (129, 1200, 'transferencias', 120, '2025-12-02 04:28:37.154202', 'Bodega BOD-0024 → Bodega BOD-01', 1, None, 16, None, 1, 9, 7, None, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (130, 1200, 'transferencias', 121, '2025-12-02 04:31:52.916067', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 16, None, 1, 7, None, None, 6, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (131, 1100, 'transferencias', 122, '2025-12-02 04:38:44.995782', 'Suc 01122335544 → Bod BOD-01', 1, None, 16, None, 1, None, 7, 6, None, 2)
INSERT INTO movimientos_stock VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (132, 6, 'transferencias', 123, '2025-12-02 04:40:12.073004', 'Bodega BOD-01 → Sucursal 01122335544', 1, None, 6, None, 1, 7, None, None, 6, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (34, 3, None, 4, None, 34, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (35, 4, None, 1, None, 35, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (37, 9, None, 4, None, 37, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (38, 15, None, 1, None, 38, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (40, 1, None, 4, None, 40, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (41, 1, None, 4, None, 41, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (43, 1, None, 4, None, 43, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (44, 1, None, 4, None, 44, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (45, 1, None, 4, None, 45, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (49, 1, None, 1, None, 49, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (50, 1, None, 1, None, 50, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (52, 12, None, 4, None, 52, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (53, 12, None, 1, None, 53, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (55, 10, None, 1, None, 55, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (56, 5, None, 1, None, 56, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (57, 5, None, 1, None, 57, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (61, 10, None, 4, None, 61, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (62, 5, None, 1, None, 62, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (63, 3, None, 4, None, 63, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (64, 7, None, 1, None, 64, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (65, 4, None, 4, None, 65, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (66, 1, None, 1, None, 66, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (67, 2, None, 4, None, 67, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (68, 3, None, 4, None, 68, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (69, 4, None, 4, None, 69, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (70, 12, None, 4, None, 70, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (71, 3, None, 4, None, 71, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (72, 1, None, 1, None, 72, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (73, 1, None, 1, None, 73, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (74, 1, None, 4, None, 74, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (75, 1, None, 1, None, 75, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (76, 1, None, 4, None, 76, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (77, 1, None, 4, None, 77, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (78, 2, None, 4, None, 78, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (79, 4, None, 4, None, 79, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (80, 17, None, 1, None, 80, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (81, 26, None, 10, None, 81, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (82, 26, None, 10, None, 82, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (83, 2, None, 10, None, 83, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (84, 1, None, 10, None, 84, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (85, 6, None, 10, None, 85, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (86, 7, None, 10, None, 86, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (87, 5, None, 10, None, 87, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (88, 5, None, 10, None, 88, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (89, 15, None, 10, None, 89, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (90, 1535, None, 10, None, 90, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (91, 51, None, 10, None, 91, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (92, 15, None, 10, None, 92, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (93, 423, None, 10, None, 93, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (94, 25, None, 10, None, 94, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (95, 10, None, 10, None, 95, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (96, 100, None, 10, None, 96, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (97, 11, None, 10, None, 97, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (98, 150, None, 10, None, 98, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (99, 100, None, 10, None, 99, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (100, 30, None, 10, None, 100, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (101, 9, None, 10, None, 101, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (102, 10, None, 10, None, 102, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (103, 17887, None, 10, None, 103, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (104, 17, None, 1, None, 104, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (105, 100, None, 9, None, 105, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (106, 1, None, 6, None, 106, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (107, 4, None, 1, None, 107, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (108, 45, None, 9, None, 108, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (109, 23, None, 5, None, 109, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (110, 15, None, 5, None, 110, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (111, 30, None, 11, None, 111, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (112, 10, None, 11, None, 112, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (113, 4, None, 11, None, 113, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (114, 50, None, 13, None, 114, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (115, 12, None, 14, None, 115, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (116, 1211, None, 16, None, 116, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (117, 12, None, 11, None, 117, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (118, 14, None, 5, None, 118, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (119, 1, None, 16, None, 119, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (120, 1200, None, 16, None, 120, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (121, 1200, None, 16, None, 121, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (122, 1100, None, 16, None, 122, 2)
INSERT INTO lineas_transferencia VALUES (?, ?, ?, ?, ?, ?, ?);
    (123, 6, None, 6, None, 123, 2)
INSERT INTO lineas_recepcion_mercaderia VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (1, 1, None, None, 3, 1, None, 1)
INSERT INTO lineas_orden_compra VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (1, 'Compra PayPal #8K149473W4530311L', 1, 5, 0, 1, 3, 1)
INSERT INTO usuarios_perfil VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (1, '2025-11-02 02:52:45.714367', '2025-12-02 03:41:31.189666', '', '', 'ADMIN', None, 1)
INSERT INTO usuarios_perfil VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (2, '2025-11-03 03:40:25.214546', '2025-11-03 03:40:25.214559', '', '', 'ADMIN', None, 2)
INSERT INTO usuarios_perfil VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (4, '2025-11-03 22:13:56.382517', '2025-11-03 22:13:56.387938', '', '+56999254350', 'PROVEEDOR', None, 4)
INSERT INTO usuarios_perfil VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (5, '2025-11-04 14:29:04.462774', '2025-12-02 02:44:04.566024', '', '', 'PROVEEDOR', None, 5)
INSERT INTO usuarios_perfil VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (6, '2025-11-04 14:31:09.203167', '2025-12-02 02:41:58.898177', '', '', 'BODEGUERO', None, 6)
INSERT INTO usuarios_perfil VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (7, '2025-12-02 13:46:22.148369', '2025-12-02 13:46:32.424570', '', '', 'BODEGUERO', None, 7)
INSERT INTO facturas_proveedor VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (1, 'FP-PAYPAL-8K149473W4530311L', 5, '2025-11-03', None, 'PAID', 2, None)
INSERT INTO django_session VALUES (?, ?, ?);
    ('y8jthgmychb1924vmqeqso53dobscwhi', '.eJxVjMEOwiAQBf-FsyFsC4X26N1vILAsFjVgoE00xn_XJj3o9c28eTHr1mW2a6NqU2ATA3b43bzDK-UNhIvL58Kx5KUmzzeF77TxUwl0O-7uX2B2bf6-jRIDmQgITiMopE56JUWgXhtUOEQ5dBEgeu1h9BpxlN6AUKFXiI5oizZqLZVs6XFP9ckm8f4Ald0_mQ:1vFOD8:3V45A9oPaAY2ZDeFr_tXsvyc-u4TRmvc2YbB7Wdv5Sc', '2025-11-16 02:52:54.239017')
INSERT INTO django_session VALUES (?, ?, ?);
    ('ws3ycens0lp9005wfrkkuwdue93zlm6v', '.eJxVjMEOwiAQBf-FsyFsC4X26N1vILAsFjVgoE00xn_XJj3o9c28eTHr1mW2a6NqU2ATA3b43bzDK-UNhIvL58Kx5KUmzzeF77TxUwl0O-7uX2B2bf6-jRIDmQgITiMopE56JUWgXhtUOEQ5dBEgeu1h9BpxlN6AUKFXiI5oizZqLZVs6XFP9ckm8f4Ald0_mQ:1vFjp8:rB8AGh0r2fnQ6mmEaPqxwBt1gibWcd-HQDkB7iZ1cIs', '2025-11-17 01:57:34.517038')
INSERT INTO django_session VALUES (?, ?, ?);
    ('9lzdex8qy4fgztw3w87gqpn4mx55b92p', '.eJxVjMEOwiAQBf-FsyFsC4X26N1vILAsFjVgoE00xn_XJj3o9c28eTHr1mW2a6NqU2ATA3b43bzDK-UNhIvL58Kx5KUmzzeF77TxUwl0O-7uX2B2bf6-jRIDmQgITiMopE56JUWgXhtUOEQ5dBEgeu1h9BpxlN6AUKFXiI5oizZqLZVs6XFP9ckm8f4Ald0_mQ:1vFjr3:46GgiFE9O6MkRDQ5xiP_TEYyW-IADrdNk9EyykheLbQ', '2025-11-17 01:59:33.823535')
INSERT INTO django_session VALUES (?, ?, ?);
    ('4qh03fmcbpbuvbi33xfxq1nhpd077tbd', '.eJxVjMEOwiAQBf-FsyFsC4X26N1vILAsFjVgoE00xn_XJj3o9c28eTHr1mW2a6NqU2ATA3b43bzDK-UNhIvL58Kx5KUmzzeF77TxUwl0O-7uX2B2bf6-jRIDmQgITiMopE56JUWgXhtUOEQ5dBEgeu1h9BpxlN6AUKFXiI5oizZqLZVs6XFP9ckm8f4Ald0_mQ:1vFnHt:BHhhiY_oVH4dFeNBGCEbZGfdLbEw_jomBaPMJYmQfPU', '2025-11-17 05:39:29.806413')
INSERT INTO django_session VALUES (?, ?, ?);
    ('velwzge1zufxbg4afyazrhnrexy5fln1', '.eJxVjDsOwjAQBe_iGlnexL9Q0nMGy7te4wCypTipEHeHSCmgfTPzXiLEbS1h67yEOYmzAHH63TDSg-sO0j3WW5PU6rrMKHdFHrTLa0v8vBzu30GJvXxrb5Rln4EgOgJDPGg0WiUenSdDNms7ZICMDmFCRzRp9KBMGg1RZBbvD-RXOFw:1vFtLB:JK4zANu-1KG8g5ns0nQ2ZuczIb2I_uG209z_Dik3rGY', '2025-11-17 12:07:17.320035')
INSERT INTO django_session VALUES (?, ?, ?);
    ('83hrj2hk484cj1lohc8jn8f8mf9hrjof', '.eJxVjEEOwiAQAP_C2RC2QqE9evcNhF0WixowpU00xr-bJj3odWYyb-HDukx-bTz7HMUoQBx-GQa6cdlEvIZyqZJqWeaMckvkbps818j3097-DabQJjEKZ1TPLgFBsASGuNNotIp8tI4M9Un3XQJIaBEGtESDRgfKxKMhCszbtHFruRbPz0eeX2JUny-V3T-Z:1vG3Nm:yTbsJGGYu2r-AHexlvvf73rKQ1gJPhTHRmOqgM7Giw0', '2025-11-17 22:50:38.557366')
INSERT INTO django_session VALUES (?, ?, ?);
    ('xir12sdcd1lfabeqxt8ci81f8j5m91w8', 'e30:1vGI5I:hWbasqbKnyE679o_EZbmqrYHw9X0qSsv3oFLjbmNBPQ', '2025-11-18 14:32:32.919799')
INSERT INTO django_session VALUES (?, ?, ?);
    ('84gfrncqrt3ckrtlkoj1buuaiengmarb', 'e30:1vGI5S:C0m0qtmJKI9ijjRRgDMmM_eVDzJMZ2ti7WAh3BM1yro', '2025-11-18 14:32:42.502753')
INSERT INTO django_session VALUES (?, ?, ?);
    ('iwsq81tvh2v4tthcnz7cph3e0uiexqwq', 'e30:1vGPGy:dV_Cdnn3xn-c5r8hBqlLbogOjX9bEuOZvaGYFt_jOHE', '2025-11-18 22:13:04.004239')
INSERT INTO django_session VALUES (?, ?, ?);
    ('699es7qacjy37d1leoefet55myqu7hsl', '.eJxVjMEOwiAQBf-FsyFsC4X26N1vILAsFjVgoE00xn_XJj3o9c28eTHr1mW2a6NqU2ATA3b43bzDK-UNhIvL58Kx5KUmzzeF77TxUwl0O-7uX2B2bf6-jRIDmQgITiMopE56JUWgXhtUOEQ5dBEgeu1h9BpxlN6AUKFXiI5oizZqLZVs6XFP9ckm8f4Ald0_mQ:1vGPJq:85XktCrVq_8elJgYbSdorL-qtoQe_FpVG1awsG1EIf0', '2025-11-18 22:16:02.841013')
INSERT INTO django_session VALUES (?, ?, ?);
    ('4wrp864c9ubfxjif4cxw46kqer9040y5', '.eJxVjMEOwiAQBf-Fc9MALVB61Ksm_gGB3a2tGmqgTTTGf1eSHvT43kzmxZxfl9GtmZKbkPVMsOr3Cx6uFAvAi4_nuYY5LmkKdVHqjeb6OCPddpv7Fxh9Hks2mMDV4AFFA53iDVGrlJSAukVuQyN40AJRExltVGs9DB21YI2UlqMs0Uw5T3N09LhP6cl6XjFYU6II38H2hxN7fwDsgERA:1vGU7g:AiL_NsVw2vHzN0s7ikWh26TDRpQy8pykbxfgSmjq7Qg', '2025-11-19 03:23:48.969485')
INSERT INTO django_session VALUES (?, ?, ?);
    ('2womg98t97wz6twzgttzp05q2061t69h', '.eJxVjEsOwiAUAO_C2hCgfIpL956BwHuvFjVgSptojHc3JF3odmYybxbits5ha7SEjOzIJDv8shThRqULvMZyqRxqWZeceE_4bhs_V6T7aW__BnNsc98ml4SZIqAcYDRiINLGKAVoNQqfBimSlYiWyFlntI8wjaTBO6W8QNWnjVrLtQR6PvLyYkfx-QKN5D8I:1vGhRj:8EpYZRGStai98KtQew7N2w8joYpjsBlvAKAvwVQXY8Y', '2025-11-19 17:37:23.152037')
INSERT INTO django_session VALUES (?, ?, ?);
    ('71m2fy0dnf7qolydeuyq5kmpcvz7b3sd', '.eJxVjEsOwiAUAO_C2hCgfIpL956BwHuvFjVgSptojHc3JF3odmYybxbits5ha7SEjOzIJDv8shThRqULvMZyqRxqWZeceE_4bhs_V6T7aW__BnNsc98ml4SZIqAcYDRiINLGKAVoNQqfBimSlYiWyFlntI8wjaTBO6W8QNWnjVrLtQR6PvLyYkfx-QKN5D8I:1vHpQ1:nPk6VdevMOyHpo1zeU32-ta2197dgDL2LINez_ui-SI', '2025-11-22 20:20:17.552370')
INSERT INTO django_session VALUES (?, ?, ?);
    ('ufg4tm1ji4vzavst2r9d38nv2w2ukvr4', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vPPc5:_uOXAEqyTgM9090qxRTtCZnki4xX0OAhTT51ABnw3y4', '2025-12-13 18:24:05.499958')
INSERT INTO django_session VALUES (?, ?, ?);
    ('kltcq8sygbtnyln83k0ip7sv4gh3ca75', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vPsx6:UwZFh22gqILIy4NgB6Vt2iRU1g56an7sCggl-sKtmXY', '2025-12-15 01:43:44.348731')
INSERT INTO django_session VALUES (?, ?, ?);
    ('kolp6nrfp6v44pzedirubohxe0a34dg6', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vPvUM:WzG5IUMs-I25YuqdZTlhEooVqDH4pPJ2WWUrM6Svqtc', '2025-12-15 04:26:14.915770')
INSERT INTO django_session VALUES (?, ?, ?);
    ('x5av6aqf6mwh6qtb3bpw3ruvp7vismte', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQ8xq:igcJ7hoUZLSRQlw_ijgYdV1xJ2Csf_0yjAEyWQEtgmg', '2025-12-15 18:49:34.883953')
INSERT INTO django_session VALUES (?, ?, ?);
    ('z4gyf7vcgt1ftoiwdsjdisicoss0upg1', '.eJxVjEEOwiAURO_CuiGAhYBL3WriDQjwPxY1YKBNNMa725oudDkzb96LWDeNg50aVpuAbAkn3W_nXbhiXga4uHwuNJQ81uTpgtB1bfRYAG-7lf0TDK4N81tJFoRg3GDPlNJGR4jaM2NAixgAlEPPfb_hTqA0GlCCQqm9Z72MTn6lDVtLJVt83FN9ki3rSJhqxRzmQPaHE3l_AO6fRLU:1vQGlL:EgNkSFW7KOBiM7N_LFo0CJd8TedNcunSo6igeI2Dvdo', '2025-12-16 03:09:11.354385')
INSERT INTO django_session VALUES (?, ?, ?);
    ('o74m93q014rsqut4bl8flv1qxozgavia', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQE17:wv7keKAvVS8zM4VTdDbpIjcoO58bxCDmajLeLZzNFH0', '2025-12-16 00:13:17.902848')
INSERT INTO django_session VALUES (?, ?, ?);
    ('uzevejyb82mgtaq3jbuif3k6jv7qwv11', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQEXt:6avom2sdS84O_nWyGQVxyKMo-PK6cNcgWOlu1PmXXzc', '2025-12-16 00:47:09.219431')
INSERT INTO django_session VALUES (?, ?, ?);
    ('v347mi9oydz3f24de7v7thror3sk4fwc', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQGZc:bi1lSc2QL4WqW7-wA07RDVCITKvYukTNki-tiEN3sHs', '2025-12-16 02:57:04.214946')
INSERT INTO django_session VALUES (?, ?, ?);
    ('fwoymbbz8q90qpw00x46za2fuqp3cy9v', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQH6E:_itfbv4x19Ojwz9Uaj_km1RIum0oDAtC62_ki6ZO6H4', '2025-12-16 03:30:46.238835')
INSERT INTO django_session VALUES (?, ?, ?);
    ('yvs7uwhkwgjacwagz2qtcrjxskja12xd', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQH91:rfxLGnTrSeHkQ2UK2dH9FAtofOGfmhAufWXM1Bh9vdU', '2025-12-16 03:33:39.533083')
INSERT INTO django_session VALUES (?, ?, ?);
    ('6s1jw3lbgoi2ib3p86lurhyz5w5wfcyy', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQHRN:OwJmuy7Ma3GrSU1QZObjiApP0uyyvJBemLb2aTuBxQ0', '2025-12-16 03:52:37.525021')
INSERT INTO django_session VALUES (?, ?, ?);
    ('y03e2ubyke4q611908drh53p8dq6llw8', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQHTf:Cld4sKHAkHgh4eN5T7CPI3cGIlE_mQjlshOA4nxViUY', '2025-12-16 03:54:59.793174')
INSERT INTO django_session VALUES (?, ?, ?);
    ('cnpbs18juge4ahg89vfsxhy643u76ful', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQQQE:nxVg7t8Ka9bz9HfYxT85vqT4J0eqdfvZI7qZqocQ2qY', '2025-12-16 13:28:02.825844')
INSERT INTO django_session VALUES (?, ?, ?);
    ('9nycuyy1cuqbytyxdwciub6sk28cxhnp', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQTGe:SYwhIotHBXYPwiG0-rdxs0ISurKHBczEjcMFuUkzfSE', '2025-12-16 16:30:20.143409')
INSERT INTO django_session VALUES (?, ?, ?);
    ('q1ddb8wiqwqiz0t9akc34i2oy65cgzpo', '.eJxVjMEOwiAQBf-FsyGAhUCP3v0GwrKLRQ0YaBON8d-1pge9vpk3T-bDMk9-6dR8RjYyyXa_G4R4obICPIdyqjzWMrcMfFX4Rjs_VqTrYXP_AlPo0-dttIhKCeloEMZYZxMmC8I5tCpFRBMIJAx7GRRpZ5E0GtIWQAw6Bf2Nduo91-LpfsvtwUbxegOIPj99:1vQTmx:l_xf7Qa8AIw5xD23virV7e_EkFNJBsNKFIoI6JsvSlU', '2025-12-16 17:03:43.692451')
INSERT INTO django_site VALUES (?, ?, ?);
    (1, 'example.com', 'example.com')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (34, '2025-11-25 23:31:21.087107', '2025-11-25 23:31:21.087107', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (35, '2025-11-25 23:31:38.241801', '2025-11-25 23:31:38.241801', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (37, '2025-11-25 23:32:59.399594', '2025-11-25 23:32:59.399594', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (38, '2025-11-25 23:44:36.293850', '2025-11-25 23:44:36.293850', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (40, '2025-11-25 23:49:45.321423', '2025-11-25 23:49:45.321423', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (41, '2025-11-25 23:50:00.925021', '2025-11-25 23:50:00.925021', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (43, '2025-11-25 23:59:21.884734', '2025-11-25 23:59:21.884734', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (44, '2025-11-25 23:59:57.299645', '2025-11-25 23:59:57.299645', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (45, '2025-11-26 00:07:00.720362', '2025-11-26 00:07:00.720362', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (49, '2025-11-26 00:46:19.878134', '2025-11-26 00:46:19.878134', 'CONFIRMADA', None, 1, None, None, None, 1, 1, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (50, '2025-11-26 00:50:43.097119', '2025-11-26 00:50:43.097119', 'CONFIRMADA', None, 1, None, None, None, 1, 1, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (52, '2025-11-26 03:17:23.541132', '2025-11-26 03:17:23.541132', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (53, '2025-11-26 03:20:13.204992', '2025-11-26 03:20:13.204992', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (55, '2025-11-26 03:20:51.885212', '2025-11-26 03:20:51.885212', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (56, '2025-11-26 03:21:04.910508', '2025-11-26 03:21:04.910508', 'CONFIRMADA', None, 1, None, None, None, 1, 1, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (57, '2025-11-26 03:21:06.206627', '2025-11-26 03:21:06.206627', 'CONFIRMADA', None, 1, None, None, None, 1, 1, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (61, '2025-11-26 03:27:02.402921', '2025-11-26 03:27:02.402921', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (62, '2025-11-26 03:27:11.159825', '2025-11-26 03:27:11.159825', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (63, '2025-11-26 03:27:15.996822', '2025-11-26 03:27:15.996822', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (64, '2025-11-26 03:27:21.553138', '2025-11-26 03:27:21.553138', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (65, '2025-11-26 03:27:26.876667', '2025-11-26 03:27:26.876667', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (66, '2025-11-26 03:27:32.361488', '2025-11-26 03:27:32.361488', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (67, '2025-11-26 03:27:39.454243', '2025-11-26 03:27:39.454243', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (68, '2025-11-26 03:27:50.190560', '2025-11-26 03:27:50.190560', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (69, '2025-11-26 03:28:38.573296', '2025-11-26 03:28:38.573296', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (70, '2025-11-26 03:29:07.117967', '2025-11-26 03:29:07.117967', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (71, '2025-11-26 03:29:16.535319', '2025-11-26 03:29:16.536318', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (72, '2025-11-26 03:29:21.104079', '2025-11-26 03:29:21.104079', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (73, '2025-11-26 03:29:28.679773', '2025-11-26 03:29:28.679773', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (74, '2025-11-26 03:29:33.891913', '2025-11-26 03:29:33.891913', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (75, '2025-11-26 03:29:43.173650', '2025-11-26 03:29:43.173650', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (76, '2025-11-26 03:29:53.931852', '2025-11-26 03:29:53.931852', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (77, '2025-11-26 03:58:45.303037', '2025-11-26 03:58:45.303037', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (78, '2025-11-26 04:08:34.978025', '2025-11-26 04:08:34.978025', 'CONFIRMADA', 1, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (79, '2025-11-26 04:08:46.704006', '2025-11-26 04:08:46.704006', 'CONFIRMADA', 1, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (80, '2025-11-27 05:54:49.463232', '2025-11-27 05:54:49.463232', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (81, '2025-11-27 18:36:54.340378', '2025-11-27 18:36:54.340378', 'CONFIRMADA', 3, 1, None, None, None, 1, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (82, '2025-11-27 18:42:49.757419', '2025-11-27 18:42:49.758415', 'CONFIRMADA', 1, 1, None, None, None, 3, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (83, '2025-11-28 02:12:17.298919', '2025-11-28 02:12:17.298919', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (84, '2025-11-28 02:23:27.416830', '2025-11-28 02:23:27.416830', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (85, '2025-11-28 02:24:42.002578', '2025-11-28 02:24:42.002578', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (86, '2025-11-28 02:26:22.231646', '2025-11-28 02:26:22.231646', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (87, '2025-11-28 03:19:12.480164', '2025-11-28 03:19:12.480164', 'CONFIRMADA', 3, 1, None, None, None, 1, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (88, '2025-11-28 03:22:20.456413', '2025-11-28 03:22:20.456413', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (89, '2025-11-28 03:25:17.938752', '2025-11-28 03:25:17.938752', 'CONFIRMADA', None, 1, None, None, None, 3, 1, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (90, '2025-11-28 23:33:07.359682', '2025-11-28 23:33:07.359682', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (91, '2025-11-28 23:51:04.666341', '2025-11-28 23:51:04.666341', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (92, '2025-11-28 23:52:51.071063', '2025-11-28 23:52:51.071063', 'CONFIRMADA', 3, 1, None, None, None, 1, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (93, '2025-11-29 01:18:11.074718', '2025-11-29 01:18:11.074718', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (94, '2025-11-29 01:32:36.270054', '2025-11-29 01:32:36.270054', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (95, '2025-11-29 02:09:13.265675', '2025-11-29 02:09:13.265675', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (96, '2025-11-29 02:28:38.392827', '2025-11-29 02:28:38.392827', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (97, '2025-11-29 02:40:51.480406', '2025-11-29 02:40:51.480406', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (98, '2025-11-29 02:41:54.762128', '2025-11-29 02:41:54.762128', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (99, '2025-11-29 02:43:37.991668', '2025-11-29 02:43:37.991668', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (100, '2025-11-29 02:45:28.229136', '2025-11-29 02:45:28.229136', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (101, '2025-11-29 02:46:43.590876', '2025-11-29 02:46:43.590876', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (102, '2025-11-29 02:50:16.904824', '2025-11-29 02:50:16.904824', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (103, '2025-11-29 04:13:49.452750', '2025-11-29 04:13:49.452750', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (104, '2025-11-29 04:21:07.482872', '2025-11-29 04:21:07.482872', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (105, '2025-11-29 04:22:26.870524', '2025-11-29 04:22:26.870524', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (106, '2025-11-29 18:00:49.950029', '2025-11-29 18:00:49.950029', 'CONFIRMADA', 1, 1, None, None, None, 3, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (107, '2025-12-01 05:18:22.872912', '2025-12-01 05:18:22.872912', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (108, '2025-12-01 05:18:37.390914', '2025-12-01 05:18:37.390914', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (109, '2025-12-01 05:22:48.988048', '2025-12-01 05:22:48.988048', 'CONFIRMADA', 1, 1, None, None, None, 3, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (110, '2025-12-01 05:32:09.701021', '2025-12-01 05:32:09.701021', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (111, '2025-12-01 21:53:50.726383', '2025-12-01 21:53:50.726383', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (112, '2025-12-01 22:00:27.579694', '2025-12-01 22:00:27.579694', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (113, '2025-12-02 00:15:58.814500', '2025-12-02 00:15:58.814500', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (114, '2025-12-02 00:35:37.775477', '2025-12-02 00:35:37.775477', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (115, '2025-12-02 02:38:39.292731', '2025-12-02 02:38:39.292731', 'CONFIRMADA', 1, 5, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (116, '2025-12-02 04:16:06.517184', '2025-12-02 04:16:06.517184', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (117, '2025-12-02 04:17:46.309135', '2025-12-02 04:17:46.309135', 'CONFIRMADA', 3, 1, 1, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (118, '2025-12-02 04:22:06.143053', '2025-12-02 04:22:06.143053', 'CONFIRMADA', None, 1, 1, None, None, None, 2, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (119, '2025-12-02 04:26:46.650494', '2025-12-02 04:26:46.650494', 'CONFIRMADA', None, 1, 2, None, None, None, 1, 'SUC_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (120, '2025-12-02 04:28:37.140858', '2025-12-02 04:28:37.140858', 'CONFIRMADA', 3, 1, None, None, None, 1, None, 'BOD_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (121, '2025-12-02 04:31:52.899386', '2025-12-02 04:31:52.899386', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (122, '2025-12-02 04:38:44.992214', '2025-12-02 04:38:44.992214', 'CONFIRMADA', None, 1, None, None, None, 1, 2, 'SUC_BOD')
INSERT INTO transferencias VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (123, '2025-12-02 04:40:12.057074', '2025-12-02 04:40:12.057074', 'CONFIRMADA', 1, 1, 2, None, None, None, None, 'BOD_SUC')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (7, 'BOD-01-654645-645645', 'pasillo 1', 1, 1, 1, '654645', '645645')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (8, 'BOD-01-000-000', 'SIN UBICACIÓN', 1, 1, None, '000', '000')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (9, 'BOD-0024-000-000', 'SIN UBICACIÓN', 1, 3, None, '000', '000')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (10, 'BOD-0024-6547654-6546456', 'pasillo 4', 1, 3, 1, '6547654', '6546456')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (11, 'BOD-0024-654765-765757765756', 'pasillo 1', 1, 3, 1, '654765', '765757765756')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (12, 'BOD-0024-765756-765756', 'pasillo 2', 1, 3, 1, '765756', '765756')
INSERT INTO ubicaciones_bodega VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (13, 'BOD-01-001-002', None, 1, 1, 1, '001', '002')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (5, 'SUC-01-000-000', 'SIN UBICACIÓN', 1, 1, None, '000', '000')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (6, '01122335544-000-000', 'SIN UBICACIÓN', 1, 2, None, '000', '000')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (7, '01122335544-654645-645645', 'pasillo 1', 1, 2, 1, '654645', '645645')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (8, '01122335544-24234324234-645645', 'pasillo 4', 1, 2, 1, '24234324234', '645645')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (9, '01122335544-24234324234-432424', 'pasillo 6', 1, 2, 1, '24234324234', '432424')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (10, 'SUC-01-878787-8787878', '4324424', 1, 1, 1, '878787', '8787878')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (11, 'SUC-01-654645-98797', 'estante central', 1, 1, 1, '654645', '98797')
INSERT INTO ubicaciones_sucursal VALUES (?, ?, ?, ?, ?, ?, ?, ?);
    (12, '01122335544-6456456-654654', 'pasillo 434245', 1, 2, 1, '6456456', '654654')
INSERT INTO productos_ubicaciones_bodega VALUES (?, ?, ?);
    (2, 4, 7)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (17, 0, 1, 7, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (18, 14, 5, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (21, 0, 6, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (24, 432, 7, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (27, 330, 8, 8, None, 1)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (30, 30, 9, 8, None, 20)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (33, 1021, 9, 7, None, 700)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (34, 15, 8, 7, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (35, 2, 5, 7, None, 16)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (36, 0, 1, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (46, 653472, 6, 7, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (47, 0, 7, 7, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (52, 0, 1, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (53, 7, 1, None, 8, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (54, 6, 1, None, 7, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (55, 0, 9, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (56, 5, 9, None, 8, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (57, 1, 6, 9, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (58, 4, 1, None, 5, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (59, 37, 9, None, 5, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (60, 23, 5, 9, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (61, 0, 5, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (62, 0, 5, None, 7, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (63, 8, 9, None, 10, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (64, 1, 5, None, 8, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (65, 0, 11, 9, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (66, 30, 11, None, 5, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (67, 199, 12, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (68, 0, 12, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (69, 10, 11, 10, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (70, 0, 11, 12, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (71, 0, 11, 11, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (72, 5, 11, None, 10, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (73, 1, 11, None, 11, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (74, 0, 11, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (75, 3, 11, None, 8, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (76, 3, 11, None, 7, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (77, 0, 11, None, 9, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (78, 0, 11, None, 12, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (79, 0, 13, 9, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (80, 35, 13, None, 5, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (81, 50, 13, 10, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (82, 100, 13, 12, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (83, 43, 13, 11, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (84, 15, 13, None, 10, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (85, 0, 14, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (86, 12, 14, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (87, 8, 14, 7, None, 8)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (88, 5, 14, 13, None, 5)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (89, 4234, 15, 8, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (90, 0, 15, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (91, 11920, 16, 9, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (92, 0, 16, None, 5, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (93, 2290, 16, 10, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (94, 1211, 16, 11, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (95, 3400, 16, 12, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (96, 4, 5, None, 5, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (97, 10, 5, None, 10, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (98, 0, 16, None, 10, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (99, 1, 16, None, 6, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (100, 1100, 16, 7, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (101, 0, 16, 13, None, 0)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (102, 100, 16, None, 8, 100)
INSERT INTO stock VALUES (?, ?, ?, ?, ?, ?);
    (103, 6, 6, None, 6, 0)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (1, 'PROD001-1762054060-1', 'Martillo demo', 1, 0, 0, 12000, 17, None, None, None, 1)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (2, 'PROD002-1762054060-2', 'Taladro demo', 1, 0, 0, 1000, 24, None, None, None, 1)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (3, 'PROD003-1762054060-3', 'Cemento demo', 1, 0, 0, 2000, 14, 1, 1, None, 1)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (4, '001-002-117543', 'bodega par', 1, 0, 0, 543534, 245, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (5, '43243242', 'productotestt21', 1, 0, 0, 432423, 54, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (6, '432432428', 'productotestt21876', 1, 0, 0, 432423, 653479, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (7, '4324324288', 'productotestt21876', 1, 0, 0, 432423, 432, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (8, '65756756', 'pro75675676', 1, 0, 0, 432423, 432, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (9, '4324324288654', 'pro756756766554', 1, 0, 0, 1205, 1101, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (10, '001-002-117', 'producto dos', 1, 0, 0, 120, 36380, 1, 1, 1, 1)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (11, '7804625950534', 'mackbook', 1, 0, 0, 170000, 52, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (12, '6975222022083', 'test agregar', 1, 0, 0, 14000, 199, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (13, '8435893', 'Frederic', 1, 0, 0, 415115, 243, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (14, '7791130460606', 'Espadol', 1, 0, 0, 6990, 25, 1, 1, 1, 1)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (15, '432432', 'aafffwww', 1, 0, 0, 432432, 4234, 1, 1, 1, 2)
INSERT INTO productos VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    (16, '4324234423', 'alonsooo', 1, 0, 0, 432, 20022, 1, 1, 1, 2)

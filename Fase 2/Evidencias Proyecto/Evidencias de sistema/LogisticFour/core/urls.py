from django.urls import path
from django.contrib.auth import views as auth_views
from . import views
from core.views import set_currency

urlpatterns = [
    # App principal
    path("", views.dashboard, name="dashboard"),
    path("productos/", views.product_list, name="products"),
    path("productos/", views.product_list, name="products"),
    path("category/<slug:slug>/", views.category, name="category"),
    path("products/add/", views.product_add, name="product_add"),
    path("productos/<int:pk>/etiqueta/", views.etiqueta_producto, name="etiqueta_producto"),

    # Auth propias
    path("login/", views.login_view, name="login"),
    path("logout/", views.logout_view, name="logout"),

    # Redirección por rol (opcionales pero útiles)
    path('home/', views.dashboard_view, name='accounts_home'),

    # Signup (si lo usas)
    path("signup/", views.signup, name="accounts-signup"),

    # Reset de contraseña (built-in views + tus plantillas)
    path( "password_reset/",auth_views.PasswordResetView.as_view(template_name="accounts/password_reset_form.html"),name="password_reset" ),
    path("password_reset/done/",auth_views.PasswordResetDoneView.as_view(template_name="accounts/password_reset_done.html"  ),name="password_reset_done",),
    path("reset/<uidb64>/<token>/",auth_views.PasswordResetConfirmView.as_view(template_name="accounts/password_reset_confirm.html"),name="password_reset_confirm"),
    path("reset/done/",auth_views.PasswordResetCompleteView.as_view(template_name="accounts/password_reset_complete.html"),name="password_reset_complete",),
    path("password_reset/", auth_views.PasswordResetView.as_view(template_name="accounts/password_reset_form.html",email_template_name="accounts/password_reset_email.html",success_url="/password_reset/done/",extra_email_context={"domain_override": "127.0.0.1:8000"},),name="password_reset",),
    path("users/<int:user_id>/set-role/", views.usuario_set_rol, name="usuario-set-rol"),

    path("users/<int:user_id>/set-role/", views.usuario_set_rol, name="usuario-set-rol"),
    path("productos/agregar/", views.product_add_combined, name="product_add"),




    # Usuarios (solo ADMIN)
    path("users/", views.user_list, name="usuario-list"),
    path("users/create/", views.user_create, name="usuario-create"),
    path("users/<int:user_id>/edit/", views.user_edit, name="usuario-edit"),
    path("users/<int:user_id>/delete/", views.user_delete, name="usuario-delete"),

    #codigo QR producto
    path("productos/", views.ProductsListView.as_view(), name="products"),
    path("productos/agregar/", views.ProductCreateView.as_view(), name="product_add"),
    path("productos/<int:pk>/editar/", views.ProductUpdateView.as_view(), name="producto-update"),
    path("productos/<slug:sku>/editar/", views.ProductUpdateView.as_view(), name="producto-update-sku"),
    path("productos/<int:pk>/eliminar/", views.ProductDeleteView.as_view(), name="producto-delete"),
    path("productos/<int:pk>/", views.ProductDetailView.as_view(), name="producto-detail"),

     # Sucursales CRUD
    path("sucursales/", views.SucursalListView.as_view(), name="sucursal-list"),
    path("sucursales/agregar/", views.SucursalCreateView.as_view(), name="sucursal-create"),
    path("sucursales/<int:pk>/editar/", views.SucursalUpdateView.as_view(), name="sucursal-edit"),
    path("sucursales/<int:pk>/eliminar/", views.SucursalDeleteView.as_view(), name="sucursal-delete"),
     #path("sucursales/<int:pk>/", views.SucursalDetailView.as_view(), name="sucursal-detail"),

     # Bodegas CRUD
    path("bodegas/", views.BodegaListView.as_view(), name="bodega-list"),
    path("bodegas/agregar/", views.BodegaCreateView.as_view(), name="bodega-create"),
    path("bodegas/<int:pk>/editar/", views.BodegaUpdateView.as_view(), name="bodega-edit"),
    path("bodegas/<int:pk>/eliminar/", views.BodegaDeleteView.as_view(), name="bodega-delete"),
    path("bodegas/<int:pk>/", views.BodegaDetailView.as_view(), name="bodega-detail"),


    path('productos/bodega/<int:bodega_id>/', views.productos_por_bodega, name='productos_por_bodega'),

    path("tipos/agregar/", views.TipoUbicacionCreateModal.as_view(), name="tipo-create"),
    path("tipos/<int:pk>/editar/", views.TipoUbicacionUpdateModal.as_view(), name="tipo-edit"),
    path("tipos/<int:pk>/eliminar/", views.TipoUbicacionDeleteModal.as_view(), name="tipo-delete"),

    # Marca (modales)
    path("marcas/agregar/", views.MarcaCreateModal.as_view(), name="marca-create"),
    path("marcas/<int:pk>/editar/", views.MarcaUpdateModal.as_view(), name="marca-edit"),
    path("marcas/<int:pk>/eliminar/", views.MarcaDeleteModal.as_view(), name="marca-delete"),

    # Unidad de Medida (modales)
    path("unidades/agregar/", views.UnidadMedidaCreateModal.as_view(), name="unidad-create"),
    path("unidades/<int:pk>/editar/", views.UnidadMedidaUpdateModal.as_view(), name="unidad-edit"),
    path("unidades/<int:pk>/eliminar/", views.UnidadMedidaDeleteModal.as_view(), name="unidad-delete"),

    # Tasa de Impuesto (modales)
    path("tasas/agregar/", views.TasaImpuestoCreateModal.as_view(), name="tasa-create"),
    path("tasas/<int:pk>/editar/", views.TasaImpuestoUpdateModal.as_view(), name="tasa-edit"),
    path("tasas/<int:pk>/eliminar/", views.TasaImpuestoDeleteModal.as_view(), name="tasa-delete"),

    # Categoría de Producto (modales)
    path("categorias/agregar/", views.CategoriaProductoCreateModal.as_view(), name="categoria-create"),
    path("categorias/<int:pk>/editar/", views.CategoriaProductoUpdateModal.as_view(), name="categoria-edit"),
    path("categorias/<int:pk>/eliminar/", views.CategoriaProductoDeleteModal.as_view(), name="categoria-delete"),

        # Lotes (modales)
    path("lotes/agregar/", views.LoteCreateModal.as_view(), name="lote-create"),
    path("lotes/<int:pk>/editar/", views.LoteUpdateModal.as_view(), name="lote-edit"),
    path("lotes/<int:pk>/eliminar/", views.LoteDeleteModal.as_view(), name="lote-delete"),

    # Series (modales)
    path("series/agregar/", views.SerieCreateModal.as_view(), name="serie-create"),
    path("series/<int:pk>/editar/", views.SerieUpdateModal.as_view(), name="serie-edit"),
    path("series/<int:pk>/eliminar/", views.SerieDeleteModal.as_view(), name="serie-delete"),

    path("auditoria/inventario/", views.auditoria_inventario, name="auditoria_inventario"),

    path("finanzas/", views.finanzas_reporte, name="finanzas_reporte"),
    path("finanzas/export/excel/", views.finanzas_export_excel, name="finanzas_export_excel"),
    path("finanzas/export/pdf/",   views.finanzas_export_pdf,   name="finanzas_export_pdf"),
    
    # Cambio de moneda
    path("set-currency/", set_currency, name="set_currency"),


























    path("movimientos/", views.movimientos_index, name="movimientos_index"),
    path("movimientos/bodega-a-sucursal/", views.bodega_a_sucursal, name="bodega_a_sucursal"),
    path("movimientos/sucursal-a-sucursal/", views.sucursal_a_sucursal,name="mov_sucursal_a_sucursal",),
    path("movimientos/bodega-a-bodega/", views.bodega_a_bodega, name="mov_bodega_a_bodega",),
    path("movimientos/sucursal-a-bodega/", views.sucursal_a_bodega, name="mov_sucursal_a_bodega",),

    path("ajax/sucursales-y-productos/", views.ajax_sucursales_y_productos, name="ajax_sucursales_y_productos"),
    





















    path("productos/stock/", views.stock_por_producto, name="stock-por-producto"),
    path("api/geocode/", views.geocode, name="geocode"),
    path("api/paypal/stock-in/", views.paypal_stock_in, name="paypal-stock-in"),
    path("paypal/ingresos/", views.paypal_ingresos_view, name="paypal-ingresos"),   
]


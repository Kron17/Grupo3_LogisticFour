from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth.models import User
from .models import Sucursal, Bodega, UsuarioPerfil


class BodegaPermissionTests(TestCase):
    def setUp(self):
        # Crear sucursales
        self.s1 = Sucursal.objects.create(codigo='S1', nombre='Sucursal 1')
        self.s2 = Sucursal.objects.create(codigo='S2', nombre='Sucursal 2')

        # Crear admin
        self.admin = User.objects.create_superuser('admin', 'a@a.com', 'pass')
        self.admin.perfil.rol = UsuarioPerfil.Rol.ADMIN
        self.admin.perfil.save()

        # Crear bodeguero asignado a s1
        self.bod = User.objects.create_user('bodeg', password='pass')
        self.bod.perfil.rol = UsuarioPerfil.Rol.BODEGUERO
        self.bod.perfil.sucursal = self.s1
        self.bod.perfil.save()

        # Cliente
        self.client = Client()

    def test_admin_can_create_bodega(self):
        self.client.login(username='admin', password='pass')
        resp = self.client.post(reverse('bodega-create'), {
            'sucursal': self.s2.id,
            'codigo': 'B1',
            'nombre': 'Bodega 1',
            'descripcion': '',
            'activo': True,
        })
        self.assertEqual(resp.status_code, 302)
        self.assertTrue(Bodega.objects.filter(codigo='B1').exists())

    def test_bodeguero_can_create_in_own_sucursal(self):
        self.client.login(username='bodeg', password='pass')
        resp = self.client.post(reverse('bodega-create'), {
            'sucursal': self.s1.id,
            'codigo': 'B2',
            'nombre': 'Bodega 2',
            'descripcion': '',
            'activo': True,
        })
        # debe crearse y típicamente redirigir
        self.assertTrue(Bodega.objects.filter(codigo='B2', sucursal=self.s1).exists())
        # puede devolver 302 (redirect) o 200 (render form) dependiendo del flujo
        self.assertIn(resp.status_code, (200, 302))

    def test_bodeguero_cannot_create_in_other_sucursal(self):
        self.client.login(username='bodeg', password='pass')
        resp = self.client.post(reverse('bodega-create'), {
            'sucursal': self.s2.id,
            'codigo': 'B3',
            'nombre': 'Bodega 3',
            'descripcion': '',
            'activo': True,
        }, follow=True)
        # No debe crear
        self.assertFalse(Bodega.objects.filter(codigo='B3').exists())
        # y debe devolver 200 (form re-rendered) o redirección a lista con mensaje
        self.assertIn(resp.status_code, (200, 302))
from django.test import TestCase

# Create your tests here.


class SucursalPermissionTests(TestCase):
    def setUp(self):
        self.client = Client()
        # Crear sucursal base
        self.s1 = Sucursal.objects.create(codigo='S1', nombre='Sucursal 1')

        # Admin
        self.admin = User.objects.create_superuser('admin2', 'a2@a.com', 'pass')
        self.admin.perfil.rol = UsuarioPerfil.Rol.ADMIN
        self.admin.perfil.save()

        # Bodeguero
        self.bod = User.objects.create_user('bodeg2', password='pass')
        self.bod.perfil.rol = UsuarioPerfil.Rol.BODEGUERO
        self.bod.perfil.sucursal = self.s1
        self.bod.perfil.save()

    def test_admin_can_create_sucursal(self):
        self.client.login(username='admin2', password='pass')
        resp = self.client.post(reverse('sucursal-create'), {
            'codigo': 'SNEW',
            'nombre': 'Sucursal Nueva',
            'direccion': '',
            'ciudad': 'CiudadX',
            'region': '',
            'pais': '',
            'activo': True,
        })
        self.assertEqual(resp.status_code, 302)
        self.assertTrue(Sucursal.objects.filter(codigo='SNEW').exists())

    def test_bodeguero_cannot_create_sucursal(self):
        self.client.login(username='bodeg2', password='pass')
        resp = self.client.post(reverse('sucursal-create'), {
            'codigo': 'SNO',
            'nombre': 'No deberia crear',
            'direccion': '',
            'ciudad': '',
            'region': '',
            'pais': '',
            'activo': True,
        }, follow=True)
        self.assertFalse(Sucursal.objects.filter(codigo='SNO').exists())
        # Debe redirigir o renderizar con mensaje
        self.assertIn(resp.status_code, (200, 302))

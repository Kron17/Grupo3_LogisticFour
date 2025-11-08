# core/utils/indicadores.py
import requests
from django.core.cache import cache

API_BASE = "https://mindicador.cl/api"
CACHE_KEY = "indicadores_mindicador"
CACHE_TTL = 60 * 60 * 6  # 6 horas

def get_mindicadores():
    """
    Función para obtener los indicadores (EUR y UTM) desde mindicador.cl y almacenarlos en cache.
    """
    data = cache.get(CACHE_KEY)
    if data:
        return data  # Si ya está en cache, devolvemos el valor
    
    try:
        # Realizamos la petición a la API de mindicador.cl
        resp = requests.get(API_BASE, timeout=5)
        resp.raise_for_status()
        data = resp.json()  # Contiene 'euro', 'utm', etc.
        
        # Guardamos los datos en cache durante 6 horas
        cache.set(CACHE_KEY, data, CACHE_TTL)
        return data
    except Exception as e:
        # Si falla la API, devolvemos los valores en cache si existen
        return data or {"euro": {"valor": None}, "utm": {"valor": None}}

def get_eur_clp():
    """
    Obtiene el valor actual del EUR en CLP desde mindicador.cl
    """
    data = get_mindicadores()
    return (data.get("euro") or {}).get("valor")

def get_utm_clp():
    """
    Obtiene el valor actual de la UTM en CLP desde mindicador.cl
    """
    data = get_mindicadores()
    return (data.get("utm") or {}).get("valor")

def get_usd_clp():
    """
    Obtiene el valor actual del USD en CLP desde mindicador.cl (promedio hoy).
    """
    data = get_mindicadores()
    # En mindicador suele venir como 'dolar' o 'dólar'. Cubrimos ambas.
    dolar = data.get("dolar") or data.get("dólar")
    return (dolar or {}).get("valor")

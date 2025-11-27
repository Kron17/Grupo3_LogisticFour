from django import template
from decimal import Decimal, InvalidOperation
from core.indicadores import get_usd_clp

register = template.Library()

SYMBOL = {"CLP": "$", "USD": "US$"}

def _to_decimal(val):
    if val is None:
        return None
    try:
        return Decimal(str(val))
    except (InvalidOperation, ValueError, TypeError):
        return None

def format_money(amount, currency="CLP"):
    amt = _to_decimal(amount)
    if amt is None:
        return ""
    if currency == "CLP":
        # CLP sin decimales, separador de miles con punto
        s = f"{int(amt):,}"
        s = s.replace(",", ".")
        return f"{SYMBOL['CLP']}{s}"
    # USD con 2 decimales, usa coma para miles y punto para decimales
    s = f"{amt:,.2f}"
    s = s.replace(",", "X").replace(".", ",").replace("X", ".")
    return f"{SYMBOL['USD']}{s}"

@register.filter
def money_clp(amount):
    """Formatea CLP (sin decimales)."""
    return format_money(amount, "CLP")

@register.simple_tag
def price_usd_from_clp(amount):
    """
    Convierte un monto en CLP a USD con mindicador.cl y lo formatea.
    Si no hay tasa, devuelve vacío.
    """
    amt = _to_decimal(amount)
    if amt is None:
        return ""
    usd_clp = _to_decimal(get_usd_clp())
    if not usd_clp or usd_clp == 0:
        return ""  # sin tasa disponible
    usd = amt / usd_clp
    return format_money(usd, "USD")

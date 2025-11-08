from django.conf import settings

def currency_context(request):
    current = request.session.get("currency", "CLP")
    return {
        "current_currency": current,
        "currency_supported": ["CLP", "USD"],
    }

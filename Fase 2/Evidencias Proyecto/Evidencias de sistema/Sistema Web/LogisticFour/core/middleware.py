# core/middleware.py
import time
import logging
logger = logging.getLogger("perf")

class TimingMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    def __call__(self, request):
        t0 = time.perf_counter()
        response = self.get_response(request)
        ms = (time.perf_counter() - t0) * 1000
        # Header útil para el navegador / DevTools
        response["Server-Timing"] = f"app;dur={ms:.1f}"
        # Log solo si es “lento”
        if ms > 300:
            logger.warning("SLOW %s %s %.1fms", request.method, request.get_full_path(), ms)
        return response

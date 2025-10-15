from django.http import JsonResponse


def healthz(request):
    """Health check endpoint inside the project package.

    Returns HTTP 200 with basic JSON to indicate app is up.
    """
    return JsonResponse({"status": "ok"})

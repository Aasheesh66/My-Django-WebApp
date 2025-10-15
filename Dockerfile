## Multi-stage Dockerfile for Django-WebApp
## - Builder stage builds wheels (optional) and prepares dependencies
## - Final stage uses a slim Python image, creates a non-root user and runs Gunicorn

# ---------- Builder ----------
FROM python:3.11-slim-bullseye AS builder
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install build dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy project requirement file if present (assumes django_web_app/requirements.txt)
COPY django_web_app/requirements.txt ./requirements.txt

# Install wheels into an isolated directory so we can copy into final image
RUN python -m pip install --upgrade pip setuptools wheel \
    && if [ -s requirements.txt ]; then pip wheel --wheel-dir=/wheels -r requirements.txt; fi


# ---------- Final image ----------
FROM python:3.11-slim-bullseye
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=off

# Create a non-root user
RUN addgroup --system web && adduser --system --ingroup web web

# Install runtime dependencies required for some Python packages (e.g. Pillow, psycopg2)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    libpq5 \
    gcc \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy wheels from builder (if any) and install
COPY --from=builder /wheels /wheels
COPY django_web_app/requirements.txt ./requirements.txt
RUN python -m pip install --upgrade pip setuptools wheel \
    && if [ -d /wheels ] && [ "$(ls -A /wheels)" ]; then pip install --no-index --find-links=/wheels -r requirements.txt; else if [ -s requirements.txt ]; then pip install -r requirements.txt; fi; fi \
    && pip install --no-cache-dir gunicorn || true

# Copy application code (copy inner package so imports like "django_web_app.settings" resolve)
COPY django_web_app/django_web_app/ ./django_web_app/
COPY django_web_app/manage.py ./manage.py
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Ensure media and static dirs exist (if used)
RUN mkdir -p /app/django_web_app/media /app/django_web_app/static

# Set permissions to the non-root user and make entrypoint executable
RUN chown -R web:web /app /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh
USER web

ENV PATH="/home/web/.local/bin:${PATH}"

# Expose port used by Gunicorn
EXPOSE 8000

# Entrypoint handles optional migrations and collectstatic; default CMD starts Gunicorn
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["gunicorn", "django_web_app.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]

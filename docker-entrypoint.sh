#!/bin/sh
set -e

# Default environment variables (can be overridden at runtime)
: ${DJANGO_ENV:=production}
: ${RUN_MIGRATIONS:=true}
: ${RUN_COLLECTSTATIC:=false}

echo "starting docker-entrypoint.sh (DJANGO_ENV=${DJANGO_ENV})"

# Activate any virtualenv if present (not necessary in container)

# Run migrations if enabled
if [ "${RUN_MIGRATIONS}" = "true" ]; then
  echo "Running migrations..."
  python manage.py migrate --noinput || echo "migrate failed"
fi

# Run collectstatic if enabled
if [ "${RUN_COLLECTSTATIC}" = "true" ]; then
  echo "Collecting static files..."
  python manage.py collectstatic --noinput || echo "collectstatic failed"
fi

echo "Executing: $@"
exec "$@"

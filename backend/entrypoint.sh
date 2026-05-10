#!/bin/sh
set -e

# Wait for database to be ready
echo "Waiting for database..."
python << END
import sys
import psycopg2
import os
import time
from urllib.parse import urlparse

# Check if DATABASE_URL is set, otherwise use separate env vars
db_url = os.environ.get('DATABASE_URL')
if db_url:
    print("Using DATABASE_URL for connection check")
    # Simple check: try to connect using the URL
    params = {}
else:
    dbname = os.environ.get('POSTGRES_DB')
    user = os.environ.get('POSTGRES_USER')
    password = os.environ.get('POSTGRES_PASSWORD')
    host = os.environ.get('POSTGRES_HOST')
    port = os.environ.get('POSTGRES_PORT', 5432)
    params = {
        'dbname': dbname,
        'user': user,
        'password': password,
        'host': host,
        'port': port
    }

max_retries = 30
retries = 0

while retries < max_retries:
    try:
        if db_url:
            conn = psycopg2.connect(db_url)
        else:
            conn = psycopg2.connect(**params)
        conn.close()
        break
    except Exception as e:
        retries += 1
        print(f"Database not ready... ({e}) retrying in 1s ({retries}/{max_retries})")
        time.sleep(1)
else:
    print("Could not connect to database. Exiting.")
    sys.exit(1)
END
echo "Database ready!"

# Run migrations if enabled (defaults to True for self-hosted)
if [ "$RUN_MIGRATIONS" != "False" ]; then
    echo "Running migrations..."
    python src/manage.py migrate --noinput
else
    echo "Skipping migrations (RUN_MIGRATIONS=False)"
fi

# Collect static files (needed for production)
if [ "$DJANGO_DEBUG" != "True" ]; then
    echo "Collecting static files..."
    python src/manage.py collectstatic --noinput
fi

# Execute the CMD
echo "Executing: $@"
exec "$@"

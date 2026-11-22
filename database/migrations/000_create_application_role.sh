#!/bin/sh
set -eu

if [ -z "${POSTGRES_APP_PASSWORD:-}" ]; then
    echo "POSTGRES_APP_PASSWORD must be defined." >&2
    exit 1
fi

psql \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    --set=ON_ERROR_STOP=1 \
    --set=app_password="$POSTGRES_APP_PASSWORD" <<'SQL'
SELECT format(
    'CREATE ROLE security_lab_app LOGIN PASSWORD %L',
    :'app_password'
)
WHERE NOT EXISTS (
    SELECT 1 FROM pg_roles WHERE rolname = 'security_lab_app'
) \gexec
SQL

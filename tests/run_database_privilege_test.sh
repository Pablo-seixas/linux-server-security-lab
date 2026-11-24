#!/bin/sh
set -eu

: "${COMPOSE_PROJECT_NAME:=linux-server-security-lab}"
: "${ENV_FILE:=.env}"

test -f tests/database_privileges.sql

docker compose --project-name "$COMPOSE_PROJECT_NAME" --env-file "$ENV_FILE" \
    exec -T postgres sh -ceu '
        pgpass_file="$(mktemp)"
        cleanup() {
            rm -f "$pgpass_file"
        }
        trap cleanup EXIT INT TERM
        chmod 0600 "$pgpass_file"
        printf "%s:%s:%s:%s:%s\n" \
            127.0.0.1 5432 "$POSTGRES_DB" security_lab_app \
            "$POSTGRES_APP_PASSWORD" >"$pgpass_file"
        PGPASSFILE="$pgpass_file" psql \
            --host=127.0.0.1 \
            --port=5432 \
            --username=security_lab_app \
            --dbname="$POSTGRES_DB" \
            --no-password \
            --file=-
    ' <tests/database_privileges.sql

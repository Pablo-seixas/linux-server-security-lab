#!/bin/sh
set -eu

: "${PGHOST:?PGHOST is required}"
: "${PGPORT:=5432}"
: "${PGUSER:?PGUSER is required}"
: "${BACKUP_FILE:?BACKUP_FILE is required}"
: "${RESTORE_DATABASE:?RESTORE_DATABASE is required}"

case "$RESTORE_DATABASE" in
    [a-z]*_restore_test) ;;
    *)
        echo "RESTORE_DATABASE must end in _restore_test." >&2
        exit 1
        ;;
esac

if printf '%s' "$RESTORE_DATABASE" | grep -Eqv '^[a-z][a-z0-9_]*_restore_test$'; then
    echo "RESTORE_DATABASE contains unsupported characters." >&2
    exit 1
fi

test -f "$BACKUP_FILE"
test -f "$BACKUP_FILE.sha256"
(
    cd "$(dirname "$BACKUP_FILE")"
    sha256sum -c "$(basename "$BACKUP_FILE").sha256"
)
pg_restore --list "$BACKUP_FILE" >/dev/null

if psql --dbname=postgres --tuples-only --no-align \
    --command="SELECT 1 FROM pg_database WHERE datname = '$RESTORE_DATABASE'" \
    | grep -qx 1; then
    echo "Refusing to overwrite existing database: $RESTORE_DATABASE" >&2
    exit 1
fi

createdb "$RESTORE_DATABASE"
cleanup() {
    dropdb --if-exists "$RESTORE_DATABASE"
}
trap cleanup EXIT INT TERM

pg_restore --exit-on-error --no-owner --no-privileges \
    --dbname="$RESTORE_DATABASE" "$BACKUP_FILE"

psql --dbname="$RESTORE_DATABASE" --set=ON_ERROR_STOP=1 \
    --command='SELECT count(*) AS restored_tables FROM information_schema.tables WHERE table_schema = '\''app'\'';'

echo "Restore drill passed; disposable database will now be removed."

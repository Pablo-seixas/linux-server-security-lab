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

database_created=false

database_exists() {
    psql --dbname=postgres --tuples-only --no-align --set=ON_ERROR_STOP=1 \
        --command="SELECT count(*) FROM pg_database WHERE datname = '$RESTORE_DATABASE'"
}

cleanup_database() {
    if ! dropdb --if-exists "$RESTORE_DATABASE"; then
        echo "Failed to remove disposable database: $RESTORE_DATABASE" >&2
        return 1
    fi

    if test "$(database_exists)" != 0; then
        echo "Disposable database still exists after cleanup: $RESTORE_DATABASE" >&2
        return 1
    fi

    database_created=false
}

cleanup_on_exit() {
    exit_status=$?
    trap - EXIT
    if test "$database_created" = true && ! cleanup_database; then
        exit_status=1
    fi
    exit "$exit_status"
}

trap cleanup_on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

createdb "$RESTORE_DATABASE"
database_created=true

pg_restore --exit-on-error --no-owner --no-privileges \
    --dbname="$RESTORE_DATABASE" "$BACKUP_FILE"

for expected_table in maintenance_events football_matches; do
    table_exists="$(
        psql --dbname="$RESTORE_DATABASE" --tuples-only --no-align \
            --set=ON_ERROR_STOP=1 \
            --command="SELECT to_regclass('app.$expected_table') IS NOT NULL"
    )"
    if test "$table_exists" != t; then
        echo "Expected restored table is missing: app.$expected_table" >&2
        exit 1
    fi
done

fixture_matches="$(
    psql --dbname="$RESTORE_DATABASE" --tuples-only --no-align \
        --set=ON_ERROR_STOP=1 \
        --command="
            SELECT count(*)
            FROM app.football_matches
            WHERE played_at = '2026-10-24T21:00:00Z'::timestamptz
              AND home_team = 'Salvador Tech AC'
              AND away_team = 'Bahia Solar FC'
              AND home_score = 1
              AND away_score = 4
              AND venue = 'Open Source Park'
        "
)"
if test "$fixture_matches" != 1; then
    echo "Representative football fixture was not restored as expected." >&2
    exit 1
fi

fixture_count="$(
    psql --dbname="$RESTORE_DATABASE" --tuples-only --no-align \
        --set=ON_ERROR_STOP=1 \
        --command='SELECT count(*) FROM app.football_matches'
)"
if test "$fixture_count" != 6; then
    echo "Expected 6 football fixtures, restored $fixture_count." >&2
    exit 1
fi

cleanup_database
trap - EXIT INT TERM
echo "Restore drill passed; expected tables and fixture data were verified, and the disposable database was removed."

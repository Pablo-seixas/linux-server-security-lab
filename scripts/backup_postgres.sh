#!/bin/sh
set -eu

: "${PGHOST:?PGHOST is required}"
: "${PGPORT:=5432}"
: "${PGDATABASE:?PGDATABASE is required}"
: "${PGUSER:?PGUSER is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"

umask 077
mkdir -p "$BACKUP_DIR"

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_path="$BACKUP_DIR/${PGDATABASE}_${timestamp}.dump"
checksum_path="$backup_path.sha256"

pg_dump \
    --format=custom \
    --compress=9 \
    --no-owner \
    --no-privileges \
    --file="$backup_path"

pg_restore --list "$backup_path" >/dev/null
(
    cd "$BACKUP_DIR"
    sha256sum "$(basename "$backup_path")" >"$(basename "$checksum_path")"
)

printf 'Backup validated: %s\nChecksum: %s\n' "$backup_path" "$checksum_path"

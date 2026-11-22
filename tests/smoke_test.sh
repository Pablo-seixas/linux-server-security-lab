#!/bin/sh
set -eu

base_url="${BASE_URL:-http://127.0.0.1:8088}"
headers="$(mktemp)"
body="$(mktemp)"
trap 'rm -f "$headers" "$body"' EXIT INT TERM

status="$(curl --silent --show-error --output "$body" \
    --dump-header "$headers" --write-out '%{http_code}' "$base_url/health")"

test "$status" = "200"
grep -qi '^X-Content-Type-Options: nosniff' "$headers"
grep -q '"status":"healthy"' "$body"
grep -q '"database":"reachable"' "$body"

not_found_status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
    "$base_url/not-present")"
test "$not_found_status" = "404"

echo "Smoke and security-header tests passed."

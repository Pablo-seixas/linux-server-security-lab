#!/bin/sh
set -eu

output_dir="${1:-./reports}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="$output_dir/host-audit-$timestamp.txt"

umask 077
mkdir -p "$output_dir"

{
    echo "Linux Server Defensive Audit"
    echo "Generated (UTC): $timestamp"
    echo
    echo "== Kernel and operating system =="
    uname -a
    test ! -r /etc/os-release || sed -n '1,12p' /etc/os-release
    echo
    echo "== Listening TCP/UDP sockets =="
    ss -lntup 2>/dev/null || ss -lntu
    echo
    echo "== Failed systemd units =="
    systemctl --failed --no-pager 2>/dev/null || echo "systemd unavailable"
    echo
    echo "== World-writable regular files under service paths =="
    find /etc /opt /srv /var/www -xdev -type f -perm -0002 -print 2>/dev/null || true
    echo
    echo "== Files without valid owner/group under service paths =="
    find /opt /srv /var/www -xdev \( -nouser -o -nogroup \) -print 2>/dev/null || true
    echo
    echo "== PostgreSQL client version =="
    psql --version 2>/dev/null || echo "psql unavailable"
    echo
    echo "== PHP version =="
    php -v 2>/dev/null | head -n 2 || echo "php unavailable"
} >"$report"

sha256sum "$report" >"$report.sha256"
printf 'Audit report: %s\n' "$report"

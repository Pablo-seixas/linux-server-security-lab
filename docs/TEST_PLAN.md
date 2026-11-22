# Quality and Security Test Plan

## Test layers

1. **Static validation** — PHP syntax, Compose rendering, shell syntax, SQL
   migration review, and configuration linting.
2. **Service validation** — container health, HTTP status, security headers,
   database connectivity, and failure behavior.
3. **Database security** — owner/application role separation, PUBLIC privilege
   revocation, positive grants, and negative authorization tests through
   `psql`.
4. **Operations** — backup generation, SHA-256 integrity, archive listing,
   disposable restore, cleanup, and recovery evidence.
5. **Linux security** — ports, permissions, service state, unexpected files,
   log rotation, and configuration drift.
6. **Isolated BlackArch assessment** — service discovery and defensive
   configuration verification against only the authorized lab address.

## Release gates

- No secrets or database dumps tracked by Git.
- All static checks pass.
- PHP health endpoint returns HTTP 200 only when PostgreSQL is reachable.
- PostgreSQL is not published to the host network.
- Application role cannot modify or delete records outside its grants.
- Backup checksum and restore drill pass.
- Logrotate dry-run reports no errors.
- Defensive scan produces no unexpected exposed ports.
- Findings are classified, remediated, and retested.

## Evidence quality

Every result must include its command, timestamp, tool version, expected result,
actual result, and pass/fail decision. Screenshots supplement text logs; they do
not replace reproducible commands.

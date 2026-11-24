# Quality and Security Test Plan

## Test layers

1. **Static validation** — PHP syntax, Compose rendering, shell syntax, SQL
   migration review, and configuration linting.
2. **Service validation** — container health, HTTP status, security headers,
   database connectivity, and failure behavior.
3. **Database security** — owner/application role separation, PUBLIC privilege
   revocation, application identity, individual positive grants, and individual
   negative authorization assertions through `psql`.
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
- Application role test exits non-zero for any identity or privilege mismatch.
- Football data remains read-only to the application role.
- Backup checksum, expected-table checks, representative fixture query, and
  confirmed restore-database cleanup pass.
- Logrotate dry-run reports no errors.
- Defensive scan produces no unexpected exposed ports.
- Findings are classified, remediated, and retested.

## Evidence quality

Every result must include its command, timestamp, tool version, expected result,
actual result, and pass/fail decision. Screenshots supplement text logs; they do
not replace reproducible commands.

Results must also identify the execution mode:

- **Local:** default `127.0.0.1` bind or disposable internal Compose service.
- **Host-only/server-side:** service policy observed on an isolated adapter.
- **Host-only/external:** behavior observed from the assessment VM.

Server-side policy does not prove external reachability. Historical results and
results from the current run must be reported separately.

## Reproducible database command

```bash
COMPOSE_PROJECT_NAME=linux-server-security-lab \
ENV_FILE=.env \
sh tests/run_database_privilege_test.sh
```

The runner uses a temporary `PGPASSFILE` inside the database container and must
not print the password. See `docs/VALIDATION_EVIDENCE.md` for the current
positive and negative results.

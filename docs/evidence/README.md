# Evidence checklist

Capture only sanitized evidence. Each image should show the command, relevant
result, date, and project name without exposing passwords or private data.

1. Project tree and architecture documentation.
2. Container/service health status.
3. PHP `/health` response with HTTP status and security headers.
4. `psql` inspection of roles, schema ownership, and grants.
5. Successful migration and least-privilege negative test.
6. Backup file plus matching SHA-256 checksum.
7. Restore drill into a disposable database.
8. `logrotate --debug` and disposable forced-rotation result.
9. Listening ports and expected loopback-only exposure.
10. BlackArch defensive scan restricted to the isolated lab target.
11. Final report summary: findings, severity, remediation, and retest status.

Do not commit raw database dumps, `.env`, credentials, private addresses, user
data, or unredacted logs.

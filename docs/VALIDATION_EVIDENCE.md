# Validation Evidence

This file separates results observed in the current validation run from older
documented observations. It contains reproducible commands and summarized
outcomes, not credentials, dumps, private keys, packet captures, or raw logs.

## Execution modes

### Local mode

- Bind address: `127.0.0.1` (the default in `.env.example`).
- Intended use: build, application checks, database tests, backup, and restore
  from the Windows/WSL host.
- External VMs cannot use a loopback-bound service.

### VirtualBox host-only mode

- Bind address used in the earlier server-side validation: `192.168.56.1`.
- Intended use: explicitly authorized assessment from an isolated VM.
- This mode is opt-in and must not be bound to Wi-Fi or a public interface.
- Server-side configuration and external reachability are separate results.

## Current run — November 23, 2026

### Compose configuration

Command:

```bash
docker compose --project-name linux-server-security-lab-validation \
  --env-file .env.validation config --quiet
```

Observed result: exit code `0`. The disposable PostgreSQL service started on an
internal Compose network with no published host port.

### Database privilege policy

Command:

```bash
COMPOSE_PROJECT_NAME=linux-server-security-lab-validation \
ENV_FILE=.env.validation \
sh tests/run_database_privilege_test.sh
```

Credential handling: the runner creates a mode `0600` temporary `PGPASSFILE`
inside the PostgreSQL container from its existing environment, runs `psql` as
`security_lab_app`, and removes the file on exit. The password is not placed in
the command line or test output.

Observed result: exit code `0`.

Verified individually:

- Identity is `security_lab_app`.
- Database `CONNECT` granted; `CREATE` and `TEMP` denied.
- Schema `app` `USAGE` granted; `CREATE` denied.
- `app.maintenance_events`: `SELECT` and `INSERT` granted.
- `app.maintenance_events`: `UPDATE`, `DELETE`, `TRUNCATE`, `REFERENCES`, and
  `TRIGGER` denied.
- Maintenance identity sequence: `USAGE` and `SELECT` granted; `UPDATE` denied.
- A representative maintenance insert succeeded inside a rolled-back
  transaction.
- `app.football_matches`: `SELECT` granted.
- `app.football_matches`: `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`,
  `REFERENCES`, and `TRIGGER` denied.
- Six synthetic football fixtures were readable.

Negative proof: a temporary `UPDATE` grant on `app.maintenance_events` caused
the test to stop with exit code `3`. The grant was revoked immediately and the
positive test passed again.

### Backup and restore

Commands executed inside the disposable PostgreSQL container:

```bash
sh /tmp/backup_postgres.sh
sh /tmp/restore_drill.sh
```

Observed positive result: exit code `0`.

- SHA-256 verification passed.
- The custom archive was readable by `pg_restore --list`.
- `app.maintenance_events` and `app.football_matches` existed after restore.
- The representative `Salvador Tech AC` versus `Bahia Solar FC` fixture was
  present with the expected timestamp, score, and venue.
- All six synthetic fixtures were present.
- The disposable restore database was removed; follow-up database count was
  `0`.

Negative proofs:

- Corrupted dump after checksum generation: exit code `1`; no database left.
- Existing target database: exit code `1`; existing database preserved.
- Valid backup missing the representative fixture: exit code `1`; disposable
  database removed.

## Earlier server-side observations — November 21–22, 2026

These observations were recorded before the current change and were not
re-executed as part of the disposable PostgreSQL-only run.

### Local application mode

- `/health` returned HTTP `200` with PostgreSQL reachable.
- `/api/matches` returned HTTP `200` and six synthetic records.
- Unknown routes returned HTTP `404`.
- Unsupported API method returned HTTP `403`.
- PHP exposed no version header after `expose_php = Off`.

### Host-only server configuration

- Docker published SSH and HTTP on the selected host-only address.
- `nft list ruleset` showed input policy `drop` and explicit internal allows for
  SSH and HTTP.
- Effective `sshd -T` output showed root login disabled, password
  authentication disabled, `AllowUsers labadmin`, and public-key-only
  authentication.
- A host-side SSH connection using the dedicated key succeeded as `labadmin`.

These are server-side observations. They do not prove that the BlackArch VM
could reach the published ports.

## External BlackArch observation — limited reachability

Observed from the BlackArch environment:

- The target answered ARP.
- The TCP 2222 attempt captured three outbound SYN packets; no response packet
  was observed.
- The HTTP request to TCP 8088 timed out without a response.
- No SSH handshake completed.
- `ssh-audit` was not run.
- Katana was not run.
- TCP 5432 was not probed.

Decision: **limited / inconclusive**. Layer-2 reachability was observed, but
application-port reachability was not. The cause is undetermined; no claim is
made that the firewall, VirtualBox path, Windows filtering, or container
service was the cause.

## PostgreSQL scope distinction

- Compose PostgreSQL: internal network only; no host port is declared in
  `compose.yaml`.
- Windows PostgreSQL: a separate host service was previously observed listening
  on wildcard TCP 5432. It is not part of this Compose project.
- A Windows Firewall rule was reported as created, but its effectiveness from
  the BlackArch VM has not been confirmed because TCP 5432 was not probed.

## Remediated defects

### PHP runtime dependency

- Failure: removing build dependencies also removed runtime `libpq5`; health
  returned HTTP `503`.
- Fix: mark `libpq5` as manually installed before build-dependency cleanup.
- Retest: `pdo_pgsql` loaded and `/health` returned HTTP `200`.

### BusyBox checksum compatibility

- Failure: BusyBox rejected `sha256sum --check`.
- Fix: use portable `sha256sum -c`.
- Retest: checksum, restore verification, and cleanup passed.

# Linux Server Security & Maintenance Lab

![Linux](https://img.shields.io/badge/Linux-server%20operations-FCC624?logo=linux&logoColor=black)
![PHP](https://img.shields.io/badge/PHP-8.2-777BB4?logo=php&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-isolated%20lab-2496ED?logo=docker&logoColor=white)
![Security](https://img.shields.io/badge/security-defensive%20validation-2E8B57)

An isolated, reproducible laboratory for demonstrating Linux server
administration, defensive security, PHP 8.2 operations, PostgreSQL lifecycle
management, backup validation, logging, and evidence-driven quality testing.

The demonstration API contains only fictional football records authored for
this repository. It does not copy league tables, match feeds, club branding,
player information, government data, or third-party datasets.

## Purpose

This project models the routine work required to operate a small production-like
Linux service safely. It focuses on preventive controls and operational proof:

- PHP 8.2 application health and database connectivity checks.
- PostgreSQL access through `psql`, using separate owner and application roles.
- Least-privilege database permissions and explicit schema ownership.
- Logical backups, integrity hashes, restore drills, and recovery evidence.
- Linux file-permission, process, port, and configuration audits.
- Structured application logs and tested `logrotate` policy.
- Repeatable smoke, security, database, and recovery tests.
- Defensive assessment from an isolated BlackArch workstation.
- An `nftables` ingress policy allowing only established traffic, ICMP needed
  for lab diagnosis, and the HTTP test port.

The BlackArch system is used only against hosts explicitly created for this
lab. No public or third-party system is in scope.

## Architecture

```text
Authorized audit workstation
          |
          | VirtualBox host-only network
          v
Hardened Linux gateway
  nftables -> SSH / nginx -> PHP 8.2 API -> PostgreSQL
                 |
                 +-> structured logs -> logrotate
                 +-> backup/restore scripts -> checksummed artifacts
```

## Demonstrated responsibilities

- Service deployment and operational readiness.
- Secure database role design and migration execution.
- Backup creation, verification, restoration, and recovery reporting.
- Linux hardening verification and configuration drift detection.
- Incident-oriented logging and evidence preservation.
- Test planning, execution records, risk classification, and remediation notes.

## Validated controls

| Area | Mode | Result and evidence |
| --- | --- | --- |
| Compose | Disposable/local | [Passed — rendered configuration](docs/VALIDATION_EVIDENCE.md#compose-configuration) |
| Network | Local | [Passed — default loopback bind](docs/VALIDATION_EVIDENCE.md#local-mode) |
| Firewall | Host-only, server side | [Passed — input policy `drop`](docs/VALIDATION_EVIDENCE.md#host-only-server-configuration) |
| SSH hardening | Host-only, server side | [Passed — effective daemon policy](docs/VALIDATION_EVIDENCE.md#host-only-server-configuration) |
| BlackArch reachability | Host-only, external | [Limited — ARP only; ports inconclusive](docs/VALIDATION_EVIDENCE.md#external-blackarch-observation--limited-reachability) |
| Web | Local | [Passed — status, headers, methods, routing](docs/VALIDATION_EVIDENCE.md#local-application-mode) |
| Runtime | Local/host-only | [Passed — read-only and no-new-privileges](reports/FINAL_VALIDATION_REPORT.md#validated-scope) |
| Database | Disposable/local | [Passed — application-role assertions](docs/VALIDATION_EVIDENCE.md#database-privilege-policy) |
| Recovery | Disposable/local | [Passed — integrity, content, cleanup](docs/VALIDATION_EVIDENCE.md#backup-and-restore) |
| Data | Disposable/local | [Passed — six synthetic fixtures](docs/VALIDATION_EVIDENCE.md#database-privilege-policy) |

## Quick start

Requirements: Docker Desktop, Docker Compose, PowerShell, OpenSSH, and an
isolated host-only adapter. Never expose this lab directly to the internet.

```powershell
pwsh ./scripts/bootstrap_env.ps1
docker compose --env-file .env up -d --build
docker compose --env-file .env ps
```

The bootstrap script creates random local credentials and an SSH key under
ignored paths. Neither `.env` nor `.secrets/` belongs in Git.

### Local mode (default)

`.env.example` binds HTTP and SSH to `127.0.0.1`. Use this mode for routine
development, database verification, backup, and restore. It is not reachable
from another VM.

```dotenv
APP_BIND_ADDRESS=127.0.0.1
```

### VirtualBox host-only mode (opt-in)

Change the bind address only to the address of an isolated VirtualBox host-only
adapter. Never use a Wi-Fi, public, or internet-facing address.

```dotenv
APP_BIND_ADDRESS=<HOST_ONLY_ADDRESS>
```

Host-only server configuration and external VM reachability are separate
validation results. The current external BlackArch result is limited and
inconclusive; see the linked evidence above.

## Database privilege test

Run from a POSIX shell with Docker access:

```bash
COMPOSE_PROJECT_NAME=linux-server-security-lab \
ENV_FILE=.env \
sh tests/run_database_privilege_test.sh
```

The runner uses a temporary mode `0600` `PGPASSFILE` inside the PostgreSQL
container. It does not put the application password in the command line or
published output. The SQL test verifies the application identity and fails
non-zero on any grant or denial mismatch.

For a database volume created before migration `003` existed, apply the repair
migration once as the database owner before running the test:

```bash
docker compose --env-file .env exec -T postgres \
  psql --username=security_lab_owner --dbname=security_lab \
  --set=ON_ERROR_STOP=1 \
  --file=/docker-entrypoint-initdb.d/003_enforce_football_read_only.sql
```

## Repository layout

| Path | Responsibility |
| --- | --- |
| `app/` | Minimal PHP 8.2 service and health checks. |
| `database/` | SQL migrations plus backup and restore operations. |
| `infrastructure/` | PostgreSQL, nginx, systemd, and logrotate configuration. |
| `scripts/` | Defensive host audit and evidence collection. |
| `tests/` | Smoke, database, security, and recovery checks. |
| `reports/` | Generated reports; secrets must never be stored here. |
| `docs/evidence/` | Screenshot checklist and sanitized evidence guidance. |

## Safety boundaries

1. Use only loopback, private lab addresses, or machines personally authorized
   for this project.
2. Begin with read-only discovery and authenticated configuration checks.
3. Do not use denial-of-service, persistence, credential attacks, exploitation,
   or destructive payloads.
4. Never publish passwords, tokens, private IP details, database dumps, or raw
   logs containing personal data.
5. Record the target, authorization, date, tool version, and expected impact for
   every assessment.

## Isolated assessment target

Host-only mode is optional. During the earlier lab configuration, the
authorized target was:

```text
http://192.168.56.1:8088
```

The BlackArch VM used a second, host-only adapter. The latest external attempt
observed an ARP response but no response to three TCP 2222 SYNs, and HTTP 8088
timed out. No SSH handshake completed; `ssh-audit` and Katana were not run; TCP
5432 was not probed. Treat this as an undetermined reachability limitation, not
as a passed remote assessment.

Allowed endpoints:

- `GET /health`
- `GET /api/matches`

Remote administration is intentionally command-line only:

```bash
ssh -i <PRIVATE_KEY_PATH> \
  -p 2222 labadmin@192.168.56.1
```

Root login, password authentication, keyboard-interactive authentication, SSH
forwarding, X11 forwarding, and tunnelling are disabled.

## Validated evidence

- [Reproducible validation evidence](docs/VALIDATION_EVIDENCE.md), separated by
  execution date and local/host-only mode.
- [Final validation report](reports/FINAL_VALIDATION_REPORT.md), including
  remediated defects and remaining limitations.
- [Quality and security test plan](docs/TEST_PLAN.md).

Two defects discovered during execution are visible portfolio evidence:

- [`libpq5` runtime dependency removal](docs/VALIDATION_EVIDENCE.md#php-runtime-dependency)
  caused HTTP `503`; preserving the runtime library restored database health.
- [BusyBox `sha256sum` compatibility](docs/VALIDATION_EVIDENCE.md#busybox-checksum-compatibility)
  required portable `-c`; checksum and restore retests then passed.

For controlled assessment commands and AI-assisted testing boundaries, see
[`docs/BLACKARCH_ASSESSMENT.md`](docs/BLACKARCH_ASSESSMENT.md) and the reusable
[`docs/BLACK_HAT_ASSISTANT.md`](docs/BLACK_HAT_ASSISTANT.md) briefing.

## Portfolio evidence commands

The following commands produce concise evidence without displaying secrets:

```powershell
docker compose --env-file .env ps
curl.exe -i http://192.168.56.1:8088/health
curl.exe -i http://192.168.56.1:8088/api/matches
docker compose --env-file .env exec -T nginx nft list ruleset
docker compose --env-file .env exec -T nginx sshd -T |
  Select-String 'permitrootlogin|passwordauthentication|authenticationmethods|allowusers'
```

Review every terminal and screenshot before publishing. Do not capture `.env`,
private keys, raw authentication logs, MAC addresses, or unrelated services.

## Status

The containerized server, API, database controls, firewall, SSH hardening,
backup, restore drill, and local quality checks are implemented. Server-side
controls and external reachability are reported separately. The BlackArch
client result is limited/inconclusive and is not presented as a completed
penetration test.

## License

Released under the [MIT License](LICENSE). Synthetic football records in this
repository were authored solely for this demonstration.

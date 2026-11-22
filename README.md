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

| Area | Implemented control | Result |
| --- | --- | --- |
| Network | Service bound only to a VirtualBox host-only address | Passed |
| Firewall | `nftables` input policy defaults to `drop` | Passed |
| SSH | Key-only login, no root, no password, restricted user | Passed |
| Web | Security headers, method restrictions, 404 handling | Passed |
| Runtime | Read-only containers and `no-new-privileges` | Passed |
| Database | Internal-only PostgreSQL and least-privilege app role | Passed |
| Recovery | SHA-256 backup validation and disposable restore drill | Passed |
| Data | Six fictional football records with no third-party feed | Passed |

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

The service is designed to bind to the VirtualBox host-only interface instead
of Wi-Fi or a public interface. In this workstation, the authorized target is:

```text
http://192.168.56.1:8088
```

The BlackArch VM must use its second, host-only adapter and an unused address in
`192.168.56.0/24`. NAT remains available on the first adapter for updates, but
the assessment target is reachable only over the host-only segment.

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

- Successful PHP health response and PostgreSQL round trip (`HTTP 200`).
- `psql` role and privilege inspection with sensitive values removed.
- Backup artifact, SHA-256 checksum, and successful disposable restore drill.
- Hardened SSH, firewall ruleset, HTTP response, and listening-port checks.
- Final quality and security report with findings and remediation status.

See [`reports/FINAL_VALIDATION_REPORT.md`](reports/FINAL_VALIDATION_REPORT.md)
for the current execution record. An additional BlackArch assessment remains
pending because that VM requires repair; the completed server-side controls are
reported separately and are not presented as penetration-test results.

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
backup, restore drill, and local quality checks are implemented and validated.
The separate BlackArch client assessment is explicitly pending.

## License

Released under the [MIT License](LICENSE). Synthetic football records in this
repository were authored solely for this demonstration.

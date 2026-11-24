# Final Validation Report

## Executive summary

The laboratory implements a containerized Linux service with PHP 8.2,
PostgreSQL 16, nginx, hardened SSH, `nftables`, backup integrity, and a
disposable restore exercise. Evidence is separated by date and execution mode
so that server-side configuration is not confused with external reachability.

The current validation run on November 23, 2026 used an isolated, disposable
PostgreSQL Compose project. Database privilege and recovery checks passed, and
controlled policy violations produced non-zero exits. No VM, VPN, or Windows
Firewall setting was changed during this run.

## Execution modes

### Local mode

- Default bind: `127.0.0.1`.
- Scope: local application, database, backup, restore, and configuration tests.
- External VM access: intentionally unavailable.

### VirtualBox host-only mode

- Opt-in bind used in earlier server-side validation: `192.168.56.1`.
- Scope: isolated assessment from a personally controlled VM.
- Server-side policy and external reachability are distinct results.

## Current validation — November 23, 2026

| Control | Result | Verifiable evidence |
| --- | --- | --- |
| Compose rendering | Pass | `docker compose ... config --quiet` returned `0`. |
| Disposable PostgreSQL readiness | Pass | Health status became `healthy`; no host port published. |
| Application identity | Pass | Privilege test confirmed `current_user = security_lab_app`. |
| Database privileges | Pass | `CONNECT` allowed; `CREATE` and `TEMP` denied. |
| Schema privileges | Pass | `USAGE` allowed; `CREATE` denied. |
| Maintenance table | Pass | `SELECT`/`INSERT` allowed; five elevated operations denied. |
| Football table | Pass | `SELECT` allowed; six write/ownership operations denied. |
| Functional insert | Pass | Maintenance insert succeeded inside a rollback. |
| Synthetic data | Pass | Six football fixtures readable. |
| Backup integrity | Pass | Custom archive listed; SHA-256 check passed. |
| Restore content | Pass | Two tables, six fixtures, and representative row verified. |
| Restore cleanup | Pass | Disposable database count was `0` after completion. |

Full commands and summarized outputs are in
[`docs/VALIDATION_EVIDENCE.md`](../docs/VALIDATION_EVIDENCE.md).

## Negative verification

| Injected condition | Expected | Observed |
| --- | --- | --- |
| Temporary unauthorized `UPDATE` grant | Privilege test fails | Exit `3`; grant revoked; positive retest passed. |
| Dump modified after checksum creation | Restore stops before creation | Exit `1`; no database remained. |
| Restore target already exists | Existing database is not overwritten | Exit `1`; existing database preserved. |
| Valid backup lacks representative fixture | Content validation fails | Exit `1`; disposable database removed. |

## Earlier local/server-side observations — November 21–22, 2026

- Local `/health`: HTTP `200`, database reachable.
- Local `/api/matches`: HTTP `200`, six records.
- Unknown route: HTTP `404`.
- Unsupported API method: HTTP `403`.
- PHP version header disabled.
- Host-only server `nftables`: input policy `drop` observed.
- Effective SSH policy: root/password login disabled, restricted user,
  public-key-only authentication.
- Host-side key login succeeded as the restricted user.

These observations were not re-executed in the current PostgreSQL-only
disposable run.

## External BlackArch result

- Target answered ARP.
- TCP 2222 attempt captured three outbound SYN packets without an observed
  response.
- TCP 8088 timed out without an HTTP response.
- No SSH handshake completed.
- `ssh-audit` was not executed.
- Katana was not executed.
- TCP 5432 was not probed.

Result: **limited / inconclusive reachability**. The cause is undetermined. No
external SSH, HTTP, `ssh-audit`, Katana, or PostgreSQL security result is
claimed.

## PostgreSQL distinction

- Compose PostgreSQL: internal backend network, no published host port.
- Windows PostgreSQL: separate host service previously observed listening on
  wildcard TCP 5432; outside this Compose project.
- Windows Firewall: a restricted block rule was reported as created, but its
  effect from BlackArch remains unconfirmed because TCP 5432 was not probed.

## Defects found, corrected, and retested

### Runtime PostgreSQL library removed during image cleanup

- Failure: PHP returned HTTP `503` because `pdo_pgsql` lost runtime `libpq5`.
- Correction: preserve `libpq5` while removing build-only packages.
- Retest: `pdo_pgsql` loaded; health returned HTTP `200`.

### BusyBox checksum option incompatibility

- Failure: BusyBox rejected GNU long option `sha256sum --check`.
- Correction: use portable `sha256sum -c`.
- Retest: checksum verification, restore content checks, and cleanup passed.

### Privilege test did not assert results

- Failure: the original SQL printed booleans and could exit successfully after
  a policy mismatch.
- Correction: run as `security_lab_app`, validate identity, and raise SQL
  exceptions for individual privilege mismatches.
- Retest: unauthorized `UPDATE` grant produced exit `3`.

### Football table inherited unintended INSERT

- Failure: default privileges granted `INSERT` to newly created app tables.
- Correction: explicitly revoke all application access on
  `app.football_matches`, then grant only `SELECT`; add a repair migration.
- Retest: `SELECT` passed and `INSERT` was denied.

## Evidence hygiene

- No credential was placed in a command line or published output.
- Temporary credentials remained in a Git-ignored validation environment.
- Dumps, checksums, and raw logs remained inside the disposable container.
- No private key, `.env`, packet capture, or raw authentication log is part of
  this report.

## Conclusion

Database authorization and recovery controls have current reproducible
evidence, including negative tests. Earlier server-side hardening evidence is
retained with its date. External BlackArch reachability remains unresolved and
must not be described as a completed penetration test.

# Final Validation Report

## Executive summary

The local Linux service laboratory was built and exercised successfully on
November 21, 2026. The validated stack uses nginx, PHP 8.2, PostgreSQL 16,
separate container networks, non-root application execution, read-only
filesystems, least-privilege database access, and loopback-only publication.

One runtime dependency defect and one cross-platform portability defect were
found during testing. Both were corrected and retested successfully. No known
release-blocking defect remains in the locally executed scope.

## Validated scope

| Control | Result | Evidence |
| --- | --- | --- |
| Compose configuration parsing | Pass | Configuration accepted without errors. |
| Shell syntax | Pass | All operational shell scripts parsed successfully. |
| PHP syntax | Pass | `index.php` reported no syntax errors. |
| Container build | Pass | PHP 8.2 Debian image built with `pdo_pgsql`. |
| PostgreSQL readiness | Pass | PostgreSQL 16 container reported healthy. |
| Health endpoint | Pass | `/health` returned HTTP 200 and database reachable. |
| Unknown route handling | Pass | Unknown path returned HTTP 404. |
| Information exposure | Pass | PHP version header was disabled. |
| Security headers | Pass | CSP, frame, content-type, referrer, and cache controls present. |
| Database least privilege | Pass | Application role can connect, use schema, select, and insert; elevated table operations are denied. |
| Backup integrity | Pass | Custom-format dump parsed and SHA-256 checksum created. |
| Restore drill | Pass | Backup restored with one application table into a disposable database. |
| Restore cleanup | Pass | Disposable database count returned zero after the drill. |

## Defects found and remediated

### Runtime PostgreSQL library removed during image cleanup

- **Impact:** PHP health check returned HTTP 503 because `pdo_pgsql` could not
  load its client library.
- **Correction:** Marked `libpq5` as an explicit runtime dependency while
  removing build-only packages.
- **Retest:** PHP loaded `PDO` and `pdo_pgsql`; health check returned HTTP 200.

### Non-portable checksum option

- **Impact:** BusyBox `sha256sum` rejected the GNU long option `--check`.
- **Correction:** Replaced it with the portable `-c` option.
- **Retest:** Checksum verification, restore, table inspection, and cleanup all
  completed successfully.

## Security observations

- PostgreSQL is not published to the host.
- The HTTP service is bound only to `127.0.0.1`.
- Application and proxy containers use read-only filesystems and
  `no-new-privileges`.
- The PHP process runs as a dedicated non-root account.
- Environment secrets are randomly generated in an ignored `.env` file.
- No credential, raw dump, or private infrastructure detail is included here.

## Remaining isolated-lab work

The BlackArch assessment has not been executed. Before it is run, the target
must be placed on a dedicated host-only network, its address and authorization
must be recorded, and the scan must remain non-destructive. This pending item
does not invalidate the completed application, database, backup, or recovery
tests; it is a separate defensive-assessment phase.

### Hardened remote gateway validation

The synthetic football API and hardened gateway are active on the VirtualBox
host-only interface. The observed `nftables` ruleset uses an input policy of
`drop` and permits established traffic, IPv4 ICMP for diagnosis, SSH on the
container port 22, and HTTP on the container port 8080. Docker publishes only
`192.168.56.1:2222` and `192.168.56.1:8088`.

SSH validation succeeded as the unprivileged `labadmin` account. Effective
server configuration confirmed root login disabled, password authentication
disabled, an `AllowUsers labadmin` restriction, and public-key-only
authentication. The football API returned HTTP 200 after firewall activation.

Final host-port inspection also identified a separate Windows PostgreSQL
service listening on wildcard TCP 5432. The Docker PostgreSQL service remains
unpublished, but the Windows service must be blocked on the host-only interface
before BlackArch testing. Automatic rule creation was attempted and rejected
because the current process was not elevated. The exact restricted firewall
command is recorded in `docs/BLACKARCH_ASSESSMENT.md`.

## Conclusion

The implemented local scope is reproducible and passed its final functional,
database-permission, integrity, backup, and recovery checks. The project is
ready for sanitized screenshots and portfolio presentation. It should not be
described as a production deployment or a completed penetration test.

# BlackArch Defensive Assessment Guide

## Authorization and scope

The application defaults to local mode (`127.0.0.1`), which is intentionally
unreachable from a VM. BlackArch work requires an explicit opt-in host-only
bind. During the recorded assessment attempt, the only authorized target was
`192.168.56.1`. Testing originated from the personally controlled `ARCH`
VirtualBox VM. Do not scan Wi-Fi, the internet, another VM, or any other target.

The project may be published, but the live assessment workspace is private.
Repository documentation must use placeholders or sanitized lab values. Never
paste a credential into an AI chat, issue, commit, terminal recording, or
screenshot.

## Secret-handling policy

Never publish or paste any of the following:

- `.env` or values copied from it.
- `.secrets/`, private SSH keys, recovery codes, passwords, or tokens.
- `infrastructure/nginx/authorized_keys` from a live workstation.
- Raw database dumps, packet captures, authentication logs, or shell history.
- Host usernames, personal paths, MAC addresses, public IP addresses, or Wi-Fi
  details that are not necessary to reproduce the lab.

Public-safe artifacts include `.env.example`, fictional football records,
redacted command output, the firewall policy, test methodology, and reports
that contain no credentials. A public SSH key is not a password, but this
project still ignores the live `authorized_keys` file to avoid publishing
workstation-specific identity material.

Before each commit:

```bash
git status --short
git diff --cached --check
git diff --cached
```

Run a secret scanner such as Gitleaks against the complete history before the
first push. If a secret is ever committed, removing it in a later commit is not
enough: rotate the credential first, then purge it from Git history.

## PostgreSQL scope and Windows firewall

A separate PostgreSQL service installed on the Windows host listens on wildcard
address TCP 5432. It is not part of this Docker project. The PostgreSQL service
in `compose.yaml` has no published host port and remains internal to the Compose
backend network.

The following restricted Windows Firewall rule was reported as created:

```powershell
New-NetFirewallRule `
  -DisplayName 'Security Lab - Block PostgreSQL on Host-Only' `
  -Direction Inbound -Action Block -Protocol TCP `
  -LocalAddress 192.168.56.1 -LocalPort 5432 `
  -RemoteAddress 192.168.56.0/24 -Profile Any
```

Its effectiveness from BlackArch is **not confirmed**: TCP 5432 was not probed
during the recorded external attempt. Do not connect to or enumerate the
separate Windows PostgreSQL service.

## Recorded external result

The BlackArch attempt produced limited reachability evidence:

- ARP response observed from the target.
- TCP 2222 attempt: three outbound SYN packets captured; no response observed.
- TCP 8088: HTTP request timed out without a response.
- SSH handshake: not completed.
- `ssh-audit`: not executed.
- Katana: not executed.
- TCP 5432: not probed.

Classification: **limited / inconclusive**. The cause is undetermined. The
evidence does not isolate VirtualBox networking, Windows filtering, the
container firewall, port publication, or service state as the cause.

## Remote shell access

The VirtualBox shared folder `security_lab_keys` exposes the lab key to the
`ARCH` VM as read-only. After the VM starts, verify the mount and protect a
temporary local copy before connecting:

```bash
install -m 0600 \
  /media/sf_security_lab_keys/blackarch_lab_ed25519 \
  "$HOME/.ssh/blackarch_lab_ed25519"

ssh -i "$HOME/.ssh/blackarch_lab_ed25519" \
  -p 2222 labadmin@192.168.56.1
```

If the shared folder is not automatically mounted, install/enable the
VirtualBox guest additions and mount the read-only share before continuing.
Do not copy the private key into screenshots or the Git repository.

The host-only adapters do not provide DHCP. Identify the second interface with
`ip -br link`, then assign the VM an unused lab address (replace `enp0s8` if the
interface name differs):

```bash
sudo ip link set enp0s8 up
sudo ip address add 192.168.56.10/24 dev enp0s8
ping -c 2 192.168.56.1
```

No default gateway is required on this interface. Keep the existing NAT default
route on the first interface.

## Allowed testing

- Host discovery for `192.168.56.1` only.
- TCP port enumeration against `192.168.56.1` only.
- HTTP header, method, routing, and low-volume input validation checks.
- Version and configuration observations that do not attempt exploitation.
- Manual verification that non-allowed ports are filtered or closed.

## Suggested tool sequence

Use the minimum tool needed and save sanitized results only:

1. `ip`, `ping`, and `ss` for local network and socket verification.
2. `nmap -Pn -sT -sV -p 2222,5432,8088 192.168.56.1` for the three approved
   ports only. Do not use a subnet target or UDP scan.
3. `curl` for headers, allowed methods, health behavior, and JSON validation.
4. OpenSSH client for public-key authentication and restricted-user checks.
5. `ssh-audit` for server-algorithm review without credential attacks.
6. `nikto` only with a low request rate and only against
   `http://192.168.56.1:8088`; exclude denial-of-service checks.
7. Gitleaks or an equivalent offline scanner for repository-secret review.

Do not use password crackers, exploit frameworks, automated exploitation,
fuzzers with unbounded input, or tools configured for evasion or persistence.

## Prohibited testing

- Denial of service, flooding, brute force, credential attacks, persistence,
  malware, destructive payloads, or exploitation outside this application.
- Scanning `192.168.56.0/24` as a range.
- Testing the NAT gateway, Wi-Fi subnet, public addresses, or third parties.
- Publishing secrets, raw database dumps, MAC addresses, or private host logs.

## Evidence checklist

1. Record the date, VM name, source address, and exact target.
2. Capture the target URL and successful synthetic football API response.
3. Record commands and versions before recording results.
4. Redact unrelated interfaces and identifiers from screenshots.
5. Assign each finding a severity, evidence, impact, and remediation.
6. Re-run the specific check after remediation and record the outcome.
7. Store raw evidence outside Git; copy only a redacted derivative into the
   repository.

## Intended target behavior (not external proof)

- TCP `8088` should accept HTTP through nginx in host-only mode.
- TCP `2222` should accept SSH with the dedicated key as `labadmin` in
  host-only mode.
- `/health` returns HTTP 200 while PostgreSQL is healthy.
- `/api/matches` returns fictional synthetic data.
- Unknown routes return HTTP 404.
- Unsupported methods are denied.
- Compose PostgreSQL is not published to the host-only network.

The intended behavior above must be retested from BlackArch before it can be
reported as externally verified.

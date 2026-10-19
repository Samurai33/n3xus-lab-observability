# Security policy

## Reporting a vulnerability

Please report security issues privately through GitHub's
[private vulnerability reporting](https://github.com/Samurai33/n3xus-lab-observability/security/advisories/new)
rather than opening a public issue. I aim to acknowledge reports within 7 days.

In scope: anything in this repository that could expose credentials, give an attacker access to a monitored
network, or let crafted input (container names, log lines, PVE notification fields) inject into alerts or
collector output.

## Hardening built into this stack

- **Read-only everywhere.** Proxmox uses a `PVEAuditor` API token. MikroTik uses a `read,api` group with a user
  locked to the monitoring host's address, over API-SSL only, with the certificate pinned to your own CA.
- **No secrets in config.** Alertmanager reads tokens and passwords from `*_file` paths. Everything under
  `secrets/` is ignored by git, and `scripts/ci-local.sh` runs gitleaks over the history and the working tree.
- **Loopback by default.** In `docker-compose.yml`, Prometheus and Alertmanager publish only on `127.0.0.1`.
  Expose them through an authenticating proxy or a VPN, never directly.
- **Network isolation.** Run the stack on a dedicated monitoring VLAN. It should reach only the exporter ports it
  scrapes (9100/9290/8006/8729), and only it should be allowed to reach those ports.
- **Hardened units.** The systemd units in `systemd/` use `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp`
  and related options, and run as the `prometheus` user.

## If you publish your own fork

Before pushing, check that you have not committed real IPs, hostnames, chat IDs, e-mail addresses or tokens.
Run `./scripts/ci-local.sh`. A scanner does not catch an internal IP address, so read the diff as well.

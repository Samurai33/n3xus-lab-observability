# MikroTik via MKTXP (read-only)

[MKTXP](https://github.com/akpw/mktxp) reads RouterOS over the API. The setup below keeps it read-only, TLS-only and
pinned to one source address.

## RouterOS side (v7)

```routeros
# read-only group and user, allowed from the monitoring host only
/user group add name=monitor policy=read,api
/user add name=monitor group=monitor address=192.0.2.10/32 password="<long random>"

# your own CA signs the API-SSL certificate (signing a cert without key-cert-sign fails with "CA not found")
/certificate add name=monitor-ca common-name=monitor-ca key-usage=key-cert-sign,crl-sign days-valid=3650
/certificate sign monitor-ca
/certificate add name=monitor-api common-name=192.0.2.1 subject-alt-name=IP:192.0.2.1 days-valid=825
/certificate sign monitor-api ca=monitor-ca
/certificate export-certificate monitor-ca   # copy the .crt to secrets/router-ca.pem

# API-SSL only, TLS 1.2+, only from the monitor; the plaintext API stays off
/ip service set api disabled=yes
/ip service set api-ssl disabled=no certificate=monitor-api tls-version=only-1.2 available-from=192.0.2.10/32

# input chain: allow the monitor to 8729, drop anything else it tries on the router
/ip firewall filter add chain=input src-address=192.0.2.10 protocol=tcp dst-port=8729 action=accept comment="MON-API allow"
/ip firewall filter add chain=input src-address=192.0.2.0/24 protocol=!icmp connection-state=new action=drop log=yes log-prefix=MON-API comment="MON-API drop"
```

Rollback:

```routeros
/ip firewall filter remove [find comment~"MON-API"]
/ip service set api-ssl disabled=yes certificate=none available-from=""
/user remove [find name=monitor]
/user group remove [find name=monitor]
/certificate remove [find name~"monitor"]
```

## Notes

- `mktxp_firewall_filter_total` is in **bytes**, and its `name` label is `| chain | action | comment | proto`. Put
  meaningful comments on your rules, then match on them (see `MikrotikWanDropSpike`).
- Measure a baseline before you set thresholds. WireGuard interfaces with endpoint-less peers count errors all
  the time, so the rules only watch `ether*`/`sfp*`.
- Isolate the monitoring VLAN. It should reach only the exporter ports it scrapes, not SSH, BMCs or the LAN.

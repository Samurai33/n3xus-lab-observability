# secrets/

Everything in this folder except this README is ignored by git. Create these files (`chmod 600`):

| File | Used by | Content |
|---|---|---|
| `telegram_bot_token` | Alertmanager | Bot token from @BotFather, a single line |
| `smtp_password` | Alertmanager | SMTP password or API key |
| `heartbeat_token` | Alertmanager | Bearer token for the dead man's switch endpoint |
| `pve.yml` | pve-exporter | Copy of `pve-exporter/pve.yml.example` with a real PVEAuditor token |
| `mktxp_credentials.yaml` | MKTXP | `username: monitor` / `password: ...` |
| `router-ca.pem` | MKTXP | Public certificate of the CA that signed the router's API-SSL certificate |

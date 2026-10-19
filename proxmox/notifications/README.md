# Proxmox VE notifications → Telegram

Proxmox VE 8.3+ has a generic **webhook** notification target with Handlebars bodies. Two ways to use it:

| Option | Body | When |
|---|---|---|
| **A. Through Alertmanager** (recommended) | [`alertmanager-webhook.json`](alertmanager-webhook.json) | You already run Alertmanager. The bot token lives in one place, PVE events share the same Telegram formatting, silences and routing as everything else. |
| **B. Straight to Telegram** | [`telegram-direct.json`](telegram-direct.json) | No Alertmanager. Token and chat id stay in PVE secrets (`/etc/pve/priv/notifications.cfg`, root-only). |

Both use the severity Proxmox assigns (`info`, `notice`, `warning`, `error`). Option B sends `info` events silently.
With option A, the `Proxmox` route in [`alertmanager.yml`](../../alertmanager/alertmanager.yml) does the same.

## A. Proxmox → Alertmanager → Telegram

Each notification becomes one alert labelled `alertname="Proxmox"`. The route sends it once, with no repeats
and no "resolved" message (the alert expires after `resolve_timeout`).

```bash
# Run on the PVE node. In the API, header values, secrets and the body are all base64.
pvesh create /cluster/notifications/endpoints/webhook \
  --name alertmanager \
  --method post \
  --url 'http://alertmanager.lab.example:9093/api/v2/alerts' \
  --header "name=Content-Type,value=$(printf application/json | base64 -w0)" \
  --body "$(base64 -w0 alertmanager-webhook.json)" \
  --comment 'PVE events -> Alertmanager'
```

If Alertmanager sits behind basic auth (`--web.config.file`), add a secret and an `Authorization` header that uses it:

```bash
  --secret "name=auth,value=$(printf 'user:password' | base64 -w0 | base64 -w0)" \
  --header "name=Authorization,value=$(printf 'Basic {{ secrets.auth }}' | base64 -w0)"
```

## B. Proxmox → Telegram

```bash
pvesh create /cluster/notifications/endpoints/webhook \
  --name telegram \
  --method post \
  --url 'https://api.telegram.org/bot{{ secrets.token }}/sendMessage' \
  --header "name=Content-Type,value=$(printf application/json | base64 -w0)" \
  --body "$(base64 -w0 telegram-direct.json)" \
  --secret "name=token,value=$(printf '<bot token>' | base64 -w0)" \
  --secret "name=chat_id,value=$(printf '<chat id>' | base64 -w0)"
```

The message is plain text on purpose, with no `parse_mode`. Proxmox's `escape` helper makes the text valid JSON,
not valid Telegram HTML, and vzdump logs contain `<` and `>`.

For a forum topic, add `"message_thread_id": <id>` to the body.

## Wire it to a matcher and test

```bash
pvesh set /cluster/notifications/matchers/default-matcher --target alertmanager   # or telegram
pvesh create /cluster/notifications/targets/alertmanager/test
```

## Gotchas

- **Test harnesses can send real mail.** If an SMTP target has no secret or fails, proxmox-notify falls back to
  `mail-to-root`. If you render templates locally, disable that target first.
- Custom templates in `/etc/pve/notification-templates/default/<name>-{subject,body}.txt.hbs` override the built-in
  ones for every target. Non-ASCII text in scripts that call `PVE::Notify` needs `decode_utf8`, or you get mojibake.

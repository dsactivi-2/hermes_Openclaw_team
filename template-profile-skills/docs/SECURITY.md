# Security & Allowlist

## Command Allowlist

### Immer erlaubt (read-only)
```bash
ls, cat, head, tail, grep, find, df, free, uptime, ps, ss, whoami
curl (nur GET/HEAD)
git status, git log, git diff
docker ps, docker images, docker inspect
kubectl get, kubectl describe, kubectl logs
```

### Mit Approval (low-risk)
```bash
curl POST/PUT/DELETE (API-Calls)
hermes chat -q (andere Profile ansprechen)
git add, git commit
```

### Mit Manual-Gate (high-risk)
```bash
apt install, apt remove
pip install, pip uninstall
systemctl restart, systemctl start
docker compose up, docker compose down
kubectl apply, kubectl delete
```

### Nie ohne Second-Pair-of-Eyes (critical)
```bash
rm -rf /
systemctl stop networking
ufw disable
iptables -F
docker system prune -a
borg delete
```

## Secret Management

### Aktuelle Secrets
| Secret | Wo | Typ |
|--------|---|-----|
| OPENROUTER_API_KEY | `~/.hermes/.env` | API Key |
| XAI_API_KEY | `~/.hermes/.env` | API Key |
| Dograh API Key | Dograh UI | API Key |
| Telnyx Connector | Dograh UI | API Key |
| SSH Keys | `~/.ssh/` | Private Keys |

### Regeln
1. Niemals Secrets in Logs, Memory oder Skills speichern
2. Secrets gehören in `.env` oder Doppler — nie in config.yaml
3. Doppler MCP ist read-only fürs Audit
4. SSH-Keys haben Passphrase oder sind auf bestimmte Hosts beschränkt

## Network Security

### Aktuelle Konfiguration
- **Tailscale:** Alle Server im Mesh (100.x.x.x)
- **UFW:** aktiv auf 210 (activi-k3-1)
- **fail2ban:** aktiv auf 210
- **SSH:** nur per Tailscale/IP-Whitelist

### Port-Binding-Regeln
```
Ollama (11434):    127.0.0.1 only  → DONE
Postgres (5432):   127.0.0.1 only  → fix pending
Docker (2376):     tailscale only  → fix pending
Hermes API (8642): 127.0.0.1 only  → DONE
```

## Audit-Log

Jede Aktion auf Policy-Level 3+ wird geloggt in:
```
~/.hermes/logs/maintenance-audit.log
```

Format:
```
[2026-06-02 17:30 UTC] Policy=high-risk | Aktion=apt install nginx | User=Hermes | Status=OK
[2026-06-02 17:35 UTC] Policy=critical | Aktion=kubectl delete pod | User=Denis | Approval=JA
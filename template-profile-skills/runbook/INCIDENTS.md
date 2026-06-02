# INCIDENTS — Incident Response

## Klassifizierung

| Level | Beschreibung | Reaktionszeit | Eskalation |
|-------|-------------|---------------|------------|
| 🔴 Critical | Service Down, Data Loss, Security Breach | Sofort | Telegram + Email + Anruf |
| 🟡 High | Performance Degradation, Feature-Ausfall | 15min | Telegram |
| 🔵 Medium | Warnung, nicht-kritischer Fehler | 1h | Telegram |
| ⚪ Low | Kosmetik, Log-Warning | Next Day | Keine |

## Incident-Response Ablauf

```
1. Erkennung (Healthcheck / Alert / User-Report)
        │
        ▼
2. Klassifizierung (Level + betroffene Komponente)
        │
        ▼
3. Erste Diagnose (read-only, nicht verschlimmern)
        │
        ▼
4. Fix / Workaround (Policy-Level beachten!)
        │
        ▼
5. Validierung (Service wieder OK?)
        │
        ▼
6. Post-Mortem (Warum? Wie verhindern?)
```

## Bekannte Incident-Templates

### 🔴 Gateway Down (104)
```yaml
level: critical
symptom: Hermes antwortet nicht
diagnose: hermes gateway status | systemctl --user status hermes-gateway
workaround: systemctl --user restart hermes-gateway
fix: log check: ~/.hermes/logs/gateway.log | tail -50
```

### 🟡 Dograh Call-Fehler (210)
```yaml
level: high
symptom: Calls werden nicht getätigt oder brechen ab
diagnose: kubectl logs -n moneymaker deployment/dograh-api
workaround: kubectl rollout restart -n moneymaker deployment/dograh-api
```

### 🔵 Disk Fast Voll (104/210)
```yaml
level: medium
symptom: df -h zeigt >80%
diagnose: du -sh /* | sort -rh | head -10
workaround: docker system prune -af | borg prune
```

## Post-Mortem Template

```markdown
# Post-Mortem: <Titel>
Datum: <YYYY-MM-DD>
Severity: <Critical/High/Medium>
Dauer: <Von–Bis>
Root Cause: <Was war die Ursache?>
Fix: <Was wurde getan?>
Prävention: <Wie verhindern wir das?>
```
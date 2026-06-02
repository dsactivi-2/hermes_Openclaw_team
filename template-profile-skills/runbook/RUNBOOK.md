# RUNBOOK — Betriebshandbuch

## System-Übersicht

| Host | IP | Rolle | OS |
|------|----|-------|----|
| MyHermes (104) | 5.78.209.104 | Hermes Gateway, Redis, Voice PBX, Borg Backup | Linux |
| Mujo (210) | 88.99.215.210 | k3s Cluster, Dograh, n8n, Ollama | Linux |
| Watchdog | 178.105.4.240 | Cron Self-Checks, Monitoring | Linux |
| Mac activi | 100.67.104.24 | Voice Client, Entwicklung | macOS |
| Mac DS8877 | 100.95.131.5 | Voice Client, Entwicklung | macOS |

## Täglicher Betrieb

### 08:00 — Healthcheck (automatisch)
```bash
dev-op chat -q "Morgen-Healthcheck: CPU, RAM, Disk, Services"
```

### 02:00 Mi — Security-Scan + Patches
```bash
dev-op chat -q "Security-Scan + Patch-Preview"
```

## Alert-Schwellwerte

| Metrik | Warning | Critical |
|--------|---------|----------|
| CPU | 75% | 85% |
| RAM | 80% | 90% |
| Disk | 80% | 90% |
| Service Down | — | 1x Failed |

## Escalation-Pfad

```
Critical → Telegram sofort + Email
Warning  → Telegram (5min Toleranz)
Info     → Nächster Healthcheck
```

## Backup-Strategie

- **Borg Backup:** Täglich 03:00 UTC
- **Retention:** 7 daily, 4 weekly, 6 monthly
- **Ziel:** Hetzner StorageBox (SSH)
- **Preflight:** Vor jedem apt upgrade oder docker compose down

## Monitoring

- **Healthchecks.io:** Kritische Cron-Jobs
- **Watchdog Self-Check:** Alle 30min
- **Docker Health:** Alle 15min

## Service-Liste

### MyHermes (104)
| Service | Port | Status |
|---------|------|--------|
| Hermes Gateway | 8642 | Running |
| Redis | 6379 | Running |
| Hindsight | — | Running |

### Mujo/activi-k3-1 (210)
| Service | Port | Namespace | Status |
|---------|------|-----------|--------|
| k3s API | 6443 | — | Running |
| Dograh API | — | moneymaker | Running |
| Dograh UI | — | moneymaker | Running |
| n8n | — | moneymaker | Running |
| Ollama | 11434 | — | Running (localhost) |
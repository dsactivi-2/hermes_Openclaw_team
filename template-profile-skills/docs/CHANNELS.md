# Channels & Gateways

## Channel-Übersicht

| Channel | Typ | Empfänger | Für Profile |
|---------|-----|-----------|-------------|
| Telegram Home | Messaging | Denis (8212488253) | dev-op, dograh, n8n |
| Telegram DM | Messaging | Direktnachricht | Alle Alarme |
| Telegram Group | Messaging | Team-Chat | sales-qualifier |
| CLI | Terminal | Hermes TUI | agent-builder, ki-voice-agent |
| Discord | Messaging | #ops, #voice | DevOps, Voice-Team |
| API Server | HTTP | Port 8642 | Externe Aufrufe |
| Webhook | HTTP | /webhooks/* | n8n → Hermes |
| Email | IMAP/SMTP | backup@ | Critical Incidents |

## Telegram-Konfiguration

```yaml
telegram:
  bot_token: ***
  chat_id: 8212488253         # Home-Channel (Denis)
  platforms:
    - cli                      # CLI → Telegram Spiegelung
    - dev-op                   # DevOps Alarme
    - dograh                   # Call-Ergebnisse
    - n8n-workflow             # Workflow-Status
```

## Routing-Logik

```
Eingehende Nachricht (Telegram/CLI/Discord)
  │
  ▼
Orchestrator analysiert Intent
  │
  ├── System-Frage → dev-op (Hermes, Policy 1)
  ├── Call-Trigger → dograh (Hermes, Policy 2)
  ├── Code-Aufgabe → agent-builder (Hermes, Policy 3)
  ├── Sales-Prompt → prompting/sales-qualifier (Hermes, Policy 2)
  ├── Voice-Agent → ki-voice-agent (Hermes, Policy 3)
  ├── n8n-Webhook → n8n-workflow (Hermes, Policy 2)
  └── Bulk-Call → OpenClaw (Sales, Policy 2, isoliert)
```

## Notification-Rules

| Event | Channel | Priority |
|-------|---------|----------|
| Server Down | Telegram + Email | 🔴 Critical |
| Disk >85% | Telegram | 🔴 Warning |
| Call Failed | Telegram | 🟡 Low |
| Deploy Success | Telegram | ✅ Info |
| Daily Health | Telegram | ℹ️ Silent |
| Security Scan | Telegram | 🔴 Findings
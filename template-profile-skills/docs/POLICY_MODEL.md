# Policy Model — Dual-Runtime Policy Engine

## Policy-Levels

Das System definiert 5 Policy-Level mit aufsteigender Berechtigung:

```
Level 0: unrestricted   → Orchestrator only
Level 1: read-only      → Monitoring, Research
Level 2: low-risk       → Sales Qualifier, n8n Workflows
Level 3: high-risk      → DevOps, Agent Builder
Level 4: critical       → System-Änderungen (immer manuelles Approval)
```

## Policy-Definition

```yaml
policy:
  level: 2                    # 0-4
  name: low-risk
  runtime: hermes             # hermes | openclaw | both
  approval_gate: auto         # auto | manual | always_ask
  allowed_toolsets:
    - terminal
    - file
    - web
    - memory
  forbidden_commands:
    - "rm -rf"
    - "docker kill"
    - "systemctl stop"
    - "apt remove"
  audit_log: true
  escalation_path: telegram
  max_turns: 30
```

## Policy-Level Detail

### Level 0: unrestricted
- **Runtime:** Hermes (Orchestrator)
- **Gate:** Auto
- **Zugriff:** Alle Tools, alle Systeme
- **Nur für:** Orchestrator-Profil
- **Audit:** Voll

### Level 1: read-only
- **Runtime:** Hermes
- **Gate:** Auto (lesen)
- **Erlaubt:** `read_file`, `search_files`, `web_search`, `terminal` (read-only commands)
- **Verboten:** Jegliche `write`, `patch`, `docker`, `systemctl`, `apt`-Befehle
- **Für:** Research, Monitoring, Creative

### Level 2: low-risk
- **Runtime:** Hermes
- **Gate:** Auto
- **Erlaubt:** Lesen + einfache Aktionen (curl, API-Calls, n8n-Trigger)
- **Verboten:** System-Änderungen, Deployment, Package-Installation
- **Für:** Sales Qualifier, n8n Workflow, Dograh Dashboard

### Level 3: high-risk
- **Runtime:** Hermes + OpenClaw
- **Gate:** Manual (User muss bestätigen)
- **Erlaubt:** Deployment, Package-Installation, Service-Restart
- **Verboten:** System-Neukonfiguration, Backup-Löschung
- **Für:** DevOps, Agent Builder, ML Ops

### Level 4: critical
- **Runtime:** Hermes (mit Approval-Chain)
- **Gate:** ALWAYS_ASK + Second-Pair-of-Eyes
- **Erlaubt:** System-Änderungen, Firewall, Backup-Restore
- **Für:** Notfälle, Security-Incidents, Disaster Recovery

## Runtime-Routing Matrix

| Task-Typ | Policy-Level | Runtime | Begründung |
|----------|-------------|---------|------------|
| Sales Call triggern | 2 | Hermes | Dograh API via Hermes |
| Code Review | 1 | Hermes | Reasoning + Skills |
| System-Health | 1 | Hermes | Read-only Diagnose |
| Package installieren | 3 | Hermes | Approval nötig |
| Bulk-Call-Kampagne | 2 | OpenClaw | Isolierte Ausführung |
| Security-Scan | 1 | Hermes | Beide Server prüfen |
| Prompt optimieren | 2 | Hermes | A/B Testing |
| k3s Deployment | 4 | Hermes | Critical + Approval |
| Paper scannen | 1 | Hermes | Research |
| Voice-Agent deployen | 3 | Hermes | Pipecat + Daily |
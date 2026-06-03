# HIERARCHY — Vollständige Team- & Agent-Hierarchie

## Übersicht

```
ORCHESTRATOR (Policy 0 — unrestricted)
│   orchestrator → Task-Router (deepseek-v4-pro:cloud)
│
├── TEAM: devops (Policy 3 — high-risk, Hermes)
│   ├── dev-op           → Server-DevOp (deepseek-v4-flash:cloud)
│   └── n8n-workflow     → API-Integration (deepseek-v4-flash:cloud)
│
├── TEAM: agent-builder (Policy 3 — high-risk, Hermes)
│   └── agent-builder    → Skill-Architekt (deepseek-v4-pro:cloud)
│
├── TEAM: sales (Policy 2 — low-risk, Hermes)
│   ├── prompting-salesteleagent  → Prompt-Engineer (deepseek-v4-pro:cloud)
│   └── sales-qualifier           → Sales-Qualifier (deepseek-v4-flash:cloud)
│
├── TEAM: voice (Policy 2 — low-risk, Hermes)
│   ├── dograh           → Dashboard-Manager (deepseek-v4-flash:cloud)
│   ├── ki-voice-agent   → Pipecat-Architekt (ministral-3:3b-cloud)
│   └── xai-voice-dograh → xAI/Grok-Spezialist (grok-realtime)
│
├── TEAM: research (Policy 1 — read-only, Hermes)
│   └── research         → Paper-Scanner (deepseek-v4-pro:cloud)
│
├── TEAM: mlops (Policy 3 — high-risk, Hermes)
│   └── mlops            → Model-Engineer (deepseek-v4-pro:cloud)
│
└── TEAM: creative (Policy 1 — read-only, Hermes)
    └── creative         → Designer (deepseek-v4-flash:cloud)
```

## Team-Definitionen

| Team | Policy | Runtime | Agenten | Channels |
|------|--------|---------|---------|----------|
| revops-core | 2 | both | sales-qualifier | telegram, cli |
| devops | 3 | hermes | dev-op, n8n-workflow | telegram, cli |
| agent-builder | 3 | hermes | agent-builder | cli |
| sales | 2 | hermes | prompting-salesteleagent, sales-qualifier | telegram, cli |
| voice | 2 | hermes | dograh, ki-voice-agent, xai-voice-dograh | telegram, cli |
| research | 1 | hermes | research | cli |
| mlops | 3 | hermes | mlops | cli |
| creative | 1 | hermes | creative | cli |

## Verknüpfung Hermes-Profile ↔ Team-Agenten

| Hermes-Profil | Team | Agent | Runtime | Modell |
|---------------|------|-------|---------|--------|
| dev-op | devops | dev-op | Hermes | deepseek-v4-flash:cloud |
| agent-builder | agent-builder | agent-builder | Hermes | deepseek-v4-pro:cloud |
| n8n-workflow | devops | n8n-workflow | Hermes | deepseek-v4-flash:cloud |
| dograh | voice | dograh | Hermes | deepseek-v4-flash:cloud |
| ki-voice-agent | voice | ki-voice-agent | Hermes | ministral-3:3b-cloud |
| prompting-sales… | sales | prompting-salesteleagent | Hermes | deepseek-v4-pro:cloud |
| xai-voice-dograh | voice | xai-voice-dograh | Hermes | grok-realtime |
| research | research | research | Hermes | deepseek-v4-pro:cloud |
| mlops | mlops | mlops | Hermes | deepseek-v4-pro:cloud |
| creative | creative | creative | Hermes | deepseek-v4-flash:cloud |

## Policy-Level Anwendung

| Level | Name | Typische Aktionen | Approval |
|-------|------|-------------------|----------|
| 0 | unrestricted | Orchestrierung, Routing | auto |
| 1 | read-only | Lesen, Scannen, Recherche | auto |
| 2 | low-risk | API-Calls, Sales, Workflows | auto |
| 3 | high-risk | Code, Deploy, Install | manual |
| 4 | critical | System-Änderungen | ALWAYS_ASK |

## Runtime-Entscheidung

Der Orchestrator routet Tasks basierend auf:
- **Hermes**: Für Reasoning, Skills, Memory, MCP, Voice, DevOps
- **OpenClaw**: Für isolierte Bulk-Jobs, Sales-Calls ohne Supervision
- **both**: Team revops-core kann beide Runtimes nutzen
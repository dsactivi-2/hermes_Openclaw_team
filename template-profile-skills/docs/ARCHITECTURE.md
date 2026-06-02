# Architektur — Dual-Runtime Agent Orchestrator

## Systemarchitektur

```
                    ┌──────────────────┐
                    │   Telegram /     │
                    │   Discord / CLI  │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   ORCHESTRATOR   │
                    │  (Policy Engine) │
                    │  Routing-Entscheid│
                    └──┬───────────┬───┘
                       │           │
              ┌────────▼──┐  ┌────▼────────┐
              │ Hermes     │  │ OpenClaw    │
              │ Runtime    │  │ Runtime     │
              │            │  │             │
              │ - Voice    │  │ - Coding    │
              │ - DevOps   │  │ - Bulk Jobs │
              │ - Research │  │ - Sales     │
              └────────────┘  └─────────────┘
```

## Dual-Runtime Prinzip

| Runtime | Stärke | Einsatz |
|---------|--------|---------|
| **Hermes** | Skills, Memory, MCP, Cron, Voice | Agent Builder, DevOps, Voice Agents, Research, n8n, Dograh |
| **OpenClaw** | Isolierte Slots, Codex-Integration | Sales Teleagent, Coding-Agenten, Bulk-Kampagnen |

## Orchestrator-Policy

Der Orchestrator entscheidet pro Task:
1. **Welche Runtime?** — Hermes für Reasoning/Integration, OpenClaw für isolierte Ausführung
2. **Welches Team?** — revops-core, sales, devops, voice, research
3. **Welcher Agent?** — Spezifische Agenten-Kompetenz
4. **Welcher Approval-Gate?** — Read-only, Low-Risk, High-Risk, Critical
5. **Welcher Channel?** — Telegram/CLI/Slack/API

## Vollständige Hierarchie

```
ORCHESTRATOR (Policy 0)
│
├── TEAM: devops (Policy 3, high-risk, Hermes)
│   ├── dev-op           → Server-DevOp (deepseek-v4-flash:cloud)
│   └── n8n-workflow     → API-Integration (deepseek-v4-flash:cloud)
│
├── TEAM: agent-builder (Policy 3, high-risk, Hermes)
│   └── agent-builder    → Skill-Architekt (deepseek-v4-pro:cloud)
│
├── TEAM: sales (Policy 2, low-risk, Hermes)
│   ├── prompting-salesteleagent  → Prompt-Engineer (deepseek-v4-pro:cloud)
│   └── sales-qualifier           → Sales-Qualifier (deepseek-v4-flash:cloud)
│
├── TEAM: voice (Policy 2, low-risk, Hermes)
│   ├── dograh           → Dashboard-Manager (deepseek-v4-flash:cloud)
│   ├── ki-voice-agent   → Pipecat-Architekt (ministral-3:3b-cloud)
│   └── xai-voice-dograh → xAI/Grok-Spezialist (grok-realtime)
│
├── TEAM: research (Policy 1, read-only, Hermes)
│   └── research         → Paper-Scanner (deepseek-v4-pro:cloud)
│
├── TEAM: mlops (Policy 3, high-risk, Hermes)
│   └── mlops            → Model-Engineer (deepseek-v4-pro:cloud)
│
├── TEAM: creative (Policy 1, read-only, Hermes)
│   └── creative         → Designer (deepseek-v4-flash:cloud)
│
└── TEAM: revops-core (Policy 2, low-risk, both Hermes+OpenClaw)
    └── sales-qualifier  → Lead-Qualifizierung (deepseek-v4-flash:cloud)
```

## Netzwerk

```
MyHermes (104)          Mujo/activi-k3-1 (210)
  ├─ Gateway             ├─ k3s Cluster
  ├─ Redis               ├─ Dograh
  ├─ Voice PBX           ├─ n8n
  └─ Borg Backup         └─ YugoGPT-7B (Modal)
                               │
                         Watchdog-VPS (178.105.4.240)
                               ├─ Cron Self-Checks
                               └─ Monitoring
```
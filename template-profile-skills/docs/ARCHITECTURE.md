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

## Laufende Profile

| Profil | Runtime | Team | Modell |
|--------|---------|------|--------|
| dev-op | Hermes | DevOps | deepseek-v4-flash:cloud |
| agent-builder | Hermes | DevOps | deepseek-v4-pro:cloud |
| n8n-workflow | Hermes | DevOps | deepseek-v4-flash:cloud |
| dograh | Hermes | Voice | deepseek-v4-flash:cloud |
| ki-voice-agent | Hermes | Voice | ministral-3:3b-cloud |
| prompting-salesteleagent | Hermes | Sales | deepseek-v4-pro:cloud |
| xai-voice-dograh | Hermes | Voice | grok-realtime |
| research | Hermes | Research | deepseek-v4-pro:cloud |
| mlops | Hermes | ML | deepseek-v4-pro:cloud |
| creative | Hermes | Creative | deepseek-v4-flash:cloud |

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
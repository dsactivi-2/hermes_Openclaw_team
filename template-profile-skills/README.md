# Template Profile & Skills — Dual-Runtime Agent Orchestrator

Ein startfertiges Monorepo-Blueprint für Multi-Agent-Betrieb mit **Hermes Agent** und **OpenClaw** als Dual-Runtime, zentralem Orchestrator und Policy-Engine.

## Überblick

```
┌─────────────────────────────────────────────────────┐
│                   ORCHESTRATOR                       │
│           (Hermes Profile: orchestrator)             │
│        Policy-Engine + Routing + Approval            │
├──────────────────┬──────────────────────────────────┤
│   Hermes Runtime │   OpenClaw Runtime                │
│   (KI Voice,     │   (Coding-Agenten,                │
│    Agent-Builder │    Sales-Teleagent,               │
│    DevOps, ...)  │    Bulk-Campaigns)                │
├──────────────────┴──────────────────────────────────┤
│                   TEAMS                               │
│   revops-core │ sales │ devops │ voice │ research    │
├──────────────────────────────────────────────────────┤
│                   AGENTS                              │
│   sales-qualifier │ code-reviewer │ sysadmin │ ...   │
├──────────────────────────────────────────────────────┤
│              SKILLS + POLICIES + CHANNELS             │
└──────────────────────────────────────────────────────┘
```

## Struktur

```
template-profile-skills/
├── README.md              ← Du bist hier
├── docs/                  ← Architektur, PRD, Policies
│   ├── ARCHITECTURE.md
│   ├── PRD.md
│   ├── REPO_LAYOUT.md
│   ├── POLICY_MODEL.md
│   ├── SECURITY.md
│   ├── CHANNELS.md
│   ├── THREAT_MODEL.md
│   ├── CI_CD.md
│   └── ONBOARDING.md
├── runbook/               ← Betriebshandbuch
│   ├── RUNBOOK.md
│   ├── DEPLOY.md
│   ├── ROLLBACK.md
│   ├── INCIDENTS.md
│   └── CHECKLISTS.md
├── scripts/               ← Guardrailed Tooling
│   ├── preflight_check.sh
│   ├── postdeploy_check.sh
│   ├── new_team.sh
│   └── new_agent.sh
├── profiles/              ← Team- + Agent-Profile
│   └── teams/
│       └── revops-core/
│           ├── team.yaml
│           ├── agents/
│           │   └── sales-qualifier/
│           │       ├── agent.yaml
│           │       ├── SOUL.md
│           │       └── prompts/
│           │           └── system-prompt.md
│           └── skills/
└── .github/workflows/
    └── ci.yml
```

## Schnellstart

```bash
# 1. Neues Team anlegen
./scripts/new_team.sh revops-core --runtime=hermes

# 2. Neuen Agenten im Team anlegen
./scripts/new_agent.sh sales-qualifier revops-core

# 3. Preflight-Check vor Deployment
./scripts/preflight_check.sh

# 4. Deploy
./scripts/postdeploy_check.sh
```
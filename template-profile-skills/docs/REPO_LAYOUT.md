# Repo-Layout & Konventionen

## Verzeichnisstruktur

```
template-profile-skills/
│
├── README.md                    # Einstieg
├── .github/workflows/           # CI/CD
│   └── ci.yml
│
├── docs/                        # Dokumentation
│   ├── ARCHITECTURE.md          # Systemarchitektur
│   ├── PRD.md                   # Product Requirements
│   ├── REPO_LAYOUT.md           # ← Du bist hier
│   ├── POLICY_MODEL.md          # Policy-Engine
│   ├── SECURITY.md              # Security-Allowlist
│   ├── CHANNELS.md              # Gateway-Konfiguration
│   ├── THREAT_MODEL.md          # Bedrohungsanalyse
│   ├── CI_CD.md                 # CI/CD Pipeline
│   └── ONBOARDING.md            # Onboarding neuer Mitglieder
│
├── runbook/                     # Betriebshandbuch
│   ├── RUNBOOK.md               # Haupt-Runbook
│   ├── DEPLOY.md                # Deployment
│   ├── ROLLBACK.md              # Rollback
│   ├── INCIDENTS.md             # Incident Response
│   └── CHECKLISTS.md            # Checklisten
│
├── scripts/                     # Tooling
│   ├── preflight_check.sh       # Read-only Systemcheck
│   ├── postdeploy_check.sh      # Post-Deployment Validation
│   ├── new_team.sh              # Team-Scaffolding
│   └── new_agent.sh             # Agent-Scaffolding
│
└── profiles/                    # Team- + Agent-Profile
    └── teams/
        ├── revops-core/         # Erstes Team
        │   ├── team.yaml
        │   ├── agents/
        │   │   └── sales-qualifier/
        │   │       ├── agent.yaml
        │   │       ├── SOUL.md
        │   │       └── prompts/
        │   │           └── system-prompt.md
        │   └── skills/
        ├── devops/              # DevOps Team
        ├── voice/               # Voice Team
        ├── sales/               # Sales Team
        └── research/            # Research Team
```

## Konventionen

### YAML-Dateien
- `team.yaml`: team_name, runtime (hermes/openclaw/both), policy_level, channels, agents[]
- `agent.yaml`: agent_name, team, model, runtime, tools, approval_gate

### Markdown
- SOUL.md: Personality-Beschreibung mit Core-Regeln
- Prompts: System-Prompt für den Agenten im Kontext

### Scripts
- Alle Scripts: bash, guardrailed (read-only bis auf Scaffolding)
- Exit-Codes: 0=OK, 1=Warning, 2=Critical
- Output: JSON-kompatibel für CI-Parsing
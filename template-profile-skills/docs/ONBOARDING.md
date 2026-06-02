# Onboarding — Neues Teammitglied

## Voraussetzungen

- GitHub Account mit Zugriff auf `dsactivi-2/hermes_Openclaw_team`
- Hermes Agent installiert (siehe `hermes-agent` Skill)
- OpenClaw installiert (optional, für OpenClaw-Runtime)
- SSH-Key auf dem Server hinterlegt

## Schritte

### 1. Repository klonen
```bash
git clone https://github.com/dsactivi-2/hermes_Openclaw_team.git
cd hermes_Openclaw_team
```

### 2. Team-Struktur verstehen
```bash
cat README.md
cat docs/REPO_LAYOUT.md
cat docs/POLICY_MODEL.md
```

### 3. Neues Team anlegen
```bash
./scripts/new_team.sh <team-name> --runtime=<hermes|openclaw|both>
```

### 4. Agent im Team anlegen
```bash
./scripts/new_agent.sh <agent-name> <team-name>
```

### 5. Preflight-Check
```bash
./scripts/preflight_check.sh
```

### 6. Committen und pushen
```bash
git add .
git commit -m "feat: add <team-name> team with <agent-name> agent"
git push
```

## Policy-Regeln für neue Agenten

1. Jeder Agent braucht eine SOUL.md
2. Jeder Agent braucht ein system-prompt.md
3. Policy-Level muss definiert sein (default: 2)
4. Runtime muss zum Team passen
5. Approval-Gate: default "auto" für Level 1-2, "manual" für Level 3+
# Activi Hermes Agent Add-on

This directory prepares Hermes Agent as an optional add-on for the Matrix stack.
The core Matrix services must remain usable without these agents.

## Layout

- `sena/`: Agent-builder and voice-workflow advisor.
- `activi/`: Operations and Matrix administration advisor.
- `shared/`: Non-secret project context mounted read-only into both agents.

Each agent has:

- `SOUL.md`: primary identity and behavior contract.
- `config.yaml`: Hermes runtime defaults.
- `.env.example`: required secrets and account variables.
- `skills/`: role-specific Hermes skills.

## Deployment Model

Agents are started only with the optional Compose profile:

```bash
docker compose --profile hermes up -d sena activi
```

Before enabling them, create real Matrix bot users and access tokens, then add
the values to the deployment environment. Do not commit real `.env` files.

## Current Policy

- Matrix/Element is the core product.
- Hermes agents are add-ons, not required for chat availability.
- Skills define behavior and review discipline.
- Plugins/MCP/tool integrations should be enabled only when a role needs them.
- The `manim-video` Matrix skill is mathematical visualization, not Matrix chat.

## Matrix Automation Plan

The current Matrix room, n8n notification, Alertmanager, Dograh/Telnyx, and
Hermes read-only rollout plan is documented in `../MATRIX_NEXT_STEPS.md`.
Agents must remain disabled until the relevant bot account, room policy,
credential storage, and human approval gates are explicitly approved.

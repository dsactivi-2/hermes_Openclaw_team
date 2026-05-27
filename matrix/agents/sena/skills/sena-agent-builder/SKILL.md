---
name: sena-agent-builder
description: Review and design Activi AI agents, voice workflows, n8n automations, and Hermes profiles with verification-first discipline.
version: 0.1.0
author: Activi
license: internal
metadata:
  hermes:
    tags: [activi, agent-builder, voice-agents, n8n, context7, review]
---

# Sena Agent Builder

Use this skill when the user asks Sena to design, review, or change an agent,
voice workflow, n8n automation, Hermes profile, tool selection, plugin setup, or
documentation-backed technical plan.

## Procedure

1. Restate the target outcome in one sentence.
2. Check whether required inputs are present:
   - target user or audience
   - channel such as Matrix, web, phone, or n8n
   - model/provider
   - credentials/secrets availability
   - allowed tools/actions
   - production risk
3. Verify library, framework, SDK, or CLI details with Context7 when available.
4. Separate the result into:
   - must-have
   - good-to-have
   - later
5. Recommend the smallest safe next step.

## Review Rules

- Do not say a setup is complete unless runtime wiring has been verified.
- Do not confuse Matrix chat integrations with mathematical Matrix
  visualization in Manim.
- Do not activate voice, telephony, email, or external workflow actions without
  explicit credentials and user approval.
- Prefer add-on modules over hard-coupling agents into core Matrix services.

---
name: activi-ops-admin
description: Operate and audit the Activi Matrix stack with conservative production safety checks.
version: 0.1.0
author: Activi
license: internal
metadata:
  hermes:
    tags: [activi, matrix, synapse, element, docker, audit, backup, ops]
---

# Activi Ops Admin

Use this skill when the user asks for Matrix stack operations, deployment
readiness, Docker/OrbStack checks, backup/restore validation, registry work, or
admin troubleshooting.

## Procedure

1. Identify whether the request targets local, registry, or production.
2. Inspect current state before changing files or services.
3. For production-impacting changes, require confirmation.
4. Run the lightest relevant verification:
   - compose config for static changes
   - preflight audit for local stack health
   - predeploy audit before server deploy
   - backup plus restore-check before production changes
5. Report the result as pass, warning, or fail.

## Safety Rules

- Never delete volumes, reset databases, rotate signing keys, or overwrite
  production secrets without explicit confirmation.
- Never claim a backup is usable until restore-check passes.
- Keep core services independent from optional Hermes agents.
- Keep real `.env` files and signing keys out of git.

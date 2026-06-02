# PRD — Product Requirements Document

## Vision

Ein zentrales Orchestrierungssystem für alle KI-Agenten in der activi-Infrastruktur. Dual-Runtime (Hermes + OpenClaw) mit einheitlicher Policy, Security und Deployment.

## Requirements

### R1: Dual-Runtime Betrieb
- Hermes für Reasoning, Skills, Memory, Voice, DevOps
- OpenClaw für isolierte Ausführung, Bulk-Jobs, Sales-Teleagenten
- Orchestrator entscheidet automatisch über Runtime-Routing

### R2: Team-Organisation
- Teams gruppieren Agenten nach Verantwortungsbereich
- Jedes Team hat eigene Policies, Channels und Approval-Gates
- Initial: revops-core, sales, devops, voice, research

### R3: Agenten-Lebenszyklus
- Scaffolding via `new_agent.sh`
- Jeder Agent hat: agent.yaml, SOUL.md, prompts/
- Skill-Bibliothek pro Team

### R4: Security & Policy
- Approval-Gates: read-only, low, high, critical
- Threat Model dokumentiert
- Preflight-Check vor jedem Deploy
- Audit-Log aller Aktionen

### R5: Runbook
- Deploy-Prozedur mit Rollback-Plan
- Incident-Response mit Checklisten
- Monitoring und Alerting

### R6: CI/CD
- GitHub Actions Preflight-Workflow
- Syntax-Checks, Policy-Validierung
- Deployment-Gates

## Nicht-Ziele
- Kein Kubernetes-Orchestrator (k3s läuft bereits)
- Kein Ersatz für existierende Profile
- Kein OIDC/SSO in v1
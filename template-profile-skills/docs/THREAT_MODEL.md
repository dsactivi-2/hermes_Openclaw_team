# Threat Model

## Assets

| Asset | Wert | Gefährdung |
|-------|------|------------|
| API Keys (OpenRouter, xAI) | Kritisch | Credential Theft |
| SSH Private Keys | Kritisch | Unauthorized Access |
| Dograh Workflows | Hoch | Manipulation |
| Hermes Profile Configs | Mittel | Policy-Umgehung |
| Skills (Custom) | Mittel | Code-Injection |
| Team-Configs | Mittel | Routing-Manipulation |
| Backup-Daten | Hoch | Datenverlust |

## Trust Boundaries

```
[Internet]
    │
    ▼
[Telegram/Discord API] ─── Trust Boundary 1
    │
    ▼
[Hermes Gateway (104)] ─── Trust Boundary 2
    │
    ├── [Hermes Runtime] ─── Trust Boundary 3a
    │       ├── Memory (Hindsight)
    │       ├── Skills (Custom Code)
    │       └── MCP Servers
    │
    └── [OpenClaw Runtime] ─── Trust Boundary 3b (isoliert)
            └── Codex/Claude Code Subprocesses
    │
    ▼
[Mujo/activi-k3-1 (210)] ─── Trust Boundary 4
    ├── Dograh Container
    ├── n8n Container
    └── k3s Cluster

[Modal Cloud] ─── Trust Boundary 5 (extern)
    └── YugoGPT-7B Inference
```

## STRIDE-Analyse

### Spoofing
| Bedrohung | Risiko | Mitigation |
|-----------|--------|------------|
| Telegram Bot impersonation | Medium | Bot-Token geheim, keine Weitergabe |
| GitHub-Identity Spoofing | Low | SSH-Key + Token-Auth |
| API-Key Reuse | Medium | Pro Provider separater Key |

### Tampering
| Bedrohung | Risiko | Mitigation |
|-----------|--------|------------|
| Config-Manipulation | High | Git-Versionierung, Preflight-Check |
| Skill-Injection | High | Code-Review vor Merge, TIRITH |
| Policy-Umgehung | High | Approval-Gates, Audit-Log |

### Repudiation
| Bedrohung | Risiko | Mitigation |
|-----------|--------|------------|
| Fehlende Audit-Logs | Medium | maintenance-audit.log obligatorisch |
| Keine Herkunft von Änderungen | Medium | Git-Commit + Author-Tracking |

### Information Disclosure
| Bedrohung | Risiko | Mitigation |
|-----------|--------|------------|
| Secrets in Skills/Logs | High | Niemals Secrets speichern, Doppler |
| API-Key in Terminal-Output | Medium | secret.redact_secrets=true |
| Memory leak via Hindsight | Medium | Bank-Isolation pro Profil |

### Denial of Service
| Bedrohung | Risiko | Mitigation |
|-----------|--------|------------|
| Token-Limit Explosion | Medium | max_turns=60, Compression |
| Cron-Job Flood | Low | max_parallel_jobs begrenzt |
| API-Rate-Limiting | Medium | Credential Pools, Retry-Logik |

### Elevation of Privilege
| Bedrohung | Risiko | Mitigation |
|-----------|--------|------------|
| Policy-Level-Umgehung | High | Approval-Gates, Manual-Mode |
| Runtime-Escape (OpenClaw→Host) | Low | Container-Isolation |
| SSH-Key zu breit | Medium | Host-Restriction in authorized_keys |

## Accepted Risks

1. **Prompt Injection** — Kann nie vollständig verhindert werden, mitigiert durch TIRITH + Decision-Gates
2. **Single Point of Failure (104)** — MyHermes (104) ist Single-Point für Gateway. Watchdog (178.105.4.240) als Fallback
3. **Kein MFA für SSH** — Tailscale-Auth als Ersatz (100.x.x.x Mesh)
4. **macOS SSH blocked** — activi-Mac (Port 22 blocked) kann nicht remote gemanagt werden
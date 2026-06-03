# HIERARCHIE & PROZESSE — Wer steht über wem? Wer macht was?

## 1. KOMMANDOKETTE (Chain of Command)

```
DU (Denis) — Entscheider / Product Owner
│
├── ORCHESTRATOR (Policy 0 — unrestricted)
│   Entscheidet: WELCHER Agent für WELCHE Aufgabe
│   Hat Zugriff auf: ALLES (nur DU darf das)
│
├── TEAM-LEADS (Policy 1-3)
│   ├── devops (Policy 3) → Server, Deploy, Backup
│   ├── agent-builder (Policy 3) → Code, PRs, Skills
│   ├── voice (Policy 2) → Telefonie, Voice-Pipelines
│   ├── sales (Policy 2) → Verkauf, Prompts
│   ├── research (Policy 1) → Recherche, Wissen
│   ├── mlops (Policy 3) → Modelle, Evaluation
│   ├── creative (Policy 1) → Design, Content
│   └── revops-core (Policy 2) → Beide Runtimes
│
└── AGENTEN (Policy 1-3)
    Führen Aufgaben aus — innerhalb ihres Policy-Levels
```

## 2. ENTSCHEIDUNGS-MATRIX — WER DARF WAS?

```
AKTION                ORCHESTRATOR  TEAM-LEAD  AGENT    GENEHMIGUNG DURCH
─────────────────────────────────────────────────────────────────────────────
System lesen          ✅            ✅          ✅      —
Backup prüfen         ✅            ✅          ✅      —
Webhook trigger       ✅            ✅          ✅      —
Sales-Call starten    ✅            ✅          ✅      —
n8n-Workflow ändern   ✅            ✅          ⚠️      Team-Lead
Code deployen         ✅            ✅          ❌      Team-Lead + DU
Package installieren  ✅            ⚠️          ❌      DU
Service neustarten    ✅            ⚠️          ❌      DU
Firewall ändern       ✅            ❌          ❌      DU (NUR DU)
rm -rf /              NUR DU        ❌          ❌      DU PERSÖNLICH
```

## 3. PROZESSE — WER MACHT WAS IN WELCHER REIHENFOLGE?

### Prozess: Server-Problem beheben
```
1. ORCHESTRATOR erkennt Alarm (Healthcheck / Watchdog)
   │
2. ORCHESTRATOR fragt devops/dev-op an
   │
3. dev-op: pre_action_verification ausführen
   │   "Server: Mujo | RAM: 85% | Disk: 62% | Plan: Docker prune"
   │
4. DU genehmigt ("DA" oder "IZVRŠI")
   │
5. dev-op: Aktion ausführen + audit_log + post_action_validation
   │
6. dev-op: Ergebnis an DU + ORCHESTRATOR melden
```

### Prozess: Sales-Call-Kampagne
```
1. DU sagt "Starte Kampagne für Kunden XYZ"
   │
2. ORCHESTRATOR routet an sales/sales-qualifier
   │
3. sales-qualifier: YugoGPT-7B Prompt laden
   │
4. sales-qualifier: Dograh API → Call triggern
   │
5. Dograh → Webhook → n8n → Ergebnis in Airtable
   │
6. sales/prompting: A/B-Test auswerten (Langfuse)
   │
7. ORCHESTRATOR: Ergebnis an DU per Telegram
```

### Prozess: Neuen Skill entwickeln
```
1. DU sagt "Baue einen Sales-Skill"
   │
2. ORCHESTRATOR → agent-builder
   │
3. agent-builder: Plan schreiben
   │
4. DU genehmigt Plan
   │
5. agent-builder: Code mit TDD → Test → Review
   │
6. agent-builder: PR aufmachen
   │
7. DU merged PR
   │
8. agent-builder: Skill im Repo speichern
```

## 4. GENEHMIGUNGS-PFADE (Approval Gates)

```
READ-ONLY (Policy 1)
  Research, Creative
  → Kein Approval nötig
  → Dürfen NIE schreiben

LOW-RISK (Policy 2)
  Sales, Voice, n8n, Dograh
  → API-Calls autonom
  → Keine System-Änderungen
  → BEI UNSICHERHEIT: Orchestrator fragen

HIGH-RISK (Policy 3)
  DevOps, Agent-Builder, MLOps
  → Schreibaktionen brauchen "DA" / "IZVRŠI"
  → Deployment NUR nach expliziter Genehmigung
  → Vorher: pre_action_verification
  → Nachher: audit_log + post_action_validation

CRITICAL (Policy 4)
  NUR Orchestrator + DU
  → System-Änderungen, Firewall, Backup-Löschung
  → ALWAYS_ASK — selbst Orchestrator fragt
```

## 5. RUNTIME-ROUTING

```
AUFGABE                   RUNTIME      WOHIN
──────────────────────────────────────────────────────────
Server-Diagnose           Hermes       dev-op
Deployment                Hermes       dev-op
Dograh Calls triggern     Hermes       dograh
Sales-Bulk-Kampagne       OpenClaw     sales-qualifier (revops)
Prompt-Optimierung        Hermes       prompting-salesteleagent
Voice-Pipeline bauen      Hermes       ki-voice-agent
xAI/Grok integrieren      Hermes       xai-voice-dograh
Code schreiben            Hermes       agent-builder
Paper scannen             Hermes       research
Modell evaluieren         Hermes       mlops
Design erstellen          Hermes       creative
```

## 6. DATENFLUSS

```
TELEGRAM (Du)
  │
  ▼
HERMES GATEWAY (104:8642)
  │
  ▼
ORCHESTRATOR (Hierarchie-Check → Policy-Check → Runtime-Routing)
  │
  ├──→ Hermes Runtime
  │     ├── Skills + Memory + MCP
  │     ├── Dograh API (210) → Telefonie
  │     ├── n8n (210) → Workflows → Airtable/Notion
  │     └── Modal Cloud → YugoGPT-7B Inference
  │
  └──→ OpenClaw Runtime
        └── Bulk-Calls (isoliert, keine Verbindung zu Hermes-Memory)
│
▼
ERGEBNIS zurück zu Telegram (Du)
```

## 7. KURZZUSAMMENFASSUNG

| Wer | Darf | Muss fragen bei |
|-----|------|-----------------|
| **Du (Denis)** | Alles | Niemanden |
| **Orchestrator** | Routen + Policy 0-2 | Dir bei Policy 3+ |
| **Team-Leads** | Ihre Domäne Policy 1-2 | Dir bei Policy 3+ |
| **Agenten** | Nur ihre Aufgabe | Ihrem Team-Lead bei Unsicherheit |
| **OpenClaw** | Nur Bulk-Calls | Nie (isoliert) |
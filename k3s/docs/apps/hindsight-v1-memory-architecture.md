# Hindsight V1 Memory Architecture - Banks, Tags, Agenten, Mental Models

Stand: 2026-05-25
Status: Zielstandard fuer V1, keine Live-Aenderung ohne Freigabe

## 1. Zweck

Diese Datei definiert die Memory-Architektur fuer Hindsight V1 im activi
K3s-Stack: Bank-Struktur, Agenten-Zusammenarbeit, Tags, Versionierung,
Konfliktbehandlung, Cleanup und die 8 Mental Models.

Sie ergaenzt:

```text
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-k3s-plan.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-deploy-runbook.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-migration-runbook.md
```

## 2. Grundsatz

Hindsight ist das Projektgedaechtnis, nicht der Koordinator.

```text
Git:
  Code-Wahrheit

Projektunterlagen/Runbooks:
  dokumentierte operative Wahrheit

Queue/Task-System:
  Task- und Lock-Wahrheit

Hindsight:
  Kontext, Entscheidungen, Erfahrungen, Bugs, Loesungen, Status,
  Mental Models und abrufbares Projektwissen
```

Agenten arbeiten ueber Hindsight zusammen, aber Hindsight weist ihnen keine
Aufgaben zu und verhindert keine parallelen Konflikte. Das muss durch User,
Wrapper, Queue, Workflow oder Git-Regeln passieren.

## 3. Bank-Standard

V1 nutzt ausschliesslich `project:<name>` als Shared Bank fuer gemeinsame
Projektarbeit.

```text
project:hindsight
project:activi-k3s
project:crm
project:agent-platform
```

Altbestand:

```text
local-codex::<folder>--<hash>
```

Altbestand ist Migrationsquelle, nicht Zielstandard.

Nicht fuer V1 als aktive Shared Bank nutzen:

- `local-codex::<folder>--<hash>`
- `hindsight-2` als produktiver Zielname
- Testbanks
- framework-zentrierte Projektbanks wie `codex:<project>`

## 3.1 Projekt-Erkennung und Fallback-Banks

Der Agent darf die Zielbank nicht raten, wenn der Projektkontext unklar ist.
Die Zielbank wird in dieser Reihenfolge bestimmt:

1. Expliziter Task-/Workflow-Parameter, zum Beispiel `project:hindsight`.
2. Workspace- oder Repo-Mapping, zum Beispiel `.hindsight-project` oder
   zentrale Mapping-Datei.
3. Git-Remote/Repo-Name plus bekannte Projektliste.
4. Expliziter User-Hinweis im Prompt.
5. Fallback auf eine nicht-produktive Inbox-Bank.

Fallback fuer unklare Arbeit:

```text
bank: org:inbox
tags:
  project:unassigned
  status:needs-triage
  authority:draft
  retention:short
```

Projektunabhaengige, aber allgemein gueltige Regeln oder Runbooks werden nicht
in eine Agent-Bank geschrieben, sondern in:

```text
bank: org:shared
tags:
  project:global
  component:platform
  authority:source-of-truth
```

Private Agentenerfahrung darf optional in eine Agent-Bank:

```text
bank: agent:<agent-id>
tags:
  scope:private-agent-experience
  project:unassigned
```

Diese Agent-Bank ist nie Projekt-Wahrheit und ersetzt keine `project:<name>`-
Bank.

## 3.2 Option C: Projektbank plus Agent-Private-Bank

V1 nutzt Option C nur eingeschraenkt:

- Projektrelevante Fakten, Entscheidungen, Bugs, Fixes, Runbooks und
  Testnachweise werden primaer in `project:<name>` gespeichert.
- Der Agent darf zusaetzlich eine kurze private Lernnotiz in `agent:<agent-id>`
  speichern, wenn sie agentenspezifische Erfahrung enthaelt.
- Es wird nicht jeder projektbezogene Inhalt automatisch vollstaendig in beide
  Banks kopiert, weil das Duplikate, veraltete Fakten und Konflikte erzeugt.
- Wenn Dual-Write genutzt wird, muss die Agent-Bank die Projektbank referenzieren
  und als abgeleitet markieren.

Beispiel:

```text
Projektbank:
  bank: project:hindsight
  tags: project:hindsight, task:HINDSIGHT-V1, framework:codex,
        agent:codex-main, authority:source-of-truth

Agent-Private-Bank:
  bank: agent:codex-main
  tags: project:hindsight, source:derived-from-project,
        scope:private-agent-experience, authority:draft
```

## 3.3 Inbox-Triage und Qualitaetspruefung

`org:inbox` ist ein Sicherheitsnetz, kein Dauerziel. Jede Inbox-Memory muss
mindestens Agenten- und Herkunftstags tragen:

```text
bank: org:inbox
tags:
  project:unassigned
  framework:<codex|hermes|openclaw|call-agent|worker>
  agent:<agent-id>
  role:<role>
  component:unknown
  source:<chat|worker|manual|import>
  status:needs-triage
  authority:draft
  retention:short
```

Ein Inbox-Triage-Worker oder Codex-Audit darf regelmaessig Vorschlaege
erstellen, aber am Anfang keine unklaren Memories blind verschieben. Der
Vorschlag enthaelt pro Memory:

```text
memory_id
current_bank: org:inbox
suggested_bank: project:<name>
confidence: high|medium|low
reason
suggested_tags
action: copy_to_project_bank|leave_in_inbox|needs_manual_review
```

Freigaberegel:

- `high`: Vorschlag kann nach Review uebernommen werden.
- `medium`: manuell pruefen.
- `low`: in `org:inbox` lassen oder loeschen/archivieren.

Bei Uebernahme wird zuerst kopiert, nicht hart verschoben:

```text
org:inbox -> bleibt Audit-Trail mit status:migrated
project:<name> -> erhaelt saubere Projekt-Memory
```

Am Anfang wird die Inbox- und Tag-Qualitaet alle 7 Tage geprueft. Wenn die
Regeln stabil sind, kann das Intervall spaeter auf 14 oder 30 Tage verlaengert
werden.

Lokaler Umsetzungsstand:

- Codex-Hook nutzt `projectBankMode`.
- `/Users/activi/Documents/activi K3s` mapped auf `project:activi-k3s`.
- `/Users/activi/Documents/Hindsight 2` mapped auf `project:hindsight`.
- Unbekannte Workspaces fallen auf `org:inbox`.
- Retain ergaenzt Governance-Tags automatisch.
- Retain fuehrt vor dem Speichern Secret-Redaction aus.
- Dieses Repo enthaelt `.hindsight-project` mit `project:activi-k3s`.

## 4. Agenten-Rollen

Agenten sind Rollen im Projektkontext.

```text
Codex:
  Code, Tests, Refactoring, Debugging, Dokumentation, Runbooks.

Hermes:
  laenger laufende Agentenlogik, Messaging, Tool-Routing, autonome Workflows,
  Debugging und Fixes.

OpenClaw:
  lokale Bedienablaeufe, Workflow-Tests, Integrationspruefung, Bug-Reports.

Call-Agent:
  Telefonie, Voice-Flows, Call-Auswertung, Gespraechstests.

Worker:
  Import, Sync, Embeddings, Batch-Jobs, Monitoring, Cleanup.
```

Jede Memory muss mindestens Owner, Framework und Agent nennen:

```text
user:mujo
framework:<name>
agent:<agent-id>
role:<role>
```

## 5. Zusammenarbeit

Beispielablauf:

```text
1. Codex schreibt Runbook und Code.
   Retain: framework:codex, agent:codex-docs, type:runbook, type:code.

2. Hermes bekommt den Auftrag, Codex-Memories fuer Task X zu lesen.
   Recall: project:<name>, task:<task-id>, framework:codex.
   Retain: framework:hermes, agent:hermes-debug, type:fix.

3. OpenClaw testet den Ablauf.
   Retain: framework:openclaw, agent:openclaw-test, type:bug-report.

4. Hermes debuggt anhand des Bug-Reports.
   Retain: framework:hermes, agent:hermes-debug, type:fix.

5. Codex aktualisiert Projektunterlagen und Runbook.
   Retain: framework:codex, agent:codex-docs, type:docs.
```

Regel:

- Agenten sehen fremde Memories nicht automatisch.
- Prompt, Wrapper oder Workflow entscheidet, welche Tags gelesen werden.
- Fuer enge Arbeit wird `all_strict` genutzt.
- Fuer breitere Suche wird `any_strict` genutzt.
- Ungetaggte Memories sind im Multi-Agent-Setup zu vermeiden.

## 6. Pflicht-Tags

Pflicht fuer neue produktive Memories:

```text
project:<name>
repo:<repo-name>
task:<task-id>
user:mujo
framework:<codex|hermes|openclaw|call-agent|worker>
agent:<agent-id>
role:<role>
component:<component-name>
env:<local|dev|staging|prod>
```

Optionale Tags:

```text
branch:<branch-name>
pr:<number>
ticket:<external-ticket-id>
source:<chat|github|manual|worker|call|import>
instance:<runtime-instance-id>
priority:<low|medium|high|critical>
status:<planned|in-progress|blocked|done|failed|obsolete>
authority:<source-of-truth|draft|historical|conflict-resolution>
retention:<short|normal|long|permanent>
type:<runbook|docs|decision|bug-report|fix|test-result|migration|handover>
```

Beispiel:

```text
bank: project:hindsight
tags:
  project:hindsight
  repo:activi-k3s
  task:HINDSIGHT-V1
  user:mujo
  framework:codex
  agent:codex-docs
  role:docs
  component:hindsight
  env:dev
  type:runbook
  status:done
  authority:source-of-truth
  retention:long
```

## 7. Recall-Regeln

Enger Task-Recall:

```text
bank: project:<name>
tags:
  project:<name>
  task:<task-id>
  component:<component>
tags_match: all_strict
```

Framework-uebergreifender Recall:

```text
bank: project:<name>
tags:
  task:<task-id>
  framework:codex
  framework:hermes
  framework:openclaw
tags_match: any_strict
```

Source-of-Truth-Recall:

```text
bank: project:<name>
tags:
  authority:source-of-truth
  status:done
tags_match: all_strict
```

## 8. document_id-Strategie

Aktuelle lebende Dokumente:

```text
project:<name>/runbook/current
project:<name>/project-docs/current
project:<name>/status/current
task:<task-id>/current
session:<session-id>/current
```

Regel: Upsert/replace mit vollstaendigem aktuellen Inhalt.

Historische Versionen:

```text
project:<name>/runbook/v2026-05-25
project:<name>/handover/v2026-05-25
project:<name>/decision/<decision-id>
migration:<source>:<timestamp>
conflict:<topic>:<timestamp>
```

Regel: Versionierte IDs bleiben erhalten, bis Retention greift.

## 9. Wahrheit und Konflikte

Wahrheitsreihenfolge:

1. `authority:source-of-truth`
2. aktuelle Projektunterlagen und Runbooks
3. freigegebene Entscheidungen
4. aktuelle Handover
5. historische Handover
6. Drafts
7. Debug- und Testdaten

Bei Widerspruch:

- nicht raten
- gueltige Quelle nennen
- Konflikt als eigene Memory speichern, wenn relevant
- alte Aussage mit `status:obsolete` oder `authority:historical` markieren

Konflikt-Document:

```text
document_id: conflict:<topic>:<timestamp>
tags:
  project:<name>
  type:conflict-resolution
  status:current
  authority:source-of-truth
  retention:long
```

## 10. Cleanup und Retention

V1-Retention-Draft:

```text
retention:short:
  Debug-Daten, Retain-Tests, temporaere Testbanks.

retention:normal:
  Task-Ergebnisse, Bug-Reports, Fixes.

retention:long:
  Handover, Migrationsberichte, wichtige Testnachweise.

retention:permanent:
  freigegebene Entscheidungen, aktuelle Runbooks, Source-of-Truth-Dokumente.
```

Delete-Regeln:

- kein automatisches Delete von `authority:source-of-truth`
- Delete nur nach Dry-Run-Bericht
- Delete nur nach Backup/Restore-Pruefung
- Delete von Dokumenten ist Cascade-Delete und permanent

## 11. Mental Models Zielstandard

Alle projektweiten Mental Models werden primaer mit `project:<name>` getaggt.
Nicht nur `framework:*` oder `agent:*`, sonst lesen sie zu eng und koennen leer
refreshen.

### 11.1 project-status-roadmap

Zweck:

```text
Aktueller Projektstatus, Roadmap, offene Punkte, Blocker und naechste Schritte.
```

Source Query:

```text
Was ist der aktuelle Status des Projekts, welche Entscheidungen sind gueltig,
welche Risiken und naechsten Schritte sind offen?
```

Primaere Tags:

```text
project:<name>
type:runbook
type:docs
type:handover
status:done
authority:source-of-truth
```

### 11.2 architecture-decisions

Zweck:

```text
Architekturentscheidungen, Begruendungen, Alternativen und technische Grenzen.
```

Source Query:

```text
Welche Architekturentscheidungen gelten fuer dieses Projekt und warum wurden
sie getroffen?
```

Primaere Tags:

```text
project:<name>
type:decision
authority:source-of-truth
component:<component>
```

### 11.3 agent-collaboration-workflow

Zweck:

```text
Rollen, Uebergaben, Parallel-/Sequenziell-Regeln und Workflow-Ablaeufe fuer
Codex, Hermes, OpenClaw, Call-Agenten und Worker.
```

Source Query:

```text
Wie arbeiten die Agenten in diesem Projekt zusammen, welche Rollen haben sie
und welche Regeln gelten fuer parallele oder sequentielle Arbeit?
```

Primaere Tags:

```text
project:<name>
framework:<codex|hermes|openclaw|call-agent|worker>
type:handover
type:decision
```

### 11.4 bank-tag-governance

Zweck:

```text
Bank-Namen, Tag-Pflichten, Recall-Regeln, Sichtbarkeit und Migrationsmapping.
```

Source Query:

```text
Welche Bank- und Tag-Regeln gelten fuer dieses Projekt und wie werden Memories
korrekt gespeichert und abgerufen?
```

Primaere Tags:

```text
project:<name>
type:docs
authority:source-of-truth
```

### 11.5 versioning-conflict-cleanup

Zweck:

```text
Upsert, Versionierung, Konfliktbehandlung, Retention und Delete-Governance.
```

Source Query:

```text
Wie werden aktuelle und historische Inhalte versioniert, wie werden Konflikte
entschieden und welche Cleanup-Regeln gelten?
```

Primaere Tags:

```text
project:<name>
type:decision
type:conflict-resolution
authority:source-of-truth
```

### 11.6 deployment-operations

Zweck:

```text
K3s-Betrieb, Deployments, Healthchecks, Monitoring, Rollout und Rollback.
```

Source Query:

```text
Wie wird dieses Projekt im activi K3s-Stack betrieben, deployed, ueberwacht
und bei Fehlern zurueckgerollt?
```

Primaere Tags:

```text
project:<name>
env:<dev|staging|prod>
type:runbook
component:k3s
component:hindsight
```

### 11.7 backup-restore-migration

Zweck:

```text
Backup, Restore, Server-1-Fallback, Dump/Export, Import und Migrationsvalidierung.
```

Source Query:

```text
Wie werden Hindsight-Daten gesichert, wiederhergestellt, migriert und validiert?
```

Primaere Tags:

```text
project:<name>
type:migration
type:runbook
component:backup
component:postgres
```

### 11.8 security-access-risk

Zweck:

```text
Auth, Secrets, interne/externe Erreichbarkeit, NetworkPolicy, Datenschutz und Risiken.
```

Source Query:

```text
Welche Sicherheits-, Zugriffs- und Risikoregeln gelten fuer dieses Projekt?
```

Primaere Tags:

```text
project:<name>
type:decision
type:runbook
component:security
authority:source-of-truth
```

## 12. Mental-Model-Validierung

Nach Import oder Deploy:

```text
1. Alle 8 Mental Models listen.
2. Tags jedes Models pruefen.
3. Quell-Memories mit passenden Tags pruefen.
4. Refresh ausfuehren.
5. Pruefen, dass jedes Model nicht leer ist.
6. Recall-Stichprobe gegen jedes Model machen.
7. Leere Models zuerst als Tag-Problem behandeln.
```

## 13. Seed-Quellen

Startquellen fuer `project:hindsight`:

```text
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-k3s-plan.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-deploy-runbook.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-migration-runbook.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-memory-architecture.md
/Users/activi/Documents/Hindsight 2/PROJEKTUNTERLAGEN.md
/Users/activi/Documents/Hindsight 2/RUNBOOK.md
/Users/activi/Documents/Hindsight 2/HANDOVER-k3s-hindsight-agenten-architektur.md
```

Vor produktivem Seed:

- pruefen, welche Quellen aktuell und welche historisch sind
- Source-of-Truth-Tags setzen
- Drafts nicht als aktuelle Wahrheit markieren
- Altbestand nur kontrolliert importieren

# Hindsight V1 K3s App-Integration - activi Cluster

Stand: 2026-05-24
Status: Planung und Runbook, keine Umsetzung ohne separate Freigabe

## 1. Zweck

Diese Datei ist die app-spezifische K3s-Integrationsplanung fuer Hindsight im bestehenden activi K3s-Stack. Sie folgt dem globalen Standard:

```text
/Users/activi/Documents/activi K3s/docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md
/Users/activi/Documents/activi K3s/docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md
```

Diese Planung deployt nichts. Sie erstellt keine Cluster-Ressourcen, keine Secrets, keine PVCs und keine Datenbanken.

Ergaenzende Vor-Deploy-Unterlagen:

```text
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-deploy-runbook.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-migration-runbook.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-memory-architecture.md
```

## 2. Gelesene Pflichtunterlagen

Gelesen und beruecksichtigt:

- `docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md`
- `docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md`
- `docs/PROJECT-STATUS-2026-05-20.md`
- `docs/BACKUP-RUNBOOK-2026-05-20.md`
- `docs/NEXT-SESSION-GUIDE-2026-05-20.md`
- `docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md`
- `docs/OPEN-TODOS-2026-05-22.md`

Zusaetzlich als Hindsight-App-Quelle:

```text
/Users/activi/Documents/Hindsight 2/K3S-HINDSIGHT-V1.md
```

## 3. Kurzempfehlung

Empfehlung: **saubere K3s-Neuaufsetzung mit spaeterer kontrollierter Migration.**

Nicht empfohlen:

- kein blindes 1:1-Verschieben der lokalen oder Docker-Hindsight-Installation
- kein Single-Pod-Postgres
- kein oeffentlicher API-/MCP-Zugriff im ersten Installationsblock
- keine Server-1-Docker-Hindsight-Abhaengigkeit fuer das K3s-Design

Begruendung:

- Der K3s-Stack hat bereits Longhorn, Velero, CloudNativePG/Barman-Smoke und Monitoring validiert.
- K3s-Hindsight wird frisch aufgebaut und zunaechst ohne Altimport validiert.
- Lokales Mac-Hindsight ist die primaere spaetere Migrationsquelle.
- Server-1-Docker-Hindsight wird bis zum Schluss ignoriert und nur optional als
  spaete Migrationsquelle/Fallback geprueft.
- Das Zielbank-Schema `project:<name>` weicht vom lokalen Altbestand `local-codex::<folder>--<hash>` ab und braucht Mapping.

## 4. Ausgefuellte App-Onboarding-Antwort

Gate-kompatible Pflichtwerte:

```text
App-Name: hindsight
Namespace: hindsight
Zielmodus: frische K3s-Neuaufsetzung, Migration separat nach Validierung
Migrationsquelle: zuerst lokales Mac-Hindsight; Server 1 nur optional ganz am Ende
Domains: hindsight.activi.io vorgemerkt, oeffentlich erst spaeter
IngressClass: nginx, erst im spaeteren Public-Access-Block
TLS-Issuer: letsencrypt-prod, erst im spaeteren Public-Access-Block
Service-Typ: ClusterIP
StorageClass: longhorn
PVCs: CloudNativePG Postgres PVC plus optionale Cache-/Artefakt-PVCs, Groessen vor Deploy festlegen
Datenbank: PostgreSQL im Cluster ueber CloudNativePG, pgvector Extension erforderlich
Backup-Strategie: Barman Cloud Plugin plus pg_dump CronJob plus Velero plus Longhorn
Velero: Namespace hindsight separat sicherbar und restorebar planen
Longhorn: alle produktiven PVCs auf StorageClass longhorn, Volume-Schutz einplanen
DB-Backup: CloudNativePG/Barman WAL/Base Backups plus zusaetzlicher pg_dump CronJob
Restore-Test: CloudNativePG Restore, pg_dump Restore, Velero Namespace Restore und Hindsight Recall/Retain Validierung
Secrets: nur Secret-Namen und Zweck dokumentiert, keine Werte
Registry/ImagePullSecrets: feste Images vor Deploy festlegen, Pull Secret nur falls private Registry
Monitoring: ServiceMonitor und PrometheusRule fuer API, Worker, DB, Backups und Memory-Funktionen planen
ResourceQuotas/LimitRanges: vor Deploy festlegen, keine Werte geraten
NetworkPolicies: einplanen, aber erst nach finalen Kommunikationspfaden aktivieren
Rollback: bestehende Alt-Systeme bleiben unveraendert; kein Cutover ohne Freigabe
Offene Entscheidungen: Zielimages, PVC-Groessen, Env-Variablen, Backup-Retention, Migration und Cutover
Stop-Punkte: kein Deploy, keine Secrets, keine PVC/DB/Namespace-Erstellung und keine Alt-Hindsight-Aenderung ohne Freigabe
Deployment-Freigabe: nicht erteilt
```

Lesbare Detailantwort:

```text
App-Name:
  hindsight

Namespace:
  hindsight

Helm-Release:
  hindsight

Domains:
  spaeter vorgemerkt: hindsight.activi.io
  V1: kein oeffentlicher Ingress ohne separate Freigabe

IngressClass:
  nginx, falls spaeter Ingress freigegeben wird

TLS-Issuer:
  letsencrypt-prod, falls spaeter Ingress freigegeben wird

Service-Typ:
  ClusterIP

StorageClass:
  longhorn

PVCs:
  CloudNativePG Postgres PVC ueber Longhorn
  optional Reranker-/Model-Cache-PVC
  optional UI-/Importer-Artefakt-PVC nur falls benoetigt
  Groessen: offen, vor Umsetzung festlegen

Datenbank:
  PostgreSQL im Cluster ueber CloudNativePG
  Longhorn PVC
  S3/WAL ueber Barman Cloud Plugin
  zusaetzlicher pg_dump CronJob
  pgvector Extension fuer Hindsight Vector Search/Embeddings erforderlich

Backup-Strategie:
  CloudNativePG Barman Cloud Plugin fuer WAL/Base Backups
  zusaetzlicher pg_dump CronJob im Namespace hindsight
  Velero Backup/Restore fuer Namespace-Ressourcen
  Longhorn Snapshots/Backups fuer relevante PVCs
  bestehender Server-1-Docker-Fallback bleibt bis Cutover erhalten

Secrets:
  Nur Namen/Zweck, keine Werte:
  hindsight-groq-secret: Groq API Key fuer Default LLM, Retain, Reflect und Consolidation
  hindsight-postgres-app-secret: DB-App-Credentials, vorzugsweise von CloudNativePG verwaltet
  hindsight-s3-backup-secret: S3 Credentials fuer Barman/pg_dump, falls nicht bestehend geteilt
  hindsight-mcp-auth-secret: MCP/API Auth Token, falls fuer internen oder spaeter externen Zugriff genutzt
  hindsight-embedding-provider-secret: Embedding Provider Key, falls API-basierter Provider genutzt wird
  hindsight-image-pull-secret: nur falls private Images genutzt werden

Registry/ImagePullSecrets:
  Images offen.
  Bestehender Docker-Altbestand nutzt ghcr.io/vectorize-io/hindsight:latest und pgvector/pgvector:pg16.
  Fuer V1 muessen feste Versionstags festgelegt werden.
  ImagePullSecret nur falls private Registry.

SMTP:
  Nicht bekannt / nicht geplant.

Externe Ports:
  Keine in V1.
  Keine NodePorts, LoadBalancer oder ExternalName ohne Freigabe.

Security/Zugriff:
  Dashboard und API/MCP werden installiert, aber zunaechst nur intern.
  Zugriff zuerst per Cluster-internem Service, Port-Forward oder VPN.
  Oeffentliche Freigabe fuer `hindsight.activi.io` kommt spaeter separat.
  Voraussetzung fuer spaeter: TLS, Auth/API-Token, Rate-Limit und NetworkPolicy.

Monitoring:
  ServiceMonitor fuer Hindsight API/Worker planen.
  PrometheusRule fuer API down, DB down, Retain failures, Worker failures, Backup failures und Groq-Healthcheck-Fehler.
  CloudNativePG/Barman/pg_dump Backup-Status einbeziehen.

Offene Entscheidungen:
  Hindsight Zielversion und Images
  exakte Hindsight Env-Variablen fuer Retain/Reflect
  initiale PVC-Groessen
  pgvector-Image/Extension-Weg
  Embedding Provider Endpoint fuer bge-m3: Ollama intern, Ollama extern oder API-kompatibler Endpoint
  Migrationsformat: Rohdokumente neu retainen vs. Datenbank-/Memory-Export
  Velero Schedule-Name und Retention
  finaler Cutover-/Rollback-Zeitpunkt

Stop-Punkte:
  kein Deploy ohne Freigabe
  keine Docker-Hindsight-Aenderung
  keine Secrets ausgeben
  keine PVC/DB/Namespace-Erstellung ohne Freigabe
  bei Abweichung vom Clusterstandard stoppen
  bei fehlendem Restore-Weg stoppen

Naechster sicherer Schritt:
  Hindsight-K3s-Draft finalisieren, Zielimages/PVC-Groessen festlegen und lokales Mac-Hindsight als primaere Migrationsquelle inventarisieren.
```

## 5. Antworten auf die 29 Hindsight-Fragen

1. V1 wird eine neue K3s-Installation mit kontrollierter Migration. Keine 1:1-Blindmigration.
2. Lokales Quell-/App-Projekt: `/Users/activi/Documents/Hindsight 2/`. Server-Altbestand: Docker-Hindsight auf Server 1 unter `/root/hindsight/docker-compose.yml`.
3. Erhalten bleiben muessen: bestehende Memory-/Dateninhalte, wichtige Projektunterlagen, Handover, Runbooks, Mental Models/Directives soweit relevant. Exakte Auswahl nach Inventarisierung.
4. Ja, bestehende Hindsight-Datenbank als Docker-Postgres auf Server 1. Format/Ort aus Unterlagen: `pgvector/pgvector:pg16`, Docker-Volume `hindsight_hindsight-postgres-data`; Dumps unter `/var/lib/k3s-backup/postgres-dumps/`. Groesse offen.
5. Es gibt bekannte Docker-Volumes `hindsight-data`, `hindsight_hindsight-data`, `hindsight_hindsight-postgres-data`. Ob darin Vektorindizes/Artefakte liegen, ist offen und read-only zu inventarisieren.
6. V1-Komponenten: API, MCP-Endpunkt, Worker, interne UI, Importer/Migrationsjob, pg_dump CronJob. Scheduler nur minimal als CronJob/Queue-Plan.
7. `dsactivi-2/codegraph` ist fuer V1 nicht als Pflichtkomponente bestaetigt. Offen/spaeter.
8. `vectorize-io/hindsight` soll als Grundlage genutzt werden, aber mit festen Versionstags und Zielversion-Pruefung. Kein `latest` fuer Produktion.
9. Namespace: `hindsight`.
10. Helm-Release: `hindsight`.
11. V1 nur intern/VPN/in-cluster. Domain nur vorgemerkt.
12. Vorgemerkte Domain: `hindsight.activi.io`; keine oeffentliche Freigabe in V1.
13. Admin-UI ja, aber nur intern mitplanen.
14. API/MCP nur intern/VPN erreichbar.
15. Ja, Postgres mit CloudNativePG im Cluster.
16. `pgvector` ist fuer Hindsight mit externem PostgreSQL erforderlich; `ghcr.io/cloudnative-pg/postgresql:16.9-standard-bookworm@sha256:ff90b6871a539ea68a740cd553b694e2217869821cafc87df8328d86be52db9d` wurde lokal auf `vector.control` geprueft.
17. Initiale DB-PVC-Groesse offen. Vor Umsetzung anhand frischem Dump/DB-Groesse festlegen.
18. Objekt-/Dateispeicher: S3 fuer Barman/WAL und pg_dump. Weitere Artefakt-S3-Beduerfnisse offen.
19. Secrets siehe Abschnitt 4; nur Namen/Zweck dokumentiert.
20. Container-Images fuer den Draft sind gepinnt: Hindsight `0.6.2`, Hindsight-UI via Node `24-alpine`, Ollama `0.12.6`, Curl `8.16.0`, CNPG/Postgres `16.9-standard-bookworm`. Altbestand bleibt nur Referenz: `ghcr.io/vectorize-io/hindsight:latest`, `pgvector/pgvector:pg16`.
21. Private Images offen; ImagePullSecret nur falls erforderlich.
22. Embedding Provider bleibt konfigurierbar. Zielstand fuer V1 ist `ollama/bge-m3` ueber den internen Service `hindsight-ollama.hindsight.svc.cluster.local:11434`.
23. Ollama laeuft als app-spezifischer K3s-Service im Namespace `hindsight`; Image-Pinning ist im Draft erledigt, Ressourcen bleiben vor Deploy zu pruefen.
24. Healthcheck-/Metrics-Endpunkte offen und gegen Zielimage zu pruefen. Plan: API `/health`, DB-Checks, Worker/Operation-Status, Backup-Status.
25. Backups: DB WAL/Base via Barman, pg_dump, Velero Namespace, Longhorn Volume-Schutz, optional S3-Artefakte.
26. Restore-Test: separater Restore-Namespace, CloudNativePG Restore aus S3/WAL, pg_dump-Restore auf Wegwerf-DB, Hindsight API gegen Restore testen, Recall/Retain/Mental-Model-Check.
27. Migrationsvalidierung: Bank-/Document-/Memory-Zaehler, Recall-Stichproben, Mental-Model-Refresh nicht leer, Vergleich definierter Source-of-Truth-Dokumente, Retain neuer Testfakten.
28. Ja, V1 soll GitOps-ready geplant werden, aber GitOps ist noch kein Muss fuer ersten Freigabeblock.
29. Minimal erfolgreicher V1-Zustand: Hindsight intern im Namespace `hindsight`, CloudNativePG DB mit Backup, API/Worker healthy, Retain/Recall funktionieren, 8 Mental Models importiert und nicht leer, frischer Altbestand kontrolliert importiert oder bewusst zurueckgestellt, Docker-Hindsight bleibt Fallback.

## 6. V1 Architektur

```text
namespace: hindsight
├─ hindsight-api
├─ hindsight-worker
├─ hindsight-ui (intern)
├─ hindsight-importer / migration job (nur nach Freigabe)
├─ hindsight-pgdump CronJob
├─ CloudNativePG Cluster
│  ├─ Longhorn PVC
│  ├─ pgvector Extension
│  ├─ Barman Cloud Plugin S3/WAL
│  └─ Restore/PITR faehig
├─ optional Embedding Provider Endpoint
└─ optional Reranker/Model Cache PVC
```

Service-Typen:

- `ClusterIP` fuer API/MCP/UI.
- Kein NodePort.
- Kein LoadBalancer.
- Kein ExternalName ohne Freigabe.

Ingress:

- V1: kein oeffentlicher Ingress.
- Spaeter moeglich: `hindsight.activi.io`, IngressClass `nginx`, ClusterIssuer `letsencrypt-prod`, Auth/TLS/Rate-Limit/NetworkPolicy-Konzept erforderlich.

## 7. Datenbank-Setup

V1 nutzt vorhandenen Stack-Standard:

- CloudNativePG Operator ist bereits als nicht-produktiver Test-/Backup-Baustein installiert und validiert.
- Barman Cloud Plugin `v0.12.0` ist validiert.
- StorageClass `longhorn`.
- Kein klassischer Single-Pod-Postgres.

Plan fuer Hindsight:

- eigener CloudNativePG Cluster im Namespace `hindsight`
- Longhorn PVC
- S3/WAL via Barman Cloud Plugin
- zusaetzlicher `pg_dump` CronJob
- pgvector Extension vorbereiten/verifizieren

Offen:

- DB-PVC-Groesse
- Postgres-Version/Image
- pgvector-Installationsweg in CloudNativePG
- Backup-Retention fuer Hindsight

## 8. Backup- und Restore-Plan

Backup-Schichten:

1. CloudNativePG Barman Cloud Plugin fuer base backups und WAL.
2. Hindsight `pg_dump` CronJob im Namespace `hindsight`.
3. Velero fuer Namespace-Ressourcen und separaten Namespace-Restore.
4. Longhorn Volume-Schutz fuer PVCs.
5. Bestehender Server-1-Docker-Hindsight-Fallback bis Cutover.

Velero:

- Namespace `hindsight` mit passenden Backup-Labels/Schedule planen.
- Restore in separaten Namespace testen, nicht direkt produktiv ueberschreiben.

Restore-Test V1:

1. CloudNativePG Restore in Testnamespace.
2. `pg_dump` in Wegwerf-DB restoren.
3. Hindsight API gegen Restore-DB starten oder pruefen.
4. Recall-Stichproben laufen lassen.
5. Retain-Test ausfuehren.
6. Mental Models refreshen und auf nicht-leere Ergebnisse pruefen.

## 9. Monitoring und Healthchecks

V1 nutzt Groq direkt, keinen LiteLLM Proxy. Automatisches Provider-Fallback ist
damit nicht Teil des ersten Deploys. Stattdessen wird ein Groq-Healthcheck als
separater CronJob geplant, der Auth-, Rate-Limit-, Credit- oder Providerfehler
als Kubernetes-Job-Fehler sichtbar macht. Alertmanager-Anbindung erfolgt im
spaeteren zentralen Alertmanager-Block.

Monitoring ist bereits als kube-prometheus-stack installiert. Hindsight V1 soll direkt einplanen:

ServiceMonitor:

- Hindsight API
- Hindsight Worker, falls Metrics vorhanden
- optional Importer/CronJob-Metriken

PrometheusRule-Ideen:

- Hindsight API down
- Hindsight Worker down
- Retain-Fehlerrate erhoeht
- Recall/Reflect Fehler
- CloudNativePG Cluster nicht healthy
- Barman/WAL Backup Fehler
- pg_dump CronJob fehlgeschlagen
- PVC nahezu voll
- Mental Model Refresh wiederholt fehlgeschlagen oder stale

Offen:

- Exakte Metrics-Endpunkte des Zielimages.
- Ob Hindsight Prometheus-Metriken nativ bietet oder Logs/Healthchecks ausgewertet werden muessen.

## 10. Modell- und Embedding-Konfiguration

Geplanter Zielstand aus der aktuellen lokalen Hindsight-Konfiguration:

Recall:

```text
autoRecall=true
recallBudget=low
recallContextTurns=5
recallMaxTokens=4096
recallMaxQueryChars=3000
recallTimeout=10s
recallTypes=world,experience
recallRoles=user,assistant
Embeddings=ollama/bge-m3
Reranker=cross-encoder/ms-marco-MiniLM-L-6-v2
```

Retain:

```text
autoRetain=true
retainMode=chunked
retainEveryNTurns=1
retainOverlapTurns=2
retainExtractionMode=concise
retainRoles=user,assistant
retainToolCalls=true
retainContext=codex
retainMaxCompletionTokens=32768
Provider=groq
Model=llama-3.3-70b-versatile
```

Default LLM, Reflect und Consolidation:

```text
Provider=groq
Model=llama-3.3-70b-versatile
```

Gemma/DeepInfra ist in der aktuellen Zielkonfiguration nicht aktiv.

Ollama-Regel:

- Ollama wird nicht hart installiert.
- Embeddings bleiben provider-konfigurierbar.
- Wenn Ollama fuer bge-m3 genutzt wird, dann bevorzugt als interner K3s-Service oder klar definierter interner Endpoint.
- Ressourcen/GPU/CPU muessen vor Installation separat geprueft werden.

## 11. Agenten-Rollen

Hindsight V1 wird projektzentriert geplant. Agenten werden nicht als getrennte
Projektinseln behandelt, sondern als Rollen innerhalb eines gemeinsamen
Projektkontexts.

Zielrollen:

```text
Codex:
  Codeaenderungen, Tests, Refactoring, Debugging, PR-Vorbereitung,
  Projektunterlagen und Runbooks.

Hermes:
  laenger laufende Agentenlogik, Tool-Routing, Messaging, autonome Workflows
  und Debugging-Aufgaben.

OpenClaw:
  lokale Bedien- und Workflow-Schicht, Entwicklerablaeufe, Integrationspruefung
  und Bug-Reports aus realen Bedienablaeufen.

Call-Agent:
  Voice-/Telefonie-Flows, Gespraechsauswertung und Call-spezifische Tests.

Worker:
  Import, Sync, Embeddings, Batch-Verarbeitung, Monitoring und Cleanup.
```

Regel:

- Code-Wahrheit bleibt in Git.
- Task-/Lock-Wahrheit liegt spaeter in Queue, Task-Tabelle oder Workflow-System.
- Hindsight speichert Kontext, Entscheidungen, Ergebnisse, Fehler und Loesungen.
- Hindsight koordiniert Agenten nicht automatisch.

## 12. Tag-Governance

Fuer geteilte Projektarbeit wird ausschliesslich die Shared Bank
`project:<name>` als gemeinsame Projektbank genutzt. Bestehende Altbanks wie
`local-codex::<folder>--<hash>` sind Migrationsquellen und werden nicht als
neuer Zielstandard fortgefuehrt.

Die Zielbank wird nicht geraten. Agenten bestimmen sie ueber:

1. expliziten Task-/Workflow-Parameter,
2. Workspace-/Repo-Mapping,
3. Git-Remote/Repo-Name gegen bekannte Projektliste,
4. expliziten User-Hinweis,
5. sonst Fallback auf `org:inbox` mit `project:unassigned`,
   `status:needs-triage`, `authority:draft` und `retention:short`.

Projektunabhaengige globale Regeln gehoeren in `org:shared`, nicht in eine
Agentenbank. Agent-private Erfahrung darf optional in `agent:<agent-id>`
gespeichert werden, ersetzt aber nie die Projektbank.

Option C ist erlaubt, aber nur eingeschraenkt: Projektrelevante Fakten werden
primaer in `project:<name>` geschrieben. Eine Agent-Bank darf hoechstens eine
kurze abgeleitete private Lernnotiz speichern und muss sie als
`source:derived-from-project` und `scope:private-agent-experience` markieren.
Vollstaendiges automatisches Duplizieren jeder Memory in Projekt- und
Agent-Bank ist nicht Zielstandard.

`org:inbox` wird regelmaessig geprueft. Jede Inbox-Memory muss trotzdem
Agenten- und Herkunftstags tragen, zum Beispiel `framework:*`, `agent:*`,
`role:*`, `source:*`, `status:needs-triage`, `authority:draft` und
`retention:short`.

Ein Inbox-Triage-Worker oder Codex-Audit erstellt Vorschlaege:

```text
memory_id
suggested_bank: project:<name>
confidence: high|medium|low
reason
suggested_tags
action: copy_to_project_bank|leave_in_inbox|needs_manual_review
```

Am Anfang wird alle 7 Tage geprueft, ob:

- relevante Memories in `org:inbox` haengen geblieben sind,
- Pflicht-Tags fehlen,
- falsche Projektbanks genutzt wurden,
- Agent-Private-Banks Projekt-Wahrheit enthalten,
- Cleanup-/Retention-Regeln angepasst werden muessen.

Der Worker soll zuerst Review-Vorlagen erstellen. Automatische Uebernahme ist
spaeter nur fuer stabile High-Confidence-Regeln vorgesehen. Bei Uebernahme wird
kopiert und die Inbox-Memory als `status:migrated` markiert.

Pflicht-Tags fuer neue Memories:

```text
project:<name>
repo:<repo-name>
task:<task-id>
user:mujo
framework:<codex|hermes|openclaw|call-agent|worker>
agent:<agent-id>
role:<role>
component:<component>
env:<local|dev|staging|prod>
```

Optionale Governance-Tags:

```text
branch:<branch-name>
pr:<number>
source:<chat|github|manual|worker|call|import>
instance:<runtime-instance-id>
status:<planned|in-progress|blocked|done|failed|obsolete>
authority:<source-of-truth|draft|historical|conflict-resolution>
retention:<short|normal|long|permanent>
```

Recall-Regeln:

- `all_strict` fuer enge projekt- und taskbezogene Arbeit.
- `any_strict` fuer breitere getaggte Suche ohne ungetaggte Memories.
- Keine ungetaggten Memories im produktiven Multi-Agent-Setup.
- Agenten lesen fremde Framework-Memories nur gezielt per Prompt, Wrapper oder Workflow.

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
  status:done
  authority:source-of-truth
```

## 13. Versionierung und Konfliktregeln

Aktuelle Dokumente nutzen stabile `document_id`s und werden per Upsert ersetzt:

```text
project:<name>/runbook/current
project:<name>/project-docs/current
project:<name>/status/current
```

Wichtige historische Staende nutzen versionierte `document_id`s:

```text
project:<name>/runbook/v2026-05-24
project:<name>/handover/v2026-05-24
project:<name>/decision/<decision-id>
```

Wahrheitsreihenfolge bei Widerspruch:

1. `authority:source-of-truth`
2. aktuelle Projektunterlagen und Runbooks
3. freigegebene Decisions
4. aktuelle Handover
5. alte Handover und Drafts
6. Debug-/Test-Memories

Konflikte werden nicht still ueberschrieben. Wenn zwei Aussagen wichtig
widersprechen, wird eine eigene Konflikt-Notiz retained:

```text
document_id: conflict:<topic>:<timestamp>
tags:
  project:<name>
  type:conflict-resolution
  status:current
  authority:source-of-truth

Inhalt:
  Alte Aussage: ...
  Neue Aussage: ...
  Gueltige Entscheidung: ...
  Grund: ...
  Ersetzt oder relativiert: ...
```

Cleanup-Regeln:

- `authority:source-of-truth` nie automatisch loeschen.
- `retention:short` fuer Debug-, Test- und Draftdaten.
- `retention:long` oder `retention:permanent` fuer Decisions, Runbooks und Migrationsnachweise.
- Permanente Deletes nur nach Dry-Run, Backup/Restore-Pruefung und Freigabe.

## 14. Mental Models Operationalisierung

Die alten 5 Mental Models bleiben als bestehender Stand und Migrationsquelle
dokumentiert. Zielstandard fuer Hindsight V1 sind 8 projektzentrierte Modelle.
Alle projektweiten Mental Models werden primaer mit `project:<name>` getaggt,
damit sie die gemeinsame Projektbank auswerten und nicht versehentlich nur
Memories eines einzelnen Frameworks lesen.

Zielmodelle:

```text
project-status-roadmap:
  Status, Roadmap, offene Punkte, naechste Schritte.

architecture-decisions:
  Architekturentscheidungen, Begruendungen, verworfene Alternativen.

agent-collaboration-workflow:
  Rollen, Uebergaben, Parallel-/Sequenziell-Regeln, Task-Fluss.

bank-tag-governance:
  Bank-Namen, Pflicht-Tags, Recall-Regeln, Sichtbarkeit.

versioning-conflict-cleanup:
  Upsert, Versionierung, Konflikte, Retention, Delete-Governance.

deployment-operations:
  K3s-Betrieb, Deployments, Healthchecks, Monitoring, Rollback.

backup-restore-migration:
  Server-1-Fallback, Dump/Export, Import, Restore-Tests, Validierung.

security-access-risk:
  Auth, Secrets, interne/externe Erreichbarkeit, NetworkPolicy, Risiken.
```

Operationalisierungsregeln:

- Mental Models muessen nicht nur selbst Tags tragen; auch die Seed- und
  Quell-Memories muessen passende Tags haben.
- Zu enge Tags wie nur `framework:codex` oder `agent:codex-docs` sind fuer
  projektweite Modelle zu vermeiden.
- Bei leerem Mental Model zuerst Tags und Quell-Memories pruefen, dann Query
  oder Modellprompt.
- Refresh/Validierung ist Teil der Migrationsabnahme.
- Erfolgreiche V1-Validierung verlangt, dass die 8 Modelle vorhanden sind,
  refreshen und nicht leer bleiben.

## 15. Migration

Empfehlung: erst frische K3s-Installation validieren, danach kontrollierter
Import aus lokalem Mac-Hindsight. Server-1-Docker-Hindsight bleibt vorerst
ignoriert und wird nur optional ganz am Ende geprueft.

Migrationsquellen:

- lokale Projektdateien aus `/Users/activi/Documents/Hindsight 2/`
- lokales Mac-Hindsight als primaere Datenquelle
- Server-1-Docker-Hindsight nur optional spaet, nach separater Freigabe
- alte Dumps nur Referenz, nicht verbindliche Quelle

Migrationsphasen:

1. Frische K3s-Hindsight-Installation ohne Altimport validieren.
2. Lokales Mac-Hindsight read-only inventarisieren.
3. Mapping `local-codex::<folder>--<hash>` nach `project:<name>`.
4. Zielbank `project:<name>` anlegen.
5. 8 Mental Models importieren.
6. Projektunterlagen/Runbooks/Handover kontrolliert retainen.
7. Ausgewaehlte Alt-Memories importieren oder Rohquellen neu retainen.
8. Vergleich/Validierung.
9. Optional Server-1-Docker-Hindsight read-only pruefen.
10. Cutover erst nach Freigabe.

## 16. Stop-Punkte

Sofort stoppen und fragen, wenn:

- Cluster-Istzustand vom App-Standard abweicht.
- Hindsight Zielimage keine festen Versionstags hat.
- ein Secret-Wert benoetigt oder sichtbar wuerde.
- Hindsight NodePort/LoadBalancer/ExternalName braucht.
- `local-path` verwendet werden soll.
- DB ohne CloudNativePG/Barman/pg_dump geplant wuerde.
- Restore-Test nicht definierbar ist.
- DNS/Firewall/Cloudflare geaendert werden muesste.
- Docker-Hindsight gestoppt oder veraendert werden muesste.
- Migrationsquelle unklar ist.
- Retain/Recall/Mental-Model-Verifikation nicht erfolgreich ist.

## 17. Risiken

- Hindsight Zielversion und Env-Variablen fuer Groq, Retain, Reflect, Consolidation und Embeddings muessen verifiziert werden.
- Docker-Altbestand kann Daten enthalten, die nicht sauber ueber dokumentierte APIs exportierbar sind.
- Mental-Model-Tags duerfen nicht zu eng sein, sonst refreshen Modelle leer.
- Embedding-Dimensionen duerfen nach gespeicherten Memories nicht ungeplant wechseln; Provider-/Modellwechsel gehoeren vor den ersten produktiven Import.
- Lokaler Cross-Encoder-Reranker kann CPU-seitig zum Recall-Latenz-Bottleneck werden; Ressourcen oder externer Reranker muessen vor Produktion bewertet werden.
- Embedding Provider ist fuer V1 als internes Ollama `bge-m3` umgesetzt.
- Ollama-Ressourcen muessen nach echten Import-/Recall-Lasten weiter beobachtet werden.
- DNS-/resolv.conf-Cleanup ist noch offener Cluster-Gap; kein harter Planungsstop, aber vor produktivem Livegang relevant.
- GitOps/External Secrets sind noch nicht final eingefuehrt.
- Oeffentlicher Zugriff braucht separates Sicherheitskonzept.

## 18. Installationsstand 2026-05-26

Die frische Hindsight-V1-Installation im K3s ist intern deployt. Server-1-Docker
Hindsight bleibt unveraendert und ist nicht die V1-Zielinstanz.

Deployter Stand:

- Namespace: `hindsight`
- API: `hindsight-api`, ClusterIP, kein Public Ingress
- Worker: `hindsight-worker`
- Dashboard/UI: `hindsight-ui`, ClusterIP, kein Public Ingress
- Datenbank: CloudNativePG `hindsight-postgres`, `3/3`, Longhorn PVCs
- Embeddings: internes Ollama mit `bge-m3`
- Reranker: lokaler MiniLM im Hindsight-Container
- LLM/Retain/Reflect/Consolidation: Groq `llama-3.3-70b-versatile`
- Longhorn RecurringJobs fuer Hindsight vorhanden
- Velero Schedule vorhanden
- pg_dump CronJob aktiv, manuell und per Schedule erfolgreich gelaufen
- pg_dump Restore-Test erfolgreich: SHA256 und gzip pruefbar
- Groq Healthcheck CronJob aktiv, manuell und per Schedule erfolgreich gelaufen

Verifiziert:

- API Health meldet `healthy` und DB `connected`
- Dashboard antwortet intern
- Ollama listet `bge-m3`
- Retain-/Recall-Smoke-Test mit Testbank erfolgreich
- `verify-hindsight-manifests.sh`: PASS
- `RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh`: PASS_WITH_GAPS
- `./run-baseline-gates.sh`: PASS

Weiterhin offen:

1. Public Ingress `hindsight.activi.io` erst nach separater Sicherheitsfreigabe.
2. Alertmanager-Routing/Benachrichtigungen fuer Hindsight/Groq/Backups final anbinden.
3. Bank-Mapping auf `project:<name>` technisch umsetzen.
4. Secret-Redaction im Retain-Pfad pruefen/haerten.
5. Mental Models und Directives final importieren.
6. Lokale Mac-Daten inventarisieren und Migration separat planen.
7. GitOps/External Secrets und Replacement-Node-DR-Drill als globale Plattform-Gaps erledigen.

Lokaler Codex-Hook-Stand:

- Bank-Mapping fuer neue Memories ist aktiv.
- Retain ergaenzt Governance-Tags automatisch.
- Secret-Redaction im Retain-Pfad ist aktiv und mit synthetischen Werten
  verifiziert.

Hinweis:

- Ein versehentlich ausgegebener MCP-Auth-Token wurde am 2026-05-26 sofort
  rotiert. Der neue Wert wurde nicht ausgegeben.

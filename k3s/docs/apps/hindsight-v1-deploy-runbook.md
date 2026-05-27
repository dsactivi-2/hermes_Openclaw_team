# Hindsight V1 Deploy-Runbook - activi K3s

Stand: 2026-05-27
Status: K3s-Deploy aktiv; Public Dashboard Ingress aktiv

## 1. Zweck

Dieses Runbook beschreibt den spaeteren Deploy-Ablauf fuer Hindsight V1 im
activi K3s-Cluster. Es ist eine Ausfuehrungsunterlage fuer den
Freigabeblock, veraendert aber selbst keine Cluster-Ressourcen.

Gueltige Hauptplanung:

```text
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-k3s-plan.md
```

Ergaenzende Unterlagen:

```text
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-migration-runbook.md
/Users/activi/Documents/activi K3s/docs/apps/hindsight-v1-memory-architecture.md
```

## 2. Deploy-Grundsatz

V1 ist eine saubere K3s-Neuaufsetzung mit kontrollierter Migration.

Nicht erlaubt ohne separate Freigabe:

- Namespace erstellen
- CloudNativePG Cluster erstellen
- PVCs erstellen
- Secrets erstellen oder aendern
- Helm installieren oder anwenden
- Manifest anwenden
- Ingress oeffentlich freigeben
- Docker-Hindsight auf Server 1 stoppen oder veraendern

## 3. Zielzustand

```text
namespace: hindsight
release: hindsight
service type: ClusterIP
storageClass: longhorn
database: CloudNativePG PostgreSQL + Longhorn PVC
backup: Barman Cloud Plugin + pg_dump CronJob + Velero + Longhorn
access V1: intern / VPN / in-cluster
reserved domain: hindsight.activi.io, public access later
public access: nicht in V1
```

Zielkomponenten:

- Hindsight API inklusive MCP-Endpunkt
- Hindsight Worker
- Hindsight UI, nur intern
- CloudNativePG Postgres
- pgvector Extension fuer externes PostgreSQL
- pg_dump CronJob
- ServiceMonitor
- PrometheusRule
- Velero Backup-Labels/Schedule
- NetworkPolicy nach finalem Zugriffskonzept

## 4. Stop-Punkte vor Deploy

Stoppen und klaeren, wenn einer dieser Punkte offen bleibt:

- kein expliziter Deploy-Freigabeblock
- Hindsight-Image ist nicht mit Digest gepinnt
- Postgres-/pgvector-Initialisierungsweg ist nicht verifiziert
- Secret-Werte muessten im Chat, Git oder Runbook stehen
- DB-PVC-Groesse ist nicht festgelegt
- Backup-Bucket/Pfad/Retention ist nicht festgelegt
- Restore-Test ist nicht geplant
- Service wuerde `NodePort`, `LoadBalancer` oder `ExternalName` brauchen
- StorageClass waere nicht `longhorn`
- Docker-Hindsight auf Server 1 muesste veraendert werden
- oeffentlicher Ingress waere fuer V1 erforderlich

## 5. Vorbereitende Entscheidungen

Vor dem Deploy muessen diese Werte konkret festgelegt werden:

```text
Hindsight API Image:
  ghcr.io/vectorize-io/hindsight:0.6.2@sha256:f0f9e9a73d6aedde9eaf4010ab604c3e015494e494318b26f1011144856b8112
Hindsight Worker Image:
  ghcr.io/vectorize-io/hindsight:0.6.2@sha256:f0f9e9a73d6aedde9eaf4010ab604c3e015494e494318b26f1011144856b8112
Hindsight UI Image:
  docker.io/library/node:24-alpine@sha256:2bdb65ed1dab192432bc31c95f94155ca5ad7fc1392fb7eb7526ab682fa5bf14
Postgres/pgvector Image:
  ghcr.io/cloudnative-pg/postgresql:16.9-standard-bookworm@sha256:ff90b6871a539ea68a740cd553b694e2217869821cafc87df8328d86be52db9d
CloudNativePG Clustername:
DB Name:
DB App User:
DB PVC Groesse:
API CPU/RAM Requests:
API CPU/RAM Limits:
Worker CPU/RAM Requests:
Worker CPU/RAM Limits:
UI CPU/RAM Requests:
UI CPU/RAM Limits:
pg_dump Schedule:
Barman Backup Retention:
Velero Schedule:
Internal Access Method:
```

Keine Annahme in dieser Liste darf als umgesetzt gelten, bis sie im
Freigabeblock bestaetigt ist.

## 6. Secret-Katalog

Nur Namen und Zweck, keine Werte:

```text
hindsight-groq-secret:
  Groq API Key fuer Default LLM, Retain, Reflect und Consolidation.

hindsight-postgres-app-secret:
  App-Credentials fuer Hindsight, vorzugsweise von CloudNativePG verwaltet.

hindsight-s3-backup-secret:
  S3 Credentials fuer Barman Cloud Plugin und/oder pg_dump Upload.

hindsight-mcp-auth-secret:
  MCP/API Auth Token fuer internen und spaeter gesicherten externen Zugriff.

hindsight-embedding-provider-secret:
  Provider-Key, falls Embeddings ueber API statt internem Endpoint laufen.

hindsight-image-pull-secret:
  Nur falls private Images genutzt werden.
```

Regel: Secret-Werte werden nie in Markdown, Chat, Logs oder Git dokumentiert.

## 7. Konfigurationsmatrix

Die exakten Env-Variablen muessen gegen die Zielversion verifiziert werden.
Geplanter Zielinhalt:

```text
Database:
  HINDSIGHT_API_DATABASE_URL

Auth:
  HINDSIGHT_API_MCP_AUTH_TOKEN

Retain:
  HINDSIGHT_API_RETAIN_LLM_PROVIDER=groq
  HINDSIGHT_API_RETAIN_LLM_MODEL=llama-3.3-70b-versatile
  retainMode=chunked
  retainEveryNTurns=1
  retainOverlapTurns=2
  retainExtractionMode=concise
  retainRoles=user,assistant
  retainToolCalls=true
  retainContext=codex
  retainMaxCompletionTokens=32768

Reflect:
  HINDSIGHT_API_REFLECT_LLM_PROVIDER=groq
  HINDSIGHT_API_REFLECT_LLM_MODEL=llama-3.3-70b-versatile

Consolidation:
  HINDSIGHT_API_CONSOLIDATION_LLM_PROVIDER=groq
  HINDSIGHT_API_CONSOLIDATION_LLM_MODEL=llama-3.3-70b-versatile

Recall:
  autoRecall=true
  recallBudget=low
  recallContextTurns=5
  recallMaxTokens=4096
  recallMaxQueryChars=3000
  recallTimeout=10s
  recallTypes=world,experience
  recallRoles=user,assistant

Embeddings:
  HINDSIGHT_API_EMBEDDINGS_PROVIDER=litellm-sdk
  HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_MODEL=ollama/bge-m3
  HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_API_BASE=<endpoint falls benoetigt>
  HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_API_KEY=ollama falls Ollama genutzt wird
  HINDSIGHT_API_EMBEDDINGS_LITELLM_SDK_ENCODING_FORMAT=

Reranker:
  HINDSIGHT_API_RERANKER_PROVIDER=local
  HINDSIGHT_API_RERANKER_LOCAL_MODEL=cross-encoder/ms-marco-MiniLM-L-6-v2
```

Offen vor Deploy:

- ob alle Variablennamen in der Zielversion exakt so gelten
- ob bge-m3 in V1 ueber Ollama intern, Ollama extern oder einen anderen API-kompatiblen Endpoint laeuft
- ob lokaler Reranker einen Cache-PVC braucht

## 8. Manifest-/Helm-Struktur

Empfohlene Struktur fuer den spaeteren Freigabeblock:

```text
deploy/hindsight/
  README.md
  values.yaml
  values-prod.yaml
  templates-or-manifests/
    namespace.yaml
    cloudnativepg-cluster.yaml
    cloudnativepg-backup.yaml
    hindsight-api-deployment.yaml
    hindsight-worker-deployment.yaml
    hindsight-ui-deployment.yaml
    services.yaml
    service-monitor.yaml
    prometheus-rule.yaml
    pgdump-cronjob.yaml
    network-policy.yaml
    velero-backup-schedule.yaml
```

Diese Struktur ist ein Vorschlag. Ob Helm, Kustomize oder plain Manifests
genutzt werden, bleibt vor Deploy final zu entscheiden.

## 9. Preflight-Checkliste

Read-only vor Freigabe pruefen:

```text
Cluster:
  K3s Nodes healthy
  IngressClass nginx vorhanden
  StorageClass longhorn default
  CloudNativePG Operator vorhanden
  Barman Cloud Plugin vorhanden
  Velero vorhanden
  kube-prometheus-stack vorhanden

App:
  Zielimages gepinnt
  Env-Variablen gegen Zielversion verifiziert
  Health-/Metrics-Endpunkte bekannt
  pgvector-Weg bekannt
  Ollama/bge-m3 Service und Modell-Pull geplant

Backup:
  S3 Ziel bekannt
  Barman Retention bekannt
  pg_dump Schedule bekannt
  Velero Schedule bekannt
  Restore-Test geplant

LLM:
  Groq direkter Provider, kein LiteLLM in V1
  Groq Healthcheck CronJob vorbereitet
  automatischer Provider-Fallback erst spaeterer V1.1-Ausbau

Migration:
  lokale Mac-Hindsight-Quelle ist primaere spaetere Migrationsquelle
  Server-1 Docker-Hindsight wird nicht als Zielbasis genutzt
  Bank-Mapping dokumentiert
  Abnahmekriterien dokumentiert
```

## 10. Deploy-Sequenz nach Freigabe

Nur nach separater Freigabe ausfuehren:

1. Namespace `hindsight` erstellen.
2. Labels fuer Velero, Monitoring und Governance setzen.
3. Secrets aus freigegebener Secret-Quelle erstellen.
4. CloudNativePG Cluster mit Longhorn PVC erstellen.
5. pgvector Extension initialisieren oder verifizieren.
6. Barman Cloud Plugin Backup aktivieren.
7. Hindsight API deployen.
8. Hindsight Worker deployen.
9. Hindsight UI intern deployen.
10. ClusterIP Services erstellen.
11. Ollama Service deployen und `bge-m3` Model-Pull-Job ausfuehren.
12. Auth/API-Token-Verhalten fuer Dashboard und interne Agenten pruefen.
13. ServiceMonitor aktivieren.
14. PrometheusRule aktivieren.
15. pg_dump CronJob aktivieren.
16. Groq Healthcheck CronJob nach Secret-/Image-Freigabe aktivieren.
17. NetworkPolicy aktivieren.
18. Interne Erreichbarkeit pruefen.
19. Retain/Recall Healthcheck ausfuehren.
20. Migration separat nach Migration-Runbook starten.
21. Public-Ingress fuer `hindsight.activi.io` spaeter separat planen.

## 11. Post-Deploy-Validierung

V1 gilt erst als technisch lauffaehig, wenn diese Checks bestanden sind:

```text
API:
  /health healthy
  DB connected
  MCP Endpoint intern erreichbar

Worker:
  Pods ready
  keine CrashLoops
  Retain Job verarbeitet Fakten

UI:
  intern erreichbar
  keine oeffentliche Freigabe

Database:
  CloudNativePG Cluster healthy
  pgvector verfuegbar
  Barman Backup erfolgreich oder initial geplant

Backup:
  pg_dump CronJob erzeugt pruefbaren Dump
  Velero Namespace Backup geplant
  Restore-Test definiert

Memory:
  Retain extrahiert Fakten
  Recall findet Testfakten
  8 Mental Models vorhanden
  Mental Models refreshen und bleiben nicht leer
```

## 12. Rollback

Rollback-Grundsatz:

- Alt-Systeme bleiben bis zur erfolgreichen K3s-Abnahme unveraendert.
- Bei V1-Problemen wird kein Altbestand geloescht.
- Externe Agenten bleiben auf ihrem bisherigen Fallback, bis Cutover freigegeben ist.

Rollback-Ausloeser:

- API nicht stabil
- DB nicht stabil
- Retain extrahiert wieder `0` Fakten
- Recall findet Migrationsdaten nicht
- Backups nicht pruefbar
- Mental Models leer oder fehlerhaft
- Auth/Zugriff nicht sicher

## 13. Abnahmekriterien

Deploy-Freigabe ist nicht gleich Produktionsfreigabe. V1 ist bereit fuer
Produktions-Cutover, wenn:

- alle Post-Deploy-Checks bestanden sind
- Migration validiert ist
- Backup und Restore mindestens einmal getestet sind
- bisheriger Fallback weiterhin verfuegbar ist
- Zugriff intern/VPN funktioniert
- keine oeffentliche Freigabe ohne Sicherheitskonzept besteht
- User erteilt separate Cutover-Freigabe

## 14. Installationsstand 2026-05-26

K3s-Installation wurde am 2026-05-26 intern ausgefuehrt. Der oeffentliche
Dashboard-Ingress fuer `hindsight.activi.io` wurde am 2026-05-27 nach
separater Freigabe erstellt.

Aktueller Live-Stand:

- `hindsight-api`: `1/1 Running`
- `hindsight-worker`: `1/1 Running`
- `hindsight-ui`: `1/1 Running`
- `hindsight-ollama`: `1/1 Running`
- `hindsight-postgres`: CloudNativePG `3/3`, Cluster healthy
- `bge-m3`: in Ollama geladen
- API Health: `{"status":"healthy","database":"connected"}`
- Dashboard: intern auf Port `9999` erreichbar
- Public Dashboard: `https://hindsight.activi.io/` leitet auf `/dashboard`
  weiter; `https://hindsight.activi.io/dashboard` liefert `HTTP 200`
- Ingress: `hindsight/hindsight`, IngressClass `nginx`
- TLS: Zertifikat `hindsight-tls` ist `Ready=True`

Wichtige Live-Fixes waehrend der Installation:

- `HINDSIGHT_API_PORT` explizit auf `8888` gesetzt, weil Kubernetes sonst
  wegen des Service-Namens eine gleichnamige Service-Env mit `tcp://...`
  injiziert.
- NetworkPolicy fuer Postgres/Ollama/CNPG/Kubernetes-API ergaenzt.
- ResourceQuota erhoeht, damit drei CNPG-Instanzen, API, Worker, UI und
  Ollama gleichzeitig laufen koennen.
- `pgvector` in der Application-DB `hindsight` aktiviert und Manifest auf
  `postInitApplicationSQL` korrigiert.

Verifikation:

- `verify-hindsight-manifests.sh`: PASS
- `RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh`: PASS_WITH_GAPS
- `./run-baseline-gates.sh`: PASS
- pg_dump CronJob aktiv; manueller und geplanter Job erfolgreich
- pg_dump Restore-Test erfolgreich: SHA256 und gzip pruefbar
- Groq Healthcheck CronJob aktiv; manueller und geplanter Job erfolgreich
- Retain-/Recall-Smoke-Test gegen Testbank erfolgreich

Bekannte offene Punkte nach der Installation:

- Alertmanager-Routing/Benachrichtigungen fuer Hindsight/Groq/Backups werden
  spaeter gemeinsam final verdrahtet.
- Bank-Mapping, Secret-Redaction und Mental Models folgen nach separatem
  Migrations-/Konfigurationsblock.
- Lokale Mac-Hindsight-Daten werden erst nach read-only Inventar migriert.
- Server-1-Docker-Hindsight bleibt fuer V1 ignoriert und nur optionale spaete
  Migrationsquelle.

Sicherheitsnotiz:

- Ein versehentlich ausgegebener MCP-Auth-Token wurde am 2026-05-26 sofort
  rotiert. Der neue Wert wurde nicht ausgegeben.

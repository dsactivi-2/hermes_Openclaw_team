# Open TODOs - 2026-05-22

Stand: 2026-05-25 03:47 CEST.

Dieses Dokument ist die aktuelle Arbeitsliste nach dem erfolgreichen
Portainer-Ingress/TLS-, NodePort-Hardening-, OS-Restic- und
Portainer-Longhorn-Migrationsblock.

## Aktueller Stand 2026-05-24

Aktuell erledigt sind Portainer Business auf Longhorn mit Ingress/TLS, Longhorn
als Default StorageClass, Velero Smoke Backup/Restore, CloudNativePG Operator +
Barman Cloud Plugin Smoke Backup/Restore, der interne Monitoring-Basisstack und
die Monitoring-Nacharbeit fuer node-exporter/Server-3-SSH-Pruefpfad.

Letzte gepruefte Baseline dieser Session:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-191109.log
RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-191206.log
RESULT: PASS
Passes: 131
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-191352.log
RESULT: PASS_WITH_GAPS
Passes: 26
Warnings: 0
Gaps: 4
Failures: 0

/tmp/portainer-api-connectivity-20260524-191423.log
RESULT: PASS
Passes: 7
Failures: 0
```

Aktueller Recheck nach dem Portainer-UI-Finalcheck:

```text
/tmp/portainer-api-connectivity-20260524-225815.log
RESULT: FAIL
Passes: 6
Failures: 1

Direkte Kubernetes-API-Konnektivitaet aus dem Portainer-Pod war stabil:
10.0.1.10:6443 ok=60 fail=0
10.0.1.20:6443 ok=60 fail=0
10.0.1.30:6443 ok=60 fail=0
10.43.0.1:443 ok=60 fail=0

Failure-Ursache laut Script: aktuelle Portainer-Logs enthalten weiterhin
`Panic in request handler` bei Kubernetes-Watch-Requests ueber Portainers
Kubernetes-Reverse-Proxy.
```

Bewertung: Die Kubernetes-API und die Netzwerkverbindung sind stabil. Offen ist
eine Portainer-UI/API-Proxy-Diagnose fuer Watch-Requests, bevor Portainer als
vollstaendig sauber bewertet wird.

Aktuell harte technische Gaps laut Production-Readiness-Audit:

- produktive `pg_dump`-Automation pro App ist noch nicht live fuer eine App
  eingerichtet; Standardtemplate und Image-Definition werden als vorbereiteter
  Baustein gefuehrt;
- GitOps;
- SOPS fuer GitOps-Secrets; External Secrets/Vault nur spaeter bei echtem
  Bedarf fuer zentralen Secret-Store;
- vollstaendiger Replacement-Node-DR-Drill.

Zusaetzliche offene Betriebsreife-/Zielsetup-Punkte:

- DNS/resolv.conf-Cleanup als separater Block;
- Smoke-/Test-Ressourcen Cleanup-Plan fuer `longhorn-test`, Velero-Smoke und
  CNPG-Smoke/Restore;
- Doku-Cleanup fuer historische Datumsnamen, alte Gap-Zahlen und ueberholte
  Aussagen zu Velero/CNPG/Monitoring;
- ResourceQuotas und LimitRanges pro produktivem Namespace planen;
- NetworkPolicies pro App-Namespace planen, idealerweise Default-Deny plus
  erlaubte Wege zu Ingress, DNS, Monitoring und Datenbank;
- Portainer-Longhorn-Volume echten Restore-Test planen;
- Alertmanager als letzter Monitoring-Ausbauschritt fertigstellen: externe
  Receiver, Test-Alert und Alarm-Runbook gemeinsam per YAML/Secret ohne
  Secret-Ausgabe einrichten. Dabei explizit Meta-Alerts fuer
  `BlackboxExporterDown`, `AlertmanagerDown`, fehlende Prometheus-Targets und
  optional einen externen Kontrollcheck einplanen, damit die Alarmkette selbst
  nicht unbemerkt ausfaellt;
- Host-/Docker-Restbestand final inventarisieren und bewusst migrieren oder
  behalten;
- Kubeconfig-/API-Zugaenge haerten: Least-Privilege, Token-Laufzeiten, keine
  unsicheren TLS-Optionen fuer produktive Zugaenge;
- App-Onboarding als Pflicht-Gate vor Deployments erzwingen: Storage, Ingress,
  Secrets, DB-Backup, Velero Schedule, Longhorn RecurringJobs, Monitoring und
  Restore-Plan je App.
- Velero Schedules pro produktivem App-Namespace planen und dokumentieren.
- Longhorn Volume-RecurringJobs pro neuer produktiver PVC/App-Gruppe planen
  und dokumentieren.
- CloudNativePG/Barman WAL-Backups pro produktiver Datenbank planen und
  dokumentieren.
- Echten Restore-Test pro App verpflichtend machen, nicht nur allgemeinen
  DR-Drill.
- Klare App-Regel: Jede produktive App braucht Longhorn-Storage,
  Velero-Backup, DB-Backup falls Datenbank vorhanden, und einen dokumentierten
  Restore-Test.
- App-Postgres-Backup-Standard in App-Onboarding aufnehmen: Template,
  Secret-Vertrag, eigenes Backup-Image, Failure-/Success-Healthcheck und
  Restore-Test-Pflicht.
- Portainer API-/UI-Watch-Proxy-Panic read-only diagnostizieren:
  Kubernetes API ist stabil erreichbar, aber Portainer loggt `Panic in request
  handler` bei Kubernetes-Watch-Requests.

Historische Gap-Zahlen in der erledigten Chronologie darunter sind
Zeitpunkt-Snapshots und nicht der aktuelle offene Gap-Stand.

Zentrale Uebergabe fuer neue Agenten:

```text
/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
```

Deploy-Pipeline Nebenprojekt fuer kuenftige App-Deployments:

```text
/Users/activi/Documents/activi K3s/docs/DEPLOY-PIPELINE-SIDEPROJECT-2026-05-27.md
```

Status: geplant und als Agentenauftrag vorbereitet. Noch nicht als gebautes
und verifiziertes Pipeline-System bestaetigt. Vor produktiver Nutzung muss der
Agenten-Output gegen die Pruefliste im Dokument verifiziert werden:
Ordnerstruktur, `deploy-pipeline.sh`, Phasen-Prompts, Report-Vertrag, Locks,
`doctor`, Dummy-App-Test, `bash -n`/Shellcheck und keine Cluster- oder
Secret-Aenderungen.

## Geklaerte Entscheidungen 2026-05-24

- Zentrale Projektunterlagen sollen ins Git: `OPEN-TODOS-2026-05-22.md`,
  App-Integration-Standard, App-Onboarding-Fragebogen, Handover-/Prompt-
  Dateien und Runbooks. `.DS_Store`, temporaere Logs und lokale Arbeitsreste
  sollen nicht aufgenommen werden.
- Portainer UI ist erweitert read-only geprueft: Business Edition aktiv, Login
  ok, ein Access Token `admin` sichtbar ohne Secret-Wertausgabe, DockerHub
  Registry vorhanden, Bitnami Helm Repo global gesetzt, Kubernetes Environment
  sichtbar, Users/Teams/Roles, License, Authentication, Shared Credentials,
  Edge Compute, Alerting/Observability, Notifications und Logs wurden
  gesichtet. Offen bleibt die Diagnose der Portainer-Proxy-Panic in den Logs
  sowie spaetere Settings-Aenderungen nur nach separater Freigabe.
- Testressourcen bleiben vorerst als Belege erhalten: `longhorn-test`,
  Velero-Smoke und CNPG-Smoke/Restore. Cleanup nur spaeter als separater Block
  mit Freigabe.
- DNS/resolv.conf hat bisher nur einen Read-only-Befund. Ein konkreter
  Rollout-Vorschlag fehlt noch und muss separat geplant werden.
- Externer Alertmanager-Receiver wird bewusst spaeter als letzter
  Monitoring-Ausbauschritt eingerichtet. Ziel: interne Alerts zuerst sauber
  definieren, danach gemeinsam Receiver wie E-Mail, Telegram/Webhook,
  Healthchecks oder Matrix per YAML/Secret ohne Secret-Ausgabe konfigurieren.
- S3-Credential-Rotation ist noch nicht ausgefuehrt. Betroffen sein koennen
  K3s etcd-S3, Server-1 Restic, Server-2/3 OS-Restic, Longhorn, Velero und
  CNPG/Barman. Vor Rotation sind Inventar und Reihenfolge Pflicht.
- GitOps/Secrets-Zielentscheidung: Argo CD + SOPS als pragmatischer Standard.
  External Secrets/Vault spaeter nur bei echtem Bedarf fuer zentralen
  Secret-Store pruefen.
- Naechste produktive App ist noch nicht final entschieden. Kandidaten:
  Healthchecks-Migration, Hindsight/Postgres-Migration oder Matrix. Vor jedem
  App-Deployment gilt der App-Onboarding-Fragebogen.
- DR-Test: Es gibt noch keine Ersatznodes und kein Zeitfenster. Erst
  schriftlichen DR-Plan erstellen, danach echten Replacement-Node-Drill mit
  Freigabe.
- Kubeconfig-/API-Zugaenge: keine vollstaendige Zugangsliste dokumentiert.
  Admin-Zugaenge, Tokens, Kubeconfigs und Maschinenzugriffe muessen ohne
  Secret-Werte inventarisiert und gehaertet werden.
- Weitere Steuerungsentscheidungen:
  - Git-Aufnahme der zentralen Doku ja, aber als eigener Doku-Block: vorher
    pruefen, welche Dateien wirklich ins Git sollen; `.DS_Store`, temporaere
    Dateien und lokale Arbeitsreste ausschliessen; danach sauberer Doku-Commit.
  - Naechster kleiner operativer Block: Portainer API-/UI-Watch-Proxy-Panic
    read-only diagnostizieren; Portainer-Settings erst danach als separate
    freigegebene Mini-Bloecke aendern.
  - Alertmanager-Ziel: ganz zum Schluss gemeinsam konfigurieren; externe
    Meldungen ueber YAML/Secret einrichten, ohne Secret-Werte auszugeben.
  - GitOps/Secrets-Zielentscheidung: Argo CD + SOPS als pragmatischer Standard.
    External Secrets/Vault spaeter nur bei echtem Bedarf fuer zentralen
    Secret-Store pruefen.
  - App-Prioritaet: zuerst Healthchecks, danach Hindsight/Postgres, danach
    Matrix. Vor jeder App bleibt der App-Onboarding-Fragebogen Pflicht.
  - Doku-Cleanup als eigener risikoarmer Block vor groesseren Arbeiten:
    historische Stellen markieren, aktuelle Baseline klar machen, zentrale
    untracked Docs sauber aufnehmen.
- Fuehrungsmodus: fuer jeden Block erst kurze Freigabeplanung; nach Freigabe
    ein ausfuehrbarer Agenten-Auftrag mit festem Rueckgabeformat.

## Neue vorbereitete Standards 2026-05-25

- Baseline-Master-Check als read-only Wrapper:
  `run-baseline-gates.sh`.
- Backup-Overview als read-only Gesamtuebersicht:
  `verify-backup-overview.sh`.
- Daily-Health-Check als read-only Tagespruefung:
  `run-daily-health-check.sh`.
- PostgreSQL-`pg_dump`-Backup-Standard vorbereitet:
  - `templates/app-backup/pgdump-cronjob.template.yaml`
  - `templates/app-backup/serviceaccount.template.yaml`
  - `templates/app-backup/app-postgres-backup-env.example.yaml`
  - `images/pgdump-s3/Dockerfile`
  - `verify-app-backup-template.sh`
- App-Onboarding-Gate vorbereitet:
  - `verify-app-onboarding-gate.sh`
- Healthchecks als erste App vorbereitet und Basisdeployment live ausgefuehrt:
  - `docs/apps/healthchecks-k3s-onboarding-2026-05-25.md`
  - Server-1-Read-only-Inventar am 2026-05-25 abgeschlossen: Docker Compose
    `/opt/healthchecks/docker-compose.yml`, Container `healthchecks` healthy,
    Image `healthchecks/healthchecks:latest`, Port `8000`, Volume
    `healthchecks_healthchecks_data`, SQLite-Datenbank `hc.sqlite` ca. `340K`,
    alte Healthchecks-Tarballs unter `/root/k3s-migration-backup`.
  - Zielentscheidungen dokumentiert: `https://healthchecks.activi.io`,
    SQLite auf Longhorn `1Gi`, Image-Digest statt `latest`,
    Ziel-Secret `healthchecks-app-env`, Docker bleibt Rollback.
  - Manifest-Entwuerfe vorbereitet unter `manifests/healthchecks/`:
    Namespace, ResourceQuota/LimitRange, ConfigMap, Secret-Schema, PVC,
    Deployment, Service, Ingress, NetworkPolicy, Velero-Schedule sowie
    Backup-/Restore-Templates.
  - Basisdeployment am 2026-05-25 ausgefuehrt: Namespace `healthchecks`,
    Secrets als Metadaten, Longhorn-PVC `healthchecks-data`, SQLite-Lift-and-
    Shift, Deployment, Service, Ingress, NetworkPolicies, ResourcePolicy und
    Velero Schedule.
  - Live-Beleg: Deployment `healthchecks` `1/1`, Pod
    `healthchecks-78f6f4469b-zdx7p` `Running`, `0` Restarts; PVC `Bound`
    auf Longhorn; Zertifikat `healthchecks-tls` `Ready=True`; ACME Order
    `valid`; externer Smoke-Test `https://healthchecks.activi.io` liefert
    `HTTP/2 302` auf `/accounts/login/`.
  - Baseline nach Deployment: `/tmp/k3s-baseline-gates-20260525-201103.log`,
    `RESULT: PASS`.
  - Manifest-Check: `verify-healthchecks-manifests.sh`,
    `RESULT: PASS`, `Passes: 48`, `Warnings: 0`, `Gaps: 0`,
    `Failures: 0`, Log
    `/tmp/healthchecks-manifests-verify-20260525-221656.log`.
  - Deploy-Gate nach Deployment:
    `/tmp/healthchecks-deploy-gate-20260525-203526.log`,
    `RESULT: PASS_WITH_GAPS`, `Passes: 19`, `Warnings: 2`, `Gaps: 1`,
    `Failures: 0`.
  - App-Onboarding-Gate nach Doku-Aktualisierung:
    `/tmp/k3s-app-onboarding-gate-20260525-203212.log`, `RESULT: PASS`,
    `Passes: 41`, `Warnings: 0`, `Gaps: 0`, `Failures: 0`.
  - SQLite-S3-Backup/Restore am 2026-05-25 live verifiziert: CronJob
    `healthchecks-sqlite-backup`, Schedule `27 3 * * *`, manueller Job
    `healthchecks-sqlite-backup-manual-20260525-2224` `Complete`, Objekt
    `s3://miniotest/healthchecks/sqlite/healthchecks-20260525T203919Z.sqlite.gz`,
    SHA256 `6156529e1b3e31ea3cbfbb8f05d222a544f438eba8c987f94686c259f839a149`,
    `SQLITE_INTEGRITY=ok`; Restore-Job `healthchecks-sqlite-restore-test`
    `Complete`, `RESTORE_SHA256_MATCH=ok`, `SQLITE_TABLES=24`.
  - Fehlgeschlagene manuelle Backup-Testjobs aus der Fehleranalyse wurden nach
    separater Cleanup-Freigabe geloescht:
    `healthchecks-sqlite-backup-manual-20260525-2109`,
    `healthchecks-sqlite-backup-manual-20260525-2122`,
    `healthchecks-sqlite-backup-manual-20260525-2145`,
    `healthchecks-sqlite-backup-manual-20260525-2157`.
  - Longhorn RecurringJobs fuer `healthchecks-data` sind live verifiziert:
    `healthchecks-snapshot-hourly` Snapshot `17 * * * *`, Retain `48`;
    `healthchecks-backup-daily` Backup `47 1 * * *`, Retain `14`;
    `healthchecks-backup-weekly` Backup `22 3 * * 0`, Retain `8`; Gruppe
    `app-healthchecks`; Volume `pvc-f3646e24-e2c8-44f4-8e2d-0241bfca5f71`
    traegt `recurring-job-group.longhorn.io/app-healthchecks=enabled`.
  - Baseline nach Healthchecks-Longhorn-Nacharbeit:
    `/tmp/k3s-baseline-gates-20260525-235629.log`, `RESULT: PASS`,
    `Passes: 4`, `Failures: 0`.
  - Monitoring/Blackbox-Probe am 2026-05-26 live eingerichtet: Blackbox Exporter
    `monitoring/blackbox-exporter` `1/1`, Probe
    `monitoring/healthchecks-external`, PrometheusRule
    `monitoring/healthchecks-external-probe`; direkter Probe-Wert
    `probe_success 1`; Prometheus sammelt
    `probe_success{job="healthchecks-external"} = 1`.
  - Naechster Healthchecks-Punkt: spaeterer Docker-Rollback-Cleanup nach
    separater Freigabe.

Diese Dateien deployen nichts und enthalten keine echten Secret-Werte. Pro App
bleiben Namespace, DB-Service, Backup-User, S3-Prefix, Secret-Erzeugung,
Healthchecks/Webhook und Restore-Test verpflichtend zu bestaetigen.

## Erledigt

- 3-Node K3s HA ist aktiv und verifiziert.
- Backup Phase 1 ist aktiv: K3s etcd-S3, Server-1-Restic, Hindsight Dumps,
  Timer, Restore-Test.
- OS-Restic Server 2/3 ist live bestaetigt aktiv, hourly, Retention
  `48/14/8/12`, mit Restore-Tests. Beleg: Full Verify
  `/tmp/k3s-stack-complete-verify-20260524-191206.log`, `RESULT: PASS`;
  Server 2 und Server 3 jeweils 50 Snapshots, `restic check` ohne Fehler.
- Longhorn ist installiert, validiert und seit 2026-05-24 die einzige Default
  StorageClass.
- Longhorn Test-PVC, Volume-Backup/Restore, SystemBackup und
  SystemBackup-RecurringJob sind validiert.
- ingress-nginx, cert-manager und `letsencrypt-prod` sind aktiv.
- `https://portainer.activi.io` ist erreichbar, HTTP leitet auf HTTPS um.
- Portainer Service ist `ClusterIP`; clusterweit existieren keine NodePorts.
- Portainer ist auf Longhorn migriert:
  `portainer/portainer-longhorn`, Longhorn Volume healthy, drei Replicas.
- Alter Portainer-`local-path` PVC bleibt als Rollback-Beleg erhalten.
- Portainer/Kubernetes-API-Timeouts sind behoben:
  Hetzner Robot Firewall `tcp established` ACK-Rueckregel auf allen drei
  Servern mit Quell-Port `0-65535`, Ziel-Port `0-65535`, `TCP-Flags=ack`.
- Neues Pruefskript fuer diesen Pfad:
  `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`.
- Rebuild-Bundle ohne Secret-Inhalte wurde erzeugt:
  `/Users/activi/Documents/activi K3s/exports/k3s-rebuild-bundle-20260522-032642.tar.gz`.
- Longhorn-Portainer-Backup-Skript wurde angelegt:
  `/Users/activi/Documents/activi K3s/run-portainer-longhorn-backup.sh`.
- Backup-Zwischenstopp vor Portainer-Business-Edition wurde ausgefuehrt:
  - Dry-Run: `RESULT: DRY-RUN PASS`.
  - SystemBackup `lh-system-backup-pre-be-20260523-034408`: `Ready`.
  - Snapshot `portainer-pre-be-snap-20260523-034408`: `readyToUse=true`.
  - Volume-Backup `portainer-pre-be-backup-20260523-034408`: `Completed`, `progress=100`.
  - Afterflight: `RESULT: AFTERFLIGHT PASS`.
- Portainer Business Edition 3 Nodes Free wurde in der UI aktiviert:
  Login klappt, Business-Lizenz wird angezeigt.
- Portainer UI-Finalcheck wurde read-only per UI/Screenshots/PDFs/CSV
  weitgehend durchgefuehrt:
  - Portainer Business Edition `2.39.2 LTS`.
  - Lizenz `activi`, `3/3 nodes used`, Ablauf `2027-05-23`.
  - Environment `local`, Kubernetes `v1.32.1+k3s1`, 3 Nodes, Status `Up`.
  - DockerHub Registry vorhanden; weitere Registries spaeter eigener Block.
  - Bitnami Helm Repository `https://charts.bitnami.com/bitnami` gesetzt.
  - Users/Teams/Roles, License, Authentication, Shared Credentials,
    Edge Compute, Alerting/Observability, Notifications und Logs gesichtet.
  - Ein Portainer Access Token `admin` ist sichtbar; kein Token-Wert wurde
    ausgegeben oder dokumentiert.
  - CSV-/PDF-Exporte aus der UI gelten als lokal/sensibel und duerfen nicht
    ohne Review ins Git.
- Portainer-Clusteransicht wurde read-only geprueft:
  - 3 Control-Plane-Nodes `Ready`, alle `EtcdIsVoter`, Version
    `v1.32.1+k3s1`.
  - Dashboard-Zaehler: 16 Namespaces, 30 Applications, 31 Services,
    1 Ingress, 60 ConfigMaps, 48 Secrets, 9 Volumes.
  - Einziger sichtbarer Ingress: `portainer.activi.io -> portainer:9443`.
  - Nameserver-Limit-Warnings im Namespace `monitoring` bestaetigen den
    offenen DNS-/resolv.conf-Cleanup.
- Doku-Cleanup und erste Git-Aufnahme wurden vorbereitet:
  - `.gitignore` und 10 zentrale Doku-Dateien sind gezielt staged.
  - Kein Commit wurde erstellt.
  - Root-Skripte, Tests, App-Projekte, Exporte, Logs und historische
    Zusatzdokus bleiben ausserhalb dieser ersten Staging-Welle.
- Storage-/K3s-Istzustand wurde am 2026-05-24 02:45 CEST erneut verifiziert:
  `longhorn` ist einzige Default StorageClass, `local-path` ist vorhanden aber
  nicht Default, `portainer/portainer-longhorn` ist der aktive produktive PVC,
  der alte `portainer/portainer` PVC ist ungenutzter Rollback-Altbestand.
- Read-only Audit nach Business-Aktivierung:
  `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260523-041234.log`.
- Letzte Abschlusspruefungen nach dem Portainer-Longhorn-Volume-Backup:
  - Portainer API Connectivity im Audit: alle Ziele stabil.
  - Audit: `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`,
    Log `/tmp/k3s-recent-stack-claims-audit-20260523-034620.log`.
  - Full Verify: `RESULT: PASS`, `Passes: 126`, `Warnings: 0`,
    `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260523-034758.log`.
- Frische Abschlusspruefungen nach Storage-Default- und Istzustandspruefung:
  - Storage Default Audit: `RESULT: PASS`,
    Log `/tmp/k3s-storage-default-audit-20260524-024143.log`.
  - Recent Audit: `RESULT: PASS`, `Passes: 53`, `Warnings: 0`,
    `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260524-024216.log`.
  - Full Verify: `RESULT: PASS`, `Passes: 126`, `Warnings: 0`,
    `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260524-024259.log`.
  - Production Readiness Gaps: `RESULT: PASS_WITH_GAPS`, `Passes: 21`,
    `Warnings: 0`, `Gaps: 9`, `Failures: 0`,
    Log `/tmp/k3s-production-readiness-gap-audit-20260524-024431.log`.
- Longhorn Volume-RecurringJobs fuer das produktive Portainer-Longhorn-Volume
  sind aktiv und verifiziert:
  - `prod-snapshot-hourly`: `snapshot`, Cron `7 * * * *`, Retain `48`,
    Gruppe `prod-critical`.
  - `prod-backup-daily`: `backup`, Cron `37 1 * * *`, Retain `14`,
    Gruppe `prod-critical`.
  - `prod-backup-weekly`: `backup`, Cron `12 3 * * 0`, Retain `8`,
    Gruppe `prod-critical`.
  - Nur `portainer/portainer-longhorn` beziehungsweise Longhorn Volume
    `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b` ist in `prod-critical`.
  - Keine Jobs auf `default`; Testvolumes sind nicht aufgenommen.
  - Aktuelle Pruefung: Full Verify `RESULT: PASS`, `Passes: 131`,
    `Warnings: 0`, `Failures: 0`,
    Log `/tmp/k3s-stack-complete-verify-20260524-030246.log`.
  - Production Readiness Gaps danach: `RESULT: PASS_WITH_GAPS`, `Gaps: 8`,
    Log `/tmp/k3s-production-readiness-gap-audit-20260524-030429.log`.
- Velero ist installiert und nicht-destruktiv restore-getestet:
  - Version `1.18.0`, Chart `velero-12.0.1`, Namespace `velero`.
  - BackupStorageLocation `default` ist `Available`.
  - S3 Bucket/Prefix: `activi/velero`.
  - Smoke Backup `velero-smoke-backup-20260524`: `Completed`.
  - Smoke Restore `velero-smoke-restore-20260524`: `Completed`.
  - Source Namespace `velero-smoke-source-20260524`, Restore Namespace
    `velero-smoke-restore-20260524`.
  - Keine produktiven Namespaces/PVCs, Portainer-, Longhorn-, StorageClass-,
    Firewall- oder DNS-Einstellungen wurden veraendert.
  - Finale Pruefungen:
    - Recent Audit `RESULT: PASS`,
      Log `/tmp/k3s-recent-stack-claims-audit-20260524-035713.log`.
    - Full Verify `RESULT: PASS`,
      Log `/tmp/k3s-stack-complete-verify-20260524-035800.log`.
    - Production Readiness `RESULT: PASS_WITH_GAPS`, `Gaps: 7`,
      Log `/tmp/k3s-production-readiness-gap-audit-20260524-035937.log`.
    - Portainer API Connectivity `RESULT: PASS`,
      Log `/tmp/portainer-api-connectivity-20260524-040004.log`.
- Globale Vorlagen fuer neue App-Projekte wurden angelegt:
  - `/Users/activi/Documents/activi K3s/docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md`
  - `/Users/activi/Documents/activi K3s/docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md`
  Neue App-Agenten muessen diese Dateien lesen und app-spezifische Sollwerte in
  einer eigenen Antwort-/Values-Datei dokumentieren.
- CloudNativePG ist als nicht-produktiver Test-/Backup-Baustein installiert und
  restore-getestet:
  - Operator `1.29.1`, Helm Chart `cloudnative-pg-0.28.2`, Namespace
    `cnpg-system`.
  - Barman Cloud Plugin `v0.12.0`, Deployment `cnpg-system/barman-cloud`,
    `Ready 1/1`.
  - Deprecated `barmanObjectStore`-Clusterpfad wurde nicht verwendet.
  - Source Namespace `cnpg-smoke-20260524`, Cluster `cnpg-smoke`,
    StorageClass `longhorn`, 1Gi.
  - ObjectStore `cnpg-smoke-store`, S3 Bucket/Prefix
    `activi/cloudnativepg/smoke-20260524`.
  - WAL/Backup `ContinuousArchiving=True:ContinuousArchivingSuccess`.
  - Backup `cnpg-smoke-backup-20260524`: `phase completed`.
  - `pg_dump`-Test `cnpg-smoke-pgdump-retry-20260524`: erfolgreich.
  - Restore Namespace `cnpg-smoke-restore-20260524`, Cluster
    `cnpg-smoke-restore`, Testdaten nach Restore vorhanden.
  - Keine produktiven Datenbanken, Namespaces oder PVCs wurden veraendert.
  - Finale Pruefungen:
    - Recent Audit `RESULT: PASS`,
      Log `/tmp/k3s-recent-stack-claims-audit-20260524-052300.log`.
    - Full Verify `RESULT: PASS`,
      Log `/tmp/k3s-stack-complete-verify-20260524-052352.log`.
    - Production Readiness `RESULT: PASS_WITH_GAPS`, `Gaps: 5`,
      Log `/tmp/k3s-production-readiness-gap-audit-20260524-052527.log`.
    - Portainer API Connectivity `RESULT: PASS`,
      Log `/tmp/portainer-api-connectivity-20260524-052603.log`.
- Monitoring-Basisstack ist installiert:
  - Release `kube-prometheus-stack`, Namespace `monitoring`, Chart `85.3.0`,
    App Version `v0.90.1`.
  - Prometheus, Alertmanager, Grafana, kube-state-metrics und node-exporter
    sind installiert.
  - Kein Grafana-Ingress, keine NodePorts, keine LoadBalancer, kein externer
    Alert-Receiver.
  - PVCs auf `longhorn`: Prometheus `10Gi`, Alertmanager `2Gi`, Grafana `5Gi`.
  - Prometheus, Alertmanager und Grafana sind Ready.
  - Portainer, Longhorn, Velero und CloudNativePG blieben healthy.
  - Monitoring-Nacharbeit erledigt: Server-3-SSH-Pruefpfad nutzt
    `-o IdentitiesOnly=yes -i ~/.ssh/k3-3`; private TCP-9100-Erreichbarkeit
    ist zwischen allen Nodes gruen; Prometheus Targets `23/23` up.
  - Frische Pruefungen:
    - Recent Audit `RESULT: PASS`,
      Log `/tmp/k3s-recent-stack-claims-audit-20260524-134016.log`.
    - Full Verify `RESULT: PASS`,
      Log `/tmp/k3s-stack-complete-verify-20260524-135828.log`.
    - Production Readiness `RESULT: PASS_WITH_GAPS`, `Gaps: 4`,
      Log `/tmp/k3s-production-readiness-gap-audit-20260524-140239.log`.
    - Portainer API Connectivity `RESULT: PASS`,
      Log `/tmp/portainer-api-connectivity-20260524-134017.log`.
- Frische Session-Baseline 2026-05-24 19:14 CEST:
  - Recent Audit `RESULT: PASS`, `Passes: 53`, `Warnings: 0`,
    `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260524-191109.log`.
  - Full Verify `RESULT: PASS`, `Passes: 131`, `Warnings: 0`,
    `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260524-191206.log`.
  - Production Readiness `RESULT: PASS_WITH_GAPS`, `Passes: 26`,
    `Warnings: 0`, `Gaps: 4`, `Failures: 0`,
    Log `/tmp/k3s-production-readiness-gap-audit-20260524-191352.log`.
  - Portainer API Connectivity `RESULT: PASS`, `Passes: 7`, `Failures: 0`,
    Log `/tmp/portainer-api-connectivity-20260524-191423.log`.

## Offen Vor Produktiven App-Deployments

1. Portainer API-/UI-Watch-Proxy-Panic read-only diagnostizieren:
   Die direkte Kubernetes-API-Konnektivitaet aus dem Portainer-Pod ist stabil,
   aber Portainer loggt `Panic in request handler` bei Kubernetes-Watch-
   Requests. Vor produktiven Portainer-Settings-Aenderungen Ursache,
   Reproduzierbarkeit und moegliche Workarounds klaeren.
2. Portainer Settings-Empfehlungsplan erstellen und danach nur freigegebene
   Mini-Bloecke umsetzen:
   Kubeconfig-Laufzeit, non-admin Kubeconfig-Download, non-admin KubeShell,
   code-based deployment, Application Notes, Registry-Konzept, OAuth/SSO/MFA,
   RBAC, Audit Logging und Portainer-Backup bewusst bewerten. Keine
   produktionsrelevanten Einstellungen ohne eigenen Mini-Plan aendern.
3. App-spezifische Backup-/Restore-Pflicht vor jeder produktiven App:
   Jede App braucht dokumentiert Longhorn-Storage, Velero Schedule,
   Longhorn Volume-RecurringJobs fuer produktive PVCs, DB-Backup falls eine
   Datenbank vorhanden ist, Monitoring und einen echten Restore-Test.
4. Produktive Postgres-Backup-Automation fuer spaetere CloudNativePG-
   Datenbanken planen:
   pro App CloudNativePG/Barman WAL-Backups, Retention, Restore-Ziele und
   zusaetzliche `pg_dump`-CronJobs festlegen. Der nicht-produktive CNPG/Barman-
   Smoke-Test ist erledigt; produktive Datenbanken wurden noch nicht erstellt.
5. Velero Schedules pro produktivem App-Namespace planen:
   Namespaces, Ausschluesse, Retention, Restore-Zielnamespace und Restore-Test
   je App festlegen.
6. Longhorn Volume-RecurringJobs pro neuer produktiver PVC/App-Gruppe planen:
   Snapshot-/Backup-Cron, Retention, Gruppenlabel und Restore-Test je
   produktiver PVC-Gruppe festlegen.
7. DNS-/resolv.conf-Cleanup planen:
   Kubernetes Events melden `Nameserver limits were exceeded`. Read-only
   Befund: alle Nodes nutzen systemd-resolved Stub; die echte
   `/run/systemd/resolve/resolv.conf` enthaelt zu viele Nameserver fuer Pod-DNS,
   Server 1 zusaetzlich Tailscale-DNS/Search-Domain. Nicht ad hoc loeschen.
   Separater Betriebsblock mit Backup-Zwischenstopp: dedizierte reduzierte
   K3s-Resolver-Datei, K3s/kubelet `resolv-conf`, Nodes einzeln rollen, danach
   alle Audits.
8. Monitoring-Nacharbeit:
   zuerst gezielte ServiceMonitors/Alerts fuer Longhorn, Velero, CloudNativePG,
   Zertifikate, Backup-Fehler und Disk-/Speicherdruck planen. Alertmanager-
   Receiver bleiben bewusst ganz am Schluss: externe Meldungen gemeinsam per
   YAML/Secret konfigurieren, Test-Alert ausloesen, Alarm-Runbook finalisieren.
   Das Runbook muss Meta-Ueberwachung enthalten: `BlackboxExporterDown`,
   `AlertmanagerDown`, fehlende Prometheus-Targets und optional einen externen
   Kontrollcheck, der meldet, wenn die Alertmanager-Kette selbst nicht mehr
   sendet.
9. Security-Hardening planen und schrittweise umsetzen:
   RBAC, NetworkPolicies, Pod Security Standards, Image Scanning,
   Admission Policies, Admin-Zugaenge, MFA/SSO und Kubeconfig-/API-Zugangs-
   Haertung. NetworkPolicies pro App-Namespace explizit planen: Default-Deny
   plus erlaubte Wege zu Ingress, DNS, Monitoring und Datenbank.
10. GitOps einfuehren, bevorzugt Argo CD:
   Cluster-Apps, Namespaces, Ingresses und Helm-Releases nachvollziehbar in Git
   ablegen. Secrets nur verschluesselt, z. B. SOPS oder External Secrets.
11. Backup-Loeschschutz erhoehen:
   S3 Object Lock/Versioning/Retention gegen Fehlbedienung, kompromittierte
   Credentials und Ransomware pruefen. Backup-Credentials trennen.
12. Healthchecks Production-ready abschliessen:
   Basisdeploy auf K3s + Longhorn ist erfolgt; SQLite-S3-Backup-CronJob und
   echter Restore-Test, Longhorn RecurringJobs/Gruppenzuordnung sowie externe
   Monitoring/Blackbox-Probe sind verifiziert. Offen bleibt spaeterer
   Docker-Rollback-Cleanup.
13. Hindsight + Postgres von Docker auf K3s + Longhorn migrieren.
14. App-spezifische Backup/Restore-Anforderungen pro neuer App erfassen:
   Datenbank, Dateien, Objektstorage, Exportfunktionen, Restore-Test. Der
   App-Onboarding-Fragekatalog ist Pflicht-Gate vor Deployments: Storage,
   Ingress, Secrets, DB-Backup, Velero Schedule, Longhorn RecurringJobs,
   Monitoring und Restore-Plan muessen je App bestaetigt sein.
15. Vollstaendigen Disaster-Recovery-Test auf Ersatznodes planen:
   neuer 3-Node-K3s-Aufbau, Restore von etcd/Velero/Longhorn/CloudNativePG/
   Restic, Abgleich der Domains und Apps.
16. Upgrade-Strategie dokumentieren:
   K3s, Longhorn, Portainer, ingress-nginx, cert-manager, Velero,
   CloudNativePG und OS-Patches mit Reihenfolge und Rollback.
17. Alten Portainer-`local-path` Rollback-PVC erst nach laengerer stabiler
   Laufzeit und separater Freigabe aufraeumen.
18. S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar war.
19. Smoke-/Test-Ressourcen Cleanup-Plan erstellen:
   `longhorn-test`, Velero-Smoke-Namespaces sowie CNPG-Smoke-/Restore-
   Namespaces/PVCs bewusst behalten oder nach separater Freigabe entfernen.
20. Portainer-Longhorn-Volume echten Restore-Test planen:
   vorhandene RecurringJobs/Backups sind verifiziert, aber ein kontrollierter
   Restore-Test des produktiven Portainer-Longhorn-Volumes bleibt ein eigener
   DR-/Betriebsreife-Block.
21. ResourceQuotas und LimitRanges pro produktivem Namespace planen, bevor
   mehrere Apps ausgerollt werden.
22. Host-/Docker-Restbestand final inventarisieren:
   alles, was noch ausserhalb K3s laeuft, entweder sauber migrieren oder
   bewusst als externer Restbestand dokumentieren.
23. Doku-Cleanup durchfuehren:
   historische Datumsnamen, alte Gap-Zahlen und ueberholte Aussagen zu Velero,
   CloudNativePG und Monitoring klar als historisch markieren oder bereinigen.

## Zielbild Wenn Alle Schutzschichten Fertig Sind

- K3s etcd-S3 sichert den Cluster-State.
- Velero sichert Kubernetes-Ressourcen und Namespaces als komfortable
  Restore-/Migrationsschicht; fuer produktive Apps braucht jeder App-Namespace
  einen bewusst geplanten Schedule.
- Longhorn sichert PVC-/Volume-Daten; fuer produktive PVCs braucht jede App
  passende RecurringJobs.
- CloudNativePG sichert Postgres mit S3/WAL und Point-in-Time-Restore; fuer
  produktive Datenbanken muessen WAL-Backups pro App aktiviert und getestet
  sein.
- Zusaetzliche `pg_dump` Jobs erzeugen leicht pruefbare logische DB-Exports;
  der Smoke-Test ist validiert, produktive CronJobs bleiben pro App offen.
- Jede produktive App hat vor Produktivsetzung einen dokumentierten Restore-
  Test fuer ihre relevanten Datenpfade.
- Restic sichert OS-/Host-Dateien und verbliebene Docker-Daten.
- Monitoring/Alerting meldet Fehler, statt dass sie nur bei manueller Pruefung
  auffallen.
- GitOps macht Deployments und Rebuilds nachvollziehbar.
- Backup-Loeschschutz schuetzt gegen versehentliches oder boeswilliges Loeschen.
- Ein echter DR-Test beweist, dass der Wiederaufbau auf Ersatznodes
  funktioniert.

## Pflicht Vor Jeder Groesseren Aenderung

- `audit-recent-stack-claims.sh` muss `PASS` sein.
- `verify-k3s-stack-complete.sh` muss `PASS` sein.
- Frischer K3s etcd-S3 Snapshot.
- Frischer Server-1-Restic-Lauf, solange Docker-App-Daten auf Server 1 liegen.
- Frischer Longhorn SystemBackup, wenn Kubernetes-/Longhorn-Systemressourcen
  betroffen sind.
- Bei Datenmigrationen: Restore-/Rollback-Weg vorher benennen.
- Keine Secrets, Token, Passwoerter, Kubeconfigs oder `.env` Inhalte ausgeben.
# Current Session Handover

- New central handover for fresh agent sessions: `docs/SESSION-HANDOVER-2026-05-24.md`
- Copy-paste start prompt for new agents: `docs/NEXT-AGENT-START-PROMPT-2026-05-24.md`

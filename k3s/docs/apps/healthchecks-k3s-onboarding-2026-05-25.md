# Healthchecks K3s Onboarding - 2026-05-25

Status: K3s-Basisdeployment live ausgefuehrt; SQLite-S3-Backup und Restore-Test
am 2026-05-25 erfolgreich verifiziert. Docker-Instanz auf Server 1 bleibt als
Rollback erhalten.

Diese Datei dokumentiert die kontrollierte Migration von Healthchecks in den
activi K3s Cluster. Der Basisbetrieb ist live und der app-konsistente
SQLite-Backup-/Restore-Pfad ist belegt. App-spezifische Longhorn
RecurringJobs und externe Monitoring-Probe sind live verifiziert.
Vollstaendige Produktionsreife haengt nur noch am spaeteren Rollback-Cleanup.

## Gate-Antworten

App-Name: healthchecks

Namespace: healthchecks

Zielmodus: Migration von bestehendem Docker-Betrieb auf Server 1 nach K3s.
Basisdeployment mit SQLite-Lift-and-Shift auf Longhorn wurde nach separater
Freigabe ausgefuehrt.

Migrationsquelle: bestehende Healthchecks-Docker-Instanz auf Server 1. Live
read-only geprueft am 2026-05-25:

- Host: `activi-k3-1.0`.
- Betrieb: Docker Compose unter `/opt/healthchecks/docker-compose.yml`.
- Container: `healthchecks`, Status `running`, Health `healthy`.
- Image: `healthchecks/healthchecks:latest`,
  Digest `sha256:6b5f593d40994345053f05f86decfa9e17ab1e4422df2ae58abd032a7b14d8f6`,
  Image-Created `2026-04-28T07:55:45Z`.
- Restart-Policy: `unless-stopped`.
- Docker-Netzwerk: `healthchecks_default`.
- Port: `8000/tcp` auf `0.0.0.0:8000` und `[::]:8000`.
- Volume: `healthchecks_healthchecks_data` nach `/data`.
- Datenpfad: `/var/lib/docker/volumes/healthchecks_healthchecks_data/_data`.
- Secret-Werte wurden nicht ausgegeben. Vorhandene Env-Keys wurden nur
  redigiert gesehen, darunter `SECRET_KEY`.

Domains: aktuelle Docker-Instanz nutzt laut Compose `SITE_ROOT` und
`PING_ENDPOINT` auf `http://88.99.215.210:8000`. Ziel fuer K3s:
`https://healthchecks.activi.io`. Keine DNS-/Cloudflare-Aenderung ohne separate
Freigabe. `ALLOWED_HOSTS=*` wird im Zielsetup nicht uebernommen; Zielwert:
`healthchecks.activi.io`.

IngressClass: nginx

TLS-Issuer: letsencrypt-prod

Service-Typ: ClusterIP

StorageClass: longhorn

PVCs: erforderlich. Bestehende Docker-Daten sind klein: Volume-Daten ca. `340K`,
SQLite-Datei `hc.sqlite` ca. `339968` Bytes. Ziel fuer K3s: Longhorn-PVC `1Gi`,
RWO, Mount nach `/data`. Kein local-path fuer neue produktive Healthchecks-Daten.

Datenbank: bestehende Docker-Instanz nutzt SQLite:
`DB=sqlite`, `DB_NAME=/data/hc.sqlite`. Zielentscheidung fuer den ersten
Healthchecks-K3s-Deploy: SQLite auf Longhorn beibehalten, weil der bestehende
Datenbestand klein ist und die Migration dadurch kontrollierbar bleibt.
PostgreSQL/CNPG bleibt ein spaeterer Ausbaupfad, falls Healthchecks groesser
wird oder DB-Backups mit WAL erforderlich werden.

Backup-Strategie: Jede produktive Healthchecks-Variante braucht Longhorn fuer
PVCs, Velero fuer den Namespace, einen app-/datenbankbewussten Backup-Pfad und
einen Restore-Test. Backup gilt erst nach erfolgreichem Restore-Test als
produktionsreif.

Velero: produktiver Schedule fuer den Namespace `healthchecks` wurde erstellt:
`healthchecks-daily`, Schedule `23 2 * * *`, included namespace
`healthchecks`, TTL `336h0m0s`.

Longhorn: produktives PVC `healthchecks-data` ist `Bound` auf StorageClass
`longhorn`, Groesse `1Gi`, RWO. App-spezifische Longhorn RecurringJobs wurden
am 2026-05-25 live verifiziert: `healthchecks-snapshot-hourly` Snapshot,
Cron `17 * * * *`, Retain `48`; `healthchecks-backup-daily` Backup, Cron
`47 1 * * *`, Retain `14`; `healthchecks-backup-weekly` Backup, Cron
`22 3 * * 0`, Retain `8`; alle Gruppe `app-healthchecks`. Das Longhorn-Volume
`pvc-f3646e24-e2c8-44f4-8e2d-0241bfca5f71` traegt das Label
`recurring-job-group.longhorn.io/app-healthchecks=enabled`. Keine Longhorn-
RecurringJobs zielen auf die Default-Gruppe.

DB-Backup: SQLite-Dump/Restore fuer den Basisdeploy ist live verifiziert; pg_dump/Barman/WAL/CNPG gilt bei spaeterer PostgreSQL-Migration. Bestehende
SQLite-Tarballs sind inventarisiert; Zielpfad fuer den ersten Deploy ist ein
app-konsistenter SQLite-Dump/Restore-Pfad plus Longhorn und Velero.
Bei spaeterer PostgreSQL-Migration gilt CloudNativePG/Barman WAL
plus pg_dump-Template. Bestehende Backup-Tarballs
`/root/k3s-migration-backup/20260519-0429/healthchecks.tar.gz` und
`/root/k3s-migration-backup/20260519-0430/healthchecks.tar.gz` enthalten
`healthchecks_healthchecks_data/_data/hc.sqlite`. Kein reines Blockbackup als
einzige Sicherung.

Restore-Test: fuer SQLite-S3-Backup am 2026-05-25 erfolgreich ausgefuehrt.
Beleg: SHA256-Sidecar passt, `SQLITE_INTEGRITY=ok`, `SQLITE_TABLES=24`.

Secrets: bestehende Env-Keys wurden nur redigiert inventarisiert. Fuer K3s
mindestens zu planen: `SECRET_KEY`, `SITE_ROOT`, `PING_ENDPOINT`,
`ALLOWED_HOSTS`, DB-Konfiguration und ggf. Mail-/Webhook-Konfiguration. Keine
Werte dokumentieren. Ziel-Secret-Name: `healthchecks-app-env`. Bestehenden
`SECRET_KEY` nur sicher uebertragen, niemals ausgeben. Spaeter bevorzugt
SOPS/External Secrets/Infisical/Vault gemaess Zielentscheidung.

Registry/ImagePullSecrets: bestehende Instanz nutzt
`healthchecks/healthchecks:latest` von Docker Hub. Fuer K3s keinen floating
`latest`-Tag verwenden. Ziel fuer ersten Deploy:
`healthchecks/healthchecks@sha256:6b5f593d40994345053f05f86decfa9e17ab1e4422df2ae58abd032a7b14d8f6`.
Private Registry nur mit separatem Pull-Secret-Plan.

Monitoring: HTTP-Erreichbarkeit, Pod/Deployment-Health und Backup-/Restore-Status
einplanen. Die externe HTTP-Probe gegen `https://healthchecks.activi.io` ist am
2026-05-26 live eingerichtet. Blackbox Exporter laeuft im Namespace
`monitoring`; Prometheus `Probe` `monitoring/healthchecks-external` wird durch
`release=kube-prometheus-stack` eingesammelt. Direkter Blackbox-Test:
`probe_http_status_code 200`, `probe_success 1`. Prometheus-Abfrage:
`probe_success{job="healthchecks-external"} = 1`. ServiceMonitor nur falls
Healthchecks spaeter verwertbare Prometheus-Metriken bereitstellt.

ResourceQuotas/LimitRanges: Namespace `healthchecks` hat kleine, bewusste
Limits gemaess `manifests/healthchecks/01-resource-policy.yaml`.

NetworkPolicies: Default-Deny plus erlaubte Wege fuer Ingress-Nginx zu
Healthchecks, Healthchecks zu DNS und ausgehende App-Verbindungen fuer
Healthchecks-Pings/Benachrichtigungen sind angewendet. Ingress-Zugriff musste
zusaetzlich fuer das Pod-Netz `10.42.0.0/16` erlaubt werden, weil der
nginx-Ingress Upstream-Verkehr aus dem Cluster-/Pod-Netz kommen kann.

Rollback: Bestehende Docker-Instanz auf Server 1 bleibt bis nach erfolgreichem
K3s-Deployment, Backup und Restore-Test als Fallback erhalten.

Offene Entscheidungen: keine fuer den ausgefuehrten Basis-Deploy. Nacharbeit
fuer Production-ready: spaeterer Docker-Rollback-Cleanup.

Stop-Punkte:

- Docker-Rollback-Cleanup nicht freigegeben.
- Bestehende Docker-Daten koennen nicht ohne Secrets migriert werden.
- PVC-Groesse oder Backup-Pfad nicht belegt.
- DNS-/Firewall-/Cloudflare-Aenderung waere noetig.
- Secret-Werte muessten ausgegeben werden.
- Ein produktiver Namespace oder PVC wuerde ohne Freigabe geaendert.

Deployment-Freigabe: erteilt und am 2026-05-25 ausgefuehrt.

## Live-Inventar 2026-05-25

Befehle wurden nur read-only per SSH auf `k3-1` ausgefuehrt. Secret-Werte wurden
nicht ausgegeben.

- Docker-Container: `healthchecks healthchecks/healthchecks:latest`, `Up 7 days
  (healthy)`, Port `8000`.
- Compose-Datei: `/opt/healthchecks/docker-compose.yml`, mode `644`,
  owner `root:root`, Groesse `567` Bytes, mtime `2026-05-17 20:58`.
- Systemd-Service fuer Healthchecks wurde nicht gefunden.
- Volume: `healthchecks_healthchecks_data`, Driver `local`, Mountpoint
  `/var/lib/docker/volumes/healthchecks_healthchecks_data/_data`.
- Datenbankdatei: `hc.sqlite`, ca. `339968` Bytes.
- Backup-Artefakte: zwei Tarballs unter `/root/k3s-migration-backup`,
  beide enthalten die SQLite-Datei.
- Host lauscht auf `8000` via Docker-Proxy; Host-Nginx lauscht auf `80/443`.

## Zielentscheidungen 2026-05-25

- Erste K3s-Migration als SQLite-Lift-and-Shift auf Longhorn.
- Ziel-Domain: `https://healthchecks.activi.io`.
- Ziel-PVC: Longhorn, `1Gi`, RWO, Mount `/data`.
- Ziel-Image: bestehender Healthchecks-Docker-Hub-Digest statt `latest`.
- Ziel-Secret: `healthchecks-app-env`, Werte niemals dokumentieren.
- Backup: Longhorn RecurringJobs + Velero Namespace Schedule +
  app-konsistenter SQLite-Dump/Restore-Test.
- Rollback: bestehende Docker-Instanz bleibt unveraendert, bis K3s-Deploy,
  Backup und Restore-Test bestanden sind.

## Manifest- und Deploymentstand 2026-05-25

Folgende Manifeste wurden lokal vorbereitet:

- `manifests/healthchecks/00-namespace.yaml`
- `manifests/healthchecks/01-resource-policy.yaml`
- `manifests/healthchecks/02-configmap.yaml`
- `manifests/healthchecks/03-secret-schema.example.yaml`
- `manifests/healthchecks/04-pvc.yaml`
- `manifests/healthchecks/05-deployment.yaml`
- `manifests/healthchecks/06-service.yaml`
- `manifests/healthchecks/07-ingress.yaml`
- `manifests/healthchecks/08-networkpolicy.yaml`
- `manifests/healthchecks/09-backup-sqlite-dump-cronjob.yaml`
- `manifests/healthchecks/09-backup-sqlite-dump-cronjob.template.yaml`
- `manifests/healthchecks/10-restore-test-job.yaml`
- `manifests/healthchecks/10-restore-test-job.template.yaml`
- `manifests/healthchecks/11-velero-schedule.yaml`

Lokaler Manifest-Check nach Backup-/Restore-Finalisierung:

- Script: `verify-healthchecks-manifests.sh`
- Ergebnis: `RESULT: PASS`, `Passes: 48`, `Warnings: 0`, `Gaps: 0`,
  `Failures: 0`
- Log: `/tmp/healthchecks-manifests-verify-20260525-230816.log`

## Live-Deployment 2026-05-25

Ausgefuehrt nach expliziter Freigabe:

- Namespace `healthchecks` erstellt.
- Secrets `healthchecks-app-env` und `healthchecks-backup-env` als Kubernetes
  Secrets angelegt; Secret-Werte wurden nicht ausgegeben.
- Docker-SQLite-Datei `/var/lib/docker/volumes/healthchecks_healthchecks_data/_data/hc.sqlite`
  in den neuen Longhorn-PVC `healthchecks-data` kopiert.
- Deployment, Service, Ingress, NetworkPolicies, ResourceQuota/LimitRange und
  Velero Schedule angewendet.
- Probe-Header im Deployment auf `Host: healthchecks.activi.io` gesetzt, damit
  Healthchecks mit restriktivem `ALLOWED_HOSTS` korrekt geprueft wird.
- NetworkPolicy fuer Ingress-Quellen aus `10.0.1.0/24` und `10.42.0.0/16`
  erweitert.

Live-Belege:

- Deployment `healthchecks`: `1/1`, Pod `healthchecks-78b7fc78b5-9xxpz`,
  `Running`, `0` Restarts.
- PVC `healthchecks-data`: `Bound`, Longhorn, `1Gi`, RWO.
- Service `healthchecks`: ClusterIP `10.43.153.55`, Port `8000/TCP`.
- Ingress `healthchecks`: Host `healthchecks.activi.io`, Class `nginx`,
  Address `10.0.1.10,10.0.1.20,10.0.1.30`.
- Zertifikat `healthchecks-tls`: `Ready=True`; ACME Order `valid`.
- Externer Smoke-Test: `curl -fsSI https://healthchecks.activi.io` liefert
  `HTTP/2 302` mit `location: /accounts/login/`.
- Baseline nach Deployment: `/tmp/k3s-baseline-gates-20260525-201103.log`,
  `RESULT: PASS`.
- App-Onboarding-Gate nach Doku-Aktualisierung:
  `/tmp/k3s-app-onboarding-gate-20260525-203212.log`, `RESULT: PASS`,
  `Passes: 41`, `Warnings: 0`, `Gaps: 0`, `Failures: 0`.
- Healthchecks Deploy Gate:
  `/tmp/healthchecks-deploy-gate-20260525-203526.log`,
  `RESULT: PASS_WITH_GAPS`, `Passes: 19`, `Warnings: 2`, `Gaps: 1`,
  `Failures: 0`. Die Gaps betreffen Backup-/Restore-Template und
  Production-ready-Nacharbeiten, nicht den laufenden Basisbetrieb.
- SQLite-Dateirechte nach Init-Container-Korrektur:
  `/data/hc.sqlite` gehoert `hc:hc`, mode `600`.
- SQLite-S3-Backup-CronJob `healthchecks-sqlite-backup`: Schedule
  `27 3 * * *`, `suspend=False`.
- Manueller Backup-Testjob
  `healthchecks-sqlite-backup-manual-20260525-2224`: `Complete`.
- Backup-Beleg:
  `s3://miniotest/healthchecks/sqlite/healthchecks-20260525T203919Z.sqlite.gz`,
  SHA256 `6156529e1b3e31ea3cbfbb8f05d222a544f438eba8c987f94686c259f839a149`,
  `SQLITE_INTEGRITY=ok`.
- Restore-Testjob `healthchecks-sqlite-restore-test`: `Complete`.
- Restore-Beleg: `RESTORE_SHA256_MATCH=ok`, `SQLITE_INTEGRITY=ok`,
  `SQLITE_TABLES=24`.
- Fehlgeschlagene manuelle Backup-Testjobs aus der Fehleranalyse wurden nach
  separater Cleanup-Freigabe geloescht:
  `healthchecks-sqlite-backup-manual-20260525-2109`,
  `healthchecks-sqlite-backup-manual-20260525-2122`,
  `healthchecks-sqlite-backup-manual-20260525-2145`,
  `healthchecks-sqlite-backup-manual-20260525-2157`.
- Longhorn RecurringJobs live verifiziert:
  `healthchecks-snapshot-hourly` `snapshot` `17 * * * *` Retain `48`,
  `healthchecks-backup-daily` `backup` `47 1 * * *` Retain `14`,
  `healthchecks-backup-weekly` `backup` `22 3 * * 0` Retain `8`; alle Gruppe
  `app-healthchecks`.
- Healthchecks-Longhorn-Volume
  `pvc-f3646e24-e2c8-44f4-8e2d-0241bfca5f71` traegt
  `recurring-job-group.longhorn.io/app-healthchecks=enabled`.
- Baseline nach Longhorn-Nacharbeit: `/tmp/k3s-baseline-gates-20260525-235629.log`,
  `RESULT: PASS`, `Passes: 4`, `Failures: 0`.
- Monitoring/Blackbox-Probe live verifiziert: Blackbox Exporter
  `monitoring/blackbox-exporter` `1/1`, Probe `monitoring/healthchecks-external`,
  PrometheusRule `monitoring/healthchecks-external-probe`; direkter Probe-Wert
  `probe_success 1`; Prometheus sammelt
  `probe_success{job="healthchecks-external"} = 1`.

## Naechster sicherer Block

Healthchecks Production-ready Nacharbeit:

- Docker-Rollback-Instanz erst nach Backup und Restore-Test kontrolliert
  abschalten oder entfernen.

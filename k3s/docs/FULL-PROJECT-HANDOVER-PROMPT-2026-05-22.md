# Full Project Handover Prompt - K3s Hetzner Stack - 2026-05-22

Dieses Dokument ist die zentrale Uebergabe fuer eine neue Agenten-Session.
Es soll als Start-Prompt verwendet werden, wenn ein neuer Agent das Projekt
eigenstaendig weiterfuehren soll.

Wichtig: Dieses Dokument ersetzt nicht die einzelnen Runbooks. Es sagt dem
Agenten, welche Dateien zuerst gelesen werden muessen, was bereits erledigt ist,
was offen ist und welche Sicherheitsregeln verbindlich sind.

## Aktueller Stand 2026-05-24

- `longhorn` ist die einzige Default StorageClass; `local-path` bleibt nur als
  Alt-/Rollback-Kontext vorhanden.
- Portainer Business Edition ist aktiviert, nutzt `portainer/portainer-longhorn`
  und ist per `ingress-nginx`/cert-manager TLS unter
  `https://portainer.activi.io` erreichbar.
- Velero ist installiert und per nicht-destruktivem Smoke Backup/Restore
  validiert.
- CloudNativePG Operator und Barman Cloud Plugin sind installiert und per Smoke
  Backup/Restore validiert; produktive DB-Backups pro App sind offen.
- Monitoring-Basisstack ist installiert; Prometheus Targets sind gruen.
- Offene Gaps: produktive `pg_dump`-Automation pro App, GitOps,
  SOPS/External Secrets/Vault, vollstaendiger Replacement-Node-DR-Drill und
  DNS/resolv.conf-Cleanup als separater Block.

Historische Unterlagen bleiben fuer Belege erhalten. Bei Widerspruch gilt dieser
aktuelle Stand plus die juengsten Audit-/Verify-Logs.

Hinweis 2026-05-24: Historische Zwischenstaende und Gap-Zahlen in diesem
Dokument sind Zeitpunkt-Snapshots. Massgeblich fuer neue Sessions sind
`SESSION-HANDOVER-2026-05-24.md` und `OPEN-TODOS-2026-05-22.md` sowie die
neuesten Audit-/Verify-Logs.

## Fertiger Prompt Fuer Neuen Agenten

```text
Wir machen am bestehenden K3s/Hetzner-Robot-Projekt weiter.

Arbeite eigenstaendig, aber strikt kontrolliert:
- Erst Unterlagen lesen.
- Dann Live-Stand pruefen.
- Dann nur den naechsten sicheren Block umsetzen.
- Nach jedem groesseren Block verifizieren und dokumentieren.
- Keine Secrets, Tokens, Passwoerter, Kubeconfigs, S3 Keys, Restic-Passwoerter
  oder .env-Inhalte ausgeben.
- Wenn Live-Stand und Unterlagen abweichen: stoppen und die Abweichung melden.

============================================================
1. Arbeitsverzeichnis
============================================================

Projektpfad:

/Users/activi/Documents/activi K3s

Alle lokalen Projektdateien, Runbooks, Pruefskripte und Exporte liegen dort.

Vor jeder Aktion:

cd "/Users/activi/Documents/activi K3s"

============================================================
2. Pflichtdokumente Zuerst Lesen
============================================================

Lies diese Dateien zuerst vollstaendig oder zumindest so weit, dass der aktuelle
Sollzustand und die Stop-Punkte klar sind:

/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
/Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md
/Users/activi/Documents/activi K3s/docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/LONGHORN-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-23-production-readiness-hardening-plan.md

Pruefskripte:

/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh
/Users/activi/Documents/activi K3s/audit-production-readiness-gaps.sh
/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh
/Users/activi/Documents/activi K3s/export-k3s-rebuild-bundle.sh

Historische, aber wichtige Handover-Dateien:

/Users/activi/Documents/activi K3s/docs/PORTAINER-INGRESS-TLS-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/PORTAINER-COMPLETE-SETUP-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md

Hinweis:
Historische Dateien koennen alte Zwischenstaende enthalten. Der verbindliche
aktuelle Stand steht in:

- FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
- OPEN-TODOS-2026-05-22.md
- PROJECT-STATUS-2026-05-20.md
- K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
- BACKUP-RUNBOOK-2026-05-20.md

============================================================
3. Verbindlicher Aktueller Live-Stand
============================================================

Cluster:
- 3-Node K3s HA auf Hetzner Robot Dedicated Servern.
- K3s Version: v1.32.1+k3s1.
- Server 1: activi-k3-1.0, Public 88.99.215.210, Private 10.0.1.10.
- Server 2: activi-k3-2, Public 178.63.12.52, Private 10.0.1.20.
- Server 3: activi-k3-3, Public 167.235.6.160, Private 10.0.1.30.
- Alle drei Nodes sind Ready.
- Alle drei Nodes sind control-plane/etcd/master.
- Longhorn ist seit 2026-05-24 Default StorageClass.
- local-path bleibt vorhanden, ist aber nicht mehr Default.
- Longhorn-Default wurde am 2026-05-24 02:45 CEST erneut verifiziert:
  `longhorn` ist die einzige Default StorageClass, `local-path` ist nur noch
  vorhanden, nicht Default. Der aktive produktive Portainer-PVC ist
  `portainer/portainer-longhorn`; der alte `portainer/portainer` PVC ist nur
  Rollback-Altbestand.
- Velero ist installiert und per nicht-destruktivem Namespace-Restore-Test
  validiert: Version `1.18.0`, Chart `velero-12.0.1`, Namespace `velero`,
  BackupStorageLocation `default` Available, S3 Bucket/Prefix `activi/velero`.
- CloudNativePG ist als nicht-produktiver Test-/Backup-Baustein installiert und
  validiert: Operator `1.29.1`, Barman Cloud Plugin `v0.12.0`, Smoke-Cluster
  `cnpg-smoke-20260524/cnpg-smoke`, S3 Prefix
  `activi/cloudnativepg/smoke-20260524`, Backup und separater Restore-Test
  erfolgreich. Es wurde nicht der deprecated `barmanObjectStore`-Clusterpfad
  verwendet.
- Monitoring-Basisstack ist installiert: `kube-prometheus-stack` Chart
  `85.3.0`, App Version `v0.90.1`, Namespace `monitoring`. Prometheus,
  Alertmanager und Grafana sind intern Ready, Services sind `ClusterIP`, PVCs
  nutzen `longhorn`. Es gibt keinen Grafana-Ingress, keine NodePorts, keine
  LoadBalancer und noch keinen externen Alert-Receiver.
- Neue App-Projekte muessen den globalen Integrationsstandard lesen:
  `/Users/activi/Documents/activi K3s/docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md`.
- Neue App-Projekte muessen den Fragekatalog verwenden:
  `/Users/activi/Documents/activi K3s/docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md`.
- App-spezifische Sollwerte muessen in einer eigenen Antwort-/Values-Datei
  dokumentiert werden und duerfen nicht nur in Chat-Prompts stehen.

SSH-/Zugangsstand:
- Server 1: `k3-1`.
- Server 2: `kube3-2`; am 2026-05-24 vom User getestet und als
  funktionierender SSH-Alias gemeldet.
- Server 3: bekannter lokaler Key `/Users/activi/.ssh/k3-3`.
- Nicht-geheime Verbindungsuebersicht:
  `/Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md`.
- Fokussierter naechster Handover-Prompt fuer Server-2-Verifikation:
  `/Users/activi/Documents/activi K3s/docs/SERVER2-VERIFY-HANDOVER-PROMPT-2026-05-24.md`.

Ingress/TLS:
- ingress-nginx ist aktiv.
- cert-manager v1.20.2 ist aktiv.
- ClusterIssuer letsencrypt-prod ist Ready.
- Domain portainer.activi.io zeigt auf 88.99.215.210.
- Cloudflare DNS steht auf Nur DNS, nicht Proxy.
- http://portainer.activi.io leitet auf HTTPS um.
- https://portainer.activi.io liefert Portainer.

Portainer:
- Namespace: portainer.
- Image: portainer/portainer-ee:2.39.2.
- Portainer Business Edition 3 Nodes Free ist aktiviert; Login klappt und die Business-Lizenz wird angezeigt.
- Helm Release: portainer.
- Service: ClusterIP.
- Keine Kubernetes-NodePorts existieren.
- Ingress: portainer/portainer.
- TLS Certificate: portainer/portainer-activi-io-tls, Ready=True.
- Aktiver PVC: portainer-longhorn, 10Gi, StorageClass longhorn.
- Aktives Longhorn Volume: pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b.
- Longhorn Volume ist attached/healthy und hat Replicas auf allen drei Nodes.
- Alter PVC portainer auf local-path bleibt absichtlich als Rollback-Beleg.
  Nicht loeschen ohne separaten Cleanup-Plan.
- Portainer/Kubernetes-API-Timeouts sind behoben. Wenn Portainer wieder langsam
  wirkt, zuerst das Skript `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`
  ausfuehren.

Backup:
- K3s etcd-S3 Snapshots aktiv.
- Server-1 Restic aktiv.
- Hindsight Postgres Dumps aktiv.
- OS-Restic Server 2/3 aktiv.
- OS-Restic Server 2/3 Timer: hourly plus RandomizedDelaySec=10min.
- OS-Restic Server 2/3 Retention: 48 hourly, 14 daily, 8 weekly, 12 monthly.
- Longhorn SystemBackup aktiv.
- Longhorn SystemBackup RecurringJob: lh-system-backup-daily, 02:17 taeglich,
  retain 14, volume-backup-policy=disabled.
- Longhorn Volume-RecurringJobs fuer `portainer/portainer-longhorn` sind aktiv:
  `prod-snapshot-hourly`, `prod-backup-daily`, `prod-backup-weekly`, Gruppe
  `prod-critical`. Keine Jobs auf `default`, keine Testvolumes in
  `prod-critical`.
- CloudNativePG/Barman Cloud Plugin ist fuer nicht-produktive Postgres-
  Backup-/Restore-Tests aktiv. Der Smoke-Test nutzt StorageClass `longhorn`,
  Hetzner Object Storage S3 und den Prefix
  `cloudnativepg/smoke-20260524`. Fuer produktive Datenbanken sind eigene
  Schedules, Retention, Restore-Ziele und zusaetzliche `pg_dump`-CronJobs noch
  pro App festzulegen.
- Monitoring ist als Basisstack aktiv. Prometheus/Alertmanager/Grafana sind
  Ready. Nach der privaten TCP-9100-Nacharbeit sind Prometheus Targets `23/23`
  up. Es gibt weiter keinen Grafana-Ingress, keine NodePorts, keine
  LoadBalancer und keinen externen Alert-Receiver.
- Offener geplanter Betriebsblock: DNS-/resolv.conf-Cleanup. Kubernetes Events
  melden `Nameserver limits were exceeded`; read-only Befund zeigt zu viele
  systemd-resolved Upstream-Nameserver fuer Pod-DNS, auf Server 1 zusaetzlich
  Tailscale-DNS/Search-Domain. Keine DNS-/K3s-Resolver-Aenderung ohne
  Backup-Zwischenstopp und eigene Freigabe.
- Rebuild-Bundle ohne Secret-Inhalte existiert:
  /Users/activi/Documents/activi K3s/exports/k3s-rebuild-bundle-20260522-032642.tar.gz

Firewall/Netzwerk:
- Hetzner Robot Firewall ist nicht automatisch ein vollwertiger Stateful-Firewall-Ersatz.
- Auf allen drei Robot-Firewalls muss die ACK-Rueckregel so bleiben:
  `tcp established`, IPv4/TCP, Quelle `0.0.0.0/0`, Ziel `0.0.0.0/0`,
  Quell-Port `0-65535`, Ziel-Port `0-65535`, TCP-Flags `ack`, Aktion `accept`.
- Diese ACK-Regel erlaubt keine neuen eingehenden Verbindungen auf alle Ports.
- Pod-Netz zu Kubernetes API bleibt noetig:
  Quelle `10.42.0.0/16`, Ziel TCP `6443`, auf allen drei Servern.
- Private K3s-Kommunikation `10.0.1.0/24` bleibt fuer die bekannten K3s-Ports erlaubt.
- Nicht wieder auf `tcp established` Ziel-Port `32768-65535` zurueckstellen; das verursachte Portainer/Kubernetes-API-Timeouts.
- Die alte Server-1-UFW-Route-Regel fuer `cni0 -> enp41s0.4000` wurde entfernt und soll nicht erneut als Primaerfix verwendet werden.

Server-1 Docker-Apps:
- Healthchecks laeuft noch als Docker-App auf Server 1.
- Hindsight laeuft noch als Docker-App auf Server 1.
- Hindsight Postgres laeuft noch als Docker-App auf Server 1.
- Diese Apps sind noch nicht HA.
- Diese Apps muessen spaeter kontrolliert nach K3s + Longhorn migriert werden.

============================================================
4. Letzte Verifizierte Abschlusspruefungen
============================================================

Letzter Portainer-API-Connectivity-Lauf:

RESULT: PASS
Direktziele: 10.0.1.10:6443, 10.0.1.20:6443, 10.0.1.30:6443
Kubernetes-Service: 10.43.0.1:443
Versuche: 60/60 pro Ziel erfolgreich
Log: /tmp/portainer-api-connectivity-20260523-024920.log

Letzter Recent-Audit-Lauf:

RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0
Log: /tmp/k3s-recent-stack-claims-audit-20260523-024855.log

Letzter vollstaendiger Verify-Lauf:

RESULT: PASS
Passes: 126
Warnings: 0
Failures: 0
Log: /tmp/k3s-stack-complete-verify-20260523-025031.log

Server-2-Verifikation und frische Abschlusspruefungen 2026-05-24 01:12 CEST:

Server 2:
- SSH via `kube3-2`: PASS.
- Hostname: `activi-k3-2`.
- OS-Restic Timer: `enabled` und `active`.
- OS-Restic Snapshots: 49 sichtbar, Host `activi-k3-2`, Tag `os-server2`.
- `restic check`: PASS, keine Fehler.

Aktuelle Logs:

RESULT: PASS
Pruefung: Portainer API Connectivity
Log: /tmp/portainer-api-connectivity-20260524-010923.log

RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0
Log: /tmp/k3s-recent-stack-claims-audit-20260524-010939.log

RESULT: PASS
Passes: 126
Warnings: 0
Failures: 0
Log: /tmp/k3s-stack-complete-verify-20260524-011026.log

RESULT: PASS_WITH_GAPS
Passes: 21
Warnings: 0
Gaps: 9
Failures: 0
Log: /tmp/k3s-production-readiness-gap-audit-20260524-011155.log

Einordnung: Die vorherige Server-2-SSH-Warning ist verschwunden. Zu diesem
Zeitpunkt waren die neun verbleibenden Gaps Longhorn Volume-RecurringJobs fuer
produktive PVCs, Velero, CloudNativePG, CloudNativePG-Testdatenbank,
Kubernetes-Postgres-`pg_dump`, Monitoring/Alerting, GitOps,
External Secrets/SOPS/Vault und echter Replacement-Node-DR-Test. Der
Longhorn-Volume-RecurringJob-Gap wurde im Update 2026-05-24 03:05 CEST
geschlossen.

Update 2026-05-24 03:05 CEST: Longhorn Volume-RecurringJobs fuer das produktive
Portainer-Volume sind umgesetzt und verifiziert. Erstellt wurden
`prod-snapshot-hourly` (`snapshot`, Cron `7 * * * *`, Retain `48`),
`prod-backup-daily` (`backup`, Cron `37 1 * * *`, Retain `14`) und
`prod-backup-weekly` (`backup`, Cron `12 3 * * 0`, Retain `8`) mit Gruppe
`prod-critical`. Nur `portainer/portainer-longhorn` beziehungsweise Longhorn
Volume `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b` ist in `prod-critical`.
Testvolumes sind nicht aufgenommen, es gibt keinen Job auf Gruppe `default`,
und `lh-system-backup-daily` blieb unveraendert.

Aktuelle Logs nach dieser Umsetzung:

RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0
Log: /tmp/k3s-recent-stack-claims-audit-20260524-025911.log

RESULT: PASS
Passes: 131
Warnings: 0
Failures: 0
Log: /tmp/k3s-stack-complete-verify-20260524-030246.log

RESULT: PASS_WITH_GAPS
Passes: 22
Warnings: 0
Gaps: 8
Failures: 0
Log: /tmp/k3s-production-readiness-gap-audit-20260524-030429.log

Einordnung: Der fruehere Longhorn-Volume-RecurringJob-Gap ist geschlossen.
Verbleibende Gaps zu diesem Zeitpunkt: Velero, CloudNativePG,
CloudNativePG-Testdatenbank, Kubernetes-Postgres-`pg_dump`,
Monitoring/Alerting, GitOps, External Secrets/SOPS/Vault und echter
Replacement-Node-DR-Test. Der Velero-Gap wurde im Update 2026-05-24 03:45 CEST
geschlossen.

Update 2026-05-24 03:45 CEST: Velero wurde installiert und live validiert.
BackupStorageLocation `default` ist `Available` und nutzt Hetzner Object
Storage S3 Bucket `activi`, Prefix `velero`, Endpoint
`https://fsn1.your-objectstorage.com`, Region `fsn1`. Smoke-Test:
Backup `velero-smoke-backup-20260524` fuer Namespace
`velero-smoke-source-20260524` ist `Completed`; Restore
`velero-smoke-restore-20260524` in Namespace
`velero-smoke-restore-20260524` ist `Completed`. Es wurden keine produktiven
Namespaces/PVCs und keine Portainer-, Longhorn-, StorageClass-, Firewall- oder
DNS-Einstellungen veraendert.

Finale Pruefungen nach Velero:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-035713.log
RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-035800.log
RESULT: PASS
Passes: 131
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-035937.log
RESULT: PASS_WITH_GAPS
Passes: 23
Warnings: 0
Gaps: 7
Failures: 0

/tmp/portainer-api-connectivity-20260524-040004.log
RESULT: PASS
Passes: 7
Failures: 0
```

Update 2026-05-24 05:26 CEST: CloudNativePG wurde als nicht-produktiver
Test-/Backup-Baustein installiert und live validiert. Operator: Helm Chart
`cloudnative-pg-0.28.2`, App Version `1.29.1`, Namespace `cnpg-system`.
Barman Cloud Plugin: `ghcr.io/cloudnative-pg/plugin-barman-cloud:v0.12.0`,
Deployment `cnpg-system/barman-cloud`, `Ready 1/1`. Verwendet wurde nur der
aktuelle Barman Cloud Plugin Weg, nicht der deprecated
`barmanObjectStore`-Clusterpfad.

Smoke-Test:

```text
Source Namespace: cnpg-smoke-20260524
Source Cluster: cnpg-smoke, 1 Instanz, StorageClass longhorn, 1Gi
ObjectStore: cnpg-smoke-store
S3 Ziel: s3://activi/cloudnativepg/smoke-20260524
WAL/Backup: ContinuousArchiving=True:ContinuousArchivingSuccess
Backup: cnpg-smoke-backup-20260524, phase completed, method plugin
Backup ID: 20260524T025915
pg_dump-Test: cnpg-smoke-pgdump-retry-20260524, succeeded=1
Restore Namespace: cnpg-smoke-restore-20260524
Restore Cluster: cnpg-smoke-restore, 1 Instanz, StorageClass longhorn, 1Gi
Restore-Testdaten vorhanden: ja
```

Es wurden keine produktiven Datenbanken, produktiven Namespaces oder
produktiven PVCs erstellt oder veraendert. Portainer, Longhorn-Setup,
StorageClass, Firewall und DNS blieben unveraendert.

Finale Pruefungen nach CloudNativePG:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-052300.log
RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-052352.log
RESULT: PASS
Passes: 131
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-052527.log
RESULT: PASS_WITH_GAPS
Passes: 25
Warnings: 0
Gaps: 5
Failures: 0

/tmp/portainer-api-connectivity-20260524-052603.log
RESULT: PASS
Passes: 7
Failures: 0
```

Update 2026-05-24 12:17 CEST: Monitoring-Basisstack wurde installiert.

```text
Release: kube-prometheus-stack
Namespace: monitoring
Chart: kube-prometheus-stack-85.3.0
App Version: v0.90.1
Prometheus: Ready, PVC 10Gi longhorn Bound
Alertmanager: Ready, PVC 2Gi longhorn Bound
Grafana: Ready, PVC 5Gi longhorn Bound
Services: ClusterIP
Monitoring Ingress: keiner
NodePorts/LoadBalancer: keine
Externer Alert-Receiver: keiner
```

Historischer Direktstand nach der Monitoring-Installation:

```text
targets_total=23
up=21
problematic=2
Problematisch:
- node-exporter 10.0.1.20:9100 context deadline exceeded
- node-exporter 10.0.1.30:9100 context deadline exceeded
```

Nachher-Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-121415.log
RESULT: PASS_WITH_WARNINGS
Passes: 49
Warnings: 4
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-121512.log
RESULT: FAIL
Passes: 108
Warnings: 1
Failures: 22
Grund: Server-3-SSH root@167.235.6.160 Too many authentication failures

/tmp/k3s-production-readiness-gap-audit-20260524-121654.log
RESULT: PASS_WITH_GAPS
Passes: 25
Warnings: 1
Gaps: 4
Failures: 0

/tmp/portainer-api-connectivity-20260524-121723.log
RESULT: PASS
Passes: 7
Failures: 0
```

Einordnung: Portainer, Longhorn, Velero und CloudNativePG blieben nach der
Monitoring-Installation healthy. Der Kubernetes-Node `activi-k3-3` ist Ready;
die Verify-Failures betreffen den lokalen SSH-Pruefpfad fuer Server 3.

Aktueller Stand nach Monitoring-Nacharbeit 2026-05-24:

```text
Prometheus targets_total=23
Prometheus up=23
Prometheus problematic=0

/tmp/k3s-recent-stack-claims-audit-20260524-134016.log
RESULT: PASS

/tmp/portainer-api-connectivity-20260524-134017.log
RESULT: PASS

/tmp/k3s-stack-complete-verify-20260524-135828.log
RESULT: PASS
Passes: 131
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-140239.log
RESULT: PASS_WITH_GAPS
Passes: 26
Warnings: 0
Gaps: 4
Failures: 0
```

Vorherige Storage-/Gesamtpruefung 2026-05-24 02:45 CEST:

```text
/tmp/k3s-storage-default-audit-20260524-024143.log
RESULT: PASS

/tmp/k3s-recent-stack-claims-audit-20260524-024216.log
RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-024259.log
RESULT: PASS
Passes: 126
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-024431.log
RESULT: PASS_WITH_GAPS
Passes: 21
Warnings: 0
Gaps: 9
Failures: 0
```

Einordnung: Storage-Sollzustand passt. Longhorn ist einzige Default
StorageClass, Portainer nutzt Longhorn, alter local-path-PVC ist nicht aktiv.

Bei jeder neuen Session zuerst erneut pruefen:

cd "/Users/activi/Documents/activi K3s"
./verify-portainer-api-connectivity.sh
./audit-recent-stack-claims.sh
./audit-production-readiness-gaps.sh
./verify-k3s-stack-complete.sh

Erwartung:
- `verify-portainer-api-connectivity.sh`: `RESULT: PASS`
- `audit-recent-stack-claims.sh`: `RESULT: PASS`
- `verify-k3s-stack-complete.sh`: `RESULT: PASS`
- `audit-production-readiness-gaps.sh`: aktuell `RESULT: PASS_WITH_GAPS`,
  solange produktive Kubernetes-`pg_dump`-Automation, GitOps,
  Secret-Management und echter DR-Test noch offen sind. Velero,
  CloudNativePG und Monitoring-Basisstack sind bereits installiert/getestet.
  `FAIL` ist ein Stop-Kriterium.

Wenn nicht:
- stoppen;
- keine Aenderungen;
- genaue Diagnose melden.

============================================================
5. Was Bereits Erledigt Ist
============================================================

Erledigt:

1. 3-Node K3s HA Cluster steht.
2. Server 3 ist neu installiert und im Cluster.
3. K3s etcd HA ist gesund.
4. Backup Phase 1 ist aktiv:
   - K3s etcd-S3 Snapshots.
   - Server-1 Restic.
   - Hindsight Postgres Dumps.
   - Timer.
   - Restore-Test.
5. OS-Restic Server 2/3 ist aktiv, hourly, Retention 48/14/8/12.
6. Longhorn ist installiert, validiert und seit 2026-05-24 Default StorageClass.
7. Longhorn Test-PVC/Test-App wurde validiert.
8. Longhorn Volume-Backup/Restore wurde fuer Testvolume validiert.
9. Longhorn SystemBackup wurde validiert.
10. Longhorn SystemBackup RecurringJob ist aktiv.
11. ingress-nginx ist installiert und extern ueber 80/443 erreichbar.
12. cert-manager ist installiert und validiert.
13. letsencrypt-prod ClusterIssuer ist Ready.
14. Portainer ist ueber Domain/TLS erreichbar.
15. Portainer NodePorts sind geschlossen.
16. Portainer wurde auf Longhorn migriert.
17. Alter Portainer local-path PVC bleibt als Rollback-Beleg.
18. Rebuild-Bundle wurde erzeugt.
19. Portainer/Kubernetes-API-Timeouts wurden per Robot-Firewall-Fix behoben.
20. Audit und Full Verify laufen aktuell gruen.
21. Longhorn Volume-RecurringJobs fuer `portainer/portainer-longhorn` sind
    aktiv und verifiziert.
22. Velero ist installiert und Smoke-Restore-validiert.
23. CloudNativePG ist mit Barman Cloud Plugin als nicht-produktiver
    Backup-/Restore-Baustein validiert.
24. Monitoring-Basisstack ist installiert; Prometheus, Alertmanager und Grafana
    sind intern Ready.

============================================================
6. Was Noch Offen Ist
============================================================

Priorisierte offene Liste:

1. Portainer Business Edition 3 Nodes Free ist aktiviert. Portainer Business
   nun final fachlich einrichten und pruefen, ohne Token/Passwoerter im Chat zu
   posten.

2. Portainer final in der UI pruefen/einrichten:
   - Benutzer/Admin.
   - Access Tokens.
   - DockerHub Registry.
   - Helm-Repositories.
   - Kubernetes Environment local.
   - Falls Business Edition aktiv: RBAC, Audit Logs, OAuth/SSO, 2FA/MFA falls verfuegbar.

3. DNS-/resolv.conf-Cleanup als separaten Betriebsblock planen:
   - Ursache der `Nameserver limits were exceeded` Events sauber beheben.
   - Keine DNS-Konfiguration blind loeschen.
   - Vor Umsetzung Backup-Zwischenstopp, dedizierte reduzierte
     K3s-Resolver-Datei planen, K3s/kubelet `resolv-conf` setzen, Nodes
     einzeln rollen und danach alle Audits ausfuehren.

4. Monitoring-Nacharbeit:
   - Externe Alertmanager-Receiver und gezielte ServiceMonitors/Alerts fuer
     Longhorn, Velero und CloudNativePG planen.

5. Healthchecks von Docker nach K3s + Longhorn migrieren.

6. Hindsight + Postgres von Docker nach K3s + Longhorn migrieren.

7. Produktive Postgres-Backup-Automation fuer spaetere CloudNativePG-
   Datenbanken planen:
   - pro App Backup-Schedules und Retention festlegen;
   - zusaetzliche `pg_dump`-CronJobs definieren;
   - Restore-Ziele und Restore-Tests festlegen.

8. Alerting konkret ausarbeiten:
   - externer Receiver ohne Secret-Ausgabe.
   - Longhorn degraded/faulted.
   - Velero/CloudNativePG Backup-Fehler.
   - Zertifikat laeuft ab.
   - Speicher-/Diskdruck.

10. Security-Hardening:
   - RBAC.
   - NetworkPolicies.
   - Pod Security Standards.
   - Image Scanning.
   - Admission Policies.
   - SOPS/External Secrets/Vault fuer Secrets-Management.

11. GitOps einfuehren, bevorzugt Argo CD:
   - gewünschter Cluster-Zustand in Git.
   - keine Klartext-Secrets.
   - Rebuild und Auditing nachvollziehbar machen.

12. Backup-Loeschschutz:
   - Object Lock/Versioning/Retention pruefen.
   - getrennte least-privilege Credentials pro Backup-Art.
   - S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar war.

13. Echter Disaster-Recovery-Test:
   - Ersatznodes aufbauen.
   - etcd/Velero/Longhorn/CloudNativePG/Restic Restore pruefen.
   - DNS/Firewall-Umschaltung dokumentieren.
   - Gaps dokumentieren.

14. Upgrade-Strategie fuer K3s, Longhorn, Portainer, ingress-nginx,
   cert-manager, Velero, CloudNativePG und OS-Patches dokumentieren.

15. Alten Portainer local-path PVC spaeter aufraeumen:
   - erst nach stabiler Laufzeit;
   - nur nach separater Freigabe;
   - vorher nochmal Backup/Verify.

============================================================
7. Reihenfolge Fuer Die Naechsten Arbeiten
============================================================

Empfohlene Reihenfolge:

Block A: Portainer UI Finalcheck
- Business Edition ist bereits aktiviert.
- Keine Tokens im Chat posten.
- Keine Passwoerter im Chat posten.
- Access Tokens nur Anzahl/Beschreibung, nie Werte.
- Registry nur Namen/Status, keine Credentials.

Block B: Longhorn RecurringJobs fuer Portainer
- Erledigt am 2026-05-24 fuer `portainer/portainer-longhorn`.
- Aktiv sind `prod-snapshot-hourly`, `prod-backup-daily` und
  `prod-backup-weekly` in Gruppe `prod-critical`.
- Keine Jobs auf Gruppe `default`, keine Testvolumes in `prod-critical`.

Block C: Velero
- Erledigt als Basisblock am 2026-05-24.
- Velero ist installiert und Smoke Backup/Restore ist abgeschlossen.
- Produktive Velero-Schedules nur nach app-spezifischer Freigabe anlegen.

Block D: CloudNativePG und Postgres-Backup
- Erledigt als nicht-produktiver Smoke-Test am 2026-05-24.
- Vor produktiver Nutzung pro App Schedules, Retention, Restore-Ziele und
  zusaetzliche `pg_dump`-CronJobs festlegen.

Block E: Monitoring/Alerting
- Basis-Monitoring ist installiert.
- node-exporter Scrape-Erreichbarkeit und Server-3-SSH-Pruefpfad sind
  korrigiert; Prometheus Targets sind `23/23` up.
- Naechster Schritt: externe Alertmanager-Receiver und gezielte
  Longhorn/Velero/CNPG-Monitore planen.

Block E2: DNS-/resolv.conf-Cleanup
- Geplant, noch nicht umgesetzt.
- Ziel: Kubernetes Event-Warnung `Nameserver limits were exceeded` bereinigen.
- Read-only-Befund: systemd-resolved liefert zu viele Upstream-Nameserver fuer
  Pod-DNS; Server 1 hat zusaetzlich Tailscale-DNS/Search-Domain.
- Umsetzung nur als eigener Betriebsblock mit Backup-Zwischenstopp,
  dedizierter reduzierter K3s-Resolver-Datei, K3s/kubelet `resolv-conf`,
  nodeweisem Rollout und anschliessenden Audits.

Block F: Security-Hardening
- RBAC, NetworkPolicies, Pod Security Standards, Image Scanning,
  Admission Policies und Secret-Management schrittweise einfuehren.
- Erst auditierend oder in Test-Namespaces, dann produktiv.

Block G: GitOps
- Argo CD oder Alternative einfuehren.
- Nicht-geheime Manifeste in Git.
- Secrets nur verschluesselt oder ueber External Secrets.

Block H: Backup-Loeschschutz
- Object Lock/Versioning/Retention pruefen.
- Backup-Credentials trennen.
- Sichtbare/alte Credentials rotieren und danach alle Backups testen.

Block I: Healthchecks Migration
- Compose und Daten read-only analysieren.
- Backup-Zwischenstopp.
- K8s Manifeste/Helm-Plan erstellen.
- Longhorn PVC verwenden.
- Testen.
- Erst nach erfolgreichem K3s-Betrieb Docker stoppen.

Block J: Hindsight + Postgres Migration
- Compose und Daten read-only analysieren.
- DB-Dump frisch erstellen.
- Backup-Zwischenstopp.
- Postgres bevorzugt ueber CloudNativePG auf Longhorn PVC.
- S3/WAL-Backup und `pg_dump` vor produktivem Switch testen.
- Hindsight auf K3s.
- Restore-Test.
- Erst nach erfolgreichem K3s-Betrieb Docker stoppen.

Block K: DR-Test und Upgrade-Strategie
- Ersatz-/Testumgebung definieren.
- Restore-Reihenfolge testen.
- Upgrade-Reihenfolge und Rollback-Kriterien dokumentieren.

============================================================
8. Backup-Zwischenstopp Pflicht
============================================================

Vor jeder groesseren Aenderung an:

- Portainer;
- Longhorn;
- PVC/PV/Storage;
- Helm Releases;
- Ingress/TLS;
- Firewall;
- produktiven Apps;
- Docker-App-Migrationen;
- Datenbanken;

muss dieser Zwischenstopp ausgefuehrt werden:

1. audit-recent-stack-claims.sh muss PASS sein.
2. verify-k3s-stack-complete.sh muss PASS sein.
3. Frischer K3s etcd Snapshot nach S3.
4. Frischer Server-1 Restic Lauf, solange Docker-App-Daten auf Server 1 liegen.
5. Frischer Longhorn SystemBackup, wenn Kubernetes-/Longhorn-Systemressourcen
   betroffen sind.
6. Bei Datenmigrationen: Restore-/Rollback-Weg vor der Migration benennen.
7. Danach erst Aenderung starten.

Wenn ein Backup-Schritt fehlschlaegt:
- sofort stoppen;
- nichts migrieren;
- nichts loeschen;
- Status und Logs melden.

============================================================
9. Strikte Nicht-Tun-Regeln
============================================================

Nicht tun ohne explizite Freigabe:

- Keine Secrets ausgeben.
- Keine Kubeconfig ausgeben.
- Keine .env Inhalte ausgeben.
- Keine Restic Passwortdateien ausgeben.
- Keine S3 Keys ausgeben.
- Keine Portainer Tokens ausgeben.
- Keine PVCs loeschen.
- Alten Portainer local-path PVC nicht loeschen.
- Keine Docker-Apps stoppen, bevor K3s-Ersatz laeuft und getestet ist.
- Longhorn ist bereits Default StorageClass; diese Entscheidung nicht ohne separaten Rollback-Plan aendern.
- local-path bleibt vorhanden, aber nicht Default; den alten Portainer-local-path-Rollback-PVC nicht ohne Cleanup-Plan loeschen.
- Keine Jobs auf Longhorn default-Gruppe legen.
- Keine Cloudflare Proxy-Aktivierung ohne Freigabe.
- Keine Firewall-Regeln entfernen ohne Freigabe.
- Keine NodePorts wieder oeffnen ohne Rollback-Plan.
- Velero ist installiert; keine Velero-Schedules, Restores in produktive
  Namespaces oder BackupStorageLocation-Aenderungen ohne separaten Plan.

============================================================
10. Wichtige Begriffe Fuer Diesen Stack
============================================================

Rollback-Beleg:
Der alte Portainer-local-path PVC bleibt als Rueckfallmoeglichkeit erhalten.
Wenn die neue Longhorn-Variante Probleme macht, kann man Portainer wieder auf
den alten PVC zurueckstellen. Nicht loeschen, bis stabiler Betrieb bestaetigt
und Cleanup freigegeben ist.

Rebuild-Bundle:
Ein nicht-geheimes Exportpaket fuer den Wiederaufbau. Es enthaelt Struktur,
Metadaten, redigierte Werte, Manifeste ohne Secret-Daten und Dokumentation.
Es ersetzt keine Backups. Es hilft, einen neuen Cluster strukturiert
nachzubauen.

Server 2/3:
Damit sind die Nodes activi-k3-2 und activi-k3-3 gemeint.

Longhorn Volume Backup:
Sichert echte Daten in Longhorn-PVCs. Jetzt relevant fuer Portainer und spaeter
fuer Healthchecks/Hindsight/Postgres nach Migration.

K3s etcd Snapshot:
Sichert den Kubernetes-Cluster-State, aber nicht die Dateiinhalte in Volumes.

Restic:
Sichert Host-Dateien und Docker-Daten, nicht automatisch Longhorn-Volume-Daten.

============================================================
11. Abschluss Jeder Session
============================================================

Am Ende jeder Agenten-Session:

1. Dokumente aktualisieren, wenn der Live-Stand geaendert wurde.
2. OPEN-TODOS-2026-05-22.md aktualisieren.
3. Wenn moeglich audit-recent-stack-claims.sh laufen lassen.
4. Bei groesseren Aenderungen verify-k3s-stack-complete.sh laufen lassen.
5. ~/.omc/SESSION-STATE.md aktualisieren mit:
   - Current Task
   - Last Response (Summary)
   - Pending Decisions
   - Open Items
   - Last Updated (YYYY-MM-DD HH:MM)

Danach dem Nutzer knapp melden:
- was erledigt wurde;
- welche Checks PASS sind;
- was noch offen ist;
- welches der naechste sichere Block ist.
```

## Kurzfassung Fuer Menschen

Der Cluster ist in einem guten, verifizierten Zustand. Die Infrastruktur-Basis
ist bereit fuer die naechsten Deploy-Schritte, aber die alten Docker-Apps
Healthchecks und Hindsight/Postgres laufen noch auf Server 1 und sind noch nicht
HA. Vor produktiven App-Deployments sollten Portainer Business/Community
entschieden, Portainer UI final geprueft, Longhorn Volume-Jobs fuer Portainer
angelegt und Monitoring/Alerting gestartet werden.

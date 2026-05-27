# K3s Hetzner Project Status - 2026-05-20

Stand: 2026-05-20 02:42 CEST.

## Aktueller Stand 2026-05-24

- `longhorn` ist die einzige Default StorageClass; `local-path` bleibt vorhanden, ist aber nicht Default.
- Portainer Business Edition ist aktiviert. Portainer laeuft produktiv auf `portainer/portainer-longhorn`, ist per `ingress-nginx`/cert-manager unter `https://portainer.activi.io` erreichbar und nutzt keinen NodePort.
- Velero ist seit 2026-05-24 installiert und per nicht-destruktivem Smoke Backup/Restore validiert.
- CloudNativePG Operator und Barman Cloud Plugin sind seit 2026-05-24 installiert und per Smoke Backup/Restore validiert. Produktive DB-Backups pro App sind noch offen.
- Monitoring-Basisstack ist installiert; Prometheus Targets sind nach Firewall-/Script-Nacharbeit gruen.
- Offene Gaps: produktive `pg_dump`-Automation pro App, GitOps, SOPS/External Secrets/Vault, vollstaendiger Replacement-Node-DR-Drill und DNS/resolv.conf-Cleanup als separater Block.

Hinweis 2026-05-24: Historische Zwischenstaende und Gap-Zahlen in diesem
Dokument sind Zeitpunkt-Snapshots. Massgeblich fuer neue Sessions sind
`SESSION-HANDOVER-2026-05-24.md` und `OPEN-TODOS-2026-05-22.md` sowie die
neuesten Audit-/Verify-Logs.

Update 2026-05-21 08:06 CEST: Backup Phase 1 ist funktional automatisiert und
validiert. Longhorn ist per Helm `1.11.2` installiert und validiert.
Longhorn Test-PVC/Test-App, Longhorn Volume-Backup/Restore-Test und Longhorn
SystemBackup sind validiert. Velero gehoert nicht zu diesem 2026-05-21-Stand;
Velero wurde erst am 2026-05-24 installiert und restore-getestet.

Update 2026-05-24 02:18 CEST: Default StorageClass wurde von `local-path` auf
`longhorn` umgestellt. `local-path` bleibt vorhanden, ist aber nicht mehr
Default. Bestehende PVCs wurden nicht migriert; der alte Portainer-`local-path`
PVC bleibt nur als Rollback-Beleg erhalten.

Update 2026-05-24 02:45 CEST: Der neue Storage-Sollzustand wurde live
gegengeprueft. `longhorn` ist die einzige Default StorageClass, `local-path`
ist vorhanden aber nicht Default, `longhorn-static` ist vorhanden.
`portainer/portainer-longhorn` ist der einzige produktive Longhorn-PVC und wird
vom laufenden Portainer-Deployment genutzt. Der alte PVC `portainer/portainer`
auf `local-path` wird von keinem laufenden Pod genutzt und bleibt nur
Rollback-Altbestand. Keine NodePorts, LoadBalancer-Services oder
ExternalName-Services sind vorhanden. Die frischen Pruefungen:

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

Update 2026-05-24 03:05 CEST: Longhorn Volume-RecurringJobs fuer das
produktive Portainer-Longhorn-Volume wurden umgesetzt und verifiziert. Erstellt
wurden ausschliesslich diese Jobs in Gruppe `prod-critical`:
`prod-snapshot-hourly` (`snapshot`, Cron `7 * * * *`, Retain `48`),
`prod-backup-daily` (`backup`, Cron `37 1 * * *`, Retain `14`) und
`prod-backup-weekly` (`backup`, Cron `12 3 * * 0`, Retain `8`). Nur das
Longhorn Volume `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b` fuer
`portainer/portainer-longhorn` wurde mit `prod-critical` markiert. Testvolumes
im Namespace `longhorn-test` wurden nicht aufgenommen. Es wurde kein Job auf
Gruppe `default` erstellt; `lh-system-backup-daily` blieb unveraendert.
Frische Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-025911.log
RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-030246.log
RESULT: PASS
Passes: 131
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-030429.log
RESULT: PASS_WITH_GAPS
Passes: 22
Warnings: 0
Gaps: 8
Failures: 0
```

Damaliger naechster freizugebender Block war: Velero installieren und
Namespace-Restore nicht-destruktiv testen. Dieser Block ist im folgenden Update
erledigt.

Update 2026-05-24 03:45 CEST: Velero wurde per Helm installiert und live
validiert. Velero Version `1.18.0`, Helm Chart `velero-12.0.1`, Namespace
`velero`. BackupStorageLocation `default` ist `Available` und nutzt Hetzner
Object Storage S3 Bucket `activi`, Prefix `velero`, Endpoint
`https://fsn1.your-objectstorage.com`, Region `fsn1`; Secret-Werte wurden nicht
ausgegeben. Nicht-destruktiver Smoke-Test:
Backup `velero-smoke-backup-20260524` fuer Namespace
`velero-smoke-source-20260524` ist `Completed`; Restore
`velero-smoke-restore-20260524` in separaten Namespace
`velero-smoke-restore-20260524` ist `Completed`. Es wurden keine produktiven
Namespaces, PVCs, Portainer-, Longhorn-, StorageClass-, Firewall- oder
DNS-Einstellungen geaendert.

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

Naechster freizugebender Block: CloudNativePG mit S3/WAL und zusaetzlichem
`pg_dump` fuer Postgres auf Longhorn testen. Danach Monitoring/Alerting,
GitOps/External Secrets und echter DR-Test.

Update 2026-05-24 05:26 CEST: CloudNativePG wurde als nicht-produktiver
Test-/Backup-Baustein installiert und validiert. Operator: Helm Chart
`cloudnative-pg-0.28.2`, App Version `1.29.1`, Namespace `cnpg-system`.
Barman Cloud Plugin: `ghcr.io/cloudnative-pg/plugin-barman-cloud:v0.12.0`,
Deployment `cnpg-system/barman-cloud`, `Ready 1/1`. Verwendet wurde
ausschliesslich der aktuelle Plugin-Weg, nicht der deprecated
`barmanObjectStore`-Clusterpfad.

Nicht-produktiver Test:

```text
Source Namespace: cnpg-smoke-20260524
Source Cluster: cnpg-smoke, 1 Instanz, StorageClass longhorn, 1Gi
ObjectStore: cnpg-smoke-store
S3 Ziel: s3://activi/cloudnativepg/smoke-20260524
S3 Endpoint: https://fsn1.your-objectstorage.com
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
StorageClass, Firewall und DNS blieben unveraendert. Der fehlgeschlagene erste
pg_dump-Testjob `cnpg-smoke-pgdump-20260524` wurde nach expliziter Freigabe
geloescht; Ursache war eine harmlose Rechteabweichung der Smoke-Testtabelle.

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

Naechster freizugebender Block: Monitoring/Alerting einrichten oder vorher
produktive `pg_dump`-Automation/Schedules fuer spaetere produktive
CloudNativePG-Datenbanken konkret planen. Weiterhin nicht automatisch mit
produktiven Apps oder Matrix fortfahren.

Update 2026-05-24 12:17 CEST: Der Monitoring-Basisblock wurde installiert.
Release `kube-prometheus-stack` im Namespace `monitoring`, Chart
`kube-prometheus-stack-85.3.0`, App Version `v0.90.1`. Installiert wurden
Prometheus, Alertmanager, Grafana, kube-state-metrics, node-exporter und die
erwarteten Prometheus-Operator-CRDs. Es wurde kein Grafana-Ingress, kein
NodePort, kein LoadBalancer und kein externer Alert-Receiver angelegt.

Storage:

```text
Prometheus PVC: 10Gi, storageClass longhorn, Bound
Alertmanager PVC: 2Gi, storageClass longhorn, Bound
Grafana PVC: 5Gi, storageClass longhorn, Bound
```

Readiness:

```text
Prometheus: Ready
Alertmanager: Ready
Grafana: Ready, /api/health database ok
Services: ClusterIP
Monitoring Ingress: keiner
StorageClass: longhorn bleibt einzige Default StorageClass
```

Prometheus Targets waren direkt nach der Installation `23` gesamt, `21` up,
`2` problematisch. Problematisch waren die Node-Exporter-Targets
`10.0.1.20:9100` und `10.0.1.30:9100` mit `context deadline exceeded`.
Zusatzdiagnose zeigte: node-exporter selbst war gesund; blockiert war private
Cross-Node-Erreichbarkeit auf TCP `9100`. Der notwendige private
Firewall-/UFW-Pfad wurde spaeter freigegeben und erneut verifiziert.

Portainer, Longhorn, Velero und CloudNativePG blieben nach der Installation
healthy. Der damalige Nebenbefund `Too many authentication failures` fuer
Server 3 betraf nur den lokalen SSH-Pruefpfad. Die Skripte wurden danach fuer
Server 3 auf `-o IdentitiesOnly=yes` mit Key `~/.ssh/k3-3` korrigiert.

Historische Nachher-Pruefungen direkt nach der Monitoring-Installation:

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

Naechster freizugebender Block: Monitoring-Nacharbeit planen. Konkret:
Node-Exporter-Erreichbarkeit fuer Server 2/3 klaeren, Server-3-SSH-Pruefpfad
der Skripte korrigieren oder freigeben lassen, danach externe Alert-Receiver
und weitere ServiceMonitors fuer Longhorn, Velero und CloudNativePG gezielt
ergaenzen.

Update 2026-05-24 14:05 CEST: Monitoring-Nacharbeit fuer node-exporter und
Server-3-SSH-Pruefpfad ist abgeschlossen. Server 3 wird in den Skripten mit
`-o IdentitiesOnly=yes -i ~/.ssh/k3-3` geprueft. Private TCP-Erreichbarkeit
`9100` ist zwischen allen drei Nodes gruen; Prometheus Targets sind `23/23`
up. Abschlusspruefungen:

```text
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

Offener geplanter Betriebsblock: DNS-/resolv.conf-Cleanup. Kubernetes Events
melden wiederholt `Nameserver limits were exceeded`. Read-only-Pruefung zeigte,
dass alle Nodes systemd-resolved Stub `/etc/resolv.conf` nutzen und die echte
`/run/systemd/resolve/resolv.conf` mehr Nameserver enthaelt, als Kubernetes pro
Pod uebernimmt. Server 1 hat zusaetzlich Tailscale-DNS/Search-Domain
`tail47b17c.ts.net`. Kein Notfall, aber vor produktiven App-Rollouts als
separater K3s-Betriebsblock planen: reduzierte dedizierte K3s-Resolver-Datei
mit Hetzner DNS, K3s/kubelet `resolv-conf` sauber setzen, Nodes einzeln
rollen, danach alle Audits erneut ausfuehren. Nicht ohne Backup-Zwischenstopp
und separate Freigabe umsetzen.

Update 2026-05-21 09:47 CEST: Longhorn SystemBackup-RecurringJob ist angelegt
und auf `volume-backup-policy=disabled` korrigiert. Ein manueller Pre-Apps
SystemBackup `lh-system-backup-pre-apps-20260521-disabled` ist `Ready`. OS-Level
Restic fuer Server 2/3 ist als separater Plan dokumentiert, aber noch nicht
umgesetzt.

Update 2026-05-21 11:53 CEST: OS-Level Restic fuer Server 2/3 ist jetzt
automatisiert und validiert. Auf beiden Nodes existieren
`k3s-os-restic-backup.service` und `k3s-os-restic-backup.timer`; manuelle
Service-Tests, neue Snapshots, `restic check` und vollstaendiges Verify sind
erfolgreich.

Dieses Dokument ist die kompakte Statusuebersicht. Details und Sicherheitsregeln stehen im Handover:

```text
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
```

Update 2026-05-23 06:30 CEST: Der Zielplan wurde auf Production Readiness
erweitert. Neben K3s/Longhorn/Portainer/Restic gehoeren jetzt verbindlich dazu:
Velero fuer Kubernetes-Ressourcen, CloudNativePG fuer Postgres auf Longhorn mit
S3/WAL-Backups, zusaetzliche `pg_dump`-Exports, Monitoring/Alerting,
Security-Hardening, GitOps/Argo CD, Backup-Loeschschutz und ein echter
Disaster-Recovery-Test auf Ersatznodes. Der detaillierte Plan liegt unter:

```text
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-23-production-readiness-hardening-plan.md
```

Update 2026-05-24 00:02 CEST: Historischer Zwischenstand. Das neue
Production-Readiness-/Gap-Audit wurde angelegt und live ausgefuehrt:

```text
/Users/activi/Documents/activi K3s/audit-production-readiness-gaps.sh
/tmp/k3s-production-readiness-gap-audit-20260524-000209.log
RESULT: PASS_WITH_GAPS
Passes: 20
Warnings: 1
Gaps: 9
Failures: 0
```

Einordnung zum damaligen Zeitpunkt: Der Stack war konsistent und ohne erkannte
harte Konflikte. Die Gaps waren die geplanten, noch nicht umgesetzten
Production-Readiness-Bloecke: Longhorn Volume-RecurringJobs, Velero,
CloudNativePG, `pg_dump` fuer K3s-Postgres, Monitoring/Alerting, GitOps,
Secret-Management und echter DR-Test. Die einzelne Warnung betraf die lokale
SSH-Pruefbarkeit von Server 2 aus dieser Session. Update 2026-05-24: Der User
hat `ssh kube3-2` getestet und als funktionierenden Server-2-Alias gemeldet.
Die lokalen Pruefscripte wurden auf `kube3-2` als Server-2-Default umgestellt;
die erneute Live-Verifikation wurde spaeter abgeschlossen. Dieser historische
00:02-Stand ist durch die Updates 01:12 und 03:05 ueberholt.

Update 2026-05-24 01:12 CEST: Die Server-2-Verifikationsluecke ist geschlossen.
`ssh kube3-2 'hostname && date -Is'` meldete `activi-k3-2`. OS-Restic auf
Server 2 wurde read-only geprueft: `restic 0.16.4`, Timer
`k3s-os-restic-backup.timer` `enabled`/`active`, root-only Metadatenrechte
korrekt, 49 Snapshots sichtbar mit Host `activi-k3-2` und Tag `os-server2`,
`restic check` ohne Fehler. Die vier Pruefscripte liefen danach erneut:

```text
/tmp/portainer-api-connectivity-20260524-010923.log
RESULT: PASS
Passes: 7
Failures: 0

/tmp/k3s-recent-stack-claims-audit-20260524-010939.log
RESULT: PASS
Passes: 53
Warnings: 0
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-011026.log
RESULT: PASS
Passes: 126
Warnings: 0
Failures: 0

/tmp/k3s-production-readiness-gap-audit-20260524-011155.log
RESULT: PASS_WITH_GAPS
Passes: 21
Warnings: 0
Gaps: 9
Failures: 0
```

Einordnung: Die fruehere Server-2-SSH-Warning ist verschwunden. Die verbleibenden
Gaps waren zu diesem Zeitpunkt die geplanten Production-Readiness-Bloecke:
Longhorn Volume-RecurringJobs fuer produktive PVCs, Velero, CloudNativePG,
CloudNativePG-Testdatenbank, Kubernetes-Postgres-`pg_dump`, Monitoring/Alerting,
GitOps, External Secrets/SOPS/Vault und echter Replacement-Node-DR-Test. Der
Longhorn-Volume-RecurringJob-Gap wurde im Update 03:05 geschlossen. Der
Velero-Gap wurde im Update 03:45 geschlossen.

## Gesamtstatus

| Bereich | Status | Naechste Aktion |
| --- | --- | --- |
| 3-Node K3s HA | erledigt, Startcheck 2026-05-20 02:30 CEST geloggt | Weiter mit Backup-/Storage-Vorbereitung |
| Server 3 Reinstall/Join | erledigt | Nicht mehr destruktiv anfassen |
| etcd | 3 full members healthy | Externe Snapshots/Restore klaeren |
| Portainer | Business Edition aktiviert, laeuft ueber Domain/TLS, Service `ClusterIP`, keine NodePorts, aktiver PVC `portainer-longhorn` auf Longhorn | Pflicht: kompletter UI-Setup-Check, Business-Funktionen gezielt konfigurieren, Access Tokens/Registry/Helm-Repos/Environment pruefen |
| Server-1-Docker-Apps | noch ausserhalb K3s, aber in Backup Phase 1 gesichert | Migration nach Longhorn-/Storage-Test planen |
| Backup-System | Phase 1 aktiv: K3s etcd-S3, Restic-S3 fuer Server 1, Hindsight Dumps, Timer und Restore-Test validiert; Longhorn Volume-Backup/Restore, SystemBackup, SystemBackup-RecurringJob und produktive Portainer-Volume-RecurringJobs validiert; Velero installiert und Smoke-Restore validiert; CloudNativePG/Barman-Smoke-Test validiert; OS-Level Restic fuer Server 2/3 automatisiert und validiert | Optional S3-Credentials rotieren; produktive `pg_dump`-Automation pro App planen |
| Longhorn | installiert: Helm `longhorn-1.11.2`, Backup Target `AVAILABLE=true`, Test-PVC, Volume-Backup/Restore, SystemBackup und SystemBackup-RecurringJob validiert, `longhorn` ist einzige Default StorageClass; `portainer/portainer-longhorn` ist in Gruppe `prod-critical` | Keine Jobs auf `default`; Testvolumes bleiben ausgeschlossen; spaetere produktive PVCs nur nach eigener Freigabe in `prod-critical` aufnehmen |
| OS-Level Backup Server 2/3 | aktiv: Server 2/3 OS-Restic Repos initialisiert, manuelle Backups validiert, systemd Timer aktiv, Verify PASS | Automatische Timerlaeufe nach dem ersten geplanten Lauf kontrollieren; keine produktiven Migrationen ohne separaten Plan |
| Ingress/TLS | aktiv: ingress-nginx, cert-manager, `https://portainer.activi.io` | Weitere Apps nur mit separater Ingress-/TLS-Freigabe |
| Firewall-Hardening | Portainer-NodePorts geschlossen, 80/443 aktiv, Pod-to-API-Pfad stabil | SSH/K3s/Node-Firewall spaeter schrittweise haerten |
| Velero | installiert: Version `1.18.0`, Chart `velero-12.0.1`, BackupStorageLocation `default` Available, Smoke Backup/Restore erfolgreich | Spaeter app-spezifische Schedules/Data-Movement nur nach eigener Freigabe planen |
| CloudNativePG/Postgres | nicht-produktiver Smoke-Test installiert und validiert; keine produktiven Datenbanken | fuer neue Postgres-Workloads pro App S3/WAL-Schedules, Retention, Restore und `pg_dump` planen |
| Monitoring/Alerting | Basisstack installiert; Prometheus/Alertmanager/Grafana Ready; node-exporter Targets `23/23` up | Externe Alertmanager-Receiver und gezielte ServiceMonitors/Alerts fuer Longhorn, Velero und CloudNativePG planen |
| GitOps | noch nicht installiert | Argo CD oder Alternative einfuehren, bevor viele Apps manuell auseinanderlaufen |

Update 2026-05-22 22:36 CEST:

- Portainer/Kubernetes-API-Timeouts wurden diagnostiziert und behoben.
- Symptom: Portainer UI war langsam; Portainer-Logs zeigten Timeouts zum Kubernetes-Service `10.43.0.1:443`.
- Ursache: Die Kubernetes-Service-Verteilung war normal, aber Rueckpakete von Server 2/3 wurden durch die Hetzner Robot Firewall nicht stabil akzeptiert. Die alte `tcp established` ACK-Regel war auf Ziel-Ports `32768-65535` begrenzt; Flannel/NAT nutzte aber auch niedrigere Rueckports.
- Fix auf allen drei Hetzner Robot Firewalls: `tcp established`, IPv4/TCP, Quelle `0.0.0.0/0`, Ziel `0.0.0.0/0`, Quell-Port `0-65535`, Ziel-Port `0-65535`, TCP-Flags `ack`, Aktion `accept`.
- Wichtig: Das ist keine Freigabe aller neuen Verbindungen. Durch `TCP-Flags ack` gilt die Regel nur fuer Antwort-/Established-Pakete.
- Bestehende private K3s-Regeln bleiben bestehen, inklusive `10.0.1.0/24` fuer K3s-Ports und `10.42.0.0/16 -> 6443` fuer Pod-Netz zu Kubernetes API.
- Die erfolglose Server-1-UFW-Route-Regel `cni0 -> enp41s0.4000` fuer `10.42.0.0/16 -> 10.0.1.0/24:6443` wurde entfernt.
- Neues Pruefskript: `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`.
- Portainer-Pod-Netzpruefung: `RESULT: PASS`, 60/60 erfolgreiche Versuche zu `10.0.1.10:6443`, `10.0.1.20:6443`, `10.0.1.30:6443` und `10.43.0.1:443`, Log `/tmp/portainer-api-connectivity-20260523-024920.log`.
- Recent-Audit nach Fix: `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260523-024855.log`.
- Full Verify nach Fix: `RESULT: PASS`, `Passes: 126`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260523-025031.log`.
- Das Audit- und Full-Verify-Skript pruefen die Portainer-Pod-zu-Kubernetes-API-Konnektivitaet jetzt aktiv mit.

## Backup-Arten und Zustaendigkeit

Die Backup-Arten laufen bewusst nicht identisch auf allen Nodes. Sie sichern
unterschiedliche Datenklassen und werden dort ausgefuehrt, wo die Daten sinnvoll
erreichbar sind.

| Backup-Art | Wo aktiv | Sichert | Sichert nicht | Status |
| --- | --- | --- | --- | --- |
| K3s etcd-Snapshot | Server 1 als Control-Plane-Node | Kubernetes-/Cluster-State: Deployments, Services, Secrets, ConfigMaps, PVC-Objekte, Ingress-Objekte, Cluster-Metadaten | keine vollstaendigen Volume-Dateiinhalte, keine Host-OS-Rekonstruktion | aktiv nach S3, 2x taeglich plus manuell vor Aenderungen |
| Restic Server 1 | Server 1 | Server-1-Dateien: K3s Token/Configs, lokale Snapshots, Docker-App-Daten, Compose-Dateien, `.env` Dateien als Dateien, Hindsight Postgres Dumps, alter Portainer-`local-path` Rollback-PVC bis Cleanup | keine OS-Rekonstruktion von Server 2/3, keine Longhorn-Volume-Strategie | aktiv, hourly Backup, Retention hourly/daily/weekly/monthly |
| OS-Restic Server 2/3 | Server 2 und Server 3 | Node-/OS-Konfiguration: `/etc`, `/root`, `/home`, Cron, Paketlisten, systemd-/Netzwerk-/Disk-Metadaten | kein K3s etcd, keine Longhorn-Volume-Daten, keine Docker-App-Daten von Server 1 | aktiv, hourly automatisiert, Retention 48/14/8/12 |
| Longhorn Volume-Backup | Longhorn im Cluster | echte Daten in Longhorn-PersistentVolumes, aktuell Portainer und spaeter freigegebene App-PVCs | kein K3s etcd, kein Host-OS, keine `local-path` PVs, keine datenbankbewussten Dumps | fuer Testvolume validiert; produktive RecurringJobs fuer `portainer/portainer-longhorn` aktiv: hourly Snapshot, daily Backup, weekly Backup in Gruppe `prod-critical` |
| Longhorn SystemBackup | Longhorn im Cluster | Longhorn-Systemzustand und Longhorn-eigene Ressourcen | keine App-Daten als Ersatz fuer Volume-Backups, kein K3s etcd | aktiv, taeglich 02:17, Retain 14 |
| Velero | installiert im Cluster | Kubernetes-Ressourcen/Namespaces nach S3; Smoke Backup/Restore validiert | ersetzt weder etcd-DR noch Restic noch Longhorn-Volume-Backups noch DB-Dumps | Basis-Smoke-Test erledigt; app-spezifische Schedules/Data-Movement spaeter nur nach Freigabe |
| CloudNativePG S3/WAL | Operator `1.29.1` und Barman Cloud Plugin `v0.12.0` installiert; nicht-produktiver Smoke Backup/Restore validiert | konsistente Postgres-Backups und Point-in-Time-Recovery fuer Postgres im Cluster | keine App-Dateien, kein K3s etcd, kein Host-OS | produktive DB-Backups pro App inkl. WAL/Retention/Restore und zusaetzlichem `pg_dump` noch offen |
| pg_dump | fuer Hindsight-Dumps auf Server 1 vorhanden; fuer K3s-Postgres noch offen | logische DB-Exports, leicht pruefbar | kein vollstaendiger Cluster-/Volume-Ersatz | pro produktiver DB zusaetzlich einrichten |

Prinzip: Nicht jede Backup-Art auf jedem Node ausrollen. Stattdessen jede
Datenklasse genau einmal sinnvoll sichern, plus Offsite-Ziel und Restore-Test.
Blind gleiche Jobs auf allen Nodes wuerden doppelte Daten, hoehere Kosten und
mehr Fehlerquellen erzeugen.

## Cluster

| Server | Hostname | Public IP | Private IP | Interface | Rolle | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Server 1 | `activi-k3-1.0` | `88.99.215.210` | `10.0.1.10` | `enp41s0.4000` | control-plane/etcd/master | Ready |
| Server 2 | `activi-k3-2` | `178.63.12.52` | `10.0.1.20` | `enp41s0.4000` | control-plane/etcd/master | Ready |
| Server 3 | `activi-k3-3` | `167.235.6.160` | `10.0.1.30` | `enp7s0.4000` | control-plane/etcd/master | Ready |

K3s Version: `v1.32.1+k3s1`.

SSH-/Zugangsstand:

- Server 1: Alias `k3-1`.
- Server 2: Alias `kube3-2`; am 2026-05-24 vom User getestet und als
  funktionierend gemeldet.
- Server 3: bekannter lokaler Key `/Users/activi/.ssh/k3-3`.
- Nicht-geheime Verbindungsuebersicht:
  `/Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md`.

etcd:

- Server 1 Endpoint: `https://10.0.1.10:2379`, Member `ubuntu-noble-latest-amd64-base-3982578f`
- Server 2 Endpoint: `https://10.0.1.20:2379`, Member `activi-k3-2-48af0a1d`
- Server 3 Endpoint: `https://10.0.1.30:2379`, Member `activi-k3-3-82cc6d74`
- Alle drei Endpoints waren healthy.
- Alle drei Member waren `learner=false`.

Die Live-Member-Namen sind generiert und weichen von den Hostnames ab. Das ist dokumentiert und technisch ok, solange Member-ID, URL, `started`, `learner=false` und Health stimmen.

Aktueller Startcheck-Log:

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

Wichtiger Snapshot:

```text
post-server3-join-20260520-013351-activi-k3-1.0-1779233631
```

## Portainer

Status:

- Namespace: `portainer`
- Deployment: `portainer`, Helm-managed, `1/1` verfuegbar
- Image: `portainer/portainer-ee:2.39.2`
- Helm Release: `portainer`, Chart `portainer-239.2.0`
- Aktiver PVC: `portainer-longhorn`, `Bound`, `10Gi`, StorageClass `longhorn`
- Alter Rollback-PVC: `portainer`, `Bound`, StorageClass `local-path`, Annotation `helm.sh/resource-policy=keep`
- Service: `ClusterIP`, Ports `9000/TCP`, `9443/TCP`, `8000/TCP`; keine Kubernetes-NodePorts
- Pod-IP ist nur intern (`10.42.x.x`); keine externe Pod-IP ist erwartet oder erforderlich.
- Externer Domain-Check: `https://portainer.activi.io` antwortet mit `HTTP/2 200`.
- HTTP leitet mit `308 Permanent Redirect` auf HTTPS um.
- Passwort-Reset wurde abgeschlossen; der temporaere Reset-Pod wurde geloescht.

Offen:

- 2FA/MFA pruefen/aktivieren, falls in der aktuellen Edition verfuegbar.
- Portainer komplett einrichten: Admin-Zugang, 2FA/MFA, Access Tokens, Helm-Repos und Kubernetes Environment pruefen.
- Portainer Business Edition 3 Nodes Free ist aktiviert. Business-Funktionen sind gezielt einzurichten, aber nicht jede BE-Funktion muss sofort genutzt werden.
- Portainer-Longhorn-Migration ist erledigt und validiert.

## Backup-Zwischenstopps vor groesseren Aenderungen

Vor jeder groesseren Aenderung an Portainer, Storage, PVCs, Helm-Releases,
Ingress/TLS, Firewall oder produktiven Apps ist ein Backup-Zwischenstopp Pflicht:

1. `audit-recent-stack-claims.sh` und `verify-k3s-stack-complete.sh` muessen `PASS` sein.
2. Frischer K3s etcd Snapshot nach S3 fuer Kubernetes-/Cluster-State.
3. Frischer Server-1 Restic Backup-Lauf, solange Portainer oder Docker-App-Daten auf Server 1 liegen.
4. Frischer Longhorn SystemBackup, wenn Longhorn-/Kubernetes-Systemressourcen betroffen sind.
5. Sichtbarkeit der neuen Backups pruefen, ohne Secret-Werte auszugeben.
6. Erst danach Migration oder groessere Aenderung starten.

Wenn ein Backup- oder Verify-Schritt fehlschlaegt, wird die Aenderung nicht gestartet.

## Server-1-Datenmigration

Status: offen.

Server 1 betreibt noch diese Docker-Apps ausserhalb von K3s:

| App | Container/Image | Ports | Compose |
| --- | --- | --- | --- |
| Healthchecks | `healthchecks/healthchecks:latest` | `8000` | `/opt/healthchecks/docker-compose.yml` |
| Hindsight | `ghcr.io/vectorize-io/hindsight:latest` | `8888`, `9999` | `/root/hindsight/docker-compose.yml` |
| Hindsight Postgres | `pgvector/pgvector:pg16` | `5432` | `/root/hindsight/docker-compose.yml` |

Bekannte Volumes:

```text
healthchecks_healthchecks_data
hindsight-data
hindsight_hindsight-data
hindsight_hindsight-postgres-data
```

Vorhandene alte Migrationsbackups:

```text
/root/k3s-migration-backup/20260519-0430/healthchecks.tar.gz
/root/k3s-migration-backup/20260519-0430/hindsight-data.tar.gz
/root/k3s-migration-backup/20260519-0430/hindsight-postgres.tar.gz
```

Noch zu tun:

1. Frische Backups und DB-Dumps erstellen.
2. Ziel-Namespaces, StorageClass und Domains entscheiden.
3. Erst Test-App/Storage pruefen.
4. Apps einzeln migrieren.
5. Alte Docker-Instanzen erst nach verifizierter Migration stoppen.

## Backup-System

Status: Phase 1 aktiv, automatisiert und nicht-destruktiv validiert.

Aktiver Stand:

- K3s native etcd-Snapshots werden nach Hetzner Object Storage S3 geschrieben.
- Bucket/Endpoint: `activi`, `https://fsn1.your-objectstorage.com`, Region `fsn1`.
- Bucket-Erstellung laut Hetzner Console/Erstellungsdialog: Object Lock `aktiviert`, Sichtbarkeit `privat`.
- S3-Ziel fuer etcd: `s3://activi/k3s/etcd/`.
- Restic Repository: `s3:https://fsn1.your-objectstorage.com/activi/restic/server1`.
- Restic sichert K3s Token/Configs, lokale Snapshots, Docker-App-Daten, Compose-Dateien, `.env` Dateien als Dateien, Hindsight Postgres Dumps und bis Cleanup den alten Portainer-`local-path` Rollback-PVC.
- Hindsight Postgres Dumps liegen unter `/var/lib/k3s-backup/postgres-dumps/`.
- Nicht-destruktiver Restore-Test liegt unter `/var/lib/k3s-backup/restore-test/restic-20260521-000917`.

Validierte Belege:

- K3s S3 Snapshots:
  - `manual-phase1-s3-20260521-000704-activi-k3-1.0-activi-k3-1.0-1779314824`
  - `manual-phase1-20260521-002925-activi-k3-1.0-activi-k3-1.0-1779316166`
- Restic Snapshots:
  - `d4faae42`
  - `c2b385b0`
  - `c9af17e7`
- `restic check`: keine Fehler.
- Datei-/Dump-Restore-Test: erfolgreich, Dump gzip-lesbar.
- Erster automatischer Timerlauf:
  - `hindsight-postgres-dump.timer`: 2026-05-21 01:04:27 CEST, erfolgreich.
  - `k3s-restic-backup.timer`: 2026-05-21 01:04:47 CEST, Snapshot `c9af17e7`, erfolgreich.
- Backup-Phase-1-Preflight:
  - `RESULT: PASS`
  - `Warnings: 0`
  - `Failures: 0`
  - Log: `/tmp/k3s-backup-phase1-check-20260521-010319.log`

Aktive Timer:

```text
hindsight-postgres-dump.timer  hourly
k3s-restic-backup.timer        hourly
k3s-restic-forget.timer        daily ca. 03:30 plus RandomizedDelaySec
k3s-etcd-snapshot-s3.timer     taeglich 00:10 und 12:10 plus RandomizedDelaySec
k3s-restic-prune.timer         sonntags ca. 04:30 plus RandomizedDelaySec
```

Retention / Zeitplan-Einordnung:

- Server-1-Restic hat bewusst die feinste Retention, weil dort aktuell die
  meisten aktiv veraenderten Dateien liegen: `hourly 48`, `daily 14`,
  `weekly 8`, `monthly 12`.
- K3s etcd-S3-Snapshots laufen 2x taeglich und zusaetzlich manuell vor groesseren
  Aenderungen. Eine Erhoehung auf 4x taeglich ist optional, aber nicht zwingend
  fuer den aktuellen Stand.
- OS-Restic Server 2/3 laeuft taeglich, weil dort nur OS-/Node-Konfiguration
  gesichert wird. Dieser Scope aendert sich deutlich seltener als Server-1-App-
  Daten.
- Longhorn SystemBackup laeuft taeglich und sichert Longhorns Systemzustand.
- Longhorn Volume-Snapshot-/Volume-Backup-RecurringJobs sind fuer
  `portainer/portainer-longhorn` aktiv. Weitere produktive Longhorn-Volumes
  duerfen erst nach separater Freigabe einer eigenen Gruppe wie
  `prod-critical` zugewiesen werden. Keine Jobs auf `default`; Testvolumes
  bleiben ausgeschlossen.

Longhorn Phase 2 Stand:

- Host-Voraussetzungen auf allen drei Nodes: `nfs-common` installiert, `iscsid` enabled/active.
- Helm Release: `longhorn`, Chart `longhorn-1.11.2`, App `v1.11.2`, Status `deployed`.
- Backup Target: `s3://activi@fsn1/longhorn/`, Secret `longhorn-s3-backup`, `AVAILABLE=true`.
- StorageClasses: `longhorn (default)`, `local-path`, `longhorn-static`.
- Test-PVC/Test-App: Namespace `longhorn-test`, PVC `longhorn-test-pvc` `Bound`; der Schreib-/Lesetest war erfolgreich.
- Backup/Restore-Test: Backup-CR `lh-test-backup-20260521-0309` `Completed`; Restore-PVC `longhorn-test-restore-pvc` `Bound`; wiederhergestellter Inhalt `longhorn-test-2026-05-21T01:06:38+0000`.
- Testressourcen bleiben bewusst als Beleg stehen:
  - Namespace `longhorn-test`.
  - Pods `longhorn-test-writer` und `longhorn-test-restore-reader` sind inzwischen `Completed`.
  - PVCs `longhorn-test-pvc` und `longhorn-test-restore-pvc` sind `Bound`.
  - Longhorn Volumes sind aktuell `detached` mit Robustness `unknown`, weil keine laufenden Test-Pods mehr daran haengen.
  - Snapshot `lh-test-snap-20260521-0309`, Backup-CR `lh-test-backup-20260521-0309` und BackupVolume bleiben vorhanden.
  - Spaeterer Cleanup nur nach separater Loeschfreigabe.
- Unabhaengiger Check: `/Users/activi/Documents/activi K3s/check-longhorn-phase2.sh`
  lief am 2026-05-21 05:10 CEST mit `RESULT: PASS`, `Failures: 0`, `Warnings: 0`.
- Longhorn SystemBackup:
  - Fix: `backup-execution-timeout` von `1` auf `5` Minuten erhoeht.
  - Neuer SystemBackup `lh-system-backup-20260521-timeout5` ist `Ready`, Version `v1.11.2`.
  - Pre-Apps SystemBackup `lh-system-backup-pre-apps-20260521-disabled` ist `Ready`, Version `v1.11.2`.
  - SystemBackup-RecurringJob `lh-system-backup-daily` existiert: Cron `17 2 * * *`, Retain `14`, Groups `[]`, `volume-backup-policy=disabled`.
  - Alter Error-CR `lh-system-backup-20260521-initial` bleibt als Beleg bestehen.
  - Weiterer Error-CR `lh-system-backup-pre-apps-20260521-0913` bleibt als Beleg fuer die verworfene `if-not-present`-Policy bestehen.
  - Normales Longhorn Volume-Backup/Restore bleibt validiert.
- Damaliger Stand: keine produktiven PVCs migriert.
- Aktueller Stand seit 2026-05-24: Portainer nutzt Longhorn, produktive
  Portainer-Volume-RecurringJobs sind aktiv und Velero ist installiert sowie
  per Smoke-Restore validiert.

OS-Level Backup Server 2/3:

- Status: aktiv, automatisiert und validiert.
- Grund: Hetzner Robot/Dedicated Root Server haben nicht die Hetzner-Cloud-Server-Snapshot-Funktion.
- Methode: Restic pro Node nach Hetzner Object Storage S3.
- Repos:
  - Server 2: `s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os`
  - Server 3: `s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os`
- Tags: `os-server2`, `os-server3`.
- Skript pro Node: `/usr/local/sbin/k3s-os-restic-backup.sh`.
- Service/Timer pro Node: `k3s-os-restic-backup.service`, `k3s-os-restic-backup.timer`.
- Timer:
  - Server 2: `hourly` plus `RandomizedDelaySec=10min`.
  - Server 3: `hourly` plus `RandomizedDelaySec=10min`.
- Retention: `48 hourly`, `14 daily`, `8 weekly`, `12 monthly`.
- Letzte validierte Snapshot-Marker:
  - Server 2: `5edd164b`
  - Server 3: `485c0079`
- `restic check`: auf beiden Repositories ohne Fehler.
- Nicht-destruktiver Restore-Test `/etc/hostname` bleibt erfolgreich:
  - Server 2: `activi-k3-2`
  - Server 3: `activi-k3-3`
- Vollstaendiges Verify nach Einrichtung:
  - `RESULT: PASS`
  - `Passes: 117`
  - `Warnings: 0`
  - `Failures: 0`
  - Log: `/tmp/k3s-stack-complete-verify-20260521-115116.log`
- Unveraendert: keine K3s-, Longhorn-, Docker-, PVC- oder Firewall-Aenderungen.

Altbestand:

- Borg/Borgmatic sind vorhanden, aber nicht Teil des neuen Backup-Plans.
- `aws`, `rclone`, `mc` und `s5cmd` sind fuer den Pflichtpfad nicht erforderlich.
- Velero ist seit 2026-05-24 installiert und restore-getestet.

Noch zu tun:

1. Portainer komplett fertig einrichten: Login, Passwort, Benutzer-/Token-/Registry-/Helm-Repo-/Environment-Sicht pruefen.
2. Business-Edition-Funktionen nur nach Bedarf konfigurieren: RBAC, Audit Logging, OAuth/SSO, Registry-Management, Quotas.
3. DNS-/resolv.conf-Cleanup als separaten K3s-Betriebsblock planen:
   `Nameserver limits were exceeded` bereinigen, ohne ad hoc DNS zu loeschen.
4. Produktive `pg_dump`-Automation/Schedules pro spaeterer App-Datenbank planen.
5. Externe Alertmanager-Receiver und gezielte Longhorn/Velero/CNPG-Monitore planen.
6. S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar wurde.
7. GitOps/Argo CD, Backup-Loeschschutz, Security-Hardening, Upgrade-Strategie und echten DR-Test umsetzen.

## Server 3

Status: neu installiert und produktiv im Cluster.

- Hostname: `activi-k3-3`
- Public IP: `167.235.6.160`
- Private IP: `10.0.1.30`
- Interface: `enp7s0.4000`
- Bootstrap-Skript: `/Users/activi/Documents/activi K3s/bootstrap-server3-k3s.sh`
- SSH-Key lokal: `/Users/activi/.ssh/k3-3`
- Alte Server-3-Daten sind nicht mehr Zielzustand.

## Storage, Ingress, TLS

Status:

- StorageClass: `longhorn (default)`, zusaetzlich `local-path` und `longhorn-static`
- Longhorn: installiert per Helm `1.11.2`, Default StorageClass
- IngressClass: `nginx` vorhanden
- `ingress-nginx`: installiert, DaemonSet/hostNetwork auf allen drei Nodes, Ports `80`/`443`
- cert-manager: installiert per Helm `v1.20.2`, Pods Ready, CRDs vorhanden
- K3s-Traefik: bewusst deaktiviert
- Portainer-Ingress vorhanden und aktiv: `portainer/portainer` fuer `portainer.activi.io`.
- Keine LoadBalancer-Services vorhanden.
- Keine NodePort-Services vorhanden.

Naechste Entscheidungen:

- Longhorn Phase 2 ist fuer Test-PVC/Test-App und Backup/Restore validiert; naechste Storage-Entscheidung ist eine separat geplante produktive Migration.
- Ingress-Controller: `ingress-nginx` ist installiert und extern erreichbar.
- TLS: cert-manager mit HTTP-01, wenn `80/443` sauber auf den Ingress zeigen; DNS-01 nur bei bewusstem DNS-API-Zugriff.
- Domain/Subdomains fuer Portainer, Healthchecks, Hindsight festlegen.
- DNS erst setzen, wenn Ingress-Controller, Entry-IPs und Zertifikatsweg klar sind.

Update 2026-05-21 17:58 CEST:

- Portainer-Zieldomain: `portainer.activi.io`.
- Let's-Encrypt-E-Mail: `ds@activi.io`.
- Cloudflare DNS: A-Record `portainer -> 88.99.215.210`, Proxy-Status `Nur DNS`.
- Ports `80` und `443` waren vor der `ingress-nginx`-Installation auf Server 1, Server 2 und Server 3 nicht belegt.
- K3s-Traefik ist deaktiviert; kein LoadBalancer blockiert den naechsten Schritt.
- Host-Port-Variante fuer `ingress-nginx` passt technisch zum aktuellen Setup.
- K3s-Startargumente nicht erneut ungefiltert ausgeben; sie koennen sensible Token enthalten.

Update 2026-05-21 18:43 CEST:

- `ingress-nginx` wurde installiert und validiert.
- Controller-Pods: `3/3` Ready, je ein Pod pro Node.
- `IngressClass`: `nginx`.
- Extern erreichbar:
  - `http://portainer.activi.io` -> nginx `404 Not Found`
  - `https://portainer.activi.io` -> nginx `404 Not Found`
  - TCP `80` und `443` sind von extern erreichbar.
- `404` ist erwarteter Zwischenstand, weil noch keine Portainer-Ingress-Route existiert.
- Hetzner Robot Firewall wurde durch den Nutzer so angepasst, dass `80/443` durchkommen; der damalige NodePort-Fallback wurde spaeter geschlossen.
- Dieser Block ist abgeschlossen; danach wurde `cert-manager` separat installiert und geprueft.

Update 2026-05-21 19:03 CEST:

- `cert-manager` wurde installiert und live gegengeprueft.
- Helm Release: `cert-manager`, Chart/App `v1.20.2`, Namespace `cert-manager`.
- Pods Ready: `cert-manager`, `cert-manager-cainjector`, `cert-manager-webhook`.
- CRDs vorhanden: `certificates`, `certificaterequests`, `issuers`, `clusterissuers`, `orders`, `challenges`.
- Bis zu diesem Installationsblock waren keine realen `Issuer`, `ClusterIssuer`, `Certificate`, `CertificateRequest`, `Order` oder `Challenge` angelegt.
- `portainer.activi.io` liefert weiter nginx `404 Not Found`, erwartbar ohne Portainer-Ingress.
- Damaliger Zustand: Portainer Service blieb unveraendert NodePort `9443:30779`; dieser Fallback ist inzwischen geschlossen.
- Dieser Block ist abgeschlossen; danach wurde der Let's-Encrypt-ClusterIssuer separat angelegt und geprueft.

Update 2026-05-21 19:22 CEST:

- Vorab-Audit fuer den ClusterIssuer-Block: `RESULT: PASS`, `Passes: 35`, `Warnings: 0`, `Failures: 0`.
- Audit-Log: `/tmp/k3s-recent-stack-claims-audit-20260521-191900.log`.
- ClusterIssuer erstellt: `letsencrypt-prod`.
- ACME Server: `https://acme-v02.api.letsencrypt.org/directory`.
- E-Mail: `ds@activi.io`.
- Solver: HTTP-01 ueber `ingressClassName: nginx`.
- Status: `Ready=True`, Reason `ACMEAccountRegistered`.
- Account-Secret existiert als Metadaten: `cert-manager/letsencrypt-prod-account-key`, Typ `Opaque`, `DATA=1`.
- Keine Secret-Inhalte ausgegeben.
- Keine realen `Issuer`, `Certificate`, `CertificateRequest`, `Order`, `Challenge` oder App-Ingresses angelegt.
- `portainer.activi.io` liefert weiter nginx `404 Not Found`, erwartbar ohne Portainer-Ingress.
- Damaliger Zustand: Portainer Service blieb unveraendert NodePort `9443:30779`; dieser Fallback ist inzwischen geschlossen.
- Naechster Block wurde versucht und am Admission-Webhook-Fehler gestoppt; Portainer-Ingress erst nach Webhook-Fix erneut versuchen.
- Audit-Skript wurde auf den neuen Soll-Zustand aktualisiert und erneut ausgefuehrt:
  - `RESULT: PASS`
  - `Passes: 38`
  - `Warnings: 0`
  - `Failures: 0`
  - Log: `/tmp/k3s-recent-stack-claims-audit-20260521-193525.log`

Update 2026-05-21 19:12 CEST:

- Neues Audit-Skript angelegt: `/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh`.
- Zweck: die Aussagen der letzten abgeschlossenen Ingress-/TLS-/Backup-Sicherheitsbloecke live pruefen, ohne Secrets auszugeben.
- Das Audit-Skript prueft inzwischen den neuen Sollzustand mit Portainer-Ingress/TLS: DNS `portainer.activi.io -> 88.99.215.210`, HTTP-Redirect auf HTTPS, HTTPS `200`, Cluster-Ready, keine Problem-Pods, `ingress-nginx`, `cert-manager`, ClusterIssuer `letsencrypt-prod`, Certificate `portainer-activi-io-tls`, Portainer Service `ClusterIP` ohne NodePorts, `longhorn` als einziger Default, Velero Deployment/BackupStorageLocation, Longhorn Backup Target und OS-Restic Host/Tag-Snapshots Server 2/3.
- Letzter Lauf nach Portainer-Ingress/TLS-Abschluss:
  - `RESULT: PASS`
  - `Passes: 45`
  - `Warnings: 0`
  - `Failures: 0`
  - Log: `/tmp/k3s-recent-stack-claims-audit-20260521-225515.log`

Update 2026-05-21 20:18 CEST:

- Portainer-Ingress-Erstellung wurde versucht, aber Kubernetes hat den Create-Vorgang vor dem Speichern abgelehnt.
- Fehler: `failed calling webhook "validate.nginx.ingress.kubernetes.io": context deadline exceeded`.
- Es wurde kein Ingress gespeichert.
- Keine `Certificate`, `CertificateRequest`, `Order` oder `Challenge` wurden erzeugt.
- `portainer.activi.io` liefert weiter nginx `404 Not Found` auf HTTP/HTTPS.
- Damaliger Zustand: Portainer Service blieb unveraendert NodePort `9443:30779`; dieser Fallback ist inzwischen geschlossen.
- `ingress-nginx-controller-admission` existiert als Service `10.43.55.93:443`.
- Admission-Endpunkte: `10.0.1.10:8443`, `10.0.1.20:8443`, `10.0.1.30:8443`.
- Von Server 1 erreichbar: `10.0.1.10:8443`.
- Von Server 1 nicht erreichbar: `10.0.1.20:8443`, `10.0.1.30:8443`; Service-IP `10.43.55.93:443` ebenfalls nicht erreichbar.
- Wahrscheinlicher Blocker: interne private TCP-Erreichbarkeit fuer ingress-nginx Admission Webhook auf `8443` zwischen den Nodes beziehungsweise der HostNetwork-Admission-Pfad.
- Wenn Firewall-Regeln angepasst werden, dann nur privat fuer Quelle `10.0.1.0/24`, nicht oeffentlich fuer `8443`.
- Frischer Audit-Lauf nach Gegenpruefung: `RESULT: PASS`, `Passes: 38`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260521-201735.log`.
- Naechster Block: ingress-nginx Admission-Webhook-Pfad diagnostizieren/reparieren und per Server-Dry-Run pruefen. Portainer-Ingress erst danach erneut versuchen.

Update 2026-05-21 21:18 CEST:

- Hetzner Robot Firewall wurde vom Nutzer auf allen drei Servern fuer internes TCP `8443` aus Quelle `10.0.1.0/24` ergaenzt.
- Auf Server 1 wurde zusaetzlich UFW fuer den privaten VLAN-Port freigegeben: `ufw allow in on enp41s0.4000 from 10.0.1.0/24 to any port 8443 proto tcp comment "ingress-nginx admission webhook"`.
- Danach ist die Node-zu-Node-Matrix fuer `10.0.1.10:8443`, `10.0.1.20:8443`, `10.0.1.30:8443` von Server 1, Server 2 und Server 3 aus erfolgreich.
- Admission-Service `10.43.55.93:443` ist von Server 1 und Server 2 erreichbar; von Server 3 noch nicht direkt per TCP-Test, aber der entscheidende Kubernetes API-Server-Pfad ist gruen.
- Portainer-Ingress Server-Dry-Run gegen den Kubernetes API-Server erfolgreich: `ingress.networking.k8s.io/portainer-dryrun-admission-test created (server dry run)`.
- Der Dry-Run hat nichts gespeichert: weiterhin keine App-Ingresses, keine Certificates, keine CertificateRequests, keine Orders, keine Challenges.
- Damaliger Zustand: Portainer Service blieb unveraendert NodePort `9443:30779`; dieser Fallback ist inzwischen geschlossen.
- Historischer naechster Block zu diesem Zeitpunkt: echten Portainer-Ingress fuer `portainer.activi.io` erstellen und cert-manager Ressourcen bis Ready oder Fehler beobachten. Dieser Block ist seit 2026-05-21 22:45 CEST erledigt.

Update 2026-05-21 22:45 CEST:

- Portainer-Ingress/TLS wurde erfolgreich abgeschlossen.
- Ingress: `portainer/portainer`, Host `portainer.activi.io`, `ingressClassName: nginx`.
- Backend: Service `portainer`, Port `9443`, Annotation `nginx.ingress.kubernetes.io/backend-protocol: HTTPS`.
- Certificate: `portainer/portainer-activi-io-tls`, `Ready=True`.
- TLS Secret: `portainer/portainer-activi-io-tls`, Typ `kubernetes.io/tls`, `DATA=2`; keine Secret-Inhalte ausgegeben.
- ACME Order war `valid`; keine Challenge mehr aktiv.
- Externes Verhalten:
  - `http://portainer.activi.io` -> `308 Permanent Redirect` auf HTTPS.
  - `https://portainer.activi.io` -> `HTTP/2 200`, Portainer-Seite sichtbar.
- Damaliger Zustand: Portainer NodePort blieb als Fallback offen: `9443:30779`. Dieser Fallback wurde im anschliessenden Hardening-Block geschlossen.
- Keine DNS-, Cloudflare-, Firewall-, Longhorn-, Restic-, K3s-, Docker- oder PVC-Aenderungen im Ingress/TLS-Abschlussblock.
- `audit-recent-stack-claims.sh` wurde auf den neuen Sollzustand umgestellt: Portainer-Ingress und Certificate werden jetzt erwartet; nginx-404 ohne Ingress wird nicht mehr als Sollzustand behandelt.

Update 2026-05-21 23:18 CEST:

- Portainer-NodePort-Hardening wurde abgeschlossen.
- Helm Release `portainer` wurde von Revision 1 auf Revision 2 aktualisiert.
- Portainer Service wurde per Helm von `NodePort` auf `ClusterIP` umgestellt.
- Aktueller Service: `ClusterIP`, Ports `9000/TCP`, `9443/TCP`, `8000/TCP`, keine `nodePort`-Felder.
- Clusterweit existieren keine `NodePort` Services mehr.
- `https://portainer.activi.io` liefert weiter `HTTP/2 200`.
- `http://portainer.activi.io` leitet weiter mit `308` auf HTTPS um.
- Externe Tests auf `30777`, `30779`, `30776` gegen alle drei Public IPs laufen in Timeout; die NodePorts sind nicht erreichbar.
- Aktualisiertes Recent-Audit: `RESULT: PASS`, `Passes: 46`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260521-233143.log`.
- Vollstaendiges Stack-Verify: `RESULT: PASS`, `Passes: 119`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260521-233236.log`.

Update 2026-05-22 03:49 CEST:

- OS-Restic Server 2/3 wurde auf denselben Ziel-Rhythmus wie Server 1 angepasst:
  `hourly` Timer, Retention `48 hourly`, `14 daily`, `8 weekly`, `12 monthly`.
- Frische OS-Restic-Belege:
  - Server 2 Snapshot `5edd164b`, Tag `os-server2`, Restore-Test Hostname `activi-k3-2`.
  - Server 3 Snapshot `485c0079`, Tag `os-server3`, Restore-Test Hostname `activi-k3-3`.
- Rebuild-Bundle ohne Secret-Inhalte erzeugt:
  `/Users/activi/Documents/activi K3s/exports/k3s-rebuild-bundle-20260522-032642.tar.gz`
  plus SHA256-Datei.
- Backup-Zwischenstopp vor Portainer-Storage-Migration wurde abgeschlossen:
  - frischer K3s etcd S3 Snapshot `manual-phase1-20260522-032854-activi-k3-1.0-activi-k3-1.0-1779413335`;
  - frischer Server-1 Restic-Lauf erfolgreich;
  - frischer Longhorn SystemBackup `lh-system-backup-pre-portainer-longhorn-20260522`, `Ready`.
- Portainer wurde kontrolliert von `local-path` auf Longhorn migriert.
- Aktiver Portainer-PVC:
  - `portainer/portainer-longhorn`, `Bound`, StorageClass `longhorn`, `10Gi`.
  - Longhorn Volume `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b`, `attached/healthy`.
  - Replicas laufen auf `activi-k3-1.0`, `activi-k3-2`, `activi-k3-3`.
- Alter Portainer-Local-Path-PVC bleibt absichtlich als Rollback-Beleg erhalten:
  `portainer/portainer`, `Bound`, StorageClass `local-path`, Annotation `helm.sh/resource-policy=keep`.
- Portainer Service bleibt `ClusterIP`, clusterweit existieren keine `NodePort` Services.
- `https://portainer.activi.io` liefert weiter `HTTP/2 200`; HTTP leitet weiter auf HTTPS um.
- Recent-Audit nach Dokumentationsupdate:
  `RESULT: PASS`, `Passes: 52`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260522-040057.log`.
- Vollstaendiges Stack-Verify nach Dokumentationsupdate:
  `RESULT: PASS`, `Passes: 125`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-stack-complete-verify-20260522-040227.log`.

Update 2026-05-22 22:36 CEST:

- Portainer/Kubernetes-API-Timeout-Fix ist abgeschlossen und validiert.
- Verbindlicher Robot-Firewall-Stand fuer alle drei Server:
  `tcp established` ACK-Regel mit Quell-Port `0-65535`, Ziel-Port `0-65535`, `TCP-Flags=ack`, `accept`.
- Neuer Connectivity-Check:
  `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`.
- Letzter Connectivity-Check:
  `RESULT: PASS`, 60/60 stabile Versuche pro Ziel, Log `/tmp/portainer-api-connectivity-20260523-024920.log`.
- Letzter Recent-Audit-Lauf nach Firewall-Fix:
  `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260523-024855.log`.
- Letzter Full-Verify-Lauf nach Firewall-Fix:
  `RESULT: PASS`, `Passes: 126`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-stack-complete-verify-20260523-025031.log`.

Update 2026-05-23 03:50 CEST:

- Longhorn-Portainer-Backup-Skript angelegt:
  `/Users/activi/Documents/activi K3s/run-portainer-longhorn-backup.sh`.
- Das Skript hat getrennte Modi:
  - `--dry-run`: Preflight plus serverseitige Simulation fuer SystemBackup/Snapshot; Backup-Manifest clientseitig validiert, weil der referenzierte Snapshot im Dry-Run nicht gespeichert wird.
  - `--execute`: erstellt genau ein Longhorn SystemBackup, einen Longhorn Snapshot und ein Longhorn Volume-Backup fuer `portainer/portainer-longhorn`.
  - `--afterflight`: prueft den erzeugten Backup-Satz und Portainer-Sicherheitsmarker erneut.
- Backup-Zwischenstopp vor Portainer Business Edition wurde erfolgreich ausgefuehrt:
  - SystemBackup `lh-system-backup-pre-be-20260523-034408`: `Ready`, Version `v1.11.2`.
  - Snapshot `portainer-pre-be-snap-20260523-034408`: `readyToUse=true`.
  - Volume-Backup `portainer-pre-be-backup-20260523-034408`: `Completed`, `progress=100`, Volume `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b`.
  - Afterflight: `RESULT: AFTERFLIGHT PASS`.
- Letzter Recent-Audit-Lauf nach Portainer-Volume-Backup:
  `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260523-034620.log`.
- Letzter Full-Verify-Lauf nach Portainer-Volume-Backup:
  `RESULT: PASS`, `Passes: 126`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-stack-complete-verify-20260523-034758.log`.

Update 2026-05-23 04:14 CEST:

- Portainer Business Edition 3 Nodes Free wurde in der UI aktiviert.
- Nutzerbestaetigung: Login funktioniert, Business-Lizenz wird angezeigt.
- Live-Stand nach Aktivierung:
  - Deployment `portainer` laeuft `1/1`.
  - Image bleibt `portainer/portainer-ee:2.39.2`.
  - Service bleibt `ClusterIP`, keine NodePorts.
  - Ingress `portainer.activi.io` bleibt aktiv.
  - Aktiver PVC bleibt `portainer/portainer-longhorn` auf Longhorn.
  - Upgrade-Pod `portainer-upgrade-1779501995-tfzsv` ist `Completed`.
- Audit nach Business-Aktivierung:
  `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260523-041234.log`.

## Wichtigste Logs

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
/Users/activi/Documents/activi K3s/logs/k3s-server3-post-join-verify-20260520-live.log
/Users/activi/Documents/activi K3s/logs/k3s-server3-local-k3s-verify-20260520-live.log
/Users/activi/Documents/activi K3s/logs/k3s-post-server3-join-snapshot-20260520-live.log
/Users/activi/Documents/activi K3s/logs/k3s-live-stack-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-live-etcd-backup-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-server1-data-migration-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-server1-backup-system-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-server1-borgmatic-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-cluster-addon-audit-20260520.log
/tmp/k3s-recent-stack-claims-audit-20260521-201735.log
/tmp/k3s-recent-stack-claims-audit-20260521-225515.log
/tmp/k3s-recent-stack-claims-audit-20260521-233143.log
/tmp/k3s-stack-complete-verify-20260521-233236.log
```

## Priorisierte naechste Schritte

Aktuelle kompakte TODO-Liste:

```text
/Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md
```

Zentrale Handover-Anweisung fuer neue Agenten:

```text
/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
```

Verbindliche Reihenfolge ab 2026-05-22 03:49 CEST:

1. Portainer UI fachlich fertig einrichten: Access Tokens pruefen, Registry/Helm-Repo-Konfiguration pruefen, Kubernetes Environment pruefen; keine Secret-Werte dokumentieren.
2. Business-Edition-Funktionen nur gezielt konfigurieren: RBAC, Audit Logging, OAuth/SSO, Registry-Management, Quotas.
3. Longhorn RecurringJobs fuer das Portainer-Volume, Velero und CloudNativePG-
   Smoke-Test als erledigt behandeln.
4. DNS-/resolv.conf-Cleanup als separaten K3s-Betriebsblock planen und erst
   nach Backup-Zwischenstopp/freigegebenem Rollout umsetzen.
5. Produktive `pg_dump`-Automation/Schedules pro spaeterer App-Datenbank planen.
6. Externe Alertmanager-Receiver und gezielte Longhorn/Velero/CNPG-Monitore planen.
7. Healthchecks-Migration von Docker nach K3s + Longhorn planen und mit Backup-Zwischenstopp umsetzen.
8. Hindsight + Postgres-Migration von Docker nach K3s + Longhorn planen und mit Backup-Zwischenstopp umsetzen.
9. Optional S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar wurde.
10. GitOps/Argo CD, Backup-Loeschschutz, Security-Hardening, Upgrade-Strategie und echten DR-Test umsetzen.

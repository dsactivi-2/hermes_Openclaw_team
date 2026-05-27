# K3s Backup and Restore Runbook - 2026-05-20

Stand: 2026-05-20.

Dieses Runbook beschreibt ausschliesslich Backup und Restore fuer den bestehenden K3s/Hetzner-Robot-Cluster. Es ersetzt keine Migrations-, Longhorn-, Ingress- oder Firewall-Runbooks.

## Aktueller Stand 2026-05-24

- `longhorn` ist die einzige Default StorageClass; `local-path` bleibt nur fuer Alt-/Rollback-PVCs vorhanden.
- Portainer Business laeuft produktiv auf dem Longhorn-PVC `portainer/portainer-longhorn` und ist per `ingress-nginx`/cert-manager TLS unter `https://portainer.activi.io` erreichbar.
- Velero ist installiert und per nicht-destruktivem Smoke Backup/Restore validiert.
- CloudNativePG Operator und Barman Cloud Plugin sind installiert und per Smoke Backup/Restore validiert; produktive DB-Backups muessen pro App noch geplant werden.
- Monitoring-Basisstack ist installiert; Prometheus Targets sind gruen.
- Aktuell offene Gaps: produktive `pg_dump`-Automation pro App, GitOps, SOPS/External Secrets/Vault, vollstaendiger Replacement-Node-DR-Drill und DNS/resolv.conf-Cleanup als separater Block.

Historische Zwischenstaende bleiben darunter zur Nachvollziehbarkeit erhalten und sind nicht als aktueller Sollzustand zu lesen.

## Verbindlicher Live-Stand

Quelle:

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

Aktueller Stand laut Startcheck:

- 3-Node K3s HA Cluster mit embedded etcd.
- Server 1: `activi-k3-1.0`, `10.0.1.10`, Public `88.99.215.210`.
- Server 2: `activi-k3-2`, `10.0.1.20`, Public `178.63.12.52`.
- Server 3: `activi-k3-3`, `10.0.1.30`, Public `167.235.6.160`.
- Alle Nodes `Ready`.
- K3s Version: `v1.32.1+k3s1`.
- Alle Pods `Running`.
- StorageClass: `longhorn (default)`, zusaetzlich `local-path` und `longhorn-static`.
- Portainer laeuft bereits im Namespace `portainer`.
- Portainer aktiver PVC `portainer-longhorn` ist `Bound`, `10Gi`, StorageClass `longhorn`.
- Alter Portainer-PVC `portainer` ist weiter `Bound` auf `local-path` und bleibt als Rollback-Beleg erhalten.
- Portainer Service ist `ClusterIP`: `9000/TCP`, `9443/TCP`, `8000/TCP`; es gibt keine Kubernetes-NodePorts mehr.
- Portainer ist extern ueber `https://portainer.activi.io` erreichbar; HTTP leitet mit `308` auf HTTPS um.
- Keine externe Pod-IP ist erwartet. Externe Erreichbarkeit muss ueber Service/Ingress erfolgen, nicht ueber Pod-IPs.
- IngressClass `nginx` vorhanden; `ingress-nginx` ist installiert und extern erreichbar.
- Portainer-Ingress ist vorhanden: `portainer/portainer` fuer `portainer.activi.io`.
- cert-manager ist installiert und geprueft; kein Traefik-IngressController und kein LoadBalancer-Service vorhanden.
- ClusterIssuer `letsencrypt-prod` ist Ready; Certificate `portainer/portainer-activi-io-tls` ist Ready.
- Der vorherige Blocker fuer den Portainer-Ingress ist repariert: internes TCP `8443` ist zwischen den Nodes erlaubt und der Kubernetes Server-Dry-Run fuer den Portainer-Ingress funktioniert.
- Longhorn ist installiert und seit 2026-05-24 die Default StorageClass.
- Longhorn Default und Storage-Istzustand wurden am 2026-05-24 02:45 CEST
  erneut verifiziert: `longhorn` ist einzige Default StorageClass,
  `local-path` ist vorhanden aber nicht Default, `portainer/portainer-longhorn`
  ist der aktive produktive PVC, der alte `portainer/portainer` PVC ist nur
  Rollback-Altbestand.
- Velero ist installiert: Version `1.18.0`, Chart `velero-12.0.1`,
  BackupStorageLocation `default` ist `Available`.
- CloudNativePG ist als nicht-produktiver Test-/Backup-Baustein installiert:
  Operator `1.29.1`, Barman Cloud Plugin `v0.12.0`, Smoke-Backup und
  Restore-Test erfolgreich. Es wurde nicht der deprecated
  `barmanObjectStore`-Clusterpfad verwendet.
- Monitoring-Basisstack ist installiert: `kube-prometheus-stack` Chart
  `85.3.0`, Namespace `monitoring`, intern per `ClusterIP`, ohne Grafana-
  Ingress, NodePort, LoadBalancer oder externen Alert-Receiver. Prometheus
  Targets sind nach der privaten TCP-9100-Nacharbeit `23/23` up.
- etcd ist healthy: alle drei Endpoints healthy, alle Member `started`, alle `learner=false`.

Bekannte kosmetische etcd-Member-Namen:

```text
ubuntu-noble-latest-amd64-base-3982578f
activi-k3-2-48af0a1d
activi-k3-3-82cc6d74
```

Das ist kein Stop-Kriterium, solange Member-ID, Client/Peer-URL, `started`, `learner=false` und Endpoint Health stimmen.

## Backup-Status

Update 2026-05-21 00:30 CEST: Phase 1 ist funktional eingerichtet, automatisiert und
nicht-destruktiv validiert.

Aktiver Stand:

- Hetzner Object Storage S3 ist als Offsite-Ziel eingerichtet.
- Bucket: `activi`.
- Endpoint/Region: `https://fsn1.your-objectstorage.com`, Region `fsn1`.
- Bucket-Erstellung laut Hetzner Console/Erstellungsdialog: Object Lock `aktiviert`, Sichtbarkeit `privat`.
  Hinweis: Diese Bucket-Eigenschaften wurden aus der Hetzner Console uebernommen; sie wurden nicht separat per S3-API/AWS-CLI ausgelesen.
- K3s native etcd-Snapshots werden nach `s3://activi/k3s/etcd/` geschrieben.
- Restic Repository ist initialisiert: `s3:https://fsn1.your-objectstorage.com/activi/restic/server1`.
- Hindsight Postgres Dumps werden lokal unter `/var/lib/k3s-backup/postgres-dumps/` erstellt und per Restic gesichert.
- Portainer war bis zur Longhorn-Migration im Server-1-Restic-Scope. Seit 2026-05-22 ist der aktive Portainer-PVC `portainer-longhorn` auf Longhorn; der alte `local-path` PVC bleibt nur als Rollback-Beleg erhalten.
- K3s Server Token `/var/lib/rancher/k3s/server/token` ist im Restic-Scope.
- Docker-App-Daten, Compose-Dateien und relevante `.env` Dateien sind im Restic-Scope. `.env` Inhalte duerfen weiterhin nicht ausgegeben werden.
- Systemd Timer sind aktiv fuer etcd-S3-Snapshots, Hindsight Dumps, Restic Backups, Retention und Prune.

Validierte Belege:

- K3s S3 Snapshot: `manual-phase1-s3-20260521-000704-activi-k3-1.0-activi-k3-1.0-1779314824`.
- K3s S3 Snapshot aus systemd-Test: `manual-phase1-20260521-002925-activi-k3-1.0-activi-k3-1.0-1779316166`.
- Restic Snapshots: `d4faae42`, `c2b385b0`, `c9af17e7`.
- `restic check`: keine Fehler.
- Nicht-destruktiver Restore-Test: `/var/lib/k3s-backup/restore-test/restic-20260521-000917`.
- Restore-getestet: Healthchecks Compose-Datei und Hindsight Postgres Dump; Dump war gzip-lesbar.
- Erster automatischer Timerlauf: `hindsight-postgres-dump.timer` um 2026-05-21 01:04:27 CEST und `k3s-restic-backup.timer` um 2026-05-21 01:04:47 CEST erfolgreich.
- Backup-Phase-1-Preflight: `RESULT: PASS`, `Warnings: 0`, `Failures: 0`, Log: `/tmp/k3s-backup-phase1-check-20260521-010319.log`.

Altbestand:

- Borg/Borgmatic sind weiterhin Altbestand und nicht Teil dieses neuen Backup-Plans.
- `aws`, `rclone`, `mc` und `s5cmd` sind fuer den Pflichtpfad nicht erforderlich.
- Longhorn ist installiert und sein Backup Target ist gesetzt; Velero ist als
  Kubernetes-Ressourcen-/Namespace-Restore-Schicht eingerichtet.
- OS-Level Restic fuer Server 2/3 ist aktiv, automatisiert und validiert.
  Details: `/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md`.

## Zielarchitektur

Die sichere Reihenfolge ist:

1. **Sofort-Basis:** K3s native etcd-Snapshots direkt nach Hetzner Object Storage S3.
2. **Sofort-Basis:** Restic nach S3 fuer Dateien, Tokens, lokale Snapshots, Docker-App-Daten, DB-Dumps und verbleibende Server-1-Daten.
3. **Sofort-Basis:** App-konsistente Dumps fuer Hindsight Postgres.
4. **Danach:** Longhorn installieren und Longhorn Backup Target auf S3 einrichten. Erledigt am 2026-05-21.
5. **Zusatzblock:** OS-Level Restic fuer Server 2/3 einrichten, weil Hetzner Robot/Dedicated Server keine Hetzner-Cloud-Server-Snapshots haben. Erledigt und validiert am 2026-05-21.
6. **Zusatzblock:** Velero als Zusatzschicht fuer Kubernetes-Ressourcen und
   Namespace-Restores installieren und restore-testen. Erledigt und validiert
   am 2026-05-24.
7. **Datenbank-Testblock:** CloudNativePG fuer Postgres auf Longhorn mit S3/WAL-Backups, zusaetzlichem `pg_dump` und Restore testen. Erledigt und validiert am 2026-05-24.
8. **Monitoring-Basisblock:** kube-prometheus-stack intern installieren. Erledigt am 2026-05-24; Prometheus/Alertmanager/Grafana Ready und Targets `23/23` up.
9. **Geplanter DNS-Betriebsblock:** `Nameserver limits were exceeded` bereinigen. Read-only-Befund: systemd-resolved liefert mehr Nameserver an Kubelet/K3s, als Kubernetes pro Pod uebernimmt; Server 1 hat zusaetzlich Tailscale-DNS/Search-Domain. Kein Notfall, aber vor breitem App-Rollout separat planen: reduzierte dedizierte K3s-Resolver-Datei, K3s/kubelet `resolv-conf` setzen, Nodes einzeln rollen und danach alle Audits ausfuehren.
10. **Naechster Betriebs-Block:** produktive `pg_dump`-Automation fuer spaetere Datenbanken, GitOps, Backup-Loeschschutz, externe Alert-Receiver/gezielte ServiceMonitors und echten Disaster-Recovery-Test vorbereiten.

Velero ist bewusst nicht der erste Backup-Baustein, aber seit 2026-05-24 Teil
des aktiven Production-Readiness-Backups vor groesseren produktiven
App-Rollouts, weil:

- aktuelle Daten noch teilweise ausserhalb von K3s in Docker laufen;
- Portainer inzwischen ein Longhorn-PVC nutzt; der alte `local-path` PVC bleibt nur als Rollback-Beleg;
- Longhorn zwar per Test-PVC/Backup/Restore validiert ist, aber noch keine produktiven Kubernetes-Apps mit Longhorn-PVCs laufen;
- Velero den K3s Server Token und etcd Disaster Recovery nicht ersetzt;
- Velero ohne CSI/Data-Movement zunaechst Kubernetes-Objekte/Namespaces sichert;
  Volume-Daten bleiben ueber Longhorn Volume-Backups abgesichert.

## Backup-Arten: Was wird womit gesichert?

Die Backup-Arten sind bewusst unterschiedlich. Sie sichern nicht alle dasselbe
und muessen deshalb auch nicht alle auf jedem Node laufen.

| Backup-Art | Laufort / Steuerung | Primaerer Zweck | Was wird gesichert? | Was wird nicht gesichert? |
| --- | --- | --- | --- | --- |
| K3s etcd-Snapshot | Server 1 als Control-Plane-Node, Snapshot nach S3 | Disaster Recovery fuer Kubernetes-Cluster-State | Kubernetes-Ressourcen wie Deployments, Services, Secrets, ConfigMaps, PVC-Objekte, Ingress-Objekte, Cluster-Metadaten | keine vollstaendigen App-Dateien in Volumes, kein Host-OS |
| Restic Server 1 | Server 1 | Datei-Backup fuer alle aktuell auf Server 1 liegenden Daten | K3s Token/Configs, lokale K3s-Snapshots, Docker-App-Daten, Compose-Dateien, `.env` Dateien als Dateien, Hindsight Postgres Dumps, alter Portainer-`local-path` Rollback-PVC bis Cleanup | keine OS-Wiederherstellung von Server 2/3, keine Longhorn-Volume-Strategie |
| OS-Restic Server 2/3 | jeweils lokal auf Server 2 und Server 3 | Rekonstruktion der Node-/OS-Konfiguration | `/etc`, `/root`, `/home`, Cron, Paketlisten, systemd-, Netzwerk- und Disk-Metadaten | kein K3s etcd, keine Longhorn-Volume-Daten, keine Server-1-Docker-App-Daten |
| Longhorn Volume-Backup | Longhorn im Cluster | Sicherung echter Daten in Longhorn-PersistentVolumes | Daten in Longhorn-PVCs, z. B. spaetere Datenbanken/App-Dateien/Portainer nach Migration | kein K3s etcd, kein Host-OS, keine bestehenden `local-path` PVs |
| Longhorn SystemBackup | Longhorn im Cluster | Sicherung Longhorn-eigener Systemressourcen | Longhorn Settings, BackupTarget-Infos, Longhorn interne Ressourcen | kein Ersatz fuer Volume-Backups, kein Ersatz fuer K3s etcd |
| Velero | installiert und Smoke-Restore validiert | komfortable Namespace-/Ressourcen-Restores | Kubernetes-Ressourcen/Namespaces nach S3; Smoke-Test ohne PVCs validiert | ersetzt weder etcd-DR noch Restic noch Longhorn-Volume-Backups noch DB-Dumps |
| CloudNativePG S3/WAL | Operator und Barman Cloud Plugin installiert; nicht-produktiver Smoke-Test validiert | datenbankkonsistente Postgres-Backups und Point-in-Time-Restore | Postgres-Datenbanken im K3s-Cluster | keine App-Dateien, kein K3s etcd, kein Host-OS |
| pg_dump | fuer Hindsight-Dumps auf Server 1 aktiv; fuer K3s-Postgres als Smoke-Test validiert, produktive CronJob-Automation noch offen | logische DB-Exports, gut pruefbar und portabel | einzelne Postgres-Datenbanken/Schemas | kein vollstaendiger Volume-/Cluster-Ersatz |

Merksatz:

```text
etcd = Kubernetes-Gehirn
Restic = Dateien auf Hosts
Longhorn Volume Backup = Daten in Longhorn-PVCs
Longhorn SystemBackup = Longhorn-Konfiguration
Velero = Kubernetes-Ressourcen-/Namespace-Restore-Schicht
CloudNativePG/WAL + pg_dump = datenbankbewusste Postgres-Sicherung
```

Wichtig: Nicht jede Backup-Art blind auf jedem Node ausrollen. Entscheidend ist,
dass jede Datenklasse genau einmal sinnvoll gesichert wird, Offsite liegt und
ein Restore-Test existiert. Mehrfach gleiche Backups auf allen Nodes erzeugen
sonst doppelte Daten, hoehere S3-Kosten und mehr Fehlerquellen.

## Zeitplaene und Retention

Aktiver Stand:

| Bereich | Frequenz | Retention / Aufbewahrung | Einordnung |
| --- | --- | --- | --- |
| Server-1-Restic | stuendlich | `hourly 48`, `daily 14`, `weekly 8`, `monthly 12` | feinste Retention, weil Server 1 aktuell Docker-App-Daten, Dumps, K3s-Dateien und verbleibende lokale Daten haelt |
| K3s etcd-S3 | 2x taeglich: 00:10 und 12:10 plus RandomizedDelay | lokale/S3-Retention ueber K3s-/Skriptlogik | zusaetzlich manuell vor groesseren Aenderungen; optional spaeter 4x taeglich |
| Hindsight Postgres Dump | stuendlich | wird per Server-1-Restic gesichert | app-konsistenter DB-Baustein |
| OS-Restic Server 2/3 | stuendlich plus `RandomizedDelaySec=10min` | `hourly 48`, `daily 14`, `weekly 8`, `monthly 12` | an Server-1-Retention angepasst; sichert OS-/Node-Konfiguration |
| Longhorn SystemBackup | taeglich 02:17 | Retain `14` | sichert Longhorn-Systemzustand, nicht App-Volume-Daten |
| Longhorn Volume Snapshot | stuendlich um Minute 7 | Retain `48` | `prod-snapshot-hourly`, Gruppe `prod-critical`, aktuell nur `portainer/portainer-longhorn` |
| Longhorn Volume Backup Daily | taeglich 01:37 | Retain `14` | `prod-backup-daily`, Gruppe `prod-critical`, Backup ins konfigurierte Longhorn S3 BackupTarget |
| Longhorn Volume Backup Weekly | sonntags 03:12 | Retain `8` | `prod-backup-weekly`, Gruppe `prod-critical`, laengere externe Volume-Aufbewahrung |
| Velero | manuell/on demand; Schedules noch nicht definiert | Backup-TTL im Smoke-Test `24h` | Kubernetes-Ressourcen-/Namespace-Backups nach S3: Bucket `activi`, Prefix `velero`, BackupStorageLocation `default` Available |
| CloudNativePG S3/WAL | im Smoke-Test aktiv | nicht-produktiver Test, keine produktiven Schedules | Barman Cloud Plugin, ObjectStore `cnpg-smoke-store`, Bucket/Prefix `activi/cloudnativepg/smoke-20260524`, Backup `cnpg-smoke-backup-20260524` Completed |
| K3s-Postgres `pg_dump` | Smoke-Test manuell/job-basiert validiert | produktive Automation noch nicht aktiv | `cnpg-smoke-pgdump-retry-20260524` erfolgreich; pro produktiver Datenbank spaeter CronJob, Retention und Restore-Pruefung festlegen |

Entscheidung umgesetzt: Server 2/3 nutzen jetzt denselben Retention-Horizont
wie Server 1 fuer OS-Restic.

Update 2026-05-24 03:05 CEST: Die produktiven Longhorn Volume-RecurringJobs
wurden fuer Portainer aktiviert. Nur das Longhorn Volume
`pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b` fuer
`portainer/portainer-longhorn` ist in Gruppe `prod-critical`. Testvolumes im
Namespace `longhorn-test`, alte Rollback-/`local-path` PVCs und die Gruppe
`default` werden nicht fuer produktive Jobs verwendet. `lh-system-backup-daily`
blieb unveraendert.

## Nicht tun

Ohne ausdrueckliche Freigabe niemals:

- K3s neu installieren oder `INSTALL_K3S_EXEC` erneut ausfuehren.
- K3s-Service-Flags auf bestehenden Nodes aendern.
- Nodes entfernen.
- etcd Member loeschen.
- Docker-Apps stoppen.
- Docker-Volumes loeschen.
- PVCs/PVs loeschen.
- Portainer neu installieren.
- Portainer-PVC loeschen.
- Firewall-Regeln aendern.
- K3s-/kubelet-Resolver oder systemd-resolved-Konfiguration aendern.
- Secrets, Tokens, Passwoerter, API Keys, Kubeconfigs oder `.env` Inhalte ausgeben.

## Backup-Zwischenstopp vor groesseren Aenderungen

Vor jeder groesseren Aenderung an Portainer, Storage, PVCs, Helm-Releases,
Ingress/TLS, Firewall, K3s/kubelet-DNS-Resolvern oder produktiven Apps muss
ein Backup-Zwischenstopp erfolgen.

Pflichtreihenfolge:

1. `audit-recent-stack-claims.sh` ausfuehren und nur bei `RESULT: PASS` weitergehen.
2. `verify-k3s-stack-complete.sh` ausfuehren und nur bei `RESULT: PASS` weitergehen.
3. Frischen K3s etcd Snapshot nach S3 erstellen.
4. Frischen Server-1 Restic Backup-Lauf starten, solange Portainer oder Docker-App-Daten auf Server 1 liegen.
5. Frischen Longhorn SystemBackup erstellen, wenn Longhorn-/Kubernetes-Systemressourcen betroffen sind.
6. Sichtbarkeit der neuen Backups pruefen.
7. Keine Secret-Inhalte ausgeben.
8. Erst danach Migration oder groessere Aenderung starten.

Bei Fehlern nicht reparieren oder fortfahren, sondern Status/Events/Logs melden.

## Backup-Scope Phase 1

Phase 1 sichert den urspruenglichen Basiszustand. Seitdem ist Longhorn
installiert, Portainer nutzt ein Longhorn-PVC, Longhorn-Volume-RecurringJobs
sind fuer Portainer aktiv und Velero ist installiert sowie per Smoke-Restore
validiert. CloudNativePG ist als nicht-produktiver Test-/Backup-Baustein
validiert. Weiter offen bleiben produktive datenbankbewusste Postgres-
Backups/Schedules, Monitoring/Alerting, GitOps/External Secrets und ein echter
DR-Test.

### K3s Control Plane

Sichern:

- Embedded etcd via `k3s etcd-snapshot save`.
- Snapshot nach Hetzner Object Storage S3.
- Lokale Snapshotliste dokumentieren.
- `/var/lib/rancher/k3s/server/token` zwingend sichern.
- `/etc/rancher/k3s` sichern.
- relevante K3s-Konfigurationsdateien sichern.

Wichtig:

- Der Server Token ist restore-kritisch. Ohne denselben Token kann ein Snapshot unbrauchbar sein, weil K3s vertrauliche Bootstrap-Daten damit schuetzt.
- Bei K3s `v1.32.1+k3s1` nicht auf neuere S3-Retention-Features verlassen, die erst in spaeteren Patch-Versionen verfuegbar sind.

### Portainer

Portainer existiert bereits.

Update 2026-05-23 04:14 CEST:

- Portainer laeuft als Helm Release `portainer`, Chart `portainer-239.2.0`.
- Image: `portainer/portainer-ee:2.39.2`.
- Portainer Business Edition 3 Nodes Free ist aktiviert; der Nutzer konnte sich einloggen und die Business-Lizenz wird angezeigt.
- Deployment ist `1/1` verfuegbar, Strategie `Recreate`.
- ServiceAccount: `portainer-sa-clusteradmin`.
- Service ist nach dem Domain/TLS-Abschluss per Helm auf `ClusterIP` umgestellt; Ingress/TLS ist aktiv ueber `https://portainer.activi.io`.
- Admin-Passwort wurde nach Reset geaendert; der temporaere Reset-Pod wurde geloescht.

Sichern:

- Kubernetes-Objekte liegen in etcd.
- Aktiver Portainer-Datenpfad liegt jetzt im Longhorn-PVC `portainer-longhorn`.
- Der alte Portainer-`local-path` PVC bleibt bis Cleanup als Rollback-Beleg erhalten und ist weiterhin durch Server-1-Restic abgedeckt.

Vorgehen:

1. PVC/PV lesen:

```bash
kubectl -n portainer get pvc portainer -o wide
kubectl get pv -o wide
kubectl describe pv <PORTAINER_PV_NAME>
```

2. Den alten lokalen Hostpfad des `local-path` Rollback-PV nur bei Rollback-/Cleanup-Arbeiten ermitteln.
3. Aktive Portainer-Daten ueber Longhorn Volume-Backup sichern; der alte `local-path` PVC bleibt bis Cleanup zusaetzlich im Server-1-Restic-Scope.

Keine PVCs oder PVs loeschen.

### Production-Readiness-/Gap-Audit

Ab 2026-05-23 gibt es zusaetzlich zum bestehenden Live-Audit ein
Readiness-Audit fuer den erweiterten Zielplan:

```text
/Users/activi/Documents/activi K3s/audit-production-readiness-gaps.sh
```

Zweck:

- aktuelle Garantien pruefen: Cluster, Portainer, Ingress/TLS, Longhorn,
  Backups, OS-Restic, Portainer API Connectivity;
- geplante, aber noch nicht installierte Schutzschichten explizit als `GAP`
  markieren;
- echte Konflikte oder kaputte aktuelle Garantien als `FAIL` markieren.

Historische Erwartung im damaligen Zwischenstand:

```text
RESULT: PASS_WITH_GAPS
```

Das war vor Abschluss der Velero-, CloudNativePG- und Monitoring-Bloecke
korrekt. Velero, CloudNativePG/Barman Smoke Backup/Restore, Monitoring-Basisstack
und die produktiven Longhorn Volume-RecurringJobs fuer Portainer sind inzwischen
umgesetzt. `FAIL` bleibt weiterhin ein Stop-Kriterium.

Historischer Zwischenlauf vor Abschluss der spaeteren Bloecke:

```text
/tmp/k3s-production-readiness-gap-audit-20260524-024431.log
RESULT: PASS_WITH_GAPS
Passes: 21
Warnings: 0
Gaps: 9
Failures: 0
```

Es gab in diesem historischen Zwischenlauf keine Warnungen und keine Failures.
Die damals genannten neun Gaps sind nicht mehr der aktuelle offene Stand.

Aktuell offene Gaps:

- produktive `pg_dump`-Automation pro App;
- GitOps;
- SOPS/External Secrets/Vault;
- vollstaendiger Replacement-Node-DR-Drill;
- DNS/resolv.conf-Cleanup als separater Block.

Neuer Live-Stand 2026-05-24 01:12 CEST:

```text
Server 2 SSH: PASS ueber kube3-2, Hostname activi-k3-2
Server 2 OS-Restic Timer: enabled/active
Server 2 OS-Restic Snapshots: 49 sichtbar, Host activi-k3-2, Tag os-server2
Server 2 restic check: PASS, keine Fehler
```

Aktuelle Prueflogs:

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

Vorherige Server-2-Schliessung der SSH-Warning:

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

Die Server-2-SSH-Warning ist damit aus dem Production-Readiness-Audit
verschwunden. Dieser Absatz ist historisch; CloudNativePG-Testdatenbank und
Monitoring/Alerting-Basis sind inzwischen umgesetzt. Offen bleiben produktive
`pg_dump`-Automation pro App, GitOps, External Secrets/SOPS/Vault,
vollstaendiger Replacement-Node-DR-Drill und DNS/resolv.conf-Cleanup.

### Aktive Longhorn Volume-RecurringJobs

Seit 2026-05-24 03:05 CEST existieren fuer das produktive
Portainer-Longhorn-Volume gezielte Snapshot-/Backup-RecurringJobs.

Aktiver Zielzustand:

| Job | Task | Cron | Retain | Gruppe |
| --- | --- | --- | --- | --- |
| `prod-snapshot-hourly` | `snapshot` | `7 * * * *` | `48` | `prod-critical` |
| `prod-backup-daily` | `backup` | `37 1 * * *` | `14` | `prod-critical` |
| `prod-backup-weekly` | `backup` | `12 3 * * 0` | `8` | `prod-critical` |

Zielvolume:

```text
Namespace/PVC: portainer/portainer-longhorn
Longhorn Volume: pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b
Gruppe: prod-critical
```

Wichtig:

- Es gibt keine Jobs auf Gruppe `default`.
- Testvolumes sind nicht in `prod-critical`.
- Der alte `portainer/portainer` local-path-PVC ist nicht aufgenommen.
- `lh-system-backup-daily` blieb unveraendert und sichert weiterhin nur den
  Longhorn-Systemzustand.

### Portainer Domain/TLS Vorbedingung

DNS zeigt auf Server 1. `ingress-nginx` ist installiert und extern ueber
`80/443` erreichbar. `cert-manager` ist installiert und geprueft. Die
Portainer-Ingress-Route und das eigentliche Zertifikat sind seit 2026-05-21
22:45 CEST erfolgreich aktiv. Der erste Portainer-Ingress-Versuch wurde vorher
vom ingress-nginx Admission Webhook blockiert; dieser Admission-Pfad wurde
danach repariert und per Server-Dry-Run validiert. Danach wurde der echte
Portainer-Ingress erstellt und cert-manager hat ein gueltiges TLS-Zertifikat
ausgestellt.

Aktueller Domain/TLS-Stand:

1. `http://portainer.activi.io` leitet mit `308` auf HTTPS um.
2. `https://portainer.activi.io` liefert `HTTP/2 200` und zeigt Portainer.
3. Certificate `portainer/portainer-activi-io-tls` ist `Ready=True`.
4. TLS Secret `portainer/portainer-activi-io-tls` existiert als `kubernetes.io/tls`, `DATA=2`; Inhalte nicht ausgeben.
5. Der fruehere NodePort-Fallback `9443:30779` wurde danach geschlossen: Portainer Service ist jetzt `ClusterIP`, clusterweit existieren keine `NodePort` Services mehr.

Update 2026-05-21 18:43 CEST:

- `http://portainer.activi.io` und `https://portainer.activi.io` liefern extern nginx `404 Not Found`.
- Dieser `404` ist korrekt, solange keine Portainer-Ingress-Route existiert.
- Damaliger Zwischenstand: NodePort `30779` blieb bis zum erfolgreichen Domain/TLS-Test als Fallback offen. Dieser Fallback ist inzwischen geschlossen.
- cert-manager Helm Release `v1.20.2` ist installiert; Pods Ready; CRDs vorhanden.
- ClusterIssuer `letsencrypt-prod` ist angelegt und `Ready=True`.
- Account-Secret `cert-manager/letsencrypt-prod-account-key` existiert als Metadaten; keine Secret-Inhalte wurden ausgegeben.
- Keine Certificates/Orders/Challenges und keine Portainer-Ingress-Route wurden beim ClusterIssuer-Block angelegt.

Update 2026-05-21 19:12 CEST:

- Audit-Skript fuer die letzten Stack-Aussagen angelegt:
  `/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh`.
- Der Lauf prueft read-only:
  DNS, HTTP-Redirect auf HTTPS, HTTPS `200`, Cluster-Ready, `ingress-nginx`,
  Portainer-Ingress, `cert-manager` inklusive CRDs/Webhook, `letsencrypt-prod`
  Ready, Certificate `portainer-activi-io-tls`, Portainer Service `ClusterIP`
  ohne NodePorts, `longhorn` als Default, Velero Deployment/BackupStorageLocation,
  Longhorn Backup Target und OS-Restic Host/Tag-Snapshots Server 2/3.
- Letzter Lauf nach Portainer-Ingress/TLS-Abschluss:
  `RESULT: PASS`, `Passes: 45`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260521-225515.log`.

Update 2026-05-21 20:18 CEST:

- Portainer-Ingress wurde versucht, aber nicht gespeichert.
- Fehler: `failed calling webhook "validate.nginx.ingress.kubernetes.io": context deadline exceeded`.
- Keine `Certificate`, `CertificateRequest`, `Order`, `Challenge` oder App-Ingresses wurden erzeugt.
- Damaliger Zustand: Portainer NodePort blieb `9443:30779`; `portainer.activi.io` lieferte zu diesem Zeitpunkt weiter nginx `404`. Dieser Fallback ist inzwischen geschlossen.
- Admission-Service `ingress-nginx-controller-admission`: `10.43.55.93:443`.
- Admission-Endpunkte: `10.0.1.10:8443`, `10.0.1.20:8443`, `10.0.1.30:8443`.
- Von Server 1 ist nur `10.0.1.10:8443` erreichbar; `10.0.1.20:8443` und `10.0.1.30:8443` sind nicht erreichbar.
- Naechster Schritt vor einem neuen Ingress-Versuch: interne private `8443`-Erreichbarkeit beziehungsweise ingress-nginx Admission-Konfiguration reparieren.

Update 2026-05-21 21:18 CEST:

- Admission-Webhook-Pfad wurde repariert.
- Hetzner Robot Firewall: auf allen drei Servern internes TCP `8443` von `10.0.1.0/24` erlaubt.
- Server 1 UFW: auf `enp41s0.4000` TCP `8443` von `10.0.1.0/24` erlaubt.
- Node-zu-Node-Matrix fuer `10.0.1.10:8443`, `10.0.1.20:8443`, `10.0.1.30:8443` ist von allen drei Servern erfolgreich.
- Kubernetes Server-Dry-Run fuer Portainer-Ingress ist erfolgreich und hat nichts gespeichert.
- Zu diesem Zeitpunkt weiterhin keine Ingresses, Certificates, CertificateRequests, Orders oder Challenges.
- Dieser naechste Schritt ist seit 2026-05-21 22:45 CEST erledigt: Portainer-Ingress erstellt, Zertifikat Ready, HTTPS aktiv.

Update 2026-05-21 22:45 CEST:

- Portainer-Ingress wurde erfolgreich erstellt.
- Ingress: `portainer/portainer`, Host `portainer.activi.io`, IngressClass `nginx`.
- Backend: Service `portainer`, Port `9443`, HTTPS-Backend-Annotation gesetzt.
- Certificate `portainer/portainer-activi-io-tls` ist `Ready=True`.
- TLS Secret `portainer/portainer-activi-io-tls` ist als Metadaten vorhanden: Typ `kubernetes.io/tls`, `DATA=2`.
- ACME Order war `valid`; keine Challenge mehr aktiv.
- `http://portainer.activi.io` leitet auf HTTPS um.
- `https://portainer.activi.io` liefert Portainer mit `HTTP/2 200`.
- Damaliger Zustand: Portainer NodePort blieb unveraendert `9443:30779`. Dieser Fallback wurde im nachfolgenden Hardening-Block geschlossen.
- `audit-recent-stack-claims.sh` wurde auf diesen neuen Sollzustand angepasst.

Update 2026-05-21 23:18 CEST:

- Portainer-NodePort-Hardening wurde abgeschlossen.
- Helm Release `portainer` wurde von Revision 1 auf Revision 2 aktualisiert.
- Portainer Service wurde per Helm von `NodePort` auf `ClusterIP` umgestellt.
- Aktueller Service: `ClusterIP`, Ports `9000/TCP`, `9443/TCP`, `8000/TCP`, keine `nodePort`-Felder.
- Clusterweit existieren keine `NodePort` Services mehr.
- `https://portainer.activi.io` liefert weiter `HTTP/2 200`.
- `http://portainer.activi.io` leitet weiter mit `308` auf HTTPS um.
- Externe Tests auf `30777`, `30779`, `30776` gegen alle drei Public IPs laufen in Timeout; die alten NodePorts sind nicht erreichbar.
- Aktualisiertes Recent-Audit: `RESULT: PASS`, `Passes: 46`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260521-233143.log`.
- Vollstaendiges Stack-Verify: `RESULT: PASS`, `Passes: 119`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260521-233236.log`.

Update 2026-05-22 22:36 CEST:

- Portainer/Kubernetes-API-Timeouts wurden nach der Longhorn-Migration und dem Ingress/TLS-Setup behoben.
- Ursache war nicht Portainer, nicht Longhorn und nicht Kubernetes-Service-Verteilung, sondern die Hetzner Robot Firewall Rueckpaket-Regel.
- Auf allen drei Robot-Firewalls muss die ACK-Rueckregel so bleiben:
  `tcp established`, IPv4/TCP, Quelle `0.0.0.0/0`, Ziel `0.0.0.0/0`, Quell-Port `0-65535`, Ziel-Port `0-65535`, TCP-Flags `ack`, Aktion `accept`.
- Diese Regel erlaubt keine neuen Verbindungen auf alle Ports; sie gilt nur fuer Pakete mit ACK-Flag.
- Die private Pod-zu-API-Regel `10.42.0.0/16 -> TCP 6443` bleibt auf allen drei Robot-Firewalls noetig.
- Pruefskript:
  `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`.
- Letzter Connectivity-Check:
  `RESULT: PASS`, 60/60 stabile Versuche pro Ziel, Log `/tmp/portainer-api-connectivity-20260523-024920.log`.
- Recent-Audit nach Fix:
  `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260523-024855.log`.
- Full Verify nach Fix:
  `RESULT: PASS`, `Passes: 126`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260523-025031.log`.

Nicht tun:

- Portainer direkt ueber Pod-IP veroeffentlichen.
- NodePort ohne separate Freigabe wieder oeffnen.
- TLS Secret-Inhalte ausgeben.

### Server-1 Docker-Apps

Aktuell ausserhalb von K3s:

```text
Healthchecks          healthchecks/healthchecks:latest        Port 8000
Hindsight             ghcr.io/vectorize-io/hindsight:latest   Ports 8888,9999
Hindsight Postgres    pgvector/pgvector:pg16                  Port 5432
```

Compose-Dateien:

```text
/opt/healthchecks/docker-compose.yml
/root/hindsight/docker-compose.yml
```

Bekannte Docker-Volumes:

```text
healthchecks_healthchecks_data
hindsight-data
hindsight_hindsight-data
hindsight_hindsight-postgres-data
```

Sichern:

- Compose-Dateien.
- `.env` Dateien nur als Dateien sichern, Inhalte nie anzeigen.
- Docker-Volumes per Restic oder kontrolliertem tar-Export.
- Hindsight Postgres per echtem DB-Dump.

DB-Dumps sind Pflicht, weil Volume-Snapshots allein nicht zwingend app-konsistent sind.

## Dateien auf Server 1

Diese Dateien wurden nach Freigabe fuer Phase 1 angelegt.

```text
/etc/k3s-backup/
/etc/k3s-backup/restic.env
/etc/k3s-backup/restic-password
/etc/k3s-backup/s3.env
/etc/k3s-backup/include-paths.txt
/etc/k3s-backup/exclude-patterns.txt
/usr/local/sbin/k3s-etcd-snapshot-s3.sh
/usr/local/sbin/k3s-s3-backup-secrets.sh
/usr/local/sbin/k3s-restic-backup.sh
/usr/local/sbin/k3s-restic-backup-init.sh
/usr/local/sbin/k3s-restic-forget.sh
/usr/local/sbin/k3s-restic-prune.sh
/usr/local/sbin/hindsight-postgres-dump.sh
/etc/systemd/system/k3s-etcd-snapshot-s3.service
/etc/systemd/system/k3s-etcd-snapshot-s3.timer
/etc/systemd/system/hindsight-postgres-dump.service
/etc/systemd/system/hindsight-postgres-dump.timer
/etc/systemd/system/k3s-restic-backup.service
/etc/systemd/system/k3s-restic-backup.timer
/etc/systemd/system/k3s-restic-forget.service
/etc/systemd/system/k3s-restic-forget.timer
/etc/systemd/system/k3s-restic-prune.service
/etc/systemd/system/k3s-restic-prune.timer
/var/lib/k3s-backup/postgres-dumps/
/var/lib/k3s-backup/restore-test/
```

Security-Anforderungen:

- `umask 077`.
- Secret-Dateien `root:root` und `0600`.
- Skripte `root:root` und `0700` oder `0750`.
- Keine Secrets in Logs.
- `set -euo pipefail`.
- `flock` gegen parallele Laeufe.
- Systemd Timer statt Cron bevorzugen.

Aktive Timer:

```text
hindsight-postgres-dump.timer  hourly
k3s-restic-backup.timer        hourly
k3s-restic-forget.timer        daily ca. 03:30 plus RandomizedDelaySec
k3s-etcd-snapshot-s3.timer     taeglich 00:10 und 12:10 plus RandomizedDelaySec
k3s-restic-prune.timer         sonntags ca. 04:30 plus RandomizedDelaySec
```

Alle Timer wurden nach manuellem `systemctl start ...` Test aktiviert.

## Phase 1 Ablauf

### 1. Backup-Ziel bestaetigen

Bevor etwas geschrieben wird, klaeren:

```text
Backup-Ziel: Hetzner Object Storage S3
Bucket: vom Nutzer bestaetigen lassen
Endpoint/Region: vom Nutzer bestaetigen lassen
Zugangsdaten: sicher auf Server 1 hinterlegen, niemals im Chat
```

### 2. Tools lesend pruefen

```bash
command -v k3s
command -v kubectl
command -v restic || true
command -v aws || true
command -v rclone || true
systemctl list-timers --all --no-pager | grep -Ei "backup|snapshot|borg|restic|rclone|k3s|longhorn|velero" || true
```

### 3. K3s Snapshot Zustand pruefen

```bash
k3s etcd-snapshot list
systemctl cat --no-pager k3s | grep -E -- "etcd-snapshot|etcd-s3" || true
```

### 4. Portainer PV-Pfad ermitteln

```bash
kubectl -n portainer get deploy,pod,pvc,svc -o wide
kubectl get pv,pvc -A
kubectl describe pv <PORTAINER_PV_NAME>
```

Nur Pfade und Status dokumentieren, keine Secret-Inhalte.

### 5. Docker-App-Scope pruefen

```bash
docker ps -a
docker volume ls
docker compose ls
find /root /srv /opt /home /var/www /usr/local /var/lib/docker \
  -maxdepth 5 \
  -type f \( -name "docker-compose.yml" -o -name "compose.yml" -o -name "compose.yaml" -o -name "*.env" \) \
  2>/dev/null | sort
```

Keine `.env` Inhalte ausgeben.

### 6. Restic initialisieren

Erst nach Freigabe:

```bash
restic init
restic snapshots
```

Nur Erfolg/Fehler melden, keine Secrets.

### 7. Erstes etcd S3 Backup

Erst nach Freigabe:

```bash
k3s etcd-snapshot save \
  --name "manual-pre-backup-system-$(date +%Y%m%d-%H%M%S)" \
  --etcd-s3 \
  --etcd-s3-endpoint "<S3_ENDPOINT>" \
  --etcd-s3-bucket "<S3_BUCKET>" \
  --etcd-s3-folder "k3s/etcd" \
  --etcd-s3-access-key "<FROM_SECURE_FILE>" \
  --etcd-s3-secret-key "<FROM_SECURE_FILE>"
```

In der echten Implementierung duerfen Access Key und Secret Key nicht in der Shell-History oder im Chat stehen. Sie muessen aus einer root-only Datei oder K3s Secret-Konfiguration kommen.

### 8. Erstes Restic Backup

Erst nach Freigabe:

```bash
restic backup \
  --files-from /etc/k3s-backup/include-paths.txt \
  --exclude-file /etc/k3s-backup/exclude-patterns.txt \
  --tag k3s \
  --tag server1 \
  --tag bootstrap
```

### 9. Retention

Empfohlene Restic Retention:

```bash
restic forget \
  --keep-hourly 48 \
  --keep-daily 14 \
  --keep-weekly 8 \
  --keep-monthly 12
```

Diese Retention ist gestaffelt zu verstehen:

- letzte 48 Stunden: stuendliche Wiederherstellungspunkte.
- letzte 14 Tage: taegliche Wiederherstellungspunkte.
- letzte 8 Wochen: woechentliche Wiederherstellungspunkte.
- letzte 12 Monate: monatliche Wiederherstellungspunkte.

Das bedeutet nicht, dass jeder einzelne Tages- oder Stundenstand fuer 12 Monate erhalten bleibt. Wenn ein Problem erst nach Monaten auffaellt, gibt es voraussichtlich noch einen groben Monatsstand, aber keinen exakten Tages- oder Stundenstand aus diesem Monat.

`restic prune` getrennt ausfuehren, nicht bei jedem stuendlichen Backup.

### 10. Validierung

```bash
restic snapshots
restic check
k3s etcd-snapshot list
```

Zusaetzlich:

- S3 Bucket objektseitig pruefen, ohne Secrets auszugeben.
- Datei-Test-Restore in ein temporaeres Verzeichnis durchfuehren.
- DB-Dump-Lesbarkeit pruefen.

## Restore Runbook Kurzfassung

Restore ist in Ebenen zu trennen.

### Datei-/Config-Restore

1. Restic Repository entsperren/pruefen.
2. Snapshot waehlen.
3. Restore in temporaeren Pfad.
4. Dateiinhalt und Rechte pruefen.
5. Erst danach produktiv zurueckkopieren.

### Portainer-PVC-Restore

1. Portainer stoppen nur mit Freigabe.
2. PVC/PV-Pfad ermitteln.
3. Restic Restore in temporaeren Pfad.
4. Rechte vergleichen.
5. Daten kontrolliert in PV-Pfad zurueckspielen.
6. Portainer starten und verifizieren.

### Hindsight Postgres Restore

1. Ziel-Postgres bestimmen.
2. Dump aus Restic wiederherstellen.
3. Restore in Test-DB bevorzugen.
4. Plausibilitaet pruefen.
5. Produktiver Restore nur mit Freigabe.

### K3s etcd Restore 3-Node HA

Nur mit ausdruecklicher Freigabe.

Grundprinzip:

1. Betroffene K3s Server stoppen.
2. Auf einem Server `k3s server --cluster-reset --cluster-reset-restore-path=...` ausfuehren.
3. Token sicherstellen.
4. Reset-Flag beachten.
5. Restore-Server normal starten.
6. Weitere Server kontrolliert wieder joinen/starten.
7. etcd Member/Health pruefen.

Dieser Restore ist destruktiv fuer den laufenden Clusterzustand und darf nicht automatisiert ohne Review laufen.

## Phase 2: Longhorn Backup Target

Erst nach Phase 1 und nach separater Longhorn-Entscheidung.

Update 2026-05-21 02:38 CEST: Longhorn wurde per Helm mit gepinnter Version
`1.11.2` installiert. Das Backup Target ist gesetzt:

```text
Backup Target: s3://activi@fsn1/longhorn/
Credential Secret: longhorn-s3-backup
Status: AVAILABLE=true
```

Unabhaengiger Phase-2-Check:

```text
Script: /Users/activi/Documents/activi K3s/check-longhorn-phase2.sh
Zeit: 2026-05-21 05:10 CEST
Ergebnis: RESULT PASS, Failures 0, Warnings 0
```

StorageClass-Stand:

```text
longhorn (default)
local-path
longhorn-static
```

Update 2026-05-21 03:06 CEST: Test-PVC/Test-App wurde validiert:

```text
Namespace: longhorn-test
PVC: longhorn-test-pvc
StorageClass: longhorn
Size: 1Gi
Longhorn Volume: pvc-997ae793-92a8-470a-a14d-f5a8a5e42179
Volume State/Robustness waehrend Test: attached / healthy
Replicas waehrend Test: 3 running, verteilt auf alle drei Nodes
Test-Pod: longhorn-test-writer war waehrend Test Running; Live-Stand 05:10 CEST: Completed
Probe file: /data/probe.txt geschrieben und gelesen
```

Live-Nachtrag 2026-05-21 05:10 CEST: Der Schreib-/Lesetest bleibt validiert,
aber der Test-Pod ist inzwischen planmaessig `Completed`. Das Testvolume ist
deshalb aktuell `detached` mit Robustness `unknown`; das ist kein
Produktivfehler, weil kein laufender Pod mehr daran haengt.

Update 2026-05-21 03:36 CEST: Longhorn Backup/Restore-Test fuer das Testvolume
wurde validiert:

```text
Snapshot: lh-test-snap-20260521-0309
Backup-CR: lh-test-backup-20260521-0309
Backup Status: Completed, progress 100
BackupVolume: pvc-997ae793-92a8-470a-a14d-f5a8a5e42179-7abc3dfe
Restore Volume: lh-test-restore-20260521-0324
Restore PVC: longhorn-test-restore-pvc Bound
Restore Pod: longhorn-test-restore-reader war waehrend Test Running; Live-Stand 05:10 CEST: Completed
Restored content: longhorn-test-2026-05-21T01:06:38+0000
Restore Volume State/Robustness waehrend Test: attached / healthy
Restore Replicas waehrend Test: 3 running, verteilt auf alle drei Nodes
```

Live-Nachtrag 2026-05-21 05:10 CEST: Der Restore-Test bleibt validiert, aber
auch der Restore-Reader-Pod ist inzwischen `Completed`. Das Restore-Volume ist
deshalb aktuell `detached` mit Robustness `unknown`.

Longhorn SystemBackup, Stand 2026-05-21 08:06 CEST:

```text
Fix: backup-execution-timeout von 1 auf 5 Minuten erhoeht
Alter SystemBackup: lh-system-backup-20260521-initial
Alter Status: Error, bleibt als Beleg stehen
Neuer SystemBackup: lh-system-backup-20260521-timeout5
Neuer Status: Ready
Version: v1.11.2
Backup Target: weiterhin AVAILABLE=true
Normales Test-Volume-Backup: weiterhin Completed, progress 100
```

Nachtrag 2026-05-21 09:21 CEST:

```text
SystemBackup-RecurringJob: lh-system-backup-daily
Task: system-backup
Cron: 17 2 * * *
Retain: 14
Groups: []
Policy: volume-backup-policy=disabled
Pre-Apps SystemBackup: lh-system-backup-pre-apps-20260521-disabled
Pre-Apps Status: Ready
Version: v1.11.2
```

Einordnung: Longhorn SystemBackup ist damit technisch validiert und automatisiert.
Die `disabled`-Policy ist bewusst gesetzt, weil noch keine produktiven Longhorn
Volumes existieren und ein vorheriger Pre-Apps-Versuch mit `if-not-present`
einen Fehler beim Parsen leerer Volume-Backup-Zeitstempel erzeugte. Der alte
fehlerhafte SystemBackup-CR und der fehlerhafte Pre-Apps-CR duerfen nur nach
separater Loeschfreigabe entfernt werden. Normales Longhorn Volume-Backup/Restore
bleibt validiert.

Wichtig: Longhorn ist seit 2026-05-24 Default. Bestehende `local-path` PVs wurden
durch diese Umstellung nicht migriert. Velero ist seit 2026-05-24 installiert
und restore-getestet. Produktive Migrationen muessen separat geplant und
freigegeben werden.

Phase-2-Ziele, Stand 2026-05-21 03:36 CEST:

- Longhorn installieren: erledigt.
- Longhorn Backup Target auf Hetzner Object Storage S3 setzen: erledigt.
- Test-PVC mit Longhorn erstellen: erledigt.
- Test-App schreiben/lesen lassen: erledigt.
- Longhorn Snapshot/Backup/Restore plausibel testen: erledigt.
- Longhorn SystemBackup: erledigt mit `lh-system-backup-20260521-timeout5`
  `Ready`.
- Longhorn SystemBackup-RecurringJob: erledigt mit `lh-system-backup-daily`,
  `volume-backup-policy=disabled`.
- Pre-Apps SystemBackup: erledigt mit
  `lh-system-backup-pre-apps-20260521-disabled` `Ready`.
- Erst danach produktive Stateful Apps auf Longhorn migrieren.
- Longhorn Volume-Snapshot-/Volume-Backup-RecurringJobs sind fuer Portainer
  aktiv. Weitere produktive Longhorn-Volumes duerfen erst nach separater
  Freigabe aufgenommen werden. Testvolumes duerfen nicht ueber eine globale
  `default`-Gruppe erfasst werden.

Wichtig:

- Bestehende `local-path` PVs werden durch Longhorn nicht automatisch zu Longhorn-Volumes.
- Portainer muss bis zu einer bewussten Migration weiter ueber Restic gesichert werden.

Update 2026-05-23 03:50 CEST:

- Portainer ist inzwischen bewusst auf Longhorn migriert. Aktiver PVC:
  `portainer/portainer-longhorn`, StorageClass `longhorn`, Longhorn Volume
  `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b`.
- Fuer manuelle Backup-Zwischenstopps vor Portainer-/Storage-Aenderungen gibt
  es jetzt ein Skript:

```bash
cd "/Users/activi/Documents/activi K3s"
./run-portainer-longhorn-backup.sh --dry-run
./run-portainer-longhorn-backup.sh --execute
./run-portainer-longhorn-backup.sh --afterflight
```

- `--dry-run` ist Pflicht vor `--execute`. Es erstellt keine Ressourcen.
- `--execute` erstellt genau:
  - ein Longhorn SystemBackup mit `volumeBackupPolicy: disabled`;
  - einen Longhorn Snapshot des Portainer-Longhorn-Volumes;
  - ein Longhorn Backup dieses Snapshots ins konfigurierte Backup Target.
- `--afterflight` prueft den zuletzt erzeugten Backup-Satz und stellt sicher,
  dass Portainer weiterhin `ClusterIP` nutzt, TLS `Ready` ist und das
  Portainer-Longhorn-Volume `healthy` bleibt.
- Erfolgreicher Lauf vor Portainer Business Edition:
  - SystemBackup `lh-system-backup-pre-be-20260523-034408`: `Ready`.
  - Snapshot `portainer-pre-be-snap-20260523-034408`: `readyToUse=true`.
  - Volume-Backup `portainer-pre-be-backup-20260523-034408`: `Completed`,
    `progress=100`.
  - Separater Afterflight: `RESULT: AFTERFLIGHT PASS`.

## Phase 2b: OS-Level Restic fuer Server 2/3

Status: aktiv, automatisiert und validiert seit 2026-05-21 11:53 CEST.

Naechster verbindlicher Backup-Schritt vor produktiven App-Installationen.

Grund: Der Cluster laeuft auf Hetzner Robot Dedicated Root Servern. Die
Hetzner-Cloud-Funktion fuer Server-Backups/Snapshots ist fuer diese Server nicht
verfuegbar. Reine OS-/Node-Konfiguration von Server 2 und Server 3 braucht daher
einen eigenen Backup-Baustein.

Verbindlicher Plan:

```text
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md
```

Aktive Restic-Repositories:

```text
Server 2 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os
Server 3 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os
```

Aktiver Scope:

- `/etc`
- `/root`
- `/home`
- `/var/spool/cron`
- generierte Metadata-Dateien unter `/var/lib/k3s-os-backup/metadata-current`

Bewusst ausgeschlossen:

- `/var/lib/rancher/k3s`
- `/etc/rancher/k3s`
- Longhorn-Volume-Daten

Sicherheitsvorgaben:

- root-only Configs unter `/etc/k3s-backup`;
- Passwortdatei via `RESTIC_PASSWORD_FILE`;
- keine Secrets in Skripten, Logs, Chat oder Git;
- Env-Datei ohne `export` nur mit `set -a; source ...; set +a` laden;
- `restic init` pro Node wurde ausgefuehrt;
- erstes Backup pro Node wurde validiert;
- `restic check` meldet auf beiden Repositories keine Fehler;
- nicht-destruktiver Restore-Test nach
  `/var/lib/k3s-os-backup/restore-test`.

Implementierter Stand:

- Server 2 hat ein initialisiertes Repo
  `s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os`.
- Server 3 hat ein initialisiertes Repo
  `s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os`.
- Auf beiden Nodes existieren root-only Configs und Passwortdateien.
- Auf beiden Nodes existieren systemd Timer fuer taegliches OS-Backup.
- Auf beiden Nodes wurde ein manueller Service-Test erfolgreich ausgefuehrt.
- Auf beiden Nodes meldet `restic check` keine Fehler.
- Auf beiden Nodes wurde `/etc/hostname` nicht-destruktiv nach
  `/var/lib/k3s-os-backup/restore-test` wiederhergestellt.
- Keine Secrets wurden ausgegeben.
- K3s, Longhorn, Docker-Apps, PVCs und Firewall wurden nicht veraendert.

Aktive Dateien/Timer:

```text
/usr/local/sbin/k3s-os-restic-backup.sh
/etc/systemd/system/k3s-os-restic-backup.service
/etc/systemd/system/k3s-os-restic-backup.timer
```

Timer:

```text
Server 2: hourly plus RandomizedDelaySec=10min
Server 3: hourly plus RandomizedDelaySec=10min
Retention: hourly 48, daily 14, weekly 8, monthly 12
```

Snapshots aus manuellem Service-Test:

```text
Server 2: 5edd164b
Server 3: 485c0079
```

Vollstaendiges Verify nach Einrichtung:

```text
RESULT: PASS
Passes: 117
Warnings: 0
Failures: 0
Log: /tmp/k3s-stack-complete-verify-20260521-115116.log
```

## Phase 3: Velero als Zusatzschicht

Velero ist kein Ersatz fuer K3s etcd, Restic, Longhorn oder
datenbankbewusste Backups. Es ist aber jetzt ein verbindlicher
Production-Readiness-Baustein, bevor groessere produktive App-Rollouts
beginnen.

Update 2026-05-24 03:45 CEST: Velero ist installiert und live validiert.

```text
Namespace: velero
Velero Version: 1.18.0
Helm Chart: velero-12.0.1
Provider: AWS/S3-kompatibel
S3 Bucket/Prefix: activi/velero
S3 Endpoint/Region: https://fsn1.your-objectstorage.com / fsn1
BackupStorageLocation: default, Available
VolumeSnapshotLocation: nicht gesetzt
Node Agent / Filesystem Backup: nicht aktiviert
```

Smoke-Test:

```text
Source Namespace: velero-smoke-source-20260524
Restore Namespace: velero-smoke-restore-20260524
Backup: velero-smoke-backup-20260524, Completed
Restore: velero-smoke-restore-20260524, Completed
PVCs: keine
Produktive Namespaces: nicht betroffen
```

Finale Pruefungen nach Velero:

```text
Recent Audit: RESULT PASS, Log /tmp/k3s-recent-stack-claims-audit-20260524-035713.log
Full Verify: RESULT PASS, Log /tmp/k3s-stack-complete-verify-20260524-035800.log
Production Readiness: RESULT PASS_WITH_GAPS, Gaps 7, Log /tmp/k3s-production-readiness-gap-audit-20260524-035937.log
Portainer API Connectivity: RESULT PASS, Log /tmp/portainer-api-connectivity-20260524-040004.log
```

Einordnung: Velero sichert hier Kubernetes-Ressourcen/Namespaces. Die
Longhorn-Volume-Daten bleiben ueber Longhorn Volume-Backups gesichert. Fuer
spaetere PostgreSQL-Workloads bleiben CloudNativePG, WAL-Archivierung und
zusaetzliche `pg_dump`-Exports erforderlich.

Velero wird eingerichtet, wenn:

- Longhorn installiert und getestet ist;
- S3 Backup-Ziel stabil funktioniert;
- Basis-Restore per K3s Snapshot und Restic verstanden ist;
- Portainer/Ingress/TLS stabil sind;
- vor produktiven App-Deployments Namespace-/Ressourcen-Restores gebraucht
  werden.

Velero-Ziel:

- Kubernetes-Ressourcen und Namespaces komfortabel sichern.
- Optional CSI Snapshots/Data Movement fuer Longhorn-Volumes nutzen.
- Keine Ersetzung fuer K3s etcd Disaster Recovery.
- Keine Ersetzung fuer App-konsistente DB-Dumps.
- Keine Ersetzung fuer K3s Server Token Backup.

Velero ist damit als Kubernetes-Ressourcen-/Namespace-Restore-Schicht aktiv.
Noch nicht eingerichtet sind Velero-Schedules fuer produktive Apps sowie
optionales CSI/Data-Movement. Diese Erweiterungen kommen erst nach
app-spezifischer Freigabe und ersetzen nicht die bestehenden Longhorn-
Volume-Backups oder datenbankbewusste Backups.

Velero war nicht der erste Backup-Schritt und wurde erst nach K3s-etcd, Restic,
Longhorn und Portainer-Hardening installiert. Vor groesseren produktiven
App-Deployments ist dieser Basis-Restore-Test jetzt erledigt.

## Phase 4: CloudNativePG mit Barman Cloud Plugin

CloudNativePG ist kein Ersatz fuer Longhorn-Volume-Backups, Velero oder K3s
etcd-DR. Es ist die datenbankbewusste Backup-Schicht fuer spaetere PostgreSQL-
Workloads. Der Testblock wurde bewusst nicht-produktiv ausgefuehrt.

Update 2026-05-24 05:26 CEST: CloudNativePG wurde installiert und live
validiert.

```text
Operator: cloudnative-pg Helm Chart 0.28.2, App Version 1.29.1
Namespace: cnpg-system
Barman Cloud Plugin: ghcr.io/cloudnative-pg/plugin-barman-cloud:v0.12.0
Plugin Deployment: cnpg-system/barman-cloud, Ready 1/1
Deprecated barmanObjectStore-Pfad: nicht verwendet
```

Nicht-produktiver Smoke-Test:

```text
Source Namespace: cnpg-smoke-20260524
Source Cluster: cnpg-smoke, 1 Instanz, StorageClass longhorn, 1Gi
ObjectStore: cnpg-smoke-store
S3 Ziel: s3://activi/cloudnativepg/smoke-20260524
S3 Endpoint/Region: https://fsn1.your-objectstorage.com / fsn1
WAL/Backup: ContinuousArchiving=True:ContinuousArchivingSuccess
Backup: cnpg-smoke-backup-20260524, phase completed, method plugin
Backup ID: 20260524T025915
pg_dump-Test: cnpg-smoke-pgdump-retry-20260524, succeeded=1
Restore Namespace: cnpg-smoke-restore-20260524
Restore Cluster: cnpg-smoke-restore, 1 Instanz, StorageClass longhorn, 1Gi
Restore-Testdaten vorhanden: ja
Produktive Namespaces/PVCs: nicht betroffen
```

Finale Pruefungen nach CloudNativePG:

```text
Recent Audit: RESULT PASS, Log /tmp/k3s-recent-stack-claims-audit-20260524-052300.log
Full Verify: RESULT PASS, Log /tmp/k3s-stack-complete-verify-20260524-052352.log
Production Readiness: RESULT PASS_WITH_GAPS, Gaps 5, Log /tmp/k3s-production-readiness-gap-audit-20260524-052527.log
Portainer API Connectivity: RESULT PASS, Log /tmp/portainer-api-connectivity-20260524-052603.log
```

Einordnung: Der Smoke-Test beweist Operator, Plugin, WAL-Archivierung, Backup,
Restore und einen logischen `pg_dump` gegen eine Testdatenbank. Fuer spaetere
produktive Datenbanken muessen trotzdem pro App Retention, Schedules,
Backup-Fenster, Restore-Ziel und zusaetzliche `pg_dump`-CronJobs definiert
werden. Der Production-Readiness-Gap fuer eine produktive Kubernetes-
`pg_dump`-Automation bleibt deshalb korrekt offen.

## Akzeptanzkriterien

Phase 1 gilt als erledigt, wenn:

- Hetzner Object Storage S3 Ziel bekannt und erreichbar ist.
- K3s etcd Snapshot extern in S3 liegt.
- Restic Repository initialisiert und geprueft ist.
- K3s Token/Configs gesichert sind.
- Portainer-PVC-Inhalt gesichert ist.
- Healthchecks/Hindsight Daten gesichert sind.
- Hindsight Postgres Dump existiert und plausibel lesbar ist.
- Restore-Runbook fuer Datei, PVC, DB und etcd existiert.
- Mindestens ein nicht-destruktiver Datei-/Dump-Restore getestet wurde.

Update 2026-05-21 01:06 CEST: Diese Akzeptanzkriterien sind fuer Phase 1 erfuellt.
Der erste automatische Dump-/Restic-Timerlauf wurde geprueft und dokumentiert.

Dieser damalige Stop-Punkt ist inzwischen ueberholt: Longhorn wurde installiert,
validiert und mit Backup Target/SystemBackup eingerichtet. Velero ist inzwischen
Teil des verbindlichen Production-Readiness-Plans und soll vor groesseren
produktiven App-Rollouts installiert und restore-getestet werden.

## Quellen

- K3s etcd snapshots: https://docs.k3s.io/cli/etcd-snapshot
- K3s backup and restore token requirement: https://docs.k3s.io/datastore/backup-restore
- Longhorn backup target: https://longhorn.io/docs/latest/snapshots-and-backups/backup-and-restore/set-backup-target/
- Velero CSI: https://velero.io/docs/v1.17/csi/

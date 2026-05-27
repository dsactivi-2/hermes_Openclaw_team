# Next Session Guide - K3s Hetzner Cluster

Stand: 2026-05-20 02:42 CEST.

## Aktueller Stand 2026-05-24

- `longhorn` ist die einzige Default StorageClass; `local-path` ist nur noch
  Alt-/Rollback-Kontext.
- Portainer Business laeuft auf `portainer/portainer-longhorn`, per
  Ingress/TLS, ohne NodePort.
- Velero ist installiert und per Smoke Backup/Restore validiert.
- CloudNativePG Operator + Barman Cloud Plugin sind installiert und per Smoke
  Backup/Restore validiert; produktive App-DB-Backups sind noch offen.
- Monitoring-Basisstack ist installiert; Prometheus Targets sind gruen.
- Offene Gaps: produktive `pg_dump`-Automation pro App, GitOps,
  SOPS/External Secrets/Vault, vollstaendiger Replacement-Node-DR-Drill und
  DNS/resolv.conf-Cleanup als separater Block.

Historische Log- und Gap-Zahlen in den Updates darunter sind Zeitpunkt-Snapshots
und nicht automatisch der aktuelle Sollzustand.

Update 2026-05-21 01:10 CEST: Backup Phase 1 ist aktiv, automatisiert und
nicht-destruktiv validiert. Der naechste Schritt ist nicht mehr
Backup-System pruefen/reparieren, sondern optional S3-Credential-Rotation und
damals Storage-Vorbereitung. Dieser Stand wurde durch die spaeteren Updates
unten ueberholt; Longhorn und OS-Restic sind inzwischen umgesetzt und validiert.

Update 2026-05-21 09:47 CEST: Longhorn ist installiert und validiert,
SystemBackup-RecurringJob ist aktiv, und ein Pre-Apps SystemBackup mit
`volume-backup-policy=disabled` ist `Ready`. OS-Level Restic fuer Server 2/3 war
zu diesem Zeitpunkt als separater Plan dokumentiert.

Update 2026-05-21 11:53 CEST: OS-Level Restic fuer Server 2/3 ist umgesetzt,
automatisiert und validiert. Vollstaendiges Verify:
`/tmp/k3s-stack-complete-verify-20260521-115116.log`, `RESULT: PASS`,
`Warnings: 0`, `Failures: 0`.

Update 2026-05-21 12:10 CEST: Backup-Arten sind in Status und Runbook getrennt
dokumentiert. Nicht jede Backup-Art laeuft auf jedem Node: etcd sichert
Cluster-State, Restic Host-Dateien, Longhorn Volume-Daten bzw. Longhorn-
Systemzustand. Longhorn Volume-RecurringJobs werden erst nach produktiver
Longhorn-Migration angelegt.

Update 2026-05-22 22:36 CEST: Portainer/Kubernetes-API-Timeouts sind behoben.
Die Ursache war die Hetzner Robot Firewall Rueckpaket-Regel: `tcp established`
war frueher auf Ziel-Port `32768-65535` begrenzt, Flannel/NAT nutzte aber auch
niedrigere Rueckports. Auf allen drei Robot-Firewalls ist die ACK-Rueckregel
jetzt `Quell-Port 0-65535`, `Ziel-Port 0-65535`, `TCP-Flags ack`, `accept`.
Das ist keine Freigabe neuer Verbindungen auf alle Ports, sondern nur fuer
Antwortpakete. Neuer aktiver Check:
`/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`.
Letzter Lauf: `RESULT: PASS`, Log
`/tmp/portainer-api-connectivity-20260523-024920.log`.

Update 2026-05-23 06:30 CEST: Der naechste Zielplan wurde erweitert:
Velero, CloudNativePG mit S3/WAL und `pg_dump`, Monitoring/Alerting,
Security-Hardening, GitOps/Argo CD, Backup-Loeschschutz, echter
Disaster-Recovery-Test und Upgrade-Strategie sind jetzt im Production-
Readiness-Plan enthalten:
`/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-23-production-readiness-hardening-plan.md`.
Update 2026-05-24 03:45 CEST: Der Velero-Basisblock aus diesem Plan ist
installiert und per nicht-destruktivem Smoke Backup/Restore validiert.

Update 2026-05-24 01:12 CEST: Server 2 ist ueber `kube3-2` live verifiziert.
Hostname `activi-k3-2`, OS-Restic Timer `enabled`/`active`, 49 Snapshots mit
Host `activi-k3-2` und Tag `os-server2`, `restic check` erfolgreich. Die
Server-2-Warning im Production-Readiness-Audit ist verschwunden. Frische
Pruefungen:

```text
/tmp/portainer-api-connectivity-20260524-010923.log
RESULT: PASS

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

Dieser Stand wurde durch das Update 2026-05-24 03:05 CEST ueberholt:
Longhorn Volume-RecurringJobs fuer Portainer sind inzwischen aktiv. Der
damalige naechste empfohlene Block war Velero installieren und
Namespace-Restore testen; dieser Velero-Basisblock ist seit 2026-05-24 03:45
CEST erledigt.

Update 2026-05-24 02:45 CEST: Storage-Default und K3s-Istzustand wurden erneut
live verifiziert. `longhorn` ist die einzige Default StorageClass,
`local-path` ist vorhanden aber nicht Default, `portainer/portainer-longhorn`
ist der aktive produktive PVC, der alte `portainer/portainer` PVC ist nur
Rollback-Altbestand. Frische Pruefungen:

```text
/tmp/k3s-storage-default-audit-20260524-024143.log
RESULT: PASS

/tmp/k3s-recent-stack-claims-audit-20260524-024216.log
RESULT: PASS

/tmp/k3s-stack-complete-verify-20260524-024259.log
RESULT: PASS

/tmp/k3s-production-readiness-gap-audit-20260524-024431.log
RESULT: PASS_WITH_GAPS
Passes: 21
Warnings: 0
Gaps: 9
Failures: 0
```

Update 2026-05-24 03:05 CEST: Longhorn Volume-RecurringJobs fuer Portainer
wurden umgesetzt und live verifiziert. Aktiv sind:
`prod-snapshot-hourly` (`snapshot`, `7 * * * *`, Retain `48`),
`prod-backup-daily` (`backup`, `37 1 * * *`, Retain `14`) und
`prod-backup-weekly` (`backup`, `12 3 * * 0`, Retain `8`). Alle drei Jobs
nutzen Gruppe `prod-critical`. Ausschliesslich
`portainer/portainer-longhorn` beziehungsweise Longhorn Volume
`pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b` ist in dieser Gruppe. Es gibt keinen
Job auf Gruppe `default`, Testvolumes sind nicht in `prod-critical`, und
`lh-system-backup-daily` blieb unveraendert.

Frische Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-025911.log
RESULT: PASS

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

Update 2026-05-24 03:45 CEST: Velero wurde installiert und mit einem
nicht-destruktiven Namespace-Restore-Test validiert. Aktiver Stand:

```text
Velero Version: 1.18.0
Helm Chart: velero-12.0.1
Namespace: velero
BackupStorageLocation: default, Available
S3 Bucket/Prefix: activi/velero
Smoke Backup: velero-smoke-backup-20260524, Completed
Smoke Restore: velero-smoke-restore-20260524, Completed
Source Namespace: velero-smoke-source-20260524
Restore Namespace: velero-smoke-restore-20260524
```

Es wurden keine produktiven Namespaces oder PVCs veraendert. Longhorn,
Portainer, StorageClass, Firewall und DNS blieben unveraendert.

Update 2026-05-24: Fuer neue App-Projekte gibt es jetzt zwei verbindliche
Vorlagen:

```text
/Users/activi/Documents/activi K3s/docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md
/Users/activi/Documents/activi K3s/docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md
```

Jeder Agent, der ein neues App-Projekt an diesen K3s-Stack anpasst, muss zuerst
den App Integration Standard lesen und den Fragekatalog verwenden. App-Werte
nicht in Prompts verstreuen, sondern app-spezifisch dokumentieren.

Finale Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-035713.log
RESULT: PASS

/tmp/k3s-stack-complete-verify-20260524-035800.log
RESULT: PASS

/tmp/k3s-production-readiness-gap-audit-20260524-035937.log
RESULT: PASS_WITH_GAPS
Gaps: 7
Failures: 0

/tmp/portainer-api-connectivity-20260524-040004.log
RESULT: PASS
```

Naechster freizugebender Block: CloudNativePG mit S3/WAL und zusaetzlichem
`pg_dump` fuer Postgres auf Longhorn testen. Danach Monitoring/Alerting,
GitOps/External Secrets und echter DR-Test.

Update 2026-05-24 05:26 CEST: Der CloudNativePG-Testblock ist abgeschlossen.
Installiert und verifiziert wurden CloudNativePG Operator `1.29.1` per Helm
Chart `cloudnative-pg-0.28.2` und Barman Cloud Plugin `v0.12.0`. Verwendet
wurde ausschliesslich der aktuelle Plugin-Weg, nicht der deprecated
`barmanObjectStore`-Clusterpfad.

Nicht-produktiver Teststand:

```text
Source Namespace: cnpg-smoke-20260524
Source Cluster: cnpg-smoke, StorageClass longhorn, 1Gi
ObjectStore: cnpg-smoke-store
S3 Bucket/Prefix: activi/cloudnativepg/smoke-20260524
WAL/Backup: ContinuousArchiving=True:ContinuousArchivingSuccess
Backup: cnpg-smoke-backup-20260524, phase completed
pg_dump-Test: cnpg-smoke-pgdump-retry-20260524, succeeded=1
Restore Namespace: cnpg-smoke-restore-20260524
Restore Cluster: cnpg-smoke-restore, StorageClass longhorn, 1Gi
Restore-Testdaten vorhanden: ja
```

Es wurden keine produktiven Datenbanken, Namespaces oder PVCs veraendert.
Portainer, Longhorn, StorageClass, Firewall und DNS blieben unveraendert. Der
erste fehlgeschlagene Smoke-`pg_dump`-Job wurde nach expliziter Freigabe
geloescht; der Retry-Job war erfolgreich.

Finale Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-052300.log
RESULT: PASS

/tmp/k3s-stack-complete-verify-20260524-052352.log
RESULT: PASS

/tmp/k3s-production-readiness-gap-audit-20260524-052527.log
RESULT: PASS_WITH_GAPS
Gaps: 5
Failures: 0

/tmp/portainer-api-connectivity-20260524-052603.log
RESULT: PASS
```

Naechster freizugebender Block: Monitoring/Alerting einrichten oder vorher die
produktive `pg_dump`-Automation/Schedules fuer spaetere CloudNativePG-
Datenbanken konkret planen. Nicht automatisch mit produktiven Apps, Matrix,
GitOps oder CloudNativePG-Produktivdatenbanken weitermachen.

Update 2026-05-24 12:17 CEST: Der Monitoring-Basisblock wurde installiert.
Release `kube-prometheus-stack`, Chart `85.3.0`, App Version `v0.90.1`,
Namespace `monitoring`. Prometheus, Alertmanager und Grafana sind Ready.
Services sind `ClusterIP`; es gibt keinen Monitoring-Ingress, keine NodePorts
und keine LoadBalancer. PVCs sind `Bound` auf `longhorn`:
Prometheus `10Gi`, Alertmanager `2Gi`, Grafana `5Gi`.

Historischer Direktstand nach der Monitoring-Installation:

```text
targets_total=23
up=21
problematic=2
Problematisch:
- node-exporter 10.0.1.20:9100 context deadline exceeded
- node-exporter 10.0.1.30:9100 context deadline exceeded
```

Einordnung: node-exporter Pods laufen, aber Prometheus kann zwei Node-IP-
Targets auf Port `9100` nicht scrapen. Keine Firewall- oder Helm-Fixes wurden
ohne Freigabe gemacht.

Nachher-Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-121415.log
RESULT: PASS_WITH_WARNINGS
Warnings: 4
Failures: 0

/tmp/k3s-stack-complete-verify-20260524-121512.log
RESULT: FAIL
Failures: 22
Grund: Server-3-SSH root@167.235.6.160 Too many authentication failures

/tmp/k3s-production-readiness-gap-audit-20260524-121654.log
RESULT: PASS_WITH_GAPS
Warnings: 1
Gaps: 4
Failures: 0

/tmp/portainer-api-connectivity-20260524-121723.log
RESULT: PASS
```

Update 2026-05-24 14:05 CEST: Das Monitoring-/Pruefpfad-Follow-up ist
abgeschlossen. Server-3-SSH wird in den Skripten mit
`-o IdentitiesOnly=yes -i ~/.ssh/k3-3` geprueft. Private TCP-Erreichbarkeit
`9100` ist zwischen allen Nodes gruen; Prometheus Targets sind `23/23` up.
Frische Pruefungen:

```text
/tmp/k3s-recent-stack-claims-audit-20260524-134016.log
RESULT: PASS

/tmp/portainer-api-connectivity-20260524-134017.log
RESULT: PASS

/tmp/k3s-stack-complete-verify-20260524-135828.log
RESULT: PASS

/tmp/k3s-production-readiness-gap-audit-20260524-140239.log
RESULT: PASS_WITH_GAPS
Gaps: 4
Failures: 0
```

Naechster sinnvoller Betriebsblock ist DNS-/resolv.conf-Cleanup fuer die
Kubernetes Event-Warnung `Nameserver limits were exceeded`. Read-only-Befund:
alle Nodes nutzen systemd-resolved Stub; die echte
`/run/systemd/resolve/resolv.conf` enthaelt zu viele Nameserver fuer Pod-DNS,
Server 1 zusaetzlich Tailscale-DNS/Search-Domain. Umsetzung nur separat mit
Backup-Zwischenstopp: reduzierte dedizierte K3s-Resolver-Datei,
K3s/kubelet `resolv-conf`, Nodes einzeln rollen, danach alle Audits.

Diese Datei ist die konkrete Startanleitung fuer die naechste Codex-Session.

## 1. Pflicht: zuerst lesen

In dieser Reihenfolge vollstaendig lesen:

```text
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-19-k3s-server2-server3-migration-backup.md
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-23-production-readiness-hardening-plan.md
```

Danach kurz zusammenfassen:

- Was ist bereits erledigt?
- Was ist offen?
- Was wird als naechstes sicher geprueft?
- Welche Aktionen brauchen ausdrueckliche Freigabe?

Der aktuelle empfohlene naechste Pfad ist:

```text
1. Vor Umsetzung einen Backup-Zwischenstopp und Verify abschliessen.
2. Portainer Business UI final fachlich abnehmen.
3. DNS-/resolv.conf-Cleanup planen und nur nach separater Freigabe umsetzen.
4. Externe Alertmanager-Receiver und gezielte Longhorn/Velero/CNPG-
   ServiceMonitors planen.
5. GitOps/External Secrets vorbereiten.
6. Danach erste produktive Apps deployen.
```

Nicht mit alten Annahmen starten. Server 3 ist kein alter LXD/Docker/MariaDB-Panel-Server mehr. Server 3 wurde neu installiert und ist jetzt produktiver K3s control-plane/etcd Node.

## 2. Startregeln

- Erst Live-Stand pruefen, dann handeln.
- Keine destruktiven Aktionen ohne Freigabe.
- Keine Secrets, Tokens, Passwoerter, API Keys, Kubeconfigs oder `.env` Inhalte ausgeben.
- Keine alten Docker-Apps stoppen, bevor Migration und Restore verifiziert sind.
- Keine Firewall-Haertung, die SSH/K3s aussperren koennte.
- Wenn Live-Stand und Doku abweichen, stoppen und klaeren.

## 3. Relevante Skills

Nutzen:

```text
kubernetes
kubernetes-resources
kubernetes-security
kubernetes-helm
kubernetes-manifests
docker
```

Nur bei passender Entscheidung:

```text
traefik
```

Nur mit Vorsicht:

```text
hetzner-deploy
```

Grund: Der Cluster laeuft auf Hetzner Robot Dedicated Servern, nicht auf Hetzner Cloud. Keine hcloud-Annahmen blind uebernehmen.

## 4. Absoluter Startcheck

Status: erledigt am 2026-05-20 02:30 CEST und lokal geloggt.

Log:

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

Ergebnis:

- Alle drei Nodes sind `Ready`.
- Alle drei laufen mit K3s `v1.32.1+k3s1`.
- Alle Pods sind `Running`.
- Keine Problem-Pods im Filter.
- StorageClasses sind `longhorn (default)`, `local-path` und `longhorn-static`.
- Longhorn ist installiert und seit 2026-05-24 bewusst Default fuer neue PVCs.
- Portainer laeuft `1/1`, Image `portainer/portainer-ee:2.39.2`.
- Portainer Business Edition 3 Nodes Free ist aktiviert; Login klappt und die Business-Lizenz wird angezeigt.
- Portainer aktiver PVC ist `Bound`, `10Gi`, StorageClass `longhorn`: `portainer-longhorn`.
- Der alte PVC `portainer` auf `local-path` bleibt absichtlich als Rollback-Beleg erhalten und darf nicht ohne Cleanup-Plan geloescht werden.
- Portainer Service ist `ClusterIP` mit `9000/TCP`, `9443/TCP`, `8000/TCP`; keine Kubernetes-NodePorts.
- Portainer antwortet extern ueber `https://portainer.activi.io` mit `HTTP/2 200`; HTTP leitet mit `308` auf HTTPS um.
- Portainer-Pods haben nur interne Pod-IPs; keine externe Pod-IP ist erwartet.
- IngressClass `nginx` ist vorhanden; cert-manager ist installiert; Portainer-Ingress ist aktiv, kein LoadBalancer-Service.
- etcd: alle drei Endpoints healthy, alle Member `started`, alle `learner=false`.

SSH-/Verbindungsstand:

- Server 1: `ssh k3-1`.
- Server 2: `ssh kube3-2`; am 2026-05-24 vom User getestet und als
  funktionierend gemeldet.
- Server 3: bekannter lokaler Key `/Users/activi/.ssh/k3-3`.
- Details:
  `/Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md`.
- Naechster fokussierter Handover-Prompt fuer diese Verifikation:
  `/Users/activi/Documents/activi K3s/docs/SERVER2-VERIFY-HANDOVER-PROMPT-2026-05-24.md`.

Bekannte kosmetische Abweichung:

```text
ubuntu-noble-latest-amd64-base-3982578f
activi-k3-2-48af0a1d
activi-k3-3-82cc6d74
```

Diese etcd Member-Namen weichen von den Hostnames ab, sind aber technisch ok. Nicht deswegen stoppen, solange Endpoint-URLs, `started`, `learner=false` und Health stimmen.

Nur erneut ausfuehren, wenn der Live-Stand seit dem Log neu bestaetigt werden soll:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get storageclass
kubectl get pv,pvc -A
kubectl get ingressclass
kubectl get ingress -A
ETCDCTL_API=3 etcdctl \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
  --endpoints=https://10.0.1.10:2379,https://10.0.1.20:2379,https://10.0.1.30:2379 \
  member list -w table
ETCDCTL_API=3 etcdctl \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
  --endpoints=https://10.0.1.10:2379,https://10.0.1.20:2379,https://10.0.1.30:2379 \
  endpoint health -w table
```

Erwartet:

- `activi-k3-1.0`, `activi-k3-2`, `activi-k3-3` sind `Ready`.
- Alle drei laufen mit K3s `v1.32.1+k3s1`.
- Alle drei sind control-plane/etcd/master.
- Alle etcd Member sind `started`.
- Alle etcd Member haben `learner=false`.
- Alle etcd Endpoints sind healthy.

Sofort stoppen, wenn:

- Ein Node `NotReady` ist.
- Ein etcd Endpoint nicht healthy ist.
- Ein Member `learner=true` bleibt.
- Pods in `CrashLoopBackOff`, `Pending`, `ImagePullBackOff`, `Error` oder `CreateContainerConfigError` auftauchen.

## 5. Arbeitspaket 1: Backup-System

Status: erledigt fuer Phase 1. Das Backup-System ist aktiv, automatisiert und
nicht-destruktiv validiert.

Aktiver Stand:

```text
Bucket: activi
Region/Endpoint: fsn1 / https://fsn1.your-objectstorage.com
K3s etcd S3 Ziel: s3://activi/k3s/etcd/
Restic Repository: s3:https://fsn1.your-objectstorage.com/activi/restic/server1
```

Validiert:

```text
Restic Snapshots: d4faae42, c2b385b0, c9af17e7
Erster automatischer Dump-Timer: 2026-05-21 01:04:27 CEST
Erster automatischer Restic-Timer: 2026-05-21 01:04:47 CEST
restic check: no errors were found
Preflight: RESULT PASS, Warnings 0, Failures 0
Preflight log: /tmp/k3s-backup-phase1-check-20260521-010319.log
```

Aktive Timer:

```text
hindsight-postgres-dump.timer  hourly
k3s-restic-backup.timer        hourly
k3s-restic-forget.timer        daily ca. 03:30 plus RandomizedDelaySec
k3s-etcd-snapshot-s3.timer     taeglich 00:10 und 12:10 plus RandomizedDelaySec
k3s-restic-prune.timer         sonntags ca. 04:30 plus RandomizedDelaySec
```

Backup-Arten:

```text
K3s etcd Snapshot      = Kubernetes-/Cluster-State
Restic Server 1        = Dateien/Docker-App-Daten/DB-Dumps und verbliebene Server-1-Daten
OS-Restic Server 2/3   = OS-/Node-Konfiguration von Server 2 und Server 3
Longhorn               = Portainer-Longhorn-PVC und kuenftige produktive Longhorn-PVCs
Longhorn Volume Backup = Daten in produktiven Longhorn-PVCs, sobald vorhanden
Longhorn SystemBackup  = Longhorn-Konfiguration/Systemressourcen
Velero                 = installiert und Smoke-Restore-validiert fuer Kubernetes-Ressourcen/Namespace-Restore
```

Wichtig: Nicht jede Backup-Art muss auf jedem Node laufen. Sie muss dort laufen,
wo die jeweilige Datenklasse liegt oder sinnvoll erreichbar ist.

Offen:

- Optional S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar wurde.
- Portainer UI fachlich fertig einrichten und absichern.
- Longhorn Volume-RecurringJobs fuer `portainer/portainer-longhorn` sind aktiv:
  `prod-snapshot-hourly`, `prod-backup-daily`, `prod-backup-weekly`, Gruppe
  `prod-critical`, keine Jobs auf `default`.
- Danach Healthchecks/Hindsight-Migrationen vorbereiten.

Nicht tun:

- Secret-Dateien mit `cat` ausgeben.
- Alte Snapshots loeschen.
- Longhorn, Velero oder CloudNativePG ohne explizite Freigabe neu installieren,
  umbauen oder erweitern.

## 5b. Arbeitspaket: OS-Level Restic Server 2/3

Status: aktiv, automatisiert und validiert.

Plan:

```text
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md
```

Aktiver Stand:

- Server 2 OS-Repo: `s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os`
- Server 3 OS-Repo: `s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os`
- root-only Configs unter `/etc/k3s-backup`;
- Passwortdatei via `RESTIC_PASSWORD_FILE`;
- Env-Datei per `set -a; source ...; set +a` laden;
- systemd Timer statt Cron;
- Server 2 Timer: `k3s-os-restic-backup.timer`, `hourly` plus
  `RandomizedDelaySec=10min`;
- Server 3 Timer: `k3s-os-restic-backup.timer`, `hourly` plus
  `RandomizedDelaySec=10min`;
- Retention: `hourly 48`, `daily 14`, `weekly 8`, `monthly 12`;
- letzte validierte Snapshot-Marker: Server 2 `5edd164b`, Server 3
  `485c0079`;
- `restic check` auf beiden Repositories ohne Fehler;
- nicht-destruktiver Restore-Test `/etc/hostname` erfolgreich.

Nicht tun:

- Keine Secrets ausgeben.
- Keine generischen `hel1`-/`k3s-backups`-Beispiele uebernehmen.
- Keine K3s-/Longhorn-Daten doppelt per OS-Restic sichern.
- Keine produktiven Pfade beim Restore-Test ueberschreiben.

Dieser Block ist abgeschlossen. Der vorherige ingress-nginx Admission-Webhook-
Blocker auf internem `8443` ist repariert und per Server-Dry-Run validiert.
Portainer ueber Domain/HTTPS und das anschliessende NodePort-Hardening sind erledigt.
Der erste automatische OS-Restic Timerlauf bleibt als separater Nachcheck fuer
2026-05-22 offen.

## 5c. Verbindliche Arbeitsreihenfolge

Stand 2026-05-22 03:49 CEST:

Aktuelle kompakte TODO-Liste:

```text
/Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md
```

Zentrale Handover-Anweisung fuer neue Agenten:

```text
/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
```

1. Portainer komplett einrichten und absichern: Access Tokens, Helm-Repos, Registries, Kubernetes Environment.
2. Business-Edition-Funktionen nur gezielt konfigurieren: RBAC, Audit Logging, OAuth/SSO, Registry-Management, Quotas.
3. DNS-/resolv.conf-Cleanup als separaten Betriebsblock planen.
4. Externe Alertmanager-Receiver und gezielte Longhorn/Velero/CNPG-
   ServiceMonitors planen.
5. Produktive `pg_dump`-Automation fuer spaetere CloudNativePG-Datenbanken planen.
6. GitOps/External Secrets vorbereiten.
7. Healthchecks von Docker nach K3s + Longhorn migrieren.
8. Hindsight + Postgres von Docker nach K3s + Longhorn migrieren.
9. Optional S3-Credentials rotieren.
10. Backup-Loeschschutz, Security-Hardening, Upgrade-Strategie und echten DR-Test umsetzen.

## 6. Arbeitspaket 2: Server-1-Datenmigration

Status: offen.

Live-Audit 2026-05-20 zeigte:

```text
healthchecks          healthchecks/healthchecks:latest        Port 8000
hindsight             ghcr.io/vectorize-io/hindsight:latest   Ports 8888,9999
hindsight-postgres    pgvector/pgvector:pg16                  Port 5432
```

Compose-Dateien:

```text
/opt/healthchecks/docker-compose.yml
/root/hindsight/docker-compose.yml
```

Volumes:

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

Vor Migration neu pruefen:

```bash
docker ps -a
docker volume ls
docker compose ls
find /root /srv /opt /home /var/www /usr/local /var/lib/docker \
  -maxdepth 5 \
  -type f \( -name "docker-compose.yml" -o -name "compose.yml" -o -name "compose.yaml" -o -name "*.env" \) \
  2>/dev/null | sort
ls -lah /root/k3s-migration-backup /root/docker-backup /root/backups 2>/dev/null || true
```

Offene Entscheidungen:

- Welche App zuerst: `healthchecks` oder `hindsight`?
- Welche App zuerst kontrolliert auf Longhorn migriert wird.
- Welche Domains/Subdomains werden genutzt?
- Wie werden Postgres Dumps erstellt und verifiziert?

Nicht tun:

- Docker-Apps stoppen.
- Docker-Volumes loeschen.
- `.env` Inhalte in Chat oder Markdown ausgeben.
- Alte Backups als ausreichend behandeln, ohne frische Backups/Dumps.

## 7. Arbeitspaket 3: Longhorn/Storage

Status: installiert und validiert.

Bekannter Stand:

```text
longhorn (default)
local-path
longhorn-static
```

Erledigt:

- Longhorn per Helm `1.11.2` installiert.
- Longhorn ist Default.
- Backup Target `s3://activi@fsn1/longhorn/` ist `AVAILABLE=true`.
- Test-PVC/Test-App validiert.
- Longhorn Volume-Backup/Restore fuer Testvolume validiert.
- Longhorn SystemBackup validiert.
- SystemBackup-RecurringJob `lh-system-backup-daily` aktiv.

Offen:

- Longhorn UI nur ueber sicheren Admin-Zugriff/Tunnel nutzen oder spaeter
  sauber absichern.
- Produktive Migrationen separat planen.
- Fuer Portainer sind Longhorn Volume-Snapshot-/Volume-Backup-RecurringJobs
  aktiv. Weitere produktive Longhorn-Volumes erst nach separater Freigabe in
  `prod-critical` aufnehmen.
- Keine Jobs auf `default`; Testvolumes bleiben ausgeschlossen.

## 8. Arbeitspaket 4: Portainer

Ziel: Portainer nutzbar, gesichert und nicht dauerhaft breit per NodePort offen. Der NodePort-Fallback ist geschlossen; Portainer laeuft ueber Domain/TLS und internen `ClusterIP` Service.

Pruefen:

```bash
kubectl -n portainer get deploy,pod,pvc,svc -o wide
kubectl -n portainer describe svc portainer
```

Offen:

- 2FA/MFA pruefen/aktivieren, falls verfuegbar.
- Domain/Ingress/TLS ist aktiv.
- NodePort-Hardening ist abgeschlossen: keine Kubernetes-NodePorts.
- Portainer Business Edition 3 Nodes Free ist aktiviert; Login klappt und die Business-Lizenz wird angezeigt.
- Portainer Longhorn-Migration ist erledigt und validiert.

Nicht tun:

- Portainer-PVCs loeschen, besonders den alten `local-path` Rollback-PVC, ohne separaten Cleanup-Plan.
- Portainer neu installieren, bevor Backup/PVC klar ist.
- Admin-Passwoerter oder Reset-Tokens dokumentieren.

## 9. Arbeitspaket 5: Ingress, DNS, TLS

Aktueller Stand:

- K3s-Traefik ist bewusst deaktiviert.
- IngressClass `nginx` vorhanden.
- `ingress-nginx` installiert und extern ueber `80/443` erreichbar.
- cert-manager installiert per Helm `v1.20.2`, Pods Ready, CRDs vorhanden.
- Keine LoadBalancer-Services vorhanden.
- Domain/DNS fuer Portainer dokumentiert: `portainer.activi.io -> 88.99.215.210`, Cloudflare `Nur DNS`.

Empfohlene Richtung:

- `ingress-nginx` ist der aktive dedizierte Ingress-Controller.
- `cert-manager` fuer TLS ist installiert und geprueft.
- DNS-01, wenn DNS-API-Zugriff vorhanden ist.
- HTTP-01, wenn `80/443` sauber auf den Ingress zeigen und kein DNS-API-Zugriff genutzt wird.

Update 2026-05-21 17:58 CEST:

- Der gewaehlte Standardweg ist Option A: Kubernetes Ingress + cert-manager + Let's Encrypt.
- Domain: `portainer.activi.io`.
- Let's-Encrypt-E-Mail: `ds@activi.io`.
- Cloudflare DNS steht auf `Nur DNS` und zeigt aktuell auf `88.99.215.210`.
- Ports `80` und `443` waren vor der `ingress-nginx`-Installation auf allen drei Nodes frei.
- `ingress-nginx` wurde danach installiert und extern validiert.
- Historischer Zwischenstand vor Ingress-Erstellung: `portainer.activi.io` lieferte nginx `404 Not Found` auf HTTP und HTTPS.
- `cert-manager` wurde danach installiert und live gegengeprueft: Helm Release `cert-manager`, Chart/App `v1.20.2`, Pods Ready, CRDs vorhanden.
- Bis zu diesem Installationsblock waren keine realen `Issuer`, `ClusterIssuer`, `Certificate`, `CertificateRequest`, `Order` oder `Challenge` angelegt.
- Neues Audit-Skript fuer diese Zwischenlage:
  `/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh`.
  Letzter Lauf nach Portainer-Ingress/TLS-Abschluss: `RESULT: PASS`, `Passes: 45`, `Warnings: 0`,
  `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260521-225515.log`.
- ClusterIssuer `letsencrypt-prod` wurde danach angelegt und ist `Ready=True` mit Reason `ACMEAccountRegistered`.
- Account-Secret `cert-manager/letsencrypt-prod-account-key` existiert als Metadaten; keine Secret-Inhalte wurden ausgegeben.
- Portainer-Ingress wurde danach versucht, aber nicht gespeichert: der ingress-nginx Admission Webhook lief in `context deadline exceeded`.
- Keine Certificates, CertificateRequests, Orders, Challenges oder Portainer-Ingresses existieren.
- Diagnose: Admission-Service `10.43.55.93:443` zeigt auf `10.0.1.10:8443`, `10.0.1.20:8443`, `10.0.1.30:8443`; von Server 1 ist nur `10.0.1.10:8443` erreichbar.
- Danach wurden die Router-/Firewall-Regeln korrigiert: Hetzner Robot Firewall auf allen drei Servern fuer internes TCP `8443` von `10.0.1.0/24`, plus UFW auf Server 1 fuer `enp41s0.4000` Port `8443`.
- Node-zu-Node `8443` ist von allen drei Servern zu allen drei Admission-Endpunkten erfolgreich.
- Server-Dry-Run fuer den Portainer-Ingress ist erfolgreich und speichert nichts: `created (server dry run)`.
- Danach wurde der echte Portainer-Ingress erstellt:
  - Ingress `portainer/portainer`, Host `portainer.activi.io`, IngressClass `nginx`.
  - Backend Service `portainer`, Port `9443`, HTTPS-Backend-Annotation gesetzt.
  - Certificate `portainer/portainer-activi-io-tls` ist `Ready=True`.
  - TLS Secret `portainer/portainer-activi-io-tls` existiert als Metadaten, Typ `kubernetes.io/tls`, `DATA=2`.
  - `http://portainer.activi.io` leitet mit `308` auf HTTPS um.
  - `https://portainer.activi.io` liefert `HTTP/2 200` und Portainer.
- Danach wurde Portainer-NodePort-Hardening abgeschlossen: Service `ClusterIP`, keine Kubernetes-NodePorts.
- Noch nicht: Cloudflare Proxy-Aktivierung, 2FA/MFA beziehungsweise gezielte Business-Feature-Konfiguration.
- Fuer den naechsten Block nicht tun: DNS-Aenderung, weitere Firewall-Aenderung, Portainer-PVC loeschen.
- K3s-Startargumente nicht ungefiltert ausgeben, weil sie sensible Token enthalten koennen.

Vor Installation klaeren:

- Welche Domain?
- Welche Subdomains?
- Welche Public Entry-IP?
- Ein Node als Entry oder spaeter Load-Balancer/Floating-IP-Alternative?
- Bleibt Traefik deaktiviert?

Nicht tun:

- Traefik und nginx-ingress ohne Konzept mischen.
- DNS setzen, bevor Ziel-IP klar ist.
- Kubernetes API oeffentlich ueber Domain exponieren.
- NodePort ohne ausdrueckliche Freigabe wieder oeffnen.

## 10a. Backup-Zwischenstopps vor groesseren Aenderungen

Vor jeder groesseren Aenderung an Portainer, Storage, PVCs, Helm-Releases,
Ingress/TLS, Firewall oder produktiven Apps:

1. `audit-recent-stack-claims.sh` muss `PASS` sein.
2. `verify-k3s-stack-complete.sh` muss `PASS` sein.
3. Frischer K3s etcd Snapshot nach S3.
4. Frischer Server-1 Restic Backup-Lauf, solange Portainer oder Docker-App-Daten auf Server 1 liegen.
5. Frischer Longhorn SystemBackup, wenn Longhorn-/Kubernetes-Systemressourcen betroffen sind.
6. Backups sichtbar pruefen, ohne Secret-Inhalte auszugeben.
7. Erst danach die Aenderung starten.

Stoppen, wenn einer dieser Punkte fehlschlaegt.

## 10. Arbeitspaket 6: Firewall/Security

Aktueller Rahmen:

- Private K3s-Kommunikation ueber `10.0.1.0/24`.
- K3s private Ports nur von `10.0.1.0/24` erlauben:
  - TCP `6443`
  - TCP `9345`
  - TCP `2379`
  - TCP `2380`
  - TCP `10250`
  - UDP `8472`
- SSH `22` initial offen.
- HTTP/HTTPS `80,443` optional fuer Ingress/Web.
- ingress-nginx Admission Webhook nutzt private HostNetwork-Endpunkte auf TCP `8443`; dieser Port ist intern von `10.0.1.0/24` erlaubt und darf nicht oeffentlich freigegeben werden.
- Pod-Netz zu Kubernetes API ist noetig: Quelle `10.42.0.0/16`, Ziel TCP `6443` auf allen drei Robot-Firewalls. Das ermoeglicht Pods wie Portainer/CoreDNS den stabilen Zugriff auf alle drei API-Server.
- `tcp established` ACK-Rueckregel auf allen drei Robot-Firewalls: Quell-Port `0-65535`, Ziel-Port `0-65535`, `TCP-Flags=ack`, `accept`. Nicht wieder auf `32768-65535` begrenzen.
- Ausgehend `Allow all`.

Bei erneuter langsamer Portainer-UI zuerst ausfuehren:

```bash
cd "/Users/activi/Documents/activi K3s"
./verify-portainer-api-connectivity.sh
```

Spaeter haerten:

- SSH auf Admin-IP oder Tailscale einschraenken.
- Portainer-NodePorts sind geschlossen; spaeter nur bei Bedarf mit Rollback-Plan wieder oeffnen.
- K3s API nicht breit oeffentlich erlauben.
- Host-Firewalls/UFW pro Node konsistent planen.

Haertung immer nur mit Vorher-/Nachher-Verifikation.

## 11. Stop-Kriterien

Sofort stoppen und Nutzer fragen, wenn:

- Ein Befehl Secrets ausgeben wuerde.
- Eine Aktion PVCs, etcd Member, Nodes, Docker-Volumes oder Firewall-Regeln destruktiv aendert.
- Ein Node aus dem Cluster fallen koennte.
- Der Live-Zustand nicht zur Dokumentation passt.
- Hetzner Robot UI etwas anderes zeigt als dokumentiert.
- Ein Tool Hetzner Cloud/hcloud statt Robot annimmt.

## 12. Empfohlene Reihenfolge fuer die naechste Session

1. Alle zentralen Dokumente lesen.
2. Startcheck-Log lesen und nur bei Bedarf erneut ausfuehren.
3. Ergebnis kurz zusammenfassen.
4. Backup Phase 1, Longhorn Phase 2 und OS-Restic Server 2/3 als erledigt
   behandeln; nicht neu aufbauen.
5. Portainer komplett einrichten und absichern.
   Backup-Zwischenstopp vor Business-Aktivierung ist erledigt:
   `lh-system-backup-pre-be-20260523-034408`,
   `portainer-pre-be-backup-20260523-034408`, Afterflight PASS.
   Business Edition ist aktiviert und nachtraeglich per Audit validiert.
6. Business-Edition-Funktionen nur nach Bedarf konfigurieren.
7. CloudNativePG-Smoke-Test als erledigt behandeln; produktive
   DB-Schedules/`pg_dump` nur pro App planen.
8. Monitoring-Nacharbeit und externe Alertmanager-Receiver planen.
9. GitOps/External Secrets vorbereiten.
10. Healthchecks migrieren.
11. Hindsight und Postgres migrieren.
12. SSH/K3s-Firewall haerten.

## 13. Fertiger Prompt fuer eine neue Session

```text
Wir machen am bestehenden K3s/Hetzner-Robot-Projekt weiter.

Pflicht vor jeder Aktion:
Lies zuerst vollstaendig diese Dateien:

/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-PHASE1-STATUS-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-19-k3s-server2-server3-migration-backup.md

Danach:
1. Kurz zusammenfassen, was erledigt und was offen ist.
2. Den Live-Stand des Clusters pruefen.
3. Keine destruktiven Aktionen ohne meine ausdrueckliche Freigabe.
4. Keine Secrets, Tokens, Passwoerter, Kubeconfigs oder .env Inhalte ausgeben.
5. Wenn Live-Stand und Unterlagen abweichen, stoppen und erst klaeren.

Bekannter Stand:
- 3-Node K3s HA ist erledigt.
- Server 3 wurde neu installiert und ist im Cluster.
- Backup Phase 1 ist aktiv, automatisiert und validiert.
- Longhorn ist installiert und validiert; seit 2026-05-24 ist Longhorn Default StorageClass.
- OS-Restic Server 2/3 ist aktiv, automatisiert und validiert.
- Optional offen ist S3-Credential-Rotation, weil eine Access Key ID im Chat sichtbar wurde.
- Portainer-Ingress/TLS und NodePort-Hardening sind erledigt. Portainer ist ueber `https://portainer.activi.io` erreichbar, der Service ist `ClusterIP`, und clusterweit existieren keine NodePort-Services.
- Portainer ist auf Longhorn migriert und validiert; der alte local-path PVC bleibt nur als Rollback-Beleg.
- Vor Portainer Business Edition wurde ein frischer Longhorn-Sicherungsstand
  erstellt: SystemBackup `lh-system-backup-pre-be-20260523-034408` und
  Portainer-Volume-Backup `portainer-pre-be-backup-20260523-034408`, beide
  erfolgreich validiert.
- Portainer Business Edition wurde danach aktiviert. Nutzerbestaetigung:
  Login klappt und Business-Lizenz wird angezeigt. Read-only Audit danach:
  `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`,
  Log `/tmp/k3s-recent-stack-claims-audit-20260523-041234.log`.
- Weitere offene Themen sind Server-1-Datenmigration, Healthchecks/Hindsight-Migration, Monitoring/Alerting und Firewall-Hardening.
```
# Current Handover Entry Point

For new sessions, start with:

1. `docs/SESSION-HANDOVER-2026-05-24.md`
2. `docs/NEXT-AGENT-START-PROMPT-2026-05-24.md`

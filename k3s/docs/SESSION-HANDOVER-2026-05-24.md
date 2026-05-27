# Session Handover - activi K3s - 2026-05-24

Dieses Dokument ist die zentrale Uebergabe fuer eine neue Agenten-Session. Es soll verhindern, dass aus altem Chat-Kontext geraten wird. Wenn Live-Zustand und Dokumentation voneinander abweichen, gilt: stoppen, Abweichung melden, keine Aenderung ausfuehren.

## Grundregel

- Keine Secrets, Tokens, Passwoerter, Kubeconfig-Inhalte oder privaten SSH-Key-Inhalte ausgeben.
- Keine produktiven Ressourcen loeschen.
- Keine DNS-, Cloudflare-, Hetzner-Firewall-, StorageClass-, Longhorn-, Portainer-, Velero-, CloudNativePG-, Monitoring- oder App-Aenderungen ohne explizite, eng begrenzte Freigabe.
- Vor jedem Aenderungsblock erst Read-only-Preflight ausfuehren.
- Bei Unsicherheit nicht raten, sondern stoppen und konkret fragen.

## Arbeitsverzeichnis

`/Users/activi/Documents/activi K3s`

## Pflichtdateien zuerst lesen

1. `docs/SESSION-HANDOVER-2026-05-24.md`
2. `docs/ACCESS-CONNECTIONS-2026-05-24.md`
3. `docs/PROJECT-STATUS-2026-05-20.md`
4. `docs/BACKUP-RUNBOOK-2026-05-20.md`
5. `docs/NEXT-SESSION-GUIDE-2026-05-20.md`
6. `docs/OPEN-TODOS-2026-05-22.md`
7. `docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md`
8. `docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md`
9. `docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md`
10. `docs/DEPLOY-PIPELINE-SIDEPROJECT-2026-05-27.md`

## Pflichtskripte kennen

- `audit-recent-stack-claims.sh`
- `verify-k3s-stack-complete.sh`
- `audit-production-readiness-gaps.sh`
- `verify-portainer-api-connectivity.sh`
- `audit-k3s-storage-default.sh`

## Baseline-Pruefung vor Aenderungen

```bash
cd "/Users/activi/Documents/activi K3s"
./audit-recent-stack-claims.sh
./verify-k3s-stack-complete.sh
./audit-production-readiness-gaps.sh
./verify-portainer-api-connectivity.sh
```

Erwartung:

- `audit-recent-stack-claims.sh`: `PASS`
- `verify-k3s-stack-complete.sh`: `PASS`
- `audit-production-readiness-gaps.sh`: `PASS_WITH_GAPS` ohne Failures
- `verify-portainer-api-connectivity.sh`: `PASS`

Wenn ein Skript Failures meldet: stoppen und Diagnose melden.

## Cluster und Zugriff

Cluster: `activi K3s`, 3-node HA K3s mit embedded etcd.

Nodes:

- Server 1: `ssh k3-1`, public `88.99.215.210`, private `10.0.1.10`, Hostname `activi-k3-1.0`
- Server 2: `ssh kube3-2`, public `178.63.12.52`, private `10.0.1.20`, Hostname `activi-k3-2`
- Server 3: `ssh -o IdentitiesOnly=yes -i ~/.ssh/k3-3 root@167.235.6.160`, private `10.0.1.30`, Hostname `activi-k3-3`

Netze:

- Private Node-IP-Netz: `10.0.1.0/24`
- Pod CIDR: `10.42.0.0/16`
- Kubernetes Service CIDR: `10.43.0.0/16`

## Aktueller Stack-Stand

- K3s: `v1.32.1+k3s1`
- StorageClass Default: `longhorn`
- `local-path` existiert, ist aber nicht Default.
- `longhorn-static` existiert, ist nicht Default. UI kann Default teilweise als `unknown` anzeigen; im Zweifel per `kubectl get storageclass` pruefen.
- Ingress: `ingress-nginx`, IngressClass `nginx`
- cert-manager: installiert, ClusterIssuer `letsencrypt-prod` Ready
- Portainer: Business Edition aktiv, Version `2.39.2`, erreichbar unter `https://portainer.activi.io`
- Portainer Service: ClusterIP, keine NodePorts
- Portainer produktives PVC: `portainer/portainer-longhorn` auf Longhorn
- Altes Portainer PVC: `portainer/portainer` auf `local-path`, nur Rollback-Altbestand, nicht ohne eigenen Cleanup-Block loeschen
- Healthchecks: Basisdeployment live unter `https://healthchecks.activi.io`,
  Namespace `healthchecks`, Deployment `1/1`, Longhorn-PVC
  `healthchecks-data`, Ingress `nginx`, Zertifikat `healthchecks-tls`
  `Ready=True`, externer Smoke-Test `HTTP/2 302` auf `/accounts/login/`.
  SQLite-S3-Backup und Restore-Test sind live verifiziert. Docker-Instanz auf
  Server 1 bleibt Rollback bis zu einem separaten Cleanup-Block.
- Longhorn: installiert und healthy, BackupTarget verfuegbar
- Velero: installiert und Smoke-Backup/Restore getestet
- CloudNativePG: Operator + Barman Cloud Plugin installiert, Smoke-Backup/Restore/pg_dump getestet
- Monitoring: kube-prometheus-stack installiert, ClusterIP only, Prometheus Targets nach Firewall-Fix `23/23 up`

## Backup-Stand

- K3s/etcd Snapshots nach S3: aktiv
- Server 1 Restic: stündlich, Retention `48 hourly, 14 daily, 8 weekly, 12 monthly`
- Server 2 OS-Restic: stündlich, gleiche Retention, via `kube3-2` verifiziert
- Server 3 OS-Restic: stündlich, gleiche Retention, via explizitem Key + `IdentitiesOnly=yes` verifiziert
- Longhorn SystemBackup: `lh-system-backup-daily`, Cron `17 2 * * *`, Retain `14`
- Longhorn Volume-RecurringJobs fuer Gruppe `prod-critical`:
  - `prod-snapshot-hourly`: Snapshot, Cron `7 * * * *`, Retain `48`
  - `prod-backup-daily`: Backup, Cron `37 1 * * *`, Retain `14`
  - `prod-backup-weekly`: Backup, Cron `12 3 * * 0`, Retain `8`
- Zielvolume fuer `prod-critical`: Portainer-Longhorn-Volume `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b`
- Velero: BackupStorageLocation `default` Available, Smoke-Restore in separatem Namespace erledigt
- Healthchecks: Velero Schedule `healthchecks-daily`, Cron `23 2 * * *`,
  included namespace `healthchecks`, TTL `336h0m0s`; SQLite-S3-CronJob
  `healthchecks-sqlite-backup`, Cron `27 3 * * *`; manueller Backup-Job
  `healthchecks-sqlite-backup-manual-20260525-2224` `Complete`, Objekt
  `s3://miniotest/healthchecks/sqlite/healthchecks-20260525T203919Z.sqlite.gz`,
  SHA256 `6156529e1b3e31ea3cbfbb8f05d222a544f438eba8c987f94686c259f839a149`,
  `SQLITE_INTEGRITY=ok`; Restore-Job `healthchecks-sqlite-restore-test`
  `Complete`, `RESTORE_SHA256_MATCH=ok`, `SQLITE_TABLES=24`.
- Healthchecks Longhorn RecurringJobs: `healthchecks-snapshot-hourly`
  Snapshot `17 * * * *`, Retain `48`; `healthchecks-backup-daily` Backup
  `47 1 * * *`, Retain `14`; `healthchecks-backup-weekly` Backup
  `22 3 * * 0`, Retain `8`; Gruppe `app-healthchecks`; Volume
  `pvc-f3646e24-e2c8-44f4-8e2d-0241bfca5f71` traegt
  `recurring-job-group.longhorn.io/app-healthchecks=enabled`. Baseline danach:
  `/tmp/k3s-baseline-gates-20260525-235629.log`, `RESULT: PASS`.
- Healthchecks Monitoring/Blackbox-Probe: Blackbox Exporter
  `monitoring/blackbox-exporter` ist `1/1`, Probe
  `monitoring/healthchecks-external` und PrometheusRule
  `monitoring/healthchecks-external-probe` sind angelegt. Direkter Probe-Wert
  `probe_success 1`; Prometheus sammelt
  `probe_success{job="healthchecks-external"} = 1`.
- CloudNativePG Smoke: S3 Endpoint `https://fsn1.your-objectstorage.com`, Bucket `activi`, Prefix `cloudnativepg/smoke-20260524`

## Bekannte UI-Hinweise

- Alte Portainer ReplicaSets mit `0/0` sind erwartbare Rollout-Historie, solange der aktuelle Portainer-ReplicaSet `1/1` ist.
- Leere ResourceQuotas, LimitRanges, HPAs, NetworkPolicies und PortForwardings sind aktuell erwartbar. NetworkPolicies sind aber ein offener Hardening-Punkt.
- CNPG `*-ro` Services koennen bei Single-Instance/Smoke-Clusters ohne Read-Replica leere Endpoints haben.
- `Nameserver limits were exceeded` Events sind bekannt und als DNS/resolv.conf-Cleanup offen.
- Portainer `local-path` PVC ist alter Rollback-Bestand, nicht aktiver Produktivspeicher.

## Geklaerte Entscheidungen 2026-05-24

- Zentrale Projektunterlagen sollen ins Git: `OPEN-TODOS-2026-05-22.md`,
  App-Integration-Standard, App-Onboarding-Fragebogen, Handover-/Prompt-
  Dateien und Runbooks. `.DS_Store`, temporaere Logs und lokale Arbeitsreste
  nicht aufnehmen.
- Portainer UI ist teilweise geprueft: Business Edition aktiv, Login ok,
  Access Tokens leer, DockerHub Registry vorhanden, Bitnami Helm Repo global
  gesetzt, Kubernetes Environment sichtbar. RBAC, Audit, OAuth/SSO und MFA
  bleiben offen.
- Testressourcen bleiben vorerst als Belege erhalten: `longhorn-test`,
  Velero-Smoke und CNPG-Smoke/Restore. Cleanup nur mit separater Freigabe.
- DNS/resolv.conf hat bisher nur Read-only-Befund; konkreter Rollout-Vorschlag
  fehlt noch.
- Externer Alertmanager-Receiver wird bewusst als letzter Monitoring-
  Ausbauschritt eingerichtet; Receiver wie E-Mail, Telegram/Webhook,
  Healthchecks oder Matrix spaeter gemeinsam per YAML/Secret ohne Secret-
  Ausgabe konfigurieren. Dabei Meta-Alerts fuer `BlackboxExporterDown`,
  `AlertmanagerDown`, fehlende Prometheus-Targets und optional einen externen
  Kontrollcheck fuer die Alarmkette einplanen.
- S3-Credential-Rotation ist noch nicht ausgefuehrt. Vorher Inventar und
  Reihenfolge fuer K3s etcd-S3, Server-1 Restic, Server-2/3 OS-Restic,
  Longhorn, Velero und CNPG/Barman erstellen.
- GitOps/Secrets-Zielentscheidung: Argo CD + SOPS als pragmatischer Standard.
  External Secrets/Vault spaeter nur bei echtem Bedarf fuer zentralen
  Secret-Store pruefen.
- Naechste produktive App nach Healthchecks-Basisdeploy: Healthchecks
  Production-ready-Nacharbeit abschliessen, danach Hindsight/Postgres oder
  Matrix. App-Onboarding-Fragebogen ist vor jedem weiteren Deployment Pflicht.
- DR-Test: erst schriftlicher DR-Plan, danach echter Replacement-Node-Drill mit
  Freigabe.
- Kubeconfig-/API-Zugaenge muessen noch ohne Secret-Werte inventarisiert und
  gehaertet werden.
- Git-Aufnahme der zentralen Doku soll als eigener Doku-Block erfolgen:
  vorher Dateiliste pruefen, `.DS_Store`, temporaere Dateien und lokale
  Arbeitsreste ausschliessen, dann sauberer Doku-Commit.
- Der Doku-Cleanup-/`.gitignore`-Block bereitet nur die spaetere Git-Aufnahme
  vor; Staging und Commit sind nicht Teil dieses Blocks.
- Naechster kleiner operativer Block: Portainer UI-Finalcheck, rein manuell und
  read-only ohne Secret-Ausgabe.
- Alertmanager-Ziel: ganz zum Schluss gemeinsam konfigurieren; externe
  Meldungen ueber YAML/Secret einrichten, ohne Secret-Werte auszugeben.
- GitOps/Secrets-Zielentscheidung: Argo CD + SOPS als pragmatischer Standard.
  External Secrets/Vault spaeter nur bei echtem Bedarf fuer zentralen
  Secret-Store pruefen.
- App-Prioritaet: Healthchecks-Basisdeploy, SQLite-Backup/Restore,
  Longhorn-RecurringJobs und Monitoring sind erledigt; zuerst spaeteren
  Healthchecks-Rollback-Cleanup planen, dann Hindsight/Postgres, danach Matrix.
  App-Onboarding-Fragebogen bleibt vor jedem Deployment Pflicht.
- Doku-Cleanup soll als eigener risikoarmer Block vor groesseren Arbeiten
  laufen: historische Stellen markieren, aktuelle Baseline klar machen und
  zentrale untracked Docs sauber aufnehmen.
- Fuehrungsmodus: Fuer jeden Block zuerst kurze Freigabeplanung; nach Freigabe
  ausfuehrbarer Agenten-Auftrag mit festem Rueckgabeformat.

## Offene naechste Bloecke

1. Deploy-Pipeline Nebenprojekt bauen und verifizieren:
   `deploy-pipeline.sh`, Phasen-Prompts, Report-Vertrag, Lock-System,
   `doctor`, Dummy-App-Test und Doku gemaess
   `docs/DEPLOY-PIPELINE-SIDEPROJECT-2026-05-27.md`. Bis zur Verifikation
   keine produktiven Deployments darueber fuehren.
2. Doku-Cleanup: alte Dateinamen/alte historische Abschnitte klarer markieren oder bereinigen.
3. DNS/resolv.conf-Cleanup wegen `Nameserver limits were exceeded`.
4. Monitoring-Nacharbeit: zuerst Longhorn/Velero/CNPG ServiceMonitors/Rules
   und weitere interne Alerts; Alertmanager Receiver ganz zum Schluss gemeinsam
   per YAML/Secret einrichten und mit Test-Alert pruefen. Pflicht im Runbook:
   `BlackboxExporterDown`, `AlertmanagerDown`, fehlende Prometheus-Targets und
   optional externer Kontrollcheck fuer die Alarmkette.
5. Healthchecks Production-ready: SQLite-Dump-CronJob und Restore-Test sind
   erledigt; Longhorn RecurringJobs/Gruppenzuordnung und Monitoring-Probe sind
   verifiziert; offen bleibt spaeterer Docker-Rollback-Cleanup.
6. Produktive pg_dump-Automation pro App/DB.
7. GitOps einrichten.
8. SOPS fuer GitOps-Secrets einrichten; External Secrets/Vault spaeter nur bei
   echtem Bedarf fuer zentralen Secret-Store pruefen.
9. NetworkPolicies/RBAC/PodSecurity-Hardening.
10. Hindsight-Migration oder Matrix-App-Integration nach App-Integration-Standard.
11. Vollstaendiger Replacement-Node-/DR-Drill.
12. S3-Credential-Rotation, weil frueher ein Access-Key-ID sichtbar wurde.
13. Spaeterer Cleanup des alten Portainer-local-path-PVC nur nach Backup- und Rollback-Freigabe.

## Stop-Punkte

Sofort stoppen, wenn:

- ein Audit Failure meldet,
- ein Schritt Secret-Inhalte ausgeben wuerde,
- eine Firewall-/DNS-/StorageClass-/PVC-/Longhorn-/Portainer-/Velero-/CNPG-Aenderung noetig waere,
- ein produktiver Namespace betroffen waere,
- Live-Zustand und Dokumentation nicht zusammenpassen,
- der User keine klare Freigabe fuer einen Aenderungsblock gegeben hat.

# Backup Handover fuer neue Session - 2026-05-21

Dieses Dokument ist ein Backup-only Handover. Es darf nicht als Freigabe fuer
Migration, Longhorn-Installation, Velero-Installation, Firewall-Haertung oder
App-Stopps verstanden werden.

## Kurzfassung

Backup Phase 1 ist nicht mehr neu aufzubauen. Sie ist aktiv, automatisiert und
nicht-destruktiv validiert.

Aktive Reihenfolge ab jetzt:

1. Ersten automatischen OS-Restic Timerlauf auf Server 2/3 nach dem geplanten Fenster pruefen.
2. Portainer komplett einrichten; Business Edition 3 Nodes Free separat bewerten.
3. Optional: Hetzner S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar wurde.
4. Danach: Portainer/Healthchecks/Hindsight-Migration weiter planen.
5. Spaeter optional: Velero als Zusatzschicht fuer Kubernetes-Ressourcen/Namespaces und ggf. CSI/Data-Movement.

Velero ist weiterhin nicht der naechste Schritt.

## Aktueller Stand

Cluster:

- 3-Node K3s HA mit embedded etcd.
- K3s `v1.32.1+k3s1`.
- Alle drei Nodes Ready laut Startcheck.
- etcd healthy laut Startcheck.
- StorageClass `local-path (default)`, zusaetzlich `longhorn` und `longhorn-static`.
- Longhorn installiert, nicht Default, Backup Target `AVAILABLE=true`.
- Velero nicht installiert.
- IngressClass `nginx` vorhanden; Portainer-Ingress/TLS aktiv.

Portainer:

- Bereits installiert.
- Namespace `portainer`.
- Deployment `portainer` laeuft `1/1`.
- PVC `portainer` ist `Bound`.
- Service ist `ClusterIP` mit `9000/TCP`, `9443/TCP`, `8000/TCP`; keine Kubernetes-NodePorts.
- Extern erreichbar ueber `https://portainer.activi.io` mit `HTTP/2 200`; HTTP leitet mit `308` auf HTTPS um.
- Portainer `local-path` PVC ist im Restic Backup-Scope.

Server-1 Docker-Apps:

- Healthchecks laeuft ausserhalb von K3s.
- Hindsight laeuft ausserhalb von K3s.
- Hindsight Postgres laeuft ausserhalb von K3s.
- Hindsight Postgres Dumps werden automatisch erstellt und per Restic gesichert.

Backup:

- Hetzner Object Storage Bucket: `activi`.
- Region/Endpoint: `fsn1`, `https://fsn1.your-objectstorage.com`.
- K3s etcd S3 Ziel: `s3://activi/k3s/etcd/`.
- Restic Repository: `s3:https://fsn1.your-objectstorage.com/activi/restic/server1`.
- Bucket-Erstellung laut Hetzner Console/Erstellungsdialog: Object Lock `aktiviert`, Sichtbarkeit `privat`.
- Object Lock/Sichtbarkeit wurden nicht separat per S3-API/AWS-CLI ausgelesen.

Longhorn:

- Helm Release `longhorn`, Chart `longhorn-1.11.2`, App `v1.11.2`.
- Backup Target: `s3://activi@fsn1/longhorn/`, `AVAILABLE=true`.
- Test-PVC/Test-App validiert.
- Longhorn Volume-Backup/Restore validiert.
- SystemBackup `lh-system-backup-20260521-timeout5` ist `Ready`.
- Pre-Apps SystemBackup `lh-system-backup-pre-apps-20260521-disabled` ist `Ready`.
- SystemBackup-RecurringJob `lh-system-backup-daily`: Cron `17 2 * * *`, Retain `14`, Groups `[]`, `volume-backup-policy=disabled`.

OS-Level Restic Server 2/3:

- Status: aktiv, automatisiert und validiert.
- Plan: `/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md`.
- Aktive Repos:
  - Server 2: `s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os`
  - Server 3: `s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os`
- Timer:
  - Server 2: `k3s-os-restic-backup.timer`, taeglich 05:20 plus RandomizedDelaySec.
  - Server 3: `k3s-os-restic-backup.timer`, taeglich 05:40 plus RandomizedDelaySec.
- Service-Test-Snapshots:
  - Server 2: `9cb2a95b`
  - Server 3: `9685ad3f`
- Vollstaendiges Verify: `RESULT: PASS`, `Passes: 117`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260521-115116.log`.

Backup-Arten:

- K3s etcd-Snapshot sichert Kubernetes-/Cluster-State.
- Restic Server 1 sichert Dateien und aktuelle Server-1-App-Daten.
- OS-Restic Server 2/3 sichert OS-/Node-Konfiguration.
- Longhorn Volume-Backup sichert spaetere Daten in produktiven Longhorn-PVCs.
- Longhorn SystemBackup sichert Longhorn-Systemressourcen.
- Velero ist spaeter nur Zusatzschicht fuer Kubernetes-Ressourcen/Namespaces.

Nicht jede Backup-Art muss auf jedem Node laufen. Jede Datenklasse muss genau
einmal sinnvoll gesichert und restore-getestet sein.

## Validierte Belege

K3s etcd-S3 Snapshots:

```text
manual-phase1-s3-20260521-000704-activi-k3-1.0-activi-k3-1.0-1779314824
manual-phase1-20260521-002925-activi-k3-1.0-activi-k3-1.0-1779316166
```

Restic Snapshots:

```text
d4faae42
c2b385b0
c9af17e7
```

Erster automatischer Timerlauf:

```text
hindsight-postgres-dump.timer: 2026-05-21 01:04:27 CEST
k3s-restic-backup.timer:       2026-05-21 01:04:47 CEST
```

Weitere Validierung:

```text
restic check: no errors were found
Preflight RESULT: PASS
Warnings: 0
Failures: 0
Preflight log: /tmp/k3s-backup-phase1-check-20260521-010319.log
Restore-Test: /var/lib/k3s-backup/restore-test/restic-20260521-000917
```

## Aktive Timer

```text
hindsight-postgres-dump.timer  hourly
k3s-restic-backup.timer        hourly
k3s-restic-forget.timer        daily ca. 03:30 plus RandomizedDelaySec
k3s-etcd-snapshot-s3.timer     taeglich 00:10 und 12:10 plus RandomizedDelaySec
k3s-restic-prune.timer         sonntags ca. 04:30 plus RandomizedDelaySec
```

## Server-1 Dateien

Root-only Konfiguration:

```text
/etc/k3s-backup/s3.env
/etc/k3s-backup/restic.env
/etc/k3s-backup/restic-password
/etc/k3s-backup/include-paths.txt
/etc/k3s-backup/exclude-patterns.txt
```

Skripte:

```text
/usr/local/sbin/k3s-s3-backup-secrets.sh
/usr/local/sbin/k3s-etcd-snapshot-s3.sh
/usr/local/sbin/hindsight-postgres-dump.sh
/usr/local/sbin/k3s-restic-backup-init.sh
/usr/local/sbin/k3s-restic-backup.sh
/usr/local/sbin/k3s-restic-forget.sh
/usr/local/sbin/k3s-restic-prune.sh
```

Arbeitsverzeichnisse:

```text
/var/lib/k3s-backup/postgres-dumps/
/var/lib/k3s-backup/restore-test/
```

## Wichtige Dateien

Vor jeder weiteren Aktion lesen:

```text
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-PHASE1-STATUS-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

## Sicherheitsregeln

Niemals ohne ausdrueckliche Freigabe:

- K3s neu installieren.
- K3s-Service-Flags aendern.
- `curl https://get.k3s.io ...` ausfuehren.
- Nodes entfernen.
- etcd Member loeschen.
- Docker-Apps stoppen.
- Docker-Volumes loeschen.
- PVCs/PVs loeschen.
- Portainer neu installieren.
- Portainer-PVC loeschen.
- Firewall-Regeln aendern.
- Longhorn neu installieren oder Default StorageClass aendern.
- Velero installieren.
- Secrets, Tokens, Passwoerter, API Keys, Kubeconfigs oder `.env` Inhalte ausgeben.

Wenn ein Befehl Secrets ausgeben wuerde: stoppen und sicherere Alternative waehlen.

## Naechster Agent

Der naechste Agent soll:

1. Backup Phase 1 als aktiv, automatisiert und validiert behandeln.
2. Nicht mehr behaupten, das Backup-System sei neu aufzubauen.
3. Longhorn als installiert und validiert behandeln; nicht erneut installieren.
4. Optional Credential-Rotation klaeren, ohne Secrets im Chat auszugeben.
5. OS-Level Restic Server 2/3 als aktiv, automatisiert und validiert behandeln;
   nur den ersten automatischen Timerlauf nachpruefen.
6. Longhorn Volume-RecurringJobs erst nach produktiver Longhorn-Migration und
   bewusster Gruppierung anlegen, nicht auf `default`.
7. Keine Docker-Apps stoppen, keine PVCs/Volumes loeschen, keine Firewall aendern.

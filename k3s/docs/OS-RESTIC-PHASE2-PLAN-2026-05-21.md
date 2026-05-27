# OS-Level Restic Phase 2 Plan - Server 2/3 - 2026-05-21

Stand: 2026-05-22 03:49 CEST.

Dieses Dokument beschreibt den Zusatzblock fuer OS-/Node-Level-Backups von
Server 2 und Server 3. Der Block ist umgesetzt, automatisiert und validiert. Er
ersetzt nicht die bereits aktive Backup Phase 1 und nicht die Longhorn-Backups.

Update 2026-05-21 10:00 CEST: Dieser Block ist der naechste verbindliche
technische Schritt vor Portainer-Absicherung, Ingress/TLS und produktiven
App-Installationen.

Update 2026-05-21 11:53 CEST: OS-Level Restic fuer Server 2/3 ist eingerichtet.
Manuelle Service-Tests, neue Snapshots, `restic check`, Timer-Aktivierung und
vollstaendiges Verify sind erfolgreich.

Update 2026-05-22 03:49 CEST: OS-Restic Server 2/3 wurde auf den Zielstandard
`hourly` plus Retention `48 hourly`, `14 daily`, `8 weekly`, `12 monthly`
angepasst und erneut validiert.

Ausfuehrungsplan:

```text
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-21-os-restic-server2-server3.md
```

## Ziel

Server 2 und Server 3 sollen jeweils ein eigenes Restic-Repository im bestehenden
Hetzner Object Storage Bucket erhalten, um reine OS-/Node-Konfiguration zu
sichern.

Nicht Ziel dieses Blocks:

- keine Sicherung produktiver Longhorn-Volume-Daten per Restic;
- keine doppelte Sicherung von K3s etcd/Cluster-State;
- keine Migration von Apps;
- keine Aenderung an StorageClasses;
- keine Secrets im Chat oder in Dokumenten.

## Hintergrund

Der Cluster laeuft auf Hetzner Robot Dedicated Root Servern, nicht auf Hetzner
Cloud Servern. Die Hetzner-Cloud-Funktion fuer Server-Snapshots/Backups ist
deshalb nicht fuer diese AX/Dedicated-Server verfuegbar. OS-Level-Backups muessen
selbst gebaut werden.

Aktueller Stand:

- Server 1 hat bereits Restic Phase 1 unter
  `s3:https://fsn1.your-objectstorage.com/activi/restic/server1`.
- Server 2 und Server 3 haben eigene OS-Restic-Repositories.
- Cluster-State ist ueber K3s etcd-S3-Snapshots gesichert.
- Kubernetes-PV-Daten werden fuer Longhorn-Volumes ueber Longhorn-Replikation
  und Longhorn-S3-Backups behandelt.

Einordnung der unterschiedlichen Backup-Arten:

- Server-1-Restic ist nicht identisch mit OS-Restic Server 2/3, weil Server 1
  aktuell zusaetzlich Docker-App-Daten, Hindsight Dumps und verbleibende
  Server-1-Daten traegt. Portainer wurde inzwischen auf Longhorn migriert.
- OS-Restic Server 2/3 ist bewusst schmaler und dient der Node-/OS-
  Rekonstruktion.
- K3s etcd-Snapshots sichern den Cluster-State, aber nicht die echten
  Volume-Dateiinhalte.
- Longhorn Volume-Backups sichern spaetere produktive Longhorn-PVC-Daten, aber
  nicht Host-OS und nicht K3s etcd.
- Longhorn SystemBackup sichert Longhorns eigene Systemressourcen, aber ersetzt
  keine Longhorn Volume-Backups.

Deshalb laufen unterschiedliche Backup-Jobs auf unterschiedlichen Ebenen. Das
ist beabsichtigt und vermeidet doppelte Sicherung derselben Datenklasse.

## Geplante Repositories

```text
Server 2 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os
Server 3 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os
```

Wichtig: Keine generischen `hel1`- oder `k3s-backups`-Beispiele verwenden. Der
aktive Bucket ist `activi`, die Region ist `fsn1`.

## Geplanter Backup-Scope

Sichern:

- `/etc`
- `/root`
- `/home`
- `/var/spool/cron`
- zusaetzlich generierte Metadata-Dateien, z. B.:
  - installierte Pakete;
  - manuell installierte Pakete;
  - systemd Unit-Dateien/Uebersicht;
  - Netzwerkuebersicht;
  - Disk-/Mount-Uebersicht.

Bewusst nicht sichern:

- `/var/lib/rancher/k3s`
- `/etc/rancher/k3s`
- Longhorn-Volume-Daten
- Docker-/Containerdaten, sofern sie nicht bewusst als OS-Konfiguration gelten

Begruendung: K3s/Cluster-State und Longhorn-Volume-Daten haben eigene Backup-
Ebenen. Dieser Block ist nur fuer Node-/OS-Rekonstruktion gedacht.

## Aktive Dateien Pro Node

```text
/etc/k3s-backup/
/etc/k3s-backup/restic-os.env
/etc/k3s-backup/restic-os-password
/usr/local/sbin/k3s-os-restic-backup.sh
/var/lib/k3s-os-backup/
/var/lib/k3s-os-backup/metadata-current/
/var/lib/k3s-os-backup/restore-test/
/etc/systemd/system/k3s-os-restic-backup.service
/etc/systemd/system/k3s-os-restic-backup.timer
```

Rechte:

```text
/etc/k3s-backup                  0700 root:root
/etc/k3s-backup/restic-os.env    0600 root:root
/etc/k3s-backup/restic-os-password 0600 root:root
/usr/local/sbin/k3s-os-*.sh      0700 root:root
/var/lib/k3s-os-backup           0700 root:root
```

## Env-Datei

Die Env-Datei darf keine Secrets ausgeben und darf nicht in Git landen.

Beispiel Server 2:

```bash
RESTIC_REPOSITORY="s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os"
RESTIC_PASSWORD_FILE="/etc/k3s-backup/restic-os-password"
AWS_ACCESS_KEY_ID="<root-only eingeben>"
AWS_SECRET_ACCESS_KEY="<root-only eingeben>"
RESTIC_TAG="os-server2"
```

Beispiel Server 3:

```bash
RESTIC_REPOSITORY="s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os"
RESTIC_PASSWORD_FILE="/etc/k3s-backup/restic-os-password"
AWS_ACCESS_KEY_ID="<root-only eingeben>"
AWS_SECRET_ACCESS_KEY="<root-only eingeben>"
RESTIC_TAG="os-server3"
```

Wichtige Shell-Regel: Wenn die Datei ohne `export` geschrieben wird, muss jedes
Skript sie mit `set -a` laden:

```bash
set -a
source /etc/k3s-backup/restic-os.env
set +a
```

Andernfalls sind die Variablen nicht sicher fuer den Kindprozess `restic`
sichtbar.

## Backup-Skript Logik

Das aktive Skript:

1. mit `set -euo pipefail` laufen;
2. `umask 077` setzen;
3. per `flock` parallele Laeufe verhindern;
4. Env per `set -a; source ...; set +a` laden;
5. Metadata unter `/var/lib/k3s-os-backup/metadata-current` neu erzeugen;
6. Restic Backup ausfuehren;
7. Retention ausfuehren: `--keep-daily 7`, `--keep-weekly 4`,
   `--keep-monthly 6`;
8. `restic check` ausfuehren;
9. Metadata nicht in `/tmp` als alleinige Quelle belassen;
10. keine Secrets ausgeben.

Beispiel-Scope:

```bash
restic backup \
  --one-file-system \
  --exclude-caches \
  --exclude '/var/lib/rancher/k3s' \
  --exclude '/etc/rancher/k3s' \
  /etc /root /home /var/spool/cron /var/lib/k3s-os-backup/metadata-current \
  --tag "$RESTIC_TAG"
```

## Init, Retention, Check

Pro Node muss das Repo einmal initialisiert werden:

```bash
restic init
```

Aktive Retention fuer OS-Backups:

```bash
restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 6
```

`prune` nicht zwingend nach jedem taeglichen Backup ausfuehren. Empfehlung:
separater woechentlicher Maintenance-Job.

`restic check`:

- nach dem ersten Backup zwingend;
- danach z. B. taeglich leicht oder woechentlich, je nach Laufzeit.

## Nicht-Destruktiver Restore-Test

Nach dem ersten Backup pro Node:

```bash
restic restore latest \
  --target /var/lib/k3s-os-backup/restore-test \
  --include /etc/hostname
```

Akzeptanz:

- Restore-Verzeichnis existiert;
- `/etc/hostname` ist im Restore-Test vorhanden;
- Hostname passt zum jeweiligen Node;
- keine produktiven Pfade werden ueberschrieben.

## Stop-Punkte

Sofort stoppen und melden, wenn:

- `restic init` wegen Repository/Permission/Password fehlschlaegt;
- S3-Zugriff fehlschlaegt;
- Env-/Secret-Dateien falsche Rechte haben;
- ein Skript Secret-Werte ausgeben wuerde;
- Restore-Test produktive Pfade beruehren wuerde;
- K3s/Longhorn/Backup Phase 1 nebenbei veraendert werden muesste.

## Status

Umgesetzt und validiert.

Belege:

```text
Server 2 Repo: s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os
Server 2 Tag: os-server2
Server 2 manueller Snapshot vor Timer: ce872a60
Server 2 Snapshot aus Service-Test: 9cb2a95b
Server 2 Restore-Test: /etc/hostname = activi-k3-2

Server 3 Repo: s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os
Server 3 Tag: os-server3
Server 3 manueller Snapshot vor Timer: b7bcbba8
Server 3 Snapshot aus Service-Test: 9685ad3f
Server 3 Restore-Test: /etc/hostname = activi-k3-3
```

Timer:

```text
Server 2: k3s-os-restic-backup.timer, hourly plus RandomizedDelaySec=10min
Server 3: k3s-os-restic-backup.timer, hourly plus RandomizedDelaySec=10min
Retention: 48 hourly, 14 daily, 8 weekly, 12 monthly
Letzte validierte Snapshot-Marker: Server 2 = 5edd164b, Server 3 = 485c0079
```

Vollstaendiges Verify:

```text
RESULT: PASS
Passes: 117
Warnings: 0
Failures: 0
Log: /tmp/k3s-stack-complete-verify-20260521-115116.log
```

Unveraendert:

- keine K3s-Aenderungen;
- keine Longhorn-Aenderungen;
- keine Docker-App-Aenderungen;
- keine PVC-/PV-Aenderungen;
- keine Firewall-Aenderungen;
- keine Secrets ausgegeben.

Naechster sicherer Schritt:

1. Portainer UI fachlich fertig einrichten; Business Edition 3 Nodes Free separat bewerten.
2. Longhorn Volume-RecurringJobs fuer Portainer und kuenftige produktive Longhorn-PVCs anlegen.
3. Healthchecks und Hindsight/Postgres kontrolliert nach K3s + Longhorn migrieren.

## Verbindliche Folge nach Abschluss

Nach erfolgreichem OS-Restic Server 2/3:

1. Portainer Domain/TLS und NodePort-Hardening sind erledigt.
2. Portainer ist auf Longhorn migriert und validiert.
3. Longhorn Volume-RecurringJobs fuer Portainer und kuenftige produktive Longhorn-PVCs anlegen.
4. Monitoring/Alerting einrichten.
5. Healthchecks und Hindsight/Postgres kontrolliert migrieren.

# Backup Phase 1 Status - 2026-05-21

Stand: 2026-05-21 01:06 CEST.

Dieses Dokument haelt den umgesetzten Backup-Phase-1-Stand fest. Es enthaelt
keine Secrets, keine `.env` Inhalte, keine Access Keys und keine Passwoerter.

## Ergebnis

Phase 1 ist funktional eingerichtet, automatisiert und nicht-destruktiv validiert.

Umgesetzt:

- K3s native etcd-Snapshots nach Hetzner Object Storage S3.
- Restic Repository nach Hetzner Object Storage S3.
- Hindsight Postgres Dump als echte DB-Dump-Datei.
- Restic Backup fuer:
  - K3s Configs und Server Token.
  - Lokale K3s Snapshots.
  - Portainer `local-path` PVC Hostpfad.
  - Docker-App-Daten fuer Healthchecks/Hindsight.
  - Compose-Dateien.
  - `.env` Dateien als Dateien, ohne Inhalte auszugeben.
  - Hindsight Postgres Dumps.
- Systemd Timer fuer automatische Laeufe.
- `restic check`.
- Nicht-destruktiver Datei-/Dump-Restore-Test.

Nicht umgesetzt:

- Longhorn ist weiterhin nicht installiert.
- Velero ist weiterhin nicht installiert.
- Firewall-Regeln wurden nicht geaendert.
- Docker-Apps wurden nicht gestoppt.
- PVCs/PVs/Volumes wurden nicht geloescht.

## S3 Ziel

```text
Bucket: activi
Region: fsn1
Endpoint: https://fsn1.your-objectstorage.com
K3s etcd folder: k3s/etcd
Restic repository: s3:https://fsn1.your-objectstorage.com/activi/restic/server1
Object Lock: aktiviert laut Hetzner Console/Erstellungsdialog
Sichtbarkeit: privat laut Hetzner Console/Erstellungsdialog
```

Hinweis: Object Lock und Sichtbarkeit wurden aus der Hetzner Console uebernommen;
sie wurden nicht separat per S3-API/AWS-CLI ausgelesen.

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

## Timer

```text
hindsight-postgres-dump.timer  hourly
k3s-restic-backup.timer        hourly
k3s-restic-forget.timer        daily ca. 03:30 plus RandomizedDelaySec
k3s-etcd-snapshot-s3.timer     taeglich 00:10 und 12:10 plus RandomizedDelaySec
k3s-restic-prune.timer         sonntags ca. 04:30 plus RandomizedDelaySec
```

## Restic Retention

Aktive Retention fuer Restic:

```text
hourly 48
daily 14
weekly 8
monthly 12
```

Das ist eine gestaffelte Aufbewahrung:

- letzte 48 Stunden: stündliche Wiederherstellungspunkte.
- letzte 14 Tage: tägliche Wiederherstellungspunkte.
- letzte 8 Wochen: wöchentliche Wiederherstellungspunkte.
- letzte 12 Monate: monatliche Wiederherstellungspunkte.

Das bedeutet nicht, dass jeder einzelne Tageszustand fuer 12 Monate erhalten bleibt. Nach mehreren Monaten gibt es nur noch grobe Monatsstände, nicht mehr jeden Tag oder jede Stunde.

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

Postgres Dumps:

```text
/var/lib/k3s-backup/postgres-dumps/hindsight-postgres-20260521-000741.sql.gz
/var/lib/k3s-backup/postgres-dumps/hindsight-postgres-20260521-002913.sql.gz
/var/lib/k3s-backup/postgres-dumps/hindsight-postgres-20260521-002926.sql.gz
/var/lib/k3s-backup/postgres-dumps/hindsight-postgres-20260521-010427.sql.gz
/var/lib/k3s-backup/postgres-dumps/hindsight-postgres-20260521-010447.sql.gz
```

Restore-Test:

```text
/var/lib/k3s-backup/restore-test/restic-20260521-000917
```

Validierung:

```text
restic check: no errors were found
systemctl --failed: keine Backup-Units fehlgeschlagen
Preflight: RESULT PASS, Warnings 0, Failures 0
Preflight log: /tmp/k3s-backup-phase1-check-20260521-010319.log
```

## Erster Automatiklauf

Der erste automatische Lauf wurde am 2026-05-21 geprueft:

```text
hindsight-postgres-dump.timer  last: 2026-05-21 01:04:27 CEST
k3s-restic-backup.timer        last: 2026-05-21 01:04:47 CEST
Restic snapshot: c9af17e7
restic check: no errors were found
```

## Naechste Pruefung

Regelmaessig oder nach Aenderungen pruefen:

```bash
systemctl list-timers --all --no-pager | grep -E "k3s|restic|hindsight"
journalctl --no-pager -u hindsight-postgres-dump.service -u k3s-restic-backup.service --since "today"
restic snapshots
restic check
```

Keine Secret-Dateien mit `cat` ausgeben.

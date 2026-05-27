# OS-Level Restic Server 2/3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Do not skip verification steps. Stop at every freigabepflichtiger Schritt.

Stand: 2026-05-21 10:00 CEST.

## Ziel

OS-Level Restic Backups fuer Server 2 und Server 3 einrichten und
nicht-destruktiv validieren.

Verbindliche Detailunterlagen:

```text
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
```

## Ziel-Repositories

```text
Server 2 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os
Server 3 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os
```

## Akzeptanzkriterien

- Server 2 und Server 3 haben jeweils ein eigenes initialisiertes Restic-Repo.
- Configs liegen root-only unter `/etc/k3s-backup`.
- Skripte liegen root-only unter `/usr/local/sbin`.
- systemd Timer sind aktiv.
- Je Node existiert mindestens ein Restic Snapshot.
- Je Node laeuft `restic check` ohne Fehler.
- Je Node ist `/etc/hostname` nicht-destruktiv nach
  `/var/lib/k3s-os-backup/restore-test` wiederhergestellt.
- Keine Secrets wurden ausgegeben.
- Keine K3s-, Longhorn-, Docker-, PVC- oder Firewall-Aenderungen wurden gemacht.

## Task 1: Read-only Preflight

- [ ] SSH zu Server 2 und Server 3 pruefen.
- [ ] Hostname, Datum und freien Speicher lesen.
- [ ] `restic` Verfuegbarkeit pruefen.
- [ ] `/etc/k3s-backup` nur per Metadaten pruefen, keine Inhalte ausgeben.
- [ ] Ergebnis melden und vor Schreibaktionen Freigabe einholen.

Erwartet:

```text
Server 2 erreichbar
Server 3 erreichbar
Keine Secrets ausgegeben
```

## Task 2: Root-only Struktur und Skripte vorbereiten

Nur nach Freigabe.

- [ ] Falls noetig `restic` installieren.
- [ ] `/etc/k3s-backup` mit `0700 root:root` anlegen.
- [ ] `/var/lib/k3s-os-backup` mit `0700 root:root` anlegen.
- [ ] Skripte unter `/usr/local/sbin` mit `0700 root:root` anlegen.
- [ ] Skripte muessen Env so laden:

```bash
set -a
source /etc/k3s-backup/restic-os.env
set +a
```

## Task 3: Secrets sicher hinterlegen

Nur nach Freigabe.

- [ ] `/etc/k3s-backup/restic-os-password` erstellen, `0600 root:root`.
- [ ] `/etc/k3s-backup/restic-os.env` erstellen, `0600 root:root`.
- [ ] Server 2 Repo-Pfad auf `server2-os` setzen.
- [ ] Server 3 Repo-Pfad auf `server3-os` setzen.
- [ ] Nur Metadaten/Rechte pruefen, keine Datei-Inhalte ausgeben.

## Task 4: Repos initialisieren

- [ ] Server 2: `restic init`.
- [ ] Server 3: `restic init`.
- [ ] Fehler sofort melden, keine Wiederholung ohne Diagnose.

## Task 5: Erstes Backup

- [ ] Metadata erzeugen:
  - `installed-packages.txt`
  - `manually-installed.txt`
  - `systemd-units.txt`
  - `network.txt`
  - `disks.txt`
  - `hostname.txt`
  - `date.txt`
- [ ] Backup Scope:
  - `/etc`
  - `/root`
  - `/home`
  - `/var/spool/cron`
  - `/var/lib/k3s-os-backup/metadata-current`
- [ ] Ausschliessen:
  - `/var/lib/rancher/k3s`
  - `/etc/rancher/k3s`
  - Longhorn-Volume-Daten

## Task 6: Check und Restore-Test

- [ ] `restic snapshots` je Node.
- [ ] `restic check` je Node.
- [ ] Restore-Test je Node nach `/var/lib/k3s-os-backup/restore-test`.
- [ ] Wiederhergestellte `etc/hostname` pruefen.

## Task 7: systemd Timer aktivieren

Erst nach erfolgreichem manuellem Backup.

- [ ] `k3s-os-backup.service` anlegen.
- [ ] `k3s-os-backup.timer` anlegen.
- [ ] Optional Check-/Prune-Timer separat anlegen.
- [ ] Timer aktivieren und naechste Laufzeit pruefen.

## Task 8: Dokumentation und Verify

- [ ] `docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md` auf umgesetzt aktualisieren.
- [ ] `docs/PROJECT-STATUS-2026-05-20.md` aktualisieren.
- [ ] `docs/BACKUP-RUNBOOK-2026-05-20.md` aktualisieren.
- [ ] Komplettes Verify-Skript um Server2/3-OS-Restic erweitern.
- [ ] Finalen Read-only Check ausfuehren.

## Stop-Punkte

Stoppen und melden, wenn:

- SSH zu einem Node fehlschlaegt;
- S3/Restic Auth fehlschlaegt;
- Secret-Dateien falsche Rechte haben;
- ein Befehl Secrets ausgeben wuerde;
- `restic check` Fehler meldet;
- Restore-Test produktive Pfade beruehren wuerde;
- K3s/Longhorn/Docker/PVC/Firewall-Aenderungen noetig waeren.

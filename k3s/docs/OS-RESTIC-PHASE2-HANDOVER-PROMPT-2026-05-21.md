# OS-Restic Phase 2 Handover Prompt - Server 2/3 - 2026-05-21

Kopiere den folgenden Prompt vollstaendig in die neue Agenten-Session.

---

Du arbeitest am Projekt:

```text
/Users/activi/Documents/activi K3s
```

## Ziel dieser Session

Richte OS-Level Restic Backups fuer Server 2 und Server 3 ein und validiere sie
nicht-destruktiv.

Dieser Block ist der naechste verbindliche technische Schritt vor:

1. Portainer ueber Domain/HTTPS erreichbar machen;
2. Portainer-Domain/TLS und NodePort-Hardening sind erledigt; NodePort nicht ohne separaten Rollback-Plan wieder oeffnen.
3. optionaler Portainer-Longhorn-Migration;
4. Monitoring/Alerting;
5. produktiven App-Installationen oder Migrationen.

## Zwingend zuerst lesen

Lies diese Dateien vollstaendig und nutze sie als verbindliche Grundlage:

```text
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/LONGHORN-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

Danach kurz melden:

- was bereits erledigt ist;
- was fuer OS-Restic Server 2/3 noch offen ist;
- welche Aktionen Schreibzugriff brauchen;
- welche Stop-Punkte gelten.

## Verbindlicher aktueller Stand

- 3-Node K3s HA ist aktiv.
- Alle drei Nodes laufen K3s `v1.32.1+k3s1`.
- Backup Phase 1 ist aktiv und validiert:
  - K3s etcd-S3 nach `s3://activi/k3s/etcd/`;
  - Restic Server 1 nach `s3:https://fsn1.your-objectstorage.com/activi/restic/server1`;
  - Hindsight Dumps;
  - systemd Timer;
  - Restore-Test.
- Longhorn ist installiert, nicht Default und validiert.
- Longhorn Backup Target ist `s3://activi@fsn1/longhorn/`, `AVAILABLE=true`.
- Longhorn SystemBackup und SystemBackup-RecurringJob sind validiert.
- Velero ist nicht installiert.
- Server 2 und Server 3 haben noch kein eigenes OS-Restic-Repository.

## Ziel-Repositories

```text
Server 2 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os
Server 3 OS: s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os
```

Keine generischen Beispiele verwenden:

- nicht `hel1`;
- nicht `k3s-backups`;
- nicht denselben Pfad wie Server 1.

## Sicherheitsregeln

Niemals ausgeben:

- Secrets;
- Access Keys;
- Secret Keys;
- Restic Passwoerter;
- Kubeconfigs;
- Tokens;
- `.env` Inhalte.

Niemals ohne separate Freigabe:

- Docker-Apps stoppen;
- K3s neu konfigurieren;
- Longhorn neu installieren;
- StorageClass Default aendern;
- PVCs/PVs/Volumes loeschen;
- Firewall-Regeln aendern;
- produktive Pfade beim Restore ueberschreiben.

## Vorgehen mit Stop-Punkten

### Schritt 1: Read-only Preflight

Nur lesen, nichts aendern:

- SSH auf Server 2 und Server 3 pruefen.
- Hostnames pruefen.
- `restic` Verfuegbarkeit pruefen.
- vorhandene `/etc/k3s-backup` Metadaten pruefen, aber keine Inhalte anzeigen.
- freien Speicher auf `/var/lib` pruefen.
- bestaetigen, dass K3s/Longhorn/Velero nicht veraendert werden muessen.

Melden:

- Server 2 erreichbar ja/nein;
- Server 3 erreichbar ja/nein;
- `restic` installiert ja/nein pro Node;
- `/etc/k3s-backup` existiert ja/nein pro Node;
- freie Kapazitaet pro Node;
- Stoppen, wenn SSH oder Basiszugriff nicht sauber ist.

### Schritt 2: Freigabe einholen

Vor Schreibaktionen explizit Freigabe einholen fuer:

- `restic` Installation, falls fehlt;
- Anlage root-only Verzeichnisse;
- Anlage root-only Env-/Password-Dateien;
- Anlage Skripte;
- Anlage systemd Services/Timer;
- `restic init`;
- erstes manuelles Backup;
- `restic check`;
- nicht-destruktiver Restore-Test.

### Schritt 3: Root-only Struktur pro Node

Pro Node vorbereiten:

```text
/etc/k3s-backup/
/etc/k3s-backup/restic-os.env
/etc/k3s-backup/restic-os-password
/usr/local/sbin/k3s-os-backup.sh
/usr/local/sbin/k3s-os-restic-init.sh
/usr/local/sbin/k3s-os-restic-check.sh
/var/lib/k3s-os-backup/
/var/lib/k3s-os-backup/metadata-current/
/var/lib/k3s-os-backup/restore-test/
```

Rechte:

```text
/etc/k3s-backup                         0700 root:root
/etc/k3s-backup/restic-os.env           0600 root:root
/etc/k3s-backup/restic-os-password      0600 root:root
/usr/local/sbin/k3s-os-*.sh             0700 root:root
/var/lib/k3s-os-backup                  0700 root:root
```

Wichtig: Env-Dateien duerfen ohne `export` geschrieben werden, aber Skripte
muessen sie dann so laden:

```bash
set -a
source /etc/k3s-backup/restic-os.env
set +a
```

### Schritt 4: Secret-Eingabe

Wenn Secrets nicht bereits sicher auf dem Node vorhanden sind:

- interaktives Eingabeskript nutzen;
- Werte nicht echoen;
- Werte nicht in Chat oder Logs schreiben;
- danach nur Dateirechte und Dateigroesse pruefen, nicht Inhalte.

### Schritt 5: Repo initialisieren

Pro Node genau einmal:

```text
restic init
```

Melden:

- Repo Server 2 initialisiert ja/nein;
- Repo Server 3 initialisiert ja/nein;
- Fehler nur als Fehlertext ohne Secrets melden.

### Schritt 6: Backup-Scope

Sichern:

```text
/etc
/root
/home
/var/spool/cron
/var/lib/k3s-os-backup/metadata-current
```

Metadata vor jedem Backup erzeugen:

```text
installed-packages.txt
manually-installed.txt
systemd-units.txt
network.txt
disks.txt
hostname.txt
date.txt
```

Bewusst ausschliessen:

```text
/var/lib/rancher/k3s
/etc/rancher/k3s
Longhorn-Volume-Daten
```

### Schritt 7: Erstes Backup und Check

Pro Node:

- erstes manuelles Backup ausfuehren;
- `restic snapshots` pruefen;
- `restic check` ausfuehren;
- keine Secrets ausgeben.

### Schritt 8: Nicht-destruktiver Restore-Test

Pro Node:

```text
Restore latest nach /var/lib/k3s-os-backup/restore-test
Include: /etc/hostname
```

Akzeptanz:

- Restore-Test-Verzeichnis existiert;
- wiederhergestellte `etc/hostname` existiert;
- Inhalt passt zum Node;
- kein produktiver Pfad wurde ueberschrieben.

### Schritt 9: systemd Timer

Erst nach erfolgreichem manuellem Backup aktivieren:

- taeglicher Backup-Timer pro Node;
- optional separater woechentlicher Check-/Prune-Timer;
- `systemctl list-timers` pruefen;
- keine Cron-Eintraege verwenden, wenn systemd Timer eingerichtet sind.

### Schritt 10: Abschlusspruefung

Melden:

- Server 2:
  - Restic installiert ja/nein;
  - Repo-Pfad;
  - Snapshot vorhanden ja/nein;
  - `restic check` Ergebnis;
  - Restore-Test Ergebnis;
  - Timer aktiv ja/nein.
- Server 3:
  - Restic installiert ja/nein;
  - Repo-Pfad;
  - Snapshot vorhanden ja/nein;
  - `restic check` Ergebnis;
  - Restore-Test Ergebnis;
  - Timer aktiv ja/nein.
- Keine Secrets ausgegeben ja/nein.
- Keine K3s/Longhorn/Docker/PVC/Firewall-Aenderungen ja/nein.

## Dokumentation nach Erfolg

Nach erfolgreicher Umsetzung aktualisieren:

```text
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
```

Ausserdem das komplette Verify-Skript erweitern, damit Server2/3-OS-Restic
zukuenftig automatisch geprueft wird.

## Wenn ein Fehler auftritt

Nicht loeschen, nicht reparieren, nicht wiederholen, bevor Ursache klar ist.

Sammeln und melden:

- betroffener Node;
- letzter nicht-geheimer Status;
- Exitcode;
- nicht-geheime Fehlermeldung;
- welche Datei/Unit/Repo betroffen ist;
- ob produktive Ressourcen unveraendert blieben.

---

Ende des Prompts.

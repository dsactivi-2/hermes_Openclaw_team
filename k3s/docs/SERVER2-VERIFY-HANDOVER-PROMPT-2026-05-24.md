# Server 2 Verification Handover Prompt - 2026-05-24

Du bist der neue Agent fuer das activi K3s-Projekt.

## Ziel dieses Blocks

Schliesse die offene Server-2-Verifikationsluecke. Server 2 ist laut User jetzt
ueber den SSH-Alias `kube3-2` erreichbar. Verifiziere damit Server 2, OS-Restic
und danach die bestehenden Stack-Pruefscripte. Installiere nichts Neues.

## Arbeitsverzeichnis

```text
/Users/activi/Documents/activi K3s
```

## Verbindlicher Zugangsstand

- Server 1: `ssh k3-1`
- Server 2: `ssh kube3-2`
- Server 3: bekannter lokaler Key `/Users/activi/.ssh/k3-3`
- Verbindungsuebersicht:
  `/Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md`

## Sicherheitsregeln

- Keine Secrets, Tokens, Passwoerter, Kubeconfigs oder private SSH-Key-Inhalte
  ausgeben.
- Keine Kubernetes-Ressourcen aendern.
- Keine Firewall-, DNS-, Cloudflare- oder Hetzner-Robot-Aenderung.
- Keine Longhorn-, Portainer-, Velero-, CloudNativePG- oder App-Installation.
- Keine PVCs aendern.
- Keine Ressourcen loeschen.
- Wenn ein Schritt eine Aenderung erfordern wuerde: stoppen und fragen.

## Pflichtdateien zuerst lesen

1. `/Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md`
2. `/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md`
3. `/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md`
4. `/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md`
5. `/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md`
6. `/Users/activi/Documents/activi K3s/audit-production-readiness-gaps.sh`
7. `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh`
8. `/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh`
9. `/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh`

## Exakte Arbeitsschritte

### 1. Server 2 SSH pruefen

```bash
ssh -o BatchMode=yes -o ConnectTimeout=8 kube3-2 'hostname && date -Is'
```

Erwartung:

- Hostname ist `activi-k3-2`.
- Kein Passwortprompt.
- Kein `Permission denied`.

Wenn das fehlschlaegt: stoppen und melden. Nicht raten, keinen Key kopieren,
keine SSH-Config aendern.

### 2. Server 2 OS-Restic Metadaten pruefen

```bash
ssh kube3-2 'hostname; date -Is; restic version; systemctl is-enabled k3s-os-restic-backup.timer; systemctl is-active k3s-os-restic-backup.timer; systemctl list-timers k3s-os-restic-backup.timer --no-pager; stat -c "%a %U:%G %s %n" /etc/k3s-backup /etc/k3s-backup/restic-os.env /etc/k3s-backup/restic-os-password /var/lib/k3s-os-backup /var/lib/k3s-os-backup/metadata-current /var/lib/k3s-os-backup/restore-test'
```

Erwartung:

- Timer `enabled` und `active`.
- `/etc/k3s-backup` und `/var/lib/k3s-os-backup` mit `700 root:root`.
- `restic-os.env` und `restic-os-password` mit `600 root:root`.
- Keine Secret-Dateien inhaltlich ausgeben.

### 3. Server 2 Restic Repo pruefen

```bash
ssh kube3-2 'set -a; . /etc/k3s-backup/restic-os.env; set +a; restic snapshots --compact; restic check'
```

Erwartung:

- Snapshots vorhanden.
- Host `activi-k3-2`.
- Tag `os-server2`.
- `restic check` ohne Fehler.

### 4. Lokale Stack-Pruefungen ausfuehren

```bash
cd "/Users/activi/Documents/activi K3s"
./verify-portainer-api-connectivity.sh
./audit-recent-stack-claims.sh
./verify-k3s-stack-complete.sh
./audit-production-readiness-gaps.sh
```

Erwartung:

- `verify-portainer-api-connectivity.sh`: `RESULT: PASS`
- `audit-recent-stack-claims.sh`: `RESULT: PASS`
- `verify-k3s-stack-complete.sh`: `RESULT: PASS`
- `audit-production-readiness-gaps.sh`: `RESULT: PASS_WITH_GAPS`
- Keine Server-2-SSH-Warning mehr.
- `Failures: 0`.

### 5. Dokumentation aktualisieren

Nur nach erfolgreicher Live-Verifikation aktualisieren:

- `/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md`
- `/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md`
- `/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md`
- `/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md`

Dokumentiere die neuen Logpfade und ob die Server-2-Warning verschwunden ist.

## Stop-Punkte

Sofort stoppen, wenn:

- `ssh kube3-2` fehlschlaegt.
- ein Passwortprompt erscheint.
- Server 2 nicht `activi-k3-2` meldet.
- `restic check` fehlschlaegt.
- ein Pruefscript `FAIL` meldet.
- Portainer API Connectivity wieder Timeouts zeigt.
- ein Schritt Secret-Inhalte ausgeben wuerde.
- eine technische Aenderung noetig waere.

## Abschlussmeldung

Melde exakt:

```text
Pflichtdateien gelesen: ja/nein
Server 2 SSH via kube3-2 erfolgreich: ja/nein
Server 2 Hostname korrekt: ja/nein
Server 2 OS-Restic Timer enabled/active: ja/nein
Server 2 Snapshots vorhanden: ja/nein
Server 2 restic check: PASS/FAIL/nicht ausgefuehrt
Portainer API Connectivity: PASS/FAIL/nicht ausgefuehrt
audit-recent-stack-claims.sh: PASS/FAIL/nicht ausgefuehrt
verify-k3s-stack-complete.sh: PASS/FAIL/nicht ausgefuehrt
audit-production-readiness-gaps.sh: PASS_WITH_GAPS/PASS/FAIL/nicht ausgefuehrt
Warnings: Anzahl
Gaps: Anzahl
Failures: Anzahl
Dokumente aktualisiert: ja/nein
Secrets ausgegeben: nein
Cluster geaendert: nein
Naechster empfohlener Block:
```

Nicht automatisch mit Longhorn Volume-RecurringJobs, Velero, CloudNativePG oder
App-Deployments weitermachen.

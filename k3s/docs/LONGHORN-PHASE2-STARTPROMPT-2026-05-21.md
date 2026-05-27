# Longhorn Phase 2 Startprompt fuer neue Session - 2026-05-21

Hinweis 2026-05-21 09:47 CEST: Dieser Startprompt beschreibt den Startzustand
vor Host-Preflight, Secret-Anlage und Longhorn-Installation. Er ist fuer neue
Sessions nur noch als Historie nutzbar. Fuer den aktuellen Stand zuerst
`/Users/activi/Documents/activi K3s/docs/LONGHORN-PHASE2-PLAN-2026-05-21.md`
und `/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md`
lesen. Aktuell ist Longhorn installiert, nicht Default, Backup Target gesetzt,
Test-PVC/Test-App, Backup/Restore, SystemBackup und SystemBackup-RecurringJob
sind validiert. Fuer OS-Level Restic Server 2/3 jetzt auch
`/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md`
lesen.

Kopiere den folgenden Prompt vollstaendig in die neue Agenten-Session.

---

Du arbeitest am Projekt:

```text
/Users/activi/Documents/activi K3s
```

Ziel dieser Session:

Longhorn Phase 2 sicher vorbereiten und nur nach expliziter Freigabe Schritt fuer Schritt umsetzen. Backup Phase 1 ist bereits aktiv, automatisiert und validiert. Longhorn ist der naechste Block. Velero kommt erst spaeter und darf in dieser Session nicht installiert werden.

## Zwingend zuerst lesen

Lies diese Dateien vollstaendig und nutze sie als verbindliche Grundlage:

```text
/Users/activi/Documents/activi K3s/docs/LONGHORN-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/BACKUP-PHASE1-STATUS-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

Wichtig:

- Der Startcheck ist bereits erledigt und lokal geloggt.
- Behandle den Startcheck nicht als offenen Blocker.
- Backup Phase 1 ist aktiv und validiert.
- Historischer Prompt-Stand: Longhorn war noch nicht installiert. Aktueller Stand:
  Longhorn ist installiert und validiert.
- Velero ist noch nicht installiert und bleibt nachgelagert.

## Bekannter Cluster-Stand

- 3-Node K3s HA mit embedded etcd.
- K3s Version: `v1.32.1+k3s1`.
- Alle drei Nodes waren beim Startcheck `Ready`.
- etcd war healthy, alle Member `started`, alle `learner=false`.
- StorageClass aktuell nur `local-path (default)`.
- Portainer laeuft bereits in K3s mit Bound PVC auf `local-path`.
- Healthchecks, Hindsight und Hindsight Postgres laufen noch als Docker-Apps auf Server 1.

Nodes:

```text
activi-k3-1.0 / k3-1 / 10.0.1.10
activi-k3-2   / k3-2 / 10.0.1.20
activi-k3-3   / k3-3 / 10.0.1.30
```

## Backup-Stand, den du respektieren musst

Backup Phase 1 ist erledigt:

- K3s etcd-Snapshots nach Hetzner Object Storage S3 funktionieren.
- Restic nach S3 funktioniert.
- Hindsight Postgres Dumps funktionieren.
- Systemd Timer sind aktiv.
- Nicht-destruktiver Restore-Test war erfolgreich.
- Preflight war `RESULT: PASS`, `Warnings: 0`, `Failures: 0`.

Bekannte Belege:

```text
K3s S3 Snapshot Prefix: s3://activi/k3s/etcd/
Restic Repository: s3:https://fsn1.your-objectstorage.com/activi/restic/server1
Restic Snapshots: d4faae42, c2b385b0, c9af17e7
Preflight Log: /tmp/k3s-backup-phase1-check-20260521-010319.log
```

Hetzner Object Storage:

```text
Bucket: activi
Region: fsn1
Endpoint: https://fsn1.your-objectstorage.com
Object Lock: aktiviert laut Hetzner Console/Erstellungsdialog
Sichtbarkeit: privat laut Hetzner Console/Erstellungsdialog
```

Hinweis: Object Lock/Sichtbarkeit sind aus der Hetzner Console dokumentiert, aber nicht separat per S3-API/AWS-CLI ausgelesen.

## Absolute Sicherheitsregeln

Ohne ausdrueckliche Freigabe nicht tun:

- K3s neu installieren.
- K3s Service Flags aendern.
- Nodes entfernen.
- etcd Member aendern.
- Docker-Apps stoppen.
- PVCs, PVs oder Volumes loeschen.
- Portainer migrieren.
- Healthchecks/Hindsight migrieren.
- Firewall-Regeln aendern.
- Velero installieren.
- Secrets, Tokens, Passwoerter, Kubeconfigs, API Keys oder `.env` Inhalte ausgeben.

Wenn ein Befehl Secrets anzeigen koennte: nicht ausfuehren oder Ausgabe redigieren.

## Aufgabe dieser Session

Arbeite Longhorn Phase 2 aus dem Plan ab, aber mit Stop-Punkten:

### Schritt 1: Dokumente lesen und Stand zusammenfassen

Nach dem Lesen kurz bestaetigen:

- Backup Phase 1 ist aktiv und validiert.
- Historischer Prompt-Stand: Longhorn war noch nicht installiert. Aktueller Stand:
  Longhorn ist installiert und validiert.
- Velero ist noch nicht installiert.
- `local-path` ist aktuell Default StorageClass.
- Der naechste Schritt ist Longhorn-Preflight, nicht Installation auf Verdacht.

### Schritt 2: Nur Read-only-Preflight ausfuehren

Fuehre zunaechst nur nicht-destruktive Checks aus:

- Auf allen Nodes pruefen:
  - Hostname
  - Kernel
  - `iscsiadm`
  - `iscsid`
  - Pakete `open-iscsi`, `nfs-common`, `cryptsetup`, `dmsetup`
  - Mounts und freier Speicher auf `/var/lib`, `/var/lib/rancher`, `/var/lib/rancher/k3s`
  - Blockdevices mit `lsblk`
  - NFS Kernel-Konfiguration, falls lesbar
- Im Cluster pruefen:
  - Nodes
  - Pods
  - StorageClasses
  - PVs/PVCs
  - Namespace `longhorn-system` soll fehlen
  - Namespace `velero` soll fehlen

Keine Installation in Schritt 2.

### Schritt 3: Ergebnis bewerten und Freigaben einholen

Wenn Pakete fehlen, frage nach Freigabe fuer Installation auf allen drei Nodes:

```text
open-iscsi
nfs-common
cryptsetup
dmsetup
```

Danach `iscsid` aktivieren/starten und Read-only-Preflight wiederholen.

### Schritt 4: Longhorn-Version verifizieren

Nicht ueber `master`-Manifest installieren.

Nutze Helm mit gepinnter Version. Vor Installation verifizieren:

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm search repo longhorn/longhorn --versions | head -10
helm show values longhorn/longhorn --version 1.11.2 >/root/longhorn-values-default-1.11.2.yaml
```

Geplante Version: `1.11.2`, aber vor Ausfuehrung anhand Helm-Repo bestaetigen.

### Schritt 5: S3 Secret fuer Longhorn vorbereiten

Longhorn soll denselben Bucket, aber eigenen Prefix nutzen:

```text
s3://activi@fsn1/longhorn/
```

Secret-Name:

```text
longhorn-s3-backup
```

Namespace:

```text
longhorn-system
```

Wichtig:

- Der Longhorn Backup Target URL muss mit `/` enden.
- Fuer Hetzner S3-kompatibel muss `AWS_ENDPOINTS=https://fsn1.your-objectstorage.com` gesetzt werden.
- Secrets nie im Chat ausgeben.
- Falls Credentials vorher rotiert werden sollen, vor Secret-Anlage stoppen und Rueckfrage stellen.

### Schritt 6: Longhorn installieren, nur nach Freigabe

Empfohlener Installationsentwurf aus dem Plan:

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update

helm upgrade --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --version 1.11.2 \
  --set persistence.defaultClass=false \
  --set persistence.defaultClassReplicaCount=3 \
  --set defaultBackupStore.backupTarget="s3://activi@fsn1/longhorn/" \
  --set defaultBackupStore.backupTargetCredentialSecret="longhorn-s3-backup" \
  --set defaultBackupStore.pollInterval=300 \
  --wait \
  --timeout 15m
```

Vorher mit `helm show values` pruefen, ob diese Values fuer die gepinnte Version gueltig sind.

Longhorn zuerst nicht als Default StorageClass setzen. `local-path` bleibt zuerst Default.

### Schritt 7: Installation validieren

Pruefen:

```bash
kubectl -n longhorn-system get pods -o wide
kubectl -n longhorn-system get svc
kubectl get storageclass
kubectl -n longhorn-system get events --sort-by=.lastTimestamp
```

Erwartung:

- Longhorn Pods laufen stabil.
- Keine CrashLoops.
- StorageClass `longhorn` existiert.
- `local-path` bleibt Default.
- Backup Target zeigt keine Fehler.

### Schritt 8: Test-PVC/Test-App

Nur Testressourcen erstellen:

- Namespace `longhorn-test`
- PVC `longhorn-test-pvc`, `storageClassName: longhorn`, `1Gi`
- Busybox-Testpod schreibt `/data/probe.txt`

Danach pruefen:

- PVC Bound
- Pod Running oder Completed je nach Testdefinition
- Datei lesbar
- Volume in Longhorn sichtbar

### Schritt 9: Longhorn Backup/Restore-Test

Ziel: beweisen, dass Longhorn nach S3 sichern und aus S3 wiederherstellen kann.

Bevorzugt per lokalem Port-Forward:

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

Dann lokal:

```text
http://127.0.0.1:8080
```

Durchfuehren:

- Snapshot fuer Testvolume erstellen.
- Backup nach S3 erstellen.
- Backup im Longhorn UI bzw. Target sichtbar bestaetigen.
- Restore in neues Testvolume testen.
- `probe.txt` aus wiederhergestelltem Volume lesen.

Keine produktiven PVCs anfassen.

### Schritt 10: Dokumentation aktualisieren

Nach jedem erfolgreichen Block die lokalen Projektunterlagen aktualisieren:

```text
/Users/activi/Documents/activi K3s/docs/LONGHORN-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
```

Dokumentieren:

- Longhorn Version
- Installationszeitpunkt
- Preflight-Ergebnis
- Paketstatus auf allen Nodes
- StorageClass-Default-Status
- Backup Target URL ohne Secrets
- Test-PVC Ergebnis
- Backup/Restore-Test Ergebnis
- offene Risiken

## Stop-Kriterien

Sofort stoppen und Rueckfrage stellen, wenn:

- Backup Phase 1 nicht mehr `PASS` ist.
- ein Node nicht `Ready` ist.
- `iscsid` nicht startet.
- Longhorn Pods nicht stabil werden.
- Backup Target Fehler zeigt.
- Test-PVC nicht `Bound` wird.
- Restore-Test fehlschlaegt.
- ein Schritt Secrets ausgeben koennte.
- ein Schritt produktive Daten veraendern wuerde.

## Rueckmeldung an Hauptsession

Nach jedem Block bitte kompakt berichten:

- Was wurde geprueft?
- Was wurde geaendert?
- Was ist das Ergebnis?
- Welche Logs/Belege gibt es?
- Welche Entscheidung/Freigabe ist als naechstes noetig?

Keine Secrets ausgeben.

---

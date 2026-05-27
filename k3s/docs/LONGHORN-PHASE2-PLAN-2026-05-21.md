# Longhorn Phase 2 Plan - 2026-05-21

Stand: 2026-05-21.

Hinweis 2026-05-24: Dieses Dokument ist ein historischer Longhorn-Phase-2-Plan
mit nachtraeglichen Statusnotizen. Fuer den aktuellen Gesamt-Sollzustand sind
`PROJECT-STATUS-2026-05-20.md`, `BACKUP-RUNBOOK-2026-05-20.md`,
`NEXT-SESSION-GUIDE-2026-05-20.md` und
`FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md` massgeblich. Aktuell ist
`longhorn` die einzige Default StorageClass, Portainer nutzt
`portainer/portainer-longhorn`, produktive Longhorn Volume-RecurringJobs fuer
Portainer sind aktiv und Velero ist installiert sowie per Smoke-Restore
validiert.

Update 2026-05-21 02:38 CEST: Longhorn wurde per Helm mit gepinnter Version
`1.11.2` installiert. Damals blieb `local-path` noch Default StorageClass.
Longhorn Backup Target ist auf `s3://activi@fsn1/longhorn/` gesetzt und laut
Longhorn `AVAILABLE=true`. Velero war zu diesem Zeitpunkt noch nicht
installiert.

Update 2026-05-21 03:01 CEST: Der unabhaengige lokale Check
`/Users/activi/Documents/activi K3s/check-longhorn-phase2.sh` wurde ausgefuehrt.
Ergebnis: `RESULT: PASS`, `Failures: 0`, `Warnings: 1`. Die einzige Warnung ist,
dass `longhorn-test` noch nicht existiert. Das ist vor Test-PVC/Test-App erwartbar.

Update 2026-05-21 03:06 CEST: Longhorn Test-PVC/Test-App wurde erstellt und
validiert. Namespace `longhorn-test`, PVC `longhorn-test-pvc`, StorageClass
`longhorn`, Groesse `1Gi`. Test-Pod `longhorn-test-writer` schreibt und liest
`/data/probe.txt`. Longhorn Volume ist `attached` und `healthy`; drei Replicas
laufen auf den drei Nodes.

Update 2026-05-21 03:36 CEST: Longhorn Backup/Restore-Test fuer das Testvolume
ist erfolgreich. Backup-CR `lh-test-backup-20260521-0309` wurde `Completed`
mit `progress: 100`. Restore-Volume `lh-test-restore-20260521-0324` wurde aus
dem Backup erstellt, Restore-PVC `longhorn-test-restore-pvc` ist `Bound`, und
Reader-Pod `longhorn-test-restore-reader` las den erwarteten Inhalt:
`longhorn-test-2026-05-21T01:06:38+0000`.

Update 2026-05-21 03:57 CEST: Die Testressourcen bleiben bewusst als Beleg
stehen. Das umfasst Namespace `longhorn-test`, Pods
`longhorn-test-writer` und `longhorn-test-restore-reader`, die gebundenen PVCs
`longhorn-test-pvc` und `longhorn-test-restore-pvc`, die Longhorn Volumes,
Snapshot `lh-test-snap-20260521-0309` und Backup-CR
`lh-test-backup-20260521-0309`. Cleanup nur nach separater Loeschfreigabe.

Update 2026-05-21 05:10 CEST: Frischer Read-only-Check direkt gegen den Stack:
`/Users/activi/Documents/activi K3s/check-longhorn-phase2.sh` meldet
`RESULT: PASS`, `Failures: 0`, `Warnings: 0`. Die Test-Pods sind inzwischen
planmaessig `Completed`; dadurch sind die beiden Testvolumes aktuell
`detached` mit Robustness `unknown` und die Replicas `stopped`. Das ist kein
Fehlerzustand, solange die PVCs `Bound` bleiben und Backup/Restore-Belege
vorhanden sind.

Update 2026-05-21 08:06 CEST: Longhorn `SystemBackup` ist nach Erhoehung von
`backup-execution-timeout` von `1` auf `5` erfolgreich validiert. Der neue
SystemBackup `lh-system-backup-20260521-timeout5` steht auf `Ready`, Version
`v1.11.2`. Der alte fehlerhafte CR `lh-system-backup-20260521-initial` bleibt
als Beleg unveraendert auf `Error`.

Update 2026-05-21 09:21 CEST: Der SystemBackup-RecurringJob
`lh-system-backup-daily` ist angelegt und auf `volume-backup-policy=disabled`
korrigiert. Der manuelle Pre-Apps SystemBackup
`lh-system-backup-pre-apps-20260521-disabled` ist `Ready`.

Dieser Plan beschreibt den naechsten Schritt nach Backup Phase 1. Er darf nicht als Freigabe fuer sofortige Installation verstanden werden.

## Ausgangslage

Backup Phase 1 ist aktiv, automatisiert und validiert:

- K3s etcd-S3-Snapshots funktionieren.
- Restic-S3 funktioniert.
- Hindsight Postgres Dumps funktionieren.
- Nicht-destruktiver Restore-Test war erfolgreich.
- Backup-Phase-1-Preflight: `RESULT: PASS`, `Warnings: 0`, `Failures: 0`.

Clusterstand zum Start der damaligen Longhorn-Phase:

- 3-Node K3s HA mit embedded etcd.
- K3s `v1.32.1+k3s1`.
- StorageClasses nach Installation: `local-path (default)`, `longhorn`, `longhorn-static`.
- Damaliger Stand: Portainer nutzte noch ein `local-path` PVC.
- Aktueller Stand seit 2026-05-24: `longhorn` ist die einzige Default
  StorageClass. Portainer nutzt `portainer/portainer-longhorn`; der alte
  `local-path` PVC bleibt nur Rollback-Altbestand.
- Damaliger Stand: Velero war noch nicht installiert.

## Ziel

Longhorn sicher als neue Storage-Schicht einfuehren, S3 Backup Target konfigurieren und vor jeder produktiven Migration mit einer Test-PVC/Test-App pruefen.

## Wichtige Regeln

Nicht tun ohne ausdrueckliche Freigabe:

- K3s neu installieren.
- K3s Service Flags aendern.
- Nodes entfernen.
- etcd Member aendern.
- Docker-Apps stoppen.
- PVCs/PVs/Volumes loeschen.
- Portainer migrieren.
- Healthchecks/Hindsight migrieren.
- Firewall-Regeln aendern.
- Velero installieren.
- Secrets oder `.env` Inhalte ausgeben.

Longhorn wird nicht ueber `master`-Manifest installiert. Installation nur per Helm mit gepinnter Version.

## Empfohlene Longhorn-Version

Empfehlung: aktuelle stabile Longhorn-Version aus offizieller Doku/Helm-Repo pinnen. Zum Zeitpunkt dieser Planung zeigt die offizielle `latest` Doku auf Longhorn `1.11.2`.

Vor Installation trotzdem verifizieren:

```bash
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm search repo longhorn/longhorn --versions | head -10
helm show values longhorn/longhorn --version 1.11.2 >/root/longhorn-values-default-1.11.2.yaml
```

## Phase 2.0: Vorbedingungen pruefen

Diese Checks sind read-only, ausser wenn fehlende Pakete spaeter explizit installiert werden.

Auf allen drei Nodes pruefen:

```bash
for host in k3-1 k3-2 k3-3; do
  echo "===== $host ====="
  ssh "$host" '
    set -u
    hostname -f
    uname -r
    command -v iscsiadm || true
    systemctl is-active iscsid || true
    dpkg -l open-iscsi nfs-common cryptsetup dmsetup 2>/dev/null | awk "/^ii/ {print \$2, \$3}" || true
    findmnt -T /var/lib/rancher/k3s || true
    df -h /var/lib /var/lib/rancher /var/lib/rancher/k3s 2>/dev/null || true
    lsblk -f
    if [ -r /boot/config-$(uname -r) ]; then
      grep -E "CONFIG_NFS_V4|CONFIG_NFS_V4_1|CONFIG_NFS_V4_2" /boot/config-$(uname -r) || true
    fi
  '
done
```

Cluster read-only pruefen:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get storageclass
kubectl get pv,pvc -A
kubectl get ns longhorn-system 2>/dev/null || true
kubectl get ns velero 2>/dev/null || true
```

Erwartung:

- Alle drei Nodes `Ready`.
- `open-iscsi` vorhanden und `iscsid` aktiv.
- `nfs-common` vorhanden oder installierbar.
- `cryptsetup` und `dmsetup` vorhanden oder installierbar.
- Genug freier Speicher auf `/var/lib` fuer Longhorn-Testvolumes.
- Vor Phase 2.2 existierte `longhorn-system` noch nicht; seit Secret/Installation existiert der Namespace erwartungsgemaess.
- `velero` existiert noch nicht.

## Phase 2.1: Fehlende Host-Pakete installieren

Nur nach Freigabe, auf allen Nodes:

```bash
apt-get update
apt-get install -y open-iscsi nfs-common cryptsetup dmsetup
systemctl enable --now iscsid
```

Danach Phase 2.0 wiederholen.

## Phase 2.2: S3 Backup Target vorbereiten

Longhorn soll denselben Hetzner Object Storage Bucket nutzen, aber eigenen Prefix:

```text
s3://activi@fsn1/longhorn/
```

Wichtig aus der Longhorn-Doku:

- Der Backup Target URL muss mit `/` enden.
- Credential Secret muss im Namespace `longhorn-system` liegen.
- Fuer S3-kompatible Stores muss der Endpoint als `AWS_ENDPOINTS` im Secret gesetzt werden.

Empfohlener Secret-Name:

```text
longhorn-s3-backup
```

Das Secret darf nicht im Chat erscheinen. Anlage nur aus root-only Dateien oder interaktiver Eingabe.

Beispielstruktur, nicht mit sichtbaren Secrets ausfuehren:

```bash
kubectl create namespace longhorn-system
kubectl -n longhorn-system create secret generic longhorn-s3-backup \
  --from-literal=AWS_ACCESS_KEY_ID="<FROM_SECURE_INPUT>" \
  --from-literal=AWS_SECRET_ACCESS_KEY="<FROM_SECURE_INPUT>" \
  --from-literal=AWS_ENDPOINTS="https://fsn1.your-objectstorage.com" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Wenn die bereits genutzten S3-Credentials rotiert werden sollen, Rotation vor diesem Schritt durchfuehren.

## Phase 2.3: Longhorn per Helm installieren

Nur nach Freigabe.

Empfohlene Strategie:

- Helm Chart gepinnt installieren.
- Longhorn nicht sofort als Default StorageClass setzen.
- Erst Test-PVC/Test-App validieren.
- Danach separat entscheiden, ob Longhorn Default werden soll.

Empfohlener Installationsentwurf:

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

Vor Ausfuehrung mit `helm show values` pruefen, dass die Values-Namen fuer die gepinnte Version gueltig sind.

## Phase 2.4: Installation validieren

Update 2026-05-21 02:38 CEST:

- Helm Release: `longhorn`, Chart `longhorn-1.11.2`, App `v1.11.2`, Status `deployed`.
- Installationsmethode: Helm, gepinnte Version `1.11.2`.
- Host-Voraussetzungen: `nfs-common` installiert, `iscsid` enabled/active auf allen drei Nodes.
- StorageClass: `longhorn` und `longhorn-static` existieren; damals blieb
  `local-path` noch Default.
- Backup Target: `s3://activi@fsn1/longhorn/`, Credential Secret `longhorn-s3-backup`, `AVAILABLE=true`.
- Longhorn Pods: nach Initialisierung alle `Running`/Ready.
- Unabhaengiger Phase-2-Check am 2026-05-21 03:01 CEST: `RESULT: PASS`,
  `Failures: 0`, `Warnings: 1`; einzige Warnung: `longhorn-test` noch nicht
  angelegt.
- Frischer unabhaengiger Phase-2-Check am 2026-05-21 05:10 CEST:
  `RESULT: PASS`, `Failures: 0`, `Warnings: 0`.
- Initiale, transiente Warnungen: fruehe Manager-Readiness-Warnungen und ein CSI-Provisioner-Restart wegen Kubernetes-API-Timeout; danach kein aktueller CrashLoop/BackOff.
- Damaliger Stand: keine produktiven PVCs migriert, keine Docker-Apps gestoppt,
  Velero noch nicht installiert.

```bash
kubectl -n longhorn-system get pods -o wide
kubectl -n longhorn-system get svc
kubectl get storageclass
kubectl -n longhorn-system get backupsettings.longhorn.io 2>/dev/null || true
kubectl -n longhorn-system get backuptargets.longhorn.io 2>/dev/null || true
```

Erwartung:

- Longhorn Pods laufen.
- Keine CrashLoops.
- StorageClass `longhorn` existiert.
- Damalige Erwartung: `local-path` blieb zunaechst Default, bis bewusst
  umgestellt wird. Aktuell ist `longhorn` die einzige Default StorageClass.
- Backup Target zeigt keine Fehler.

Bei Fehlern:

```bash
kubectl -n longhorn-system get events --sort-by=.lastTimestamp | tail -80
kubectl -n longhorn-system logs deploy/longhorn-manager --tail=200
```

Keine Secrets ausgeben.

## Phase 2.5: Test-PVC und Test-App

Update 2026-05-21 03:06 CEST:

- Namespace: `longhorn-test` existiert.
- PVC: `longhorn-test-pvc`, `Bound`, `1Gi`, StorageClass `longhorn`.
- PV/Longhorn Volume: `pvc-997ae793-92a8-470a-a14d-f5a8a5e42179`.
- Test-Pod: `longhorn-test-writer` lief fuer den Test auf Node `activi-k3-3`
  und ist im Live-Stand 2026-05-21 05:10 CEST `Completed`.
- Probe: `/data/probe.txt` wurde geschrieben und per Pod-Log gelesen.
- Longhorn Volume: State `attached`, Robustness `healthy`.
- Replicas: 3, alle `running`, verteilt auf `activi-k3-1.0`, `activi-k3-2`, `activi-k3-3`.
- Keine produktiven PVCs migriert, Portainer unveraendert auf `local-path`.

Nur Testressourcen, keine Produktivmigration.

Namespace:

```bash
kubectl create namespace longhorn-test
```

PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-test-pvc
  namespace: longhorn-test
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
```

Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: longhorn-test-writer
  namespace: longhorn-test
spec:
  restartPolicy: Never
  containers:
    - name: writer
      image: busybox:1.36
      command: ["/bin/sh", "-c"]
      args:
        - |
          set -eu
          echo "longhorn-test-$(date -Iseconds)" > /data/probe.txt
          cat /data/probe.txt
          sleep 3600
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: longhorn-test-pvc
```

Pruefen:

```bash
kubectl -n longhorn-test get pod,pvc -o wide
kubectl -n longhorn-test logs longhorn-test-writer
kubectl -n longhorn-system get volumes.longhorn.io
```

## Phase 2.6: Longhorn Backup/Restore-Test

Ziel: Erst beweisen, dass Longhorn nach S3 sichern und aus S3 wiederherstellen kann.

Update 2026-05-21 03:36 CEST:

- Snapshot: `lh-test-snap-20260521-0309`, `ReadyToUse=true`.
- Backup-CR: `lh-test-backup-20260521-0309`, Status `Completed`, `progress: 100`.
- BackupVolume: `pvc-997ae793-92a8-470a-a14d-f5a8a5e42179-7abc3dfe`.
- Restore-Volume: `lh-test-restore-20260521-0324`.
- Restore-PVC: `longhorn-test-restore-pvc`, `Bound`, StorageClass `longhorn`.
- Restore-Pod: `longhorn-test-restore-reader`, `Running`.
- Wiederhergestellter Inhalt: `longhorn-test-2026-05-21T01:06:38+0000`.
- Restore-Volume: State `attached`, Robustness `healthy`, `restoreRequired=false`.
- Restore-Replicas: 3, alle `running`, verteilt auf `activi-k3-1.0`, `activi-k3-2`, `activi-k3-3`.
- Damaliger Stand: keine produktiven PVCs migriert,
  Portainer/Healthchecks/Hindsight unveraendert, Velero noch nicht installiert.

Aktueller Testressourcen-Status, Stand 2026-05-21 03:57 CEST:

- Bewusst beibehalten als Beleg:
  - Namespace `longhorn-test`.
  - Pods `longhorn-test-writer` und `longhorn-test-restore-reader`; beide sind
    im Live-Stand 2026-05-21 05:10 CEST `Completed`.
  - PVCs `longhorn-test-pvc` und `longhorn-test-restore-pvc`; beide `Bound`.
  - Longhorn Volumes `pvc-997ae793-92a8-470a-a14d-f5a8a5e42179` und
    `lh-test-restore-20260521-0324`; waehrend der Tests `attached`/`healthy`,
    im Live-Stand 2026-05-21 05:10 CEST `detached` mit Robustness `unknown`.
  - Snapshot `lh-test-snap-20260521-0309`.
  - Backup-CR `lh-test-backup-20260521-0309` und zugehoeriges BackupVolume.
- Diese Testressourcen verbrauchen weiterhin Longhorn-Test-Speicher. Da die
  Test-Pods inzwischen `Completed` sind, sind die Testvolumes aktuell detached.
- Spaeterer Cleanup nur nach separater Loeschfreigabe.

Aktueller Live-Status, Stand 2026-05-21 05:10 CEST:

- Namespace `longhorn-test` existiert weiterhin.
- Pods `longhorn-test-writer` und `longhorn-test-restore-reader` sind
  `Completed`; sie laufen nicht dauerhaft weiter.
- PVCs `longhorn-test-pvc` und `longhorn-test-restore-pvc` sind weiterhin
  `Bound`.
- Longhorn Volumes `pvc-997ae793-92a8-470a-a14d-f5a8a5e42179` und
  `lh-test-restore-20260521-0324` sind aktuell `detached` mit Robustness
  `unknown`, weil keine laufenden Pods mehr daran haengen.
- Replicas der Testvolumes sind aktuell `stopped`; das ist bei detached
  Testvolumes erwartbar.
- Backup-CR `lh-test-backup-20260521-0309` bleibt `Completed` mit
  `progress: 100`.
- BackupVolume `pvc-997ae793-92a8-470a-a14d-f5a8a5e42179-7abc3dfe` bleibt
  sichtbar.

## Phase 2.6a: Longhorn SystemBackup

Update 2026-05-21 08:06 CEST:

- Ausgangsfehler: `lh-system-backup-20260521-initial` stand auf `Error` wegen
  Timeout bei `longhorn system-backup list s3://activi@fsn1/longhorn/`.
- Fix: Longhorn Setting `backup-execution-timeout` wurde von `1` auf `5`
  Minuten erhoeht.
- Neuer SystemBackup: `lh-system-backup-20260521-timeout5`.
- Status: `Ready`.
- Version: `v1.11.2`.
- `conditions: null`, also kein aktives Fehlerfeld.
- Backup Target bleibt `AVAILABLE=true`.
- Normales Volume-Backup `lh-test-backup-20260521-0309` bleibt `Completed`
  mit `progress: 100`.
- Zusaetzlich sichtbare SystemBackup-Volume-Backups:
  `system-backup-c3e90362ec1844a7` und `system-backup-fef0245a89e145f3`,
  beide `Completed`, `progress: 100`.
- Update 2026-05-24: `longhorn` ist inzwischen die einzige Default
  StorageClass. `local-path` bleibt vorhanden, ist aber nicht Default.
  Bestehende PVCs wurden dadurch nicht automatisch migriert; der alte
  Portainer-`local-path` PVC bleibt nur Rollback-Altbestand.
- Velero ist seit 2026-05-24 installiert und per nicht-destruktivem
  Namespace-Smoke-Restore validiert.

Damit ist Longhorn SystemBackup technisch validiert. Der alte Error-CR bleibt
als Diagnosebeleg bestehen und darf nur nach separater Loeschfreigabe entfernt
werden.

Nachtrag 2026-05-21 09:21 CEST:

- SystemBackup-RecurringJob: `lh-system-backup-daily`.
- Task: `system-backup`.
- Cron: `17 2 * * *`.
- Retain: `14`.
- Groups: `[]`.
- Policy: `volume-backup-policy=disabled`.
- Pre-Apps SystemBackup: `lh-system-backup-pre-apps-20260521-disabled`.
- Pre-Apps Status: `Ready`, Version `v1.11.2`.
- Der fehlgeschlagene Versuch `lh-system-backup-pre-apps-20260521-0913` bleibt
  als Beleg bestehen; Ursache war die verworfene `if-not-present`-Policy in
  Kombination mit Test-Volume-Backup-Metadaten.

Seit 2026-05-24 existieren produktive Longhorn Volume-RecurringJobs fuer das
Portainer-Longhorn-Volume in Gruppe `prod-critical`:
`prod-snapshot-hourly`, `prod-backup-daily` und `prod-backup-weekly`. Testvolumes
sind nicht aufgenommen und es gibt keine Jobs auf Gruppe `default`.

Option A: UI-Test ueber Port-Forward, ohne oeffentliche Exposure:

```bash
kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80
```

Dann lokal Longhorn UI nutzen:

```text
http://127.0.0.1:8080
```

In der UI:

1. Testvolume finden.
2. Snapshot erstellen.
3. Backup erstellen.
4. Backup im S3 Target sichtbar bestaetigen.
5. Restore in neues Testvolume durchfuehren.
6. Test-Pod gegen Restore-PVC starten und `/data/probe.txt` lesen.

Option B: per Longhorn CRDs/API, nur wenn der Agent die konkrete Longhorn-Version und CRDs geprueft hat.

## Phase 2.7: Default StorageClass Entscheidung

Erst nach erfolgreichem Test:

Damalige Option 1: Longhorn bleibt explizit, `local-path` bleibt Default.

- Sicherer fuer schrittweise Migration.
- Neue PVCs nutzen nur Longhorn, wenn `storageClassName: longhorn` gesetzt ist.

Damalige Option 2: Longhorn wird Default.

- Praktischer fuer neue Apps.
- Muss bewusst dokumentiert werden.

Aktuelle Entscheidung seit 2026-05-24: Option 2 ist umgesetzt. `longhorn` ist
die einzige Default StorageClass; `local-path` existiert weiter, ist aber nicht
Default.
- `local-path` Default Annotation entfernen und Longhorn Default Annotation setzen.

Empfehlung fuer diesen Cluster: zuerst Option 1, nach Test-App und erster produktiver App neu entscheiden.

## Phase 2.8: Dokumentation aktualisieren

Nach erfolgreichem Test aktualisieren:

```text
docs/PROJECT-STATUS-2026-05-20.md
docs/BACKUP-RUNBOOK-2026-05-20.md
docs/BACKUP-PHASE1-STATUS-2026-05-21.md oder neue LONGHORN-PHASE2-STATUS-2026-05-21.md
docs/NEXT-SESSION-GUIDE-2026-05-20.md
docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
```

Dokumentieren:

- Longhorn Version.
- Installationsmethode.
- StorageClass-Default-Status.
- Backup Target URL ohne Secrets.
- Secret-Name ohne Werte.
- Test-PVC/Test-App Ergebnis.
- Backup/Restore-Test Ergebnis.
- Offene Entscheidung: Portainer/Healthchecks/Hindsight Migration.

## Stop-Kriterien

Sofort stoppen und Nutzer fragen, wenn:

- Ein Node nicht `Ready` ist.
- Backup Phase 1 nicht mehr `PASS` ist.
- `iscsid` auf einem Node nicht gestartet werden kann.
- Longhorn Pods nicht stabil `Running` werden.
- Backup Target Fehler zeigt.
- Test-PVC nicht `Bound` wird.
- Restore-Test fehlschlaegt.
- Ein Befehl Secrets ausgeben wuerde.
- Eine Aktion produktive PVCs, Docker-Volumes oder Apps veraendern wuerde.

## Quellen

- Longhorn Installation Requirements: https://longhorn.io/docs/1.11.2/deploy/install/
- Longhorn Backup Target: https://longhorn.io/docs/1.11.2/snapshots-and-backups/backup-and-restore/set-backup-target/
- Longhorn Default Settings via Helm: https://longhorn.io/docs/1.11.2/advanced-resources/deploy/customizing-default-settings/

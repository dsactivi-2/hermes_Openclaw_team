# Portainer Complete Setup Handover Prompt - 2026-05-21

Status: historischer Prompt; Portainer-Ingress, NodePort-Hardening und
Longhorn-Migration sind inzwischen erledigt. Fuer neue Sessions den aktuellen
Projektstatus und das Next-Session-Guide verwenden.

Ziel dieses Blocks ist nicht App-Installation, sondern Portainer sauber fertig
einrichten und den naechsten Migrationspfad absichern.

## Einordnung

Portainer ist aktuell erreichbar und technisch stabil:

- Domain: `https://portainer.activi.io`
- Ingress/TLS: aktiv
- Certificate: `portainer/portainer-activi-io-tls`, `Ready=True`
- Service: `ClusterIP`, keine Kubernetes-NodePorts
- Aktiver PVC: `portainer-longhorn`, `10Gi`, StorageClass `longhorn`
- Alter PVC: `portainer`, StorageClass `local-path`, bleibt als Rollback-Beleg erhalten

Wichtig:

- Portainer Business Edition 3 Nodes Free ist eine bewusste Entscheidung, aber
  keine technische Pflicht fuer den Clusterbetrieb.
- Portainer komplett absichern ist Pflicht.
- Portainer von `local-path` auf Longhorn ist erledigt und validiert.

## Prompt fuer die naechste Agenten-Session

```text
Wir machen am bestehenden K3s/Hetzner-Robot-Projekt weiter.

Ziel dieses Blocks:
Portainer vollstaendig absichern und die naechste Pflicht-Migration auf Longhorn
vorbereiten. In diesem Block keine App-Installationen starten.

Arbeite strikt schrittweise und stoppe nach jedem Stop-Punkt.

============================================================
1. Pflichtdokumente zuerst lesen
============================================================

Vor jeder Aktion vollstaendig lesen:

/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PORTAINER-COMPLETE-SETUP-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh
/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh

Wenn eine Datei fehlt oder dem Live-Cluster widerspricht:
sofort stoppen und melden.

============================================================
2. Bekannter aktueller Stand
============================================================

Cluster:
- 3-Node K3s HA, K3s v1.32.1+k3s1
- Nodes: activi-k3-1.0, activi-k3-2, activi-k3-3
- local-path bleibt Default StorageClass
- Longhorn ist installiert und validiert, aber nicht Default
- Velero ist nicht installiert

Portainer:
- Namespace: portainer
- Helm Release: portainer
- Image: portainer/portainer-ce:2.39.2
- Domain: https://portainer.activi.io
- HTTP leitet auf HTTPS um
- Service ist ClusterIP
- Keine Kubernetes-NodePorts mehr
- PVC portainer ist aktuell local-path, 10Gi, auf Server 1

Ingress/TLS:
- ingress-nginx aktiv
- cert-manager v1.20.2 aktiv
- ClusterIssuer letsencrypt-prod Ready
- Certificate portainer/portainer-activi-io-tls Ready

Backups:
- Backup Phase 1 aktiv
- Server-1 Restic aktiv
- K3s etcd S3 Snapshots aktiv
- Longhorn SystemBackup aktiv
- OS-Restic Server 2/3 aktiv

============================================================
3. Read-only Preflight
============================================================

Fuehre zuerst aus:

cd "/Users/activi/Documents/activi K3s"
./audit-recent-stack-claims.sh
./verify-k3s-stack-complete.sh

Erwartung:
- beide RESULT: PASS
- Warnings: 0
- Failures: 0

Wenn nicht PASS:
stoppen, nichts aendern, Diagnose melden.

Danach read-only pruefen:

- Portainer Login-Seite ueber https://portainer.activi.io erreichbar
- Portainer Service ist ClusterIP
- keine NodePort Services existieren
- Portainer aktiver PVC ist `portainer-longhorn` und Bound auf `longhorn`
- alter Portainer-PVC `portainer` auf `local-path` existiert nur als Rollback-Beleg
- Portainer Pod ist Running
- kein zweiter Portainer-Admin-Reset-Pod vorhanden
- keine unerwarteten Portainer Access Tokens vorhanden, soweit ohne Secret-Ausgabe pruefbar
- keine Secret-Inhalte ausgeben

============================================================
4. Backup-Zwischenstopp vor jeder groesseren Aenderung
============================================================

Vor jeder Aenderung an Portainer, Storage, PVC, Helm, Ingress, Firewall oder
produktiven Apps muss ein Backup-Zwischenstopp erfolgen.

Fuer diesen Portainer-Block sind vor einer Stateful-Aenderung Pflicht:

1. Frischer K3s etcd Snapshot nach S3.
2. Frischer Server-1 Restic Backup-Lauf, solange noch Docker-App-Daten oder Rollback-Daten auf Server 1 liegen.
3. Frischer Longhorn SystemBackup, wenn Longhorn-/Ingress-/Kubernetes-Systemressourcen betroffen sind.
4. Danach kurzer Verify:
   - etcd Snapshot sichtbar
   - Restic Snapshot sichtbar
   - restic check ohne Fehler oder bestehender letzter check ist frisch genug und dokumentiert
   - Portainer weiterhin erreichbar

Keine Backup-Secret-Werte ausgeben.

Wenn ein Backup-Schritt fehlschlaegt:
sofort stoppen und keine Migration/Setup-Aenderung starten.

============================================================
5. Portainer richtig komplett einrichten
============================================================

Pruefe/erledige nur mit separater Freigabe:

1. Admin-Zugang:
   - Login funktioniert.
   - Starkes Admin-Passwort ist gesetzt.
   - 2FA/MFA pruefen und aktivieren, falls in der verwendeten Edition verfuegbar.
   - Keine Passwoerter im Chat ausgeben.

2. Access Tokens:
   - Vorhandene Tokens nur listen, keine Token-Werte ausgeben.
   - Unbenutzte Tokens nicht loeschen ohne Freigabe.
   - Neue Tokens nur erstellen, wenn konkret benoetigt.

3. Helm Repositories:
   - Aktuelle Repos nur anzeigen.
   - Keine neuen Repos ohne Freigabe.
   - Bitnami Repo ist nutzbar, aber nicht automatisch Vertrauensfreigabe fuer produktive Installationen.

4. Kubernetes Environment:
   - Local Kubernetes Environment ist erreichbar.
   - Keine externe Kubeconfig herunterladen oder weitergeben.
   - Kein Cloud-Provider-Import noetig.

5. Business Edition:
   - Nur pruefen, ob 3 Nodes Free sinnvoll ist.
   - Nicht upgraden, keine Lizenz einspielen, keine Registrierung absenden ohne ausdrueckliche Freigabe.
   - Ergebnis melden: Vorteile, Risiken, ob fuer 2FA/RBAC/Audit wirklich noetig.

============================================================
6. Portainer Migration auf Longhorn - historisch erledigt
============================================================

Diese Migration wurde am 2026-05-22 abgeschlossen und validiert. Der folgende
Abschnitt bleibt nur als historischer Ablauf/Referenz erhalten und ist nicht
mehr als offene Aufgabe zu behandeln.

Der Plan muss enthalten:

1. Preflight:
   - Portainer PVC/PV/Pfad identifizieren.
   - Portainer Chart/Values sichern.
   - Ziel-PVC auf Longhorn planen.
   - Longhorn Health pruefen.

2. Backup vor Migration:
   - K3s etcd S3 Snapshot.
   - Server-1 Restic Backup mit damaligen Portainer local-path Daten.
   - Optional tar/rsync-Kopie des Portainer-Datenpfads in ein root-only Backup-Verzeichnis.
   - Verify, dass Backup sichtbar ist.

3. Migrationsmethode:
   - Portainer Deployment kontrolliert auf 0 skalieren.
   - Daten vom alten local-path PV in neues Longhorn PVC kopieren.
   - Portainer Helm/Values auf Longhorn PVC umstellen.
   - Portainer starten.
   - Login, Settings und Environment pruefen.

4. Rollback:
   - Alten local-path PV/PVC nicht sofort loeschen.
   - Falls Portainer nicht funktioniert: Helm/Deployment zur alten PVC-Konfiguration zurueck.
   - Erst nach erfolgreicher mehrstufiger Verifikation aufraeumen.

5. Nach Migration:
   - Portainer PVC StorageClass ist longhorn.
   - Portainer erreichbar ueber https://portainer.activi.io.
   - Keine NodePorts.
   - Longhorn Volume healthy.
   - Longhorn Backup/Snapshot fuer Portainer-Volume separat planen.

============================================================
7. Nicht tun
============================================================

In diesem Block nicht:

- keine produktiven Apps installieren;
- keine Portainer-PVC-Migration ohne separaten finalen Migrationsplan starten;
- keine PVCs/PVs loeschen;
- keine Longhorn Default StorageClass setzen;
- keine NodePorts wieder oeffnen;
- keine Firewall-/DNS-/Cloudflare-Aenderung ohne separate Freigabe;
- keine Secrets, Tokens, Kubeconfigs oder Passwortwerte ausgeben;
- keine Business-Edition-Lizenz einspielen oder Registrierung absenden ohne Freigabe.

============================================================
8. Ergebnis melden
============================================================

Nach Abschluss melden:

- Pflichtdokumente gelesen: ja/nein
- Audit PASS: ja/nein
- Full Verify PASS: ja/nein
- Portainer Domain erreichbar: ja/nein
- Portainer Service ClusterIP ohne NodePorts: ja/nein
- Portainer aktiver PVC: `portainer-longhorn` auf `longhorn` erwartet; alten local-path Rollback-PVC getrennt melden
- 2FA/MFA Status: aktiviert/nicht verfuegbar/offen
- Access Tokens: keine/Anzahl, ohne Werte
- Business Edition: Empfehlung ja/nein mit Grund
- Backup-Zwischenstopp vor Aenderungen erfolgt: ja/nein/nicht noetig, weil nur read-only
- Keine Secrets ausgegeben: ja/nein
- Keine produktiven Apps installiert: ja/nein
- Offener naechster Stop-Punkt

Danach stoppen.
```

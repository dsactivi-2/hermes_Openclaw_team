# K3s Hetzner Handover - 2026-05-20

Stand: 2026-05-20 02:42 CEST.

Dieses Dokument ist die zentrale Uebergabe fuer das K3s/Hetzner-Robot-Projekt. Es beschreibt den verifizierten Live-Stand, die offenen Punkte, die Sicherheitsregeln und die Arbeitsweise fuer die naechste Session.

## Pflicht vor jeder weiteren Arbeit

Vor Aenderungen, Migrationen oder Installationen muessen diese Dateien gelesen werden:

```text
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-19-k3s-server2-server3-migration-backup.md
```

Regel: Erst Unterlagen lesen, dann Live-Stand pruefen, dann handeln. Wenn Unterlagen und Live-Stand voneinander abweichen, den Live-Stand dokumentieren und vor riskanten Aktionen nachfragen.

## Kurzstand

Der K3s-HA-Cluster auf Hetzner Robot Dedicated Servern wurde erfolgreich auf drei control-plane/etcd Nodes erweitert.

Server 3 wurde bewusst neu installiert. Die alten LXD-, Docker-, MariaDB-, Hermes-, Ollama-, Mail- und Panel-Daten auf Server 3 sind nicht mehr Teil des Zielzustands. Server 3 ist jetzt ein produktiver K3s control-plane/etcd Node und darf nicht mehr destruktiv behandelt werden.

Verifiziert am 2026-05-20:

- Alle drei Nodes waren `Ready`.
- Alle drei Nodes laufen mit K3s `v1.32.1+k3s1`.
- embedded etcd hat drei volle Member.
- Alle etcd Member waren `learner=false`.
- Alle etcd Endpoints waren healthy.
- Der neue Startcheck wurde am 2026-05-20 02:30 CEST erledigt und lokal geloggt.
- Portainer laeuft im Namespace `portainer`.
- Der post-server3-join Snapshot wurde erstellt.
- Longhorn ist installiert, seit 2026-05-24 Default und mit Test-PVC, Backup/Restore,
  SystemBackup und SystemBackup-RecurringJob validiert.
- Der Storage-Sollzustand wurde am 2026-05-24 02:45 CEST erneut verifiziert:
  `longhorn` ist die einzige Default StorageClass; `local-path` ist vorhanden,
  aber nicht Default. `portainer/portainer-longhorn` ist der aktive produktive
  PVC; der alte `portainer/portainer` PVC ist ungenutzter Rollback-Altbestand.
- `ingress-nginx` ist installiert und extern erreichbar; cert-manager ist installiert und geprueft; Velero ist noch nicht installiert.
- Server 1 betreibt weiterhin Docker-Apps ausserhalb von K3s.
- Backup Phase 1 ist aktiv, automatisiert und nicht-destruktiv validiert.
- OS-Level Restic fuer Server 2/3 ist aktiv, automatisiert und validiert.

Aktueller Startcheck-Log:

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

## Cluster

| Server | Hostname | Public IP | Private IP | Interface | Rolle | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Server 1 | `activi-k3-1.0` | `88.99.215.210` | `10.0.1.10` | `enp41s0.4000` | control-plane/etcd/master | Ready |
| Server 2 | `activi-k3-2` | `178.63.12.52` | `10.0.1.20` | `enp41s0.4000` | control-plane/etcd/master | Ready |
| Server 3 | `activi-k3-3` | `167.235.6.160` | `10.0.1.30` | `enp7s0.4000` | control-plane/etcd/master | Ready |

etcd Live-Stand:

| Member ID | Live-Member-Name | Client URL | Peer URL | Status |
| --- | --- | --- | --- | --- |
| `22ea434a682f6cd4` | `ubuntu-noble-latest-amd64-base-3982578f` | `https://10.0.1.10:2379` | `https://10.0.1.10:2380` | started, full member, healthy |
| `5d1662445ceef182` | `activi-k3-2-48af0a1d` | `https://10.0.1.20:2379` | `https://10.0.1.20:2380` | started, full member, healthy |
| `6af70bb753cd1ddb` | `activi-k3-3-82cc6d74` | `https://10.0.1.30:2379` | `https://10.0.1.30:2380` | started, full member, healthy |

Hinweis: Die etcd Member-Namen entsprechen im Live-Output nicht exakt den Hostnames. Das ist als bekannte kosmetische Abweichung dokumentiert. Entscheidend sind Member-ID, Client/Peer-URL, `started`, `learner=false` und Endpoint Health.

SSH-/Zugangsstand:

- Server 1: `ssh k3-1`.
- Server 2: `ssh kube3-2`; am 2026-05-24 vom User getestet und als
  funktionierend gemeldet.
- Server 3: bekannter lokaler Key `/Users/activi/.ssh/k3-3`.
- Nicht-geheime Verbindungsuebersicht:
  `/Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md`.

Wichtiger Snapshot:

```text
post-server3-join-20260520-013351-activi-k3-1.0-1779233631
```

Snapshot-Pfad laut Log:

```text
file:///var/lib/rancher/k3s/server/db/snapshots/post-server3-join-20260520-013351-activi-k3-1.0-1779233631
```

## Server 3

Aktueller Stand:

- Hostname: `activi-k3-3`
- Public IP: `167.235.6.160`
- Private IP: `10.0.1.30/24`
- Public Interface: `enp7s0`
- VLAN Interface: `enp7s0.4000`
- OS: Ubuntu 24.04.3
- K3s: `v1.32.1+k3s1`
- Flannel Interface: `enp7s0.4000`
- Rolle: control-plane/etcd/master

Historischer Server-3-Altbestand vor Reinstall:

```text
LXD: coolify-master, dograh-prod, n8n-prod, flexible-bass, vm02
Docker: prometheus, grafana, cadvisor, node-exporter
MariaDB: /var/lib/mysql
Weitere Spuren: Nginx/Hestia/php8.3-fpm/exim/dovecot/roundcube/fail2ban/Ollama/Hermes/rclone
```

Diese Altlasten wurden durch den bewusst freigegebenen Reinstall entfernt. Sie muessen nicht migriert werden.

Lokale Server-3-Dateien:

```text
/Users/activi/.ssh/k3-3
/Users/activi/.ssh/k3-3.pub
/Users/activi/Documents/activi K3s/bootstrap-server3-k3s.sh
```

Wichtig: Die temporaere Token-Datei `/root/k3s-token-for-server3` wurde nach erfolgreichem Join entfernt.

## Server-1-Datenmigration

Status: offen und wichtig.

Auf Server 1 laufen weiterhin Docker-Apps ausserhalb von K3s:

| App | Container/Image | Ports | Compose |
| --- | --- | --- | --- |
| Healthchecks | `healthchecks/healthchecks:latest` | `8000` | `/opt/healthchecks/docker-compose.yml` |
| Hindsight | `ghcr.io/vectorize-io/hindsight:latest` | `8888`, `9999` | `/root/hindsight/docker-compose.yml` |
| Hindsight Postgres | `pgvector/pgvector:pg16` | `5432` | `/root/hindsight/docker-compose.yml` |

Bekannte Docker-Volumes:

```text
healthchecks_healthchecks_data
hindsight-data
hindsight_hindsight-data
hindsight_hindsight-postgres-data
```

Vorhandene Migrationsbackups:

```text
/root/k3s-migration-backup/20260519-0430/healthchecks.tar.gz
/root/k3s-migration-backup/20260519-0430/hindsight-data.tar.gz
/root/k3s-migration-backup/20260519-0430/hindsight-postgres.tar.gz
```

Regeln fuer die Migration:

- Vor produktiver Migration frische Backups und DB-Dumps erstellen.
- Alte Docker-Apps nicht stoppen, bevor K3s-Deployments laufen und Daten verifiziert sind.
- Keine Docker-Volumes loeschen.
- Keine `.env` Inhalte, Tokens oder Passwoerter in Chat oder Markdown ausgeben.
- Stateful Apps erst nach Storage-Entscheidung migrieren.

## Backup- und Restore-Stand

Status: Phase 1 aktiv, automatisiert und nicht-destruktiv validiert.

Aktiver Stand:

- Hetzner Object Storage Bucket: `activi`.
- Region/Endpoint: `fsn1`, `https://fsn1.your-objectstorage.com`.
- K3s etcd S3 Ziel: `s3://activi/k3s/etcd/`.
- Restic Repository: `s3:https://fsn1.your-objectstorage.com/activi/restic/server1`.
- Bucket-Erstellung laut Hetzner Console/Erstellungsdialog: Object Lock `aktiviert`, Sichtbarkeit `privat`.
- Object Lock/Sichtbarkeit wurden nicht separat per S3-API/AWS-CLI ausgelesen.
- K3s Server Token, K3s Configs, lokale Snapshots, Docker-App-Daten, Compose-Dateien, `.env` Dateien als Dateien, Hindsight Postgres Dumps und bis Cleanup der alte Portainer-`local-path` Rollback-PVC sind im Restic-Scope.
- Hindsight Postgres Dumps werden automatisch erstellt.
- Restic Snapshots `d4faae42`, `c2b385b0`, `c9af17e7` existieren.
- `restic check` meldete keine Fehler.
- Erster automatischer Timerlauf wurde verifiziert:
  - `hindsight-postgres-dump.timer`: 2026-05-21 01:04:27 CEST.
  - `k3s-restic-backup.timer`: 2026-05-21 01:04:47 CEST.
- Backup-Phase-1-Preflight: `RESULT: PASS`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-backup-phase1-check-20260521-010319.log`.

Longhorn-Backup-Stand:

- Longhorn Backup Target: `s3://activi@fsn1/longhorn/`, `AVAILABLE=true`.
- Longhorn Volume-Backup/Restore fuer Testvolume ist validiert.
- Longhorn SystemBackup `lh-system-backup-20260521-timeout5` ist `Ready`.
- Pre-Apps SystemBackup `lh-system-backup-pre-apps-20260521-disabled` ist `Ready`.
- SystemBackup-RecurringJob `lh-system-backup-daily` ist aktiv:
  - Cron: `17 2 * * *`
  - Retain: `14`
  - Groups: `[]`
  - Policy: `volume-backup-policy=disabled`

OS-Level Backup Server 2/3:

- Status: aktiv, automatisiert und validiert.
- Plan: `/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md`.
- Aktive Repos:
  - `s3:https://fsn1.your-objectstorage.com/activi/restic/server2-os`
  - `s3:https://fsn1.your-objectstorage.com/activi/restic/server3-os`
- Wichtige Korrektur: Env-Dateien ohne `export` muessen in Skripten mit
  `set -a; source ...; set +a` geladen werden.
- Timer:
  - Server 2: `k3s-os-restic-backup.timer`, `hourly` plus RandomizedDelaySec.
  - Server 3: `k3s-os-restic-backup.timer`, `hourly` plus RandomizedDelaySec.
- Retention: `hourly 48`, `daily 14`, `weekly 8`, `monthly 12`.
- Letzte validierte Snapshot-Marker:
  - Server 2: `5edd164b`
  - Server 3: `485c0079`
- Vollstaendiges Verify nach Automatisierung:
  - `RESULT: PASS`
  - `Passes: 117`
  - `Warnings: 0`
  - `Failures: 0`
  - Log: `/tmp/k3s-stack-complete-verify-20260521-115116.log`

Backup-Arten sind bewusst getrennt:

- K3s etcd-Snapshot = Kubernetes-/Cluster-State.
- Restic Server 1 = Server-1-Dateien, Docker-App-Daten, DB-Dumps und alter Portainer-`local-path` Rollback-PVC bis Cleanup.
- OS-Restic Server 2/3 = OS-/Node-Konfiguration.
- Longhorn Volume-Backup = spaetere Daten in produktiven Longhorn-PVCs.
- Longhorn SystemBackup = Longhorn-Systemressourcen.
- Velero = geplante Zusatzschicht fuer Kubernetes-Ressourcen/Namespaces vor groesseren produktiven App-Rollouts.
- CloudNativePG/WAL + `pg_dump` = geplante datenbankbewusste Postgres-Sicherung fuer K3s-Postgres auf Longhorn.

Nicht jede Backup-Art muss auf jedem Node laufen. Jede Datenklasse muss genau
einmal sinnvoll gesichert und restore-getestet sein.

Offen:

Aktuelle kompakte TODO-Liste:

```text
/Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md
```

Zentrale Handover-Anweisung fuer neue Agenten:

```text
/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
```

1. Portainer UI fachlich fertig einrichten: Access Tokens, Registry/Helm-Repos und Kubernetes Environment pruefen.
2. Portainer Business Edition 3 Nodes Free ist aktiviert; Business-Funktionen gezielt einrichten und pruefen.
3. Longhorn Volume-RecurringJobs fuer `portainer/portainer-longhorn` sind aktiv:
   `prod-snapshot-hourly`, `prod-backup-daily`, `prod-backup-weekly`, Gruppe
   `prod-critical`; keine Jobs auf `default`, keine Testvolumes.
4. Healthchecks von Docker nach K3s + Longhorn migrieren.
5. Hindsight + Postgres von Docker nach K3s + Longhorn migrieren.
6. Optional S3-Credentials rotieren, weil eine Access Key ID im Chat sichtbar wurde.
7. Velero als Kubernetes-Ressourcen-/Namespace-Restore-Schicht planen, installieren und restore-testen.
8. CloudNativePG mit S3/WAL und zusaetzlichem `pg_dump` fuer Postgres-Workloads testen.

Altbestand:

- Borg/Borgmatic sind vorhanden, aber nicht Teil des neuen Backup-Plans.
- `aws`, `rclone`, `mc` und `s5cmd` sind fuer den Pflichtpfad nicht erforderlich.
- Velero ist weiterhin nicht installiert.
- Longhorn ist installiert und validiert; produktive PVCs wurden aber nicht migriert.

## Portainer

Status:

- Namespace: `portainer`
- Deployment: `portainer`, Helm-managed, zuletzt `1/1`
- Image: `portainer/portainer-ee:2.39.2`
- Helm Release: `portainer`, Chart `portainer-239.2.0`
- Pod: zuletzt `Running`
- Aktiver PVC: `portainer-longhorn`, `Bound`, `10Gi`, StorageClass `longhorn`.
- Aktives Longhorn Volume: `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b`, `attached/healthy`, Replicas auf allen drei Nodes.
- Alter Rollback-PVC: `portainer`, `Bound`, StorageClass `local-path`, Annotation `helm.sh/resource-policy=keep`; nicht loeschen ohne separaten Cleanup-Plan.
- Service: aktuell `ClusterIP`, `9000/TCP`, `9443/TCP`, `8000/TCP`; keine Kubernetes-NodePorts.
- Extern erreichbar ueber `https://portainer.activi.io` mit `HTTP/2 200`; HTTP leitet mit `308` auf HTTPS um.
- Pods haben nur interne Cluster-IPs; keine externe Pod-IP ist erwartet.
- Passwort-Reset abgeschlossen; temporaerer Reset-Pod geloescht.

Offen:

- 2FA pruefen/aktivieren, falls verfuegbar.
- Domain/Ingress/TLS fuer Portainer ist umgesetzt.
- NodePort-Zugriff ist geschlossen: clusterweit existieren keine NodePort-Services.
- Portainer komplett einrichten: Admin-Zugang, 2FA/MFA, Access Tokens, Helm-Repos und Kubernetes Environment pruefen.
- Portainer Business Edition 3 Nodes Free ist aktiviert; Business-Funktionen sind gezielt zu konfigurieren, aber nicht jede Funktion ist sofort Pflicht.
- Portainer-Longhorn-Migration ist erledigt und validiert.

Nicht tun:

- Portainer-PVCs loeschen, insbesondere den alten `local-path` Rollback-PVC, ohne separaten Cleanup-Plan.
- Portainer neu installieren, bevor PVC/Backup-Verhalten verstanden ist.
- Admin-Passwoerter oder Reset-Tokens dokumentieren.

## Storage, Ingress, TLS

Aktueller Stand:

- StorageClass: `longhorn (default)`, zusaetzlich `local-path` und `longhorn-static`.
- Longhorn: installiert per Helm `1.11.2`, Default StorageClass.
- IngressClass: `nginx` vorhanden.
- `ingress-nginx`: installiert, DaemonSet/hostNetwork auf allen drei Nodes.
- K3s-Traefik: bewusst deaktiviert.
- cert-manager: installiert per Helm `v1.20.2`, Pods Ready, CRDs vorhanden.
- Portainer-Ingress vorhanden und aktiv; weitere App-Ingresses noch nicht angelegt.
- Keine LoadBalancer-Services vorhanden.
- Longhorn-Test-App mit PVC ist nachgewiesen und validiert; keine produktive App ist migriert.

Empfohlene Richtung:

- Domain/Subdomain und Let's-Encrypt-E-Mail fuer Portainer festlegen.
- `ingress-nginx` ist der aktive dedizierte Ingress-Controller; cert-manager ist installiert.
- DNS erst setzen, wenn Entry-IPs, Ingress-Controller und Zertifikatsweg klar sind.
- NodePort ohne ausdrueckliche Freigabe nicht wieder oeffnen.

Update 2026-05-21 17:58 CEST:

- Fuer Portainer wurde Option A gewaehlt: Kubernetes Ingress + cert-manager + Let's Encrypt.
- Domain: `portainer.activi.io`.
- Let's-Encrypt-E-Mail: `ds@activi.io`.
- Cloudflare DNS: A-Record `portainer -> 88.99.215.210`, Proxy `Nur DNS`.
- Ports `80`/`443` waren vor der `ingress-nginx`-Installation auf allen drei Nodes frei.
- Host-Port-Variante fuer `ingress-nginx` passt zum aktuellen Setup.
- `ingress-nginx` wurde installiert und extern validiert.
- Historisch lieferte `portainer.activi.io` auf HTTP/HTTPS nginx `404 Not Found`, erwartbar ohne Portainer-Ingress.
- Hetzner Robot Firewall laesst `80/443` jetzt durch; der damalige NodePort-Fallback wurde spaeter geschlossen.
- cert-manager wurde installiert und live gegengeprueft: Helm Release `cert-manager`, Chart/App `v1.20.2`, Pods Ready, CRDs vorhanden.
- Bis zu diesem Installationsblock waren keine realen `Issuer`, `ClusterIssuer`, `Certificate`, `CertificateRequest`, `Order` oder `Challenge` angelegt.
- Audit-Skript `/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh` prueft die letzten Stack-Aussagen live inklusive Portainer-Ingress/TLS. Letzter Lauf 2026-05-21 22:55 CEST: `RESULT: PASS`, `Passes: 45`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260521-225515.log`.
- ClusterIssuer `letsencrypt-prod` wurde danach angelegt und ist `Ready=True` mit Reason `ACMEAccountRegistered`.
- Account-Secret `cert-manager/letsencrypt-prod-account-key` existiert als Metadaten; keine Secret-Inhalte wurden ausgegeben.
- Portainer-Ingress wurde danach versucht, aber nicht gespeichert: der ingress-nginx Admission Webhook antwortete mit `context deadline exceeded`.
- Keine Certificates, CertificateRequests, Orders, Challenges oder App-Ingresses wurden erzeugt.
- Admission-Service `ingress-nginx-controller-admission`: `10.43.55.93:443`, Endpunkte `10.0.1.10:8443`, `10.0.1.20:8443`, `10.0.1.30:8443`.
- Von Server 1 ist `10.0.1.10:8443` erreichbar, `10.0.1.20:8443` und `10.0.1.30:8443` sind nicht erreichbar.
- Danach wurde der Admission-Pfad repariert:
  - Hetzner Robot Firewall auf allen drei Servern: internes TCP `8443` von `10.0.1.0/24` erlaubt.
  - Server 1 UFW: `enp41s0.4000` TCP `8443` von `10.0.1.0/24` erlaubt.
  - Node-zu-Node-Matrix `10.0.1.10/20/30:8443` ist von Server 1, 2 und 3 erfolgreich.
  - Kubernetes API-Server-Dry-Run fuer Portainer-Ingress ist erfolgreich.
- Danach wurde der echte Portainer-Ingress erstellt und validiert:
  - Ingress `portainer/portainer`, Host `portainer.activi.io`, IngressClass `nginx`.
  - Backend Service `portainer`, Port `9443`, HTTPS-Backend-Annotation gesetzt.
  - Certificate `portainer/portainer-activi-io-tls` ist `Ready=True`.
  - TLS Secret `portainer/portainer-activi-io-tls` existiert als Metadaten, Typ `kubernetes.io/tls`, `DATA=2`.
  - `http://portainer.activi.io` leitet mit `308` auf HTTPS um.
  - `https://portainer.activi.io` liefert `HTTP/2 200` und Portainer.
- Danach wurde der Portainer Service per Helm auf `ClusterIP` umgestellt:
  - Helm Release `portainer` Revision 2.
  - Service `portainer`: `ClusterIP`, Ports `9000/TCP`, `9443/TCP`, `8000/TCP`.
  - Clusterweit existieren keine `NodePort` Services mehr.

Update 2026-05-22 03:49 CEST:

- Portainer wurde nach Backup-Zwischenstopp von `local-path` auf Longhorn migriert.
- Backup-Zwischenstopp vorher:
  - K3s etcd S3 Snapshot `manual-phase1-20260522-032854-activi-k3-1.0-activi-k3-1.0-1779413335`;
  - Server-1 Restic-Lauf erfolgreich;
  - Longhorn SystemBackup `lh-system-backup-pre-portainer-longhorn-20260522`, `Ready`.
- Aktiver PVC ist jetzt `portainer/portainer-longhorn`, StorageClass `longhorn`, `10Gi`.
- Portainer Deployment nutzt `portainer-longhorn`.
- Altes `portainer/portainer` local-path PVC bleibt mit `helm.sh/resource-policy=keep` als Rollback-Beleg erhalten.
- Longhorn Volume `pvc-55be5ed9-52ee-4d5b-90e2-1fd5b045c99b` ist `attached/healthy` mit Replicas auf allen drei Nodes.
- Recent-Audit nach Dokumentationsupdate: `RESULT: PASS`, `Passes: 52`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260522-040057.log`.
- Full Verify nach Dokumentationsupdate: `RESULT: PASS`, `Passes: 125`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260522-040227.log`.
- Update 2026-05-22 22:36 CEST: Portainer/Kubernetes-API-Timeouts sind behoben. Das neue Skript `/Users/activi/Documents/activi K3s/verify-portainer-api-connectivity.sh` prueft aus dem Portainer-Pod-Netz alle drei API-Endpunkte und den Kubernetes-Service. Letzter Lauf: `RESULT: PASS`, 60/60 stabil pro Ziel, Log `/tmp/portainer-api-connectivity-20260523-024920.log`.
- Recent-Audit nach Firewall-Fix: `RESULT: PASS`, `Passes: 53`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-recent-stack-claims-audit-20260523-024855.log`.
- Full Verify nach Firewall-Fix: `RESULT: PASS`, `Passes: 126`, `Warnings: 0`, `Failures: 0`, Log `/tmp/k3s-stack-complete-verify-20260523-025031.log`.
  - Externe Tests auf `30777`, `30779`, `30776` gegen alle drei Public IPs laufen in Timeout.
  - `https://portainer.activi.io` liefert weiter `HTTP/2 200`, HTTP leitet weiter mit `308` um.
- Noch nicht: DNS-Aenderung, Cloudflare Proxy-Aktivierung, weitere SSH/K3s-Firewall-Haertung.
- K3s-Startargumente nicht ungefiltert ausgeben, da sie sensible Token enthalten koennen.

## Firewall und Netzwerk

vSwitch/VLAN:

- VLAN: `4000`
- Privates Netz: `10.0.1.0/24`
- Server 1: `10.0.1.10`
- Server 2: `10.0.1.20`
- Server 3: `10.0.1.30`

Robot Firewall, aktuell relevante Regeln:

- ICMP von `0.0.0.0/0`
- SSH TCP `22` initial offen
- HTTP/HTTPS TCP `80,443` optional fuer spaeteren Web/Ingress-Zugriff
- TCP established ACK Rueckregel: Quell-Port `0-65535`, Ziel-Port `0-65535`, TCP-Flags `ack`, Aktion `accept`
- Private K3s-Regeln nur von Quelle `10.0.1.0/24`:
  - TCP `6443`
  - TCP `9345`
  - TCP `2379`
  - TCP `2380`
  - TCP `10250`
  - UDP `8472`
- ingress-nginx Admission Webhook verwendet private TCP-Endpunkte auf `8443`; intern von `10.0.1.0/24` erlaubt, nicht oeffentlich freigegeben.
- Pod-Netz zu Kubernetes API: Quelle `10.42.0.0/16`, Ziel-Port TCP `6443` auf allen drei Robot-Firewalls erlauben. Diese Regel ist fuer Pods wie Portainer/CoreDNS wichtig, wenn der Kubernetes-Service `10.43.0.1:443` auf einen API-Server auf Server 2/3 verteilt.
- Ausgehend: `Allow all`

Wichtig zur Robot-Firewall:

- Die `tcp established` Regel mit `TCP-Flags=ack` ist eine Rueckpaket-Regel, keine Freigabe fuer neue eingehende Verbindungen auf alle Ports.
- Nicht wieder auf `32768-65535` begrenzen. Flannel/NAT kann auch niedrigere Rueckports verwenden; genau das verursachte die Portainer-Timeouts.
- Die alte, erfolglose Server-1-UFW-Route-Regel `cni0 -> enp41s0.4000` fuer `10.42.0.0/16 -> 10.0.1.0/24:6443` wurde entfernt und soll nicht erneut als Primaerfix verwendet werden.

Spaeter haerten:

- SSH auf Admin-IP oder Tailscale einschraenken.
- NodePorts sind aktuell geschlossen; nur bei bewusstem Rollback-Plan wieder oeffnen.
- Kubernetes API nicht breit oeffentlich exponieren.
- Host-Firewalls/UFW pro Node konsistent planen.

## Absolute Sicherheitsregeln

Niemals ohne neue ausdrueckliche Freigabe:

- Server 1, Server 2 oder Server 3 neu installieren.
- Einen Node aus dem Cluster entfernen.
- Ein etcd Member loeschen.
- K3s-Service-Flags auf bestehenden Nodes aendern.
- Portainer-PVC loeschen.
- Docker-Volumes auf Server 1 loeschen.
- Alte Docker-Apps auf Server 1 stoppen.
- Firewall-Regeln so haerten, dass SSH/K3s ausgesperrt werden koennte.
- Secrets, Tokens, Passwoerter, Kubeconfigs oder API Keys in Chat/Markdown ausgeben.
- Produktive Migration starten, bevor frische Backups vorhanden sind.

## Backup-Zwischenstopps

Vor jeder groesseren Aenderung an Portainer, Storage, PVCs, Helm-Releases,
Ingress/TLS, Firewall oder produktiven Apps ist ein Backup-Zwischenstopp Pflicht:

1. `audit-recent-stack-claims.sh` und `verify-k3s-stack-complete.sh` muessen `PASS` sein.
2. Frischer K3s etcd Snapshot nach S3.
3. Frischer Server-1 Restic Backup-Lauf, solange Portainer oder Docker-App-Daten auf Server 1 liegen.
4. Frischer Longhorn SystemBackup, wenn Longhorn-/Kubernetes-Systemressourcen betroffen sind.
5. Sichtbarkeit der neuen Backups pruefen, ohne Secret-Werte auszugeben.
6. Erst danach Migration oder groessere Aenderung starten.

Wenn ein Backup- oder Verify-Schritt fehlschlaegt, wird gestoppt.

Sofort stoppen und fragen, wenn:

- Ein Befehl Secrets ausgeben wuerde.
- Ein Node `NotReady` ist.
- etcd nicht healthy ist.
- Unterlagen und Live-Stand widersprechen.
- Hetzner Robot UI etwas anderes zeigt als dokumentiert.
- Ein Tool Hetzner Cloud/hcloud-Annahmen macht, obwohl Robot gemeint ist.

## Skills und Arbeitsweise

Relevante Skills:

```text
kubernetes
kubernetes-resources
kubernetes-security
kubernetes-helm
kubernetes-manifests
docker
traefik
hetzner-deploy
```

Nutzung:

- `kubernetes`: Cluster-Checks, kubectl, Pods, Nodes, Services, Events.
- `kubernetes-resources`: Services, PVC/PV, StorageClass, NodePort/ClusterIP/LoadBalancer.
- `kubernetes-security`: RBAC, NetworkPolicy, Secret-Handling, Hardening.
- `kubernetes-helm`: Helm-Installationen und Helm-values, z. B. Portainer, Longhorn, ingress-nginx.
- `kubernetes-manifests`: YAML fuer Deployments, Services, Ingress, PVCs.
- `docker`: Server-1-Docker-Inventar, Compose, Volumes, Migration.
- `traefik`: nur verwenden, wenn Traefik bewusst gewaehlt wird.
- `hetzner-deploy`: nur mit Vorsicht, weil dieser Skill Hetzner Cloud/hcloud-lastig ist; der aktuelle Cluster laeuft auf Hetzner Robot Dedicated Servern.

Nicht verwenden oder nicht darauf verlassen:

- `kubectl` Skill: nicht installiert.
- `hetzner-server`: entfernt, da Cloud/VPS-lastig.
- `k8s-clusters`: nicht als echte lokale Skill-Datei verfuegbar.
- `simple-backup`: Download/Treffer nicht belastbar.
- `cert-manager` aus `cubenlp/chattool`: nicht fuer normalen Kubernetes-cert-manager-Betrieb verwenden.

## Naechste Arbeitsreihenfolge

Verbindliche Reihenfolge ab 2026-05-21 23:18 CEST:

1. Portainer UI fachlich fertig einrichten und absichern.
2. Portainer Business Edition 3 Nodes Free ist aktiviert; Business-Funktionen gezielt konfigurieren.
3. Velero als Kubernetes-Ressourcen-/Namespace-Restore-Schicht planen, installieren und restore-testen.
4. Healthchecks von Docker nach K3s + Longhorn migrieren.
5. Hindsight + Postgres von Docker nach K3s + Longhorn migrieren.
6. Danach weitere Longhorn Volume-RecurringJobs nur fuer neue produktive Longhorn-PVCs erweitern.
7. Monitoring/Alerting einrichten.
8. Erst danach produktive Apps installieren oder migrieren.
9. Optional S3-Credentials rotieren und Backup danach erneut pruefen.
10. Velero als Zusatzschicht planen, installieren und restore-testen.
11. CloudNativePG/Postgres-Backup-Schicht planen und restore-testen.
11. SSH und K3s-Firewall nach stabiler Zugriffsschicht schrittweise haerten.

## Wichtige lokale Dateien und Logs

Zentrale Dokumente:

```text
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-PLAN-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/OS-RESTIC-PHASE2-HANDOVER-PROMPT-2026-05-21.md
/Users/activi/Documents/activi K3s/docs/superpowers/plans/2026-05-19-k3s-server2-server3-migration-backup.md
```

Skripte:

```text
/Users/activi/Documents/activi K3s/bootstrap-server3-k3s.sh
/Users/activi/Documents/activi K3s/check-server1-cluster.sh
/Users/activi/Documents/activi K3s/check-server2-node.sh
/Users/activi/Documents/activi K3s/check-server3-preflight.sh
/Users/activi/Documents/activi K3s/check-full-server-preflight.sh
/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh
/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh
```

Wichtigste Logs:

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
/Users/activi/Documents/activi K3s/logs/k3s-server3-post-join-verify-20260520-live.log
/Users/activi/Documents/activi K3s/logs/k3s-server3-local-k3s-verify-20260520-live.log
/Users/activi/Documents/activi K3s/logs/k3s-post-server3-join-snapshot-20260520-live.log
/Users/activi/Documents/activi K3s/logs/k3s-live-stack-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-live-etcd-backup-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-server1-data-migration-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-server1-backup-system-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-server1-borgmatic-audit-20260520.log
/Users/activi/Documents/activi K3s/logs/k3s-cluster-addon-audit-20260520.log
/tmp/k3s-recent-stack-claims-audit-20260521-233143.log
/tmp/k3s-stack-complete-verify-20260521-233236.log
```

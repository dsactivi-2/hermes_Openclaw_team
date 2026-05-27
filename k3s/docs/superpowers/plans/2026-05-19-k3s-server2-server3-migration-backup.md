# K3s Hetzner Migration and Backup Plan

Stand: 2026-05-20 02:42 CEST.

> Fuer agentische Worker: Dieser Plan ist der aktuelle Ausfuehrungsplan. Er ersetzt die historische Version, in der Server 3 noch ohne Reinstall und ohne Datenverlust vorbereitet werden sollte.

## Ausgangslage

Der urspruengliche Plan entstand vor dem Server-3-Reinstall. Der Nutzer hat spaeter entschieden, dass der alte Server-3-Datenbestand nicht mehr benoetigt wird. Server 3 wurde danach neu installiert und erfolgreich in den K3s-Cluster aufgenommen.

Aktueller Zielzustand:

- Server 1: `activi-k3-1.0`, Public `88.99.215.210`, Private `10.0.1.10`, Interface `enp41s0.4000`
- Server 2: `activi-k3-2`, Public `178.63.12.52`, Private `10.0.1.20`, Interface `enp41s0.4000`
- Server 3: `activi-k3-3`, Public `167.235.6.160`, Private `10.0.1.30`, Interface `enp7s0.4000`
- K3s: `v1.32.1+k3s1`
- etcd: drei full members, zuletzt healthy; Live-Member-Namen sind generiert und dokumentiert
- Portainer: laeuft ueber `https://portainer.activi.io`; Service ist `ClusterIP`, keine NodePorts
- Server 1: betreibt noch Docker-Apps ausserhalb von K3s

Verifikationslogs:

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
```

## Absolut gesperrt ohne Freigabe

- Server neu installieren.
- Nodes aus dem Cluster entfernen.
- etcd Member loeschen.
- K3s-Service-Flags auf bestehenden Nodes aendern.
- Portainer-PVC loeschen.
- Docker-Volumes auf Server 1 loeschen.
- Healthchecks/Hindsight Docker-Instanzen stoppen.
- Firewall-Regeln so aendern, dass SSH/K3s ausgesperrt werden koennte.
- Secrets, Tokens, Passwoerter, API Keys, Kubeconfigs oder `.env` Inhalte in Chat/Markdown ausgeben.

## Phase 0: Pflicht-Lektuere und Live-Baseline

Ziel: Aktuelle Dokumentation lesen und den Live-Zustand belegen, bevor Arbeit beginnt.

Status: Startcheck wurde am 2026-05-20 02:30 CEST erledigt und lokal geloggt:

```text
/Users/activi/Documents/activi K3s/logs/k3s-startcheck-20260520-current.log
```

Bekannter Live-Stand daraus:

- Alle drei Nodes `Ready`.
- Alle Pods `Running`.
- StorageClass nur `local-path (default)`.
- Portainer `1/1`, PVC `Bound`, Service `ClusterIP`.
- IngressClass `nginx` ist vorhanden; Portainer-Ingress/TLS ist aktiv.
- etcd alle drei Endpoints healthy, alle Member `started`, alle `learner=false`.
- etcd Member-Namen sind generiert:
  - `ubuntu-noble-latest-amd64-base-3982578f`
  - `activi-k3-2-48af0a1d`
  - `activi-k3-3-82cc6d74`

Diese Member-Namen sind eine bekannte kosmetische Abweichung und kein Stop-Kriterium, solange Health/URLs/Member-Status stimmen.

- [ ] Handover lesen:

```text
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
```

- [ ] Projektstatus lesen:

```text
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
```

- [ ] Next-Session-Guide lesen:

```text
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
```

- [x] Cluster live pruefen:

```bash
kubectl get nodes -o wide
kubectl get pods -A -o wide
kubectl get storageclass
kubectl get pv,pvc -A
kubectl get ingressclass
kubectl get ingress -A
```

- [x] etcd live pruefen:

```bash
ETCDCTL_API=3 etcdctl \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
  --endpoints=https://10.0.1.10:2379,https://10.0.1.20:2379,https://10.0.1.30:2379 \
  member list -w table
ETCDCTL_API=3 etcdctl \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/client.key \
  --endpoints=https://10.0.1.10:2379,https://10.0.1.20:2379,https://10.0.1.30:2379 \
  endpoint health -w table
```

Stop-Kriterien:

- Node nicht `Ready`.
- etcd Endpoint nicht healthy.
- etcd Member `learner=true`.
- Unerklaerte Pods in Fehlerzustand.
- Doku und Live-Stand widersprechen.

## Phase 1: Backup-System entscheidungsfaehig machen

Ziel: Kein produktiver Migrationsschritt ohne belastbares Backup/Restore-Konzept. Backup-Bestandteile sind vorhanden, aber der externe Restore-Weg ist noch nicht final verifiziert.

- [ ] Lokale etcd Snapshots pruefen:

```bash
k3s etcd-snapshot list
```

- [ ] K3s Snapshot-Konfiguration pruefen:

```bash
systemctl cat --no-pager k3s | grep -E -- "etcd-snapshot|etcd-s3" || true
```

- [ ] Borgmatic-Stand pruefen:

```bash
borgmatic list
systemctl list-timers --all --no-pager | grep -Ei "backup|snapshot|borg|restic|rclone|k3s|longhorn|velero" || true
```

Bekannter Stand:

```text
Lokale etcd Snapshots vorhanden.
Keine etcd-s3 Konfiguration gefunden.
borg/borgmatic installiert.
borgmatic.timer vorhanden.
borgmatic list: No valid configuration files found.
```

- [ ] Vorhandenes Backup-Ziel/System lesend pruefen und mit Nutzer bestaetigen.

- [ ] Tooling entscheiden:
  - K3s native S3 snapshots fuer etcd
  - Borgmatic fuer Dateien/App-Backups
  - Restic als Alternative
  - Longhorn Backup Target fuer PVs

- [ ] Retention festlegen:
  - lokale etcd Snapshots
  - externe etcd Snapshots
  - App-/DB-Backups
  - Longhorn Backups

- [ ] Restore-Runbook als Pflicht-Ergebnis definieren.

Akzeptanz:

- Externes Backup-Ziel ist bekannt.
- Zugangsdaten sind sicher hinterlegt, nicht dokumentiert.
- etcd Snapshot kann extern abgelegt werden.
- Restore-Schritte sind dokumentiert.

## Phase 2: Server-1-Docker-Apps frisch sichern

Ziel: Vor Migration aktuelle App-Daten sichern.

Bekannte Apps:

```text
healthchecks          healthchecks/healthchecks:latest
hindsight             ghcr.io/vectorize-io/hindsight:latest
hindsight-postgres    pgvector/pgvector:pg16
```

Bekannte Compose-Dateien:

```text
/opt/healthchecks/docker-compose.yml
/root/hindsight/docker-compose.yml
```

Bekannte Volumes:

```text
healthchecks_healthchecks_data
hindsight-data
hindsight_hindsight-data
hindsight_hindsight-postgres-data
```

- [ ] Aktuelle Container pruefen:

```bash
docker ps -a
docker compose ls
docker volume ls
```

- [ ] Compose- und Env-Dateien finden, ohne Secrets auszugeben:

```bash
find /root /srv /opt /home /var/www /usr/local /var/lib/docker \
  -maxdepth 5 \
  -type f \( -name "docker-compose.yml" -o -name "compose.yml" -o -name "compose.yaml" -o -name "*.env" \) \
  2>/dev/null | sort
```

- [ ] Frische Volume-Backups erstellen.
- [ ] Frische DB-Dumps fuer Postgres erstellen.
- [ ] Backup-Groessen und Lesbarkeit pruefen.
- [ ] Keine `.env` Inhalte dokumentieren.

Akzeptanz:

- Frische Backups existieren.
- DB-Dumps existieren und sind plausibel lesbar.
- Restore-Pfad fuer jede App ist beschrieben.
- Alte Docker-Instanzen laufen weiterhin.

## Phase 3: Storage/Longhorn aufbauen

Ziel: Stateful Workloads nicht blind auf `local-path` migrieren.

Bekannter Stand:

```text
StorageClass: local-path (default)
Longhorn: nicht installiert
Longhorn Backup Target: nicht eingerichtet
```

- [ ] Longhorn-Voraussetzungen auf allen Nodes pruefen.
- [ ] Longhorn per Helm oder Manifest installieren.
- [ ] StorageClass-Default-Strategie entscheiden.
- [ ] Longhorn UI nicht breit oeffentlich exponieren.
- [ ] Longhorn Backup Target einrichten.
- [ ] Test-PVC erstellen.
- [ ] Test-App deployen.
- [ ] Snapshot/Backup/Restore plausibel testen.

Akzeptanz:

- Test-PVC wird provisioniert.
- Test-App kann schreiben/lesen.
- Backup Target ist konfiguriert.
- Restore-Plausibilitaet ist dokumentiert.

## Phase 4: Portainer absichern

Ziel: Portainer als Admin-Oberflaeche erhalten, aber nicht unnoetig offen betreiben.

- [ ] Live-Status pruefen:

```bash
kubectl -n portainer get deploy,pod,pvc,svc -o wide
kubectl -n portainer describe svc portainer
```

- [ ] Admin-Zugang mit Nutzer klaeren.
- [ ] 2FA pruefen/aktivieren.
- [ ] Portainer-PVC in Backup-Plan aufnehmen.
- [ ] Ziel-Exposure entscheiden:
  - temporaer NodePort mit Einschraenkung
  - bevorzugt Domain/Ingress/TLS
  - optional Tailscale/Admin-IP-only

Akzeptanz:

- Zugang ist geklaert.
- PVC ist im Backup-Plan.
- NodePort ist nur temporaer oder eingeschraenkt.

## Phase 5: Ingress, DNS und TLS

Ziel: Saubere Zugriffsschicht fuer Portainer und spaeter Apps.

Aktueller Stand:

```text
K3s-Traefik: deaktiviert
IngressClass: nginx vorhanden
cert-manager: installiert und geprueft
```

- [x] Domain fuer Portainer entschieden: `portainer.activi.io`.
- [x] Public Entry-IP fuer Portainer gesetzt: `88.99.215.210`.
- [x] Ingress-Controller entschieden und installiert: `ingress-nginx`.
- [x] cert-manager installieren und pruefen.
- [x] Let's-Encrypt ClusterIssuer `letsencrypt-prod` mit HTTP-01 ueber `nginx` anlegen und pruefen.
- [x] TLS-Methode entschieden:
  - HTTP-01 ist aktuell bevorzugt, weil `80/443` extern auf `ingress-nginx` erreichbar sind.
  - DNS-01 nur bei bewusstem DNS-API-Zugriff.
- [x] ingress-nginx Admission-Webhook-Pfad auf internem `8443` reparieren und per Server-Dry-Run pruefen.
- [ ] Test-Ingress mit Test-App pruefen.
- [ ] Portainer ueber Domain/TLS bereitstellen.

Akzeptanz:

- IngressClass existiert.
- Test-Ingress funktioniert.
- Zertifikat wird ausgestellt.
- Portainer ist ueber Domain/TLS erreichbar.
- NodePort kann geschlossen/eingeschraenkt werden.

## Phase 6: Healthchecks migrieren

Ziel: Erste Server-1-App kontrolliert nach K3s migrieren.

- [ ] Healthchecks Compose analysieren, ohne Secrets auszugeben.
- [ ] Image, Env-Keys, Ports und Datenpfade erfassen.
- [ ] Kubernetes Secret-Strategie festlegen.
- [ ] PVC anlegen.
- [ ] Deployment/Service/Ingress erstellen.
- [ ] Daten aus frischem Backup wiederherstellen.
- [ ] Funktion intern testen.
- [ ] TLS/Ingress testen.
- [ ] Erst nach erfolgreicher Verifikation alte Docker-Instanz stoppen.

Akzeptanz:

- Healthchecks laeuft in K3s.
- Daten sind vorhanden.
- Zugriff funktioniert.
- Backup/Restore ist dokumentiert.
- Alte Docker-Instanz wird erst nach Freigabe gestoppt.

## Phase 7: Hindsight und Postgres migrieren

Ziel: Hindsight inklusive Postgres kontrolliert nach K3s migrieren.

- [ ] Compose analysieren, ohne Secrets auszugeben.
- [ ] Postgres-Dump frisch erstellen.
- [ ] Ziel festlegen:
  - Postgres als eigener StatefulSet/Deployment mit PVC
  - oder externer DB-Dienst, falls gewuenscht
- [ ] PVCs anlegen.
- [ ] Secrets sicher erstellen.
- [ ] Postgres restore testen.
- [ ] Hindsight deployen.
- [ ] Service/Ingress testen.
- [ ] Alte Docker-Instanzen erst nach Verifikation stoppen.

Akzeptanz:

- Hindsight laeuft in K3s.
- Postgres-Daten sind wiederhergestellt.
- App-Zugriff funktioniert.
- Backup/Restore ist dokumentiert.

## Phase 8: Firewall und Security haerten

Ziel: Erst haerten, wenn Zugriffsschicht und Backups stabil sind.

- [ ] SSH-Zugriff einschraenken: Admin-IP oder Tailscale.
- [x] Portainer-NodePorts geschlossen; keine Kubernetes-NodePort-Services vorhanden.
- [ ] K3s private Ports nur aus `10.0.1.0/24` erlauben.
- [ ] Kubernetes API nicht breit oeffentlich exponieren.
- [ ] Host-Firewalls konsistent planen.
- [ ] NetworkPolicies fuer produktive Apps pruefen.
- [ ] RBAC und Secret-Handling pruefen.

Akzeptanz:

- Admin-Zugriff bleibt erhalten.
- Cluster bleibt healthy.
- Public Exposure ist dokumentiert und minimal.

## Abschlusskriterien

Das Projekt gilt fuer diesen Abschnitt als sauber abgeschlossen, wenn:

- Cluster mit drei Nodes healthy ist.
- Externes etcd Backup funktioniert.
- App-/DB-Backups fuer migrierte Apps funktionieren.
- Restore-Weg dokumentiert ist.
- Longhorn oder gewaehlte Storage-Strategie getestet ist.
- Portainer sicher erreichbar ist.
- Ingress/TLS funktioniert.
- Healthchecks und Hindsight migriert oder bewusst zurueckgestellt sind.
- NodePorts/SSH/K3s-Firewall gehaertet sind.
- Alle Dokumente aktualisiert sind.

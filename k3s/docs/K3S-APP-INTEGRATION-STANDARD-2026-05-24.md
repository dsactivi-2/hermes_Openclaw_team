# K3s App Integration Standard - activi Cluster - 2026-05-24

Dieses Dokument ist die globale Vorlage fuer neue Apps, die in den bestehenden
activi K3s Cluster integriert werden sollen. Es beschreibt den verbindlichen
Cluster-Standard. App-spezifische Werte gehoeren nicht hier hinein, sondern in
eine eigene Values-/Antwortdatei des jeweiligen Projekts.

## Zweck

Neue Projekte sollen nicht raten, ob Traefik, nginx, local-path, NodePort oder
Longhorn verwendet werden. Jeder neue Agent oder jedes neue Projekt muss diesen
Standard zuerst lesen und seine Manifeste, Helm-Charts und Preflight-Skripte
darauf ausrichten.

Wenn Live-Zustand und dieses Dokument abweichen, muss der Agent stoppen und die
Abweichung melden. Nicht automatisch reparieren.

## Verbindlicher Cluster-Ist-Zustand

Cluster:

- Plattform: K3s HA mit embedded etcd.
- Provider: Hetzner Robot / Dedicated Root Server.
- Nodes:
  - `activi-k3-1.0`, private IP `10.0.1.10`, public IP `88.99.215.210`.
  - `activi-k3-2`, private IP `10.0.1.20`, public IP `178.63.12.52`.
  - `activi-k3-3`, private IP `10.0.1.30`, public IP `167.235.6.160`.
- Alle drei Nodes sind Control-Plane-/etcd-/Master-Nodes.
- K3s Version laut letzter Dokumentation: `v1.32.1+k3s1`.

Storage:

- `longhorn` ist die einzige Default StorageClass.
- `local-path` existiert noch, ist aber nicht Default und darf fuer neue Apps
  nicht verwendet werden.
- `longhorn-static` existiert fuer Spezialfaelle, ist aber nicht der Standard.
- Neue produktive Apps verwenden PVCs mit StorageClass `longhorn`.
- Keine neue StorageClass aus einem App-Chart erstellen, ausser es gibt eine
  separate Freigabe.

Ingress und TLS:

- Ingress Controller: `ingress-nginx`.
- IngressClass: `nginx`.
- Traefik wird fuer neue Apps nicht verwendet.
- cert-manager ist installiert.
- ClusterIssuer: `letsencrypt-prod`.
- Challenge-Typ: HTTP-01 ueber `nginx`.
- Cloudflare DNS fuer App-Domains muss auf `Nur DNS` stehen, wenn HTTP-01
  genutzt wird.
- Neue Apps sollen ueber Ingress/TLS erreichbar sein, nicht ueber NodePort.

Service-Typen:

- Standard fuer Apps: `ClusterIP`.
- `NodePort` ist fuer neue Apps nicht erlaubt, ausser es gibt eine separate
  Freigabe mit Begruendung.
- `LoadBalancer` ist aktuell nicht der Standard, weil kein Hetzner
  LoadBalancer/MetalLB als Zielpfad festgelegt ist.
- `ExternalName` nur nach separater Freigabe.

Backup- und Restore-Schichten:

- K3s etcd-S3 Snapshots sichern Cluster-State.
- Velero sichert Kubernetes-Ressourcen und Namespace-Restore-Schichten.
- Longhorn sichert PVC-/Volume-Daten.
- Longhorn Volume-RecurringJobs existieren fuer bestaetigte produktive Volumes.
- Datenbanken brauchen zusaetzlich datenbankbewusste Backups, z. B. WAL,
  Operator-Backups oder `pg_dump`. Longhorn allein reicht fuer Datenbanken nicht
  als einzige Sicherung.
- Restic sichert Host-/OS-Dateien und verbliebene Daten ausserhalb K3s.

PostgreSQL-App-Backup-Standard:

- Jede produktive PostgreSQL-App braucht vor Produktionsfreigabe ein
  datenbankbewusstes Backup.
- Standardtemplate fuer `pg_dump`-Backups liegt unter
  `templates/app-backup/pgdump-cronjob.template.yaml`.
- Der CronJob muss pro App angepasst werden; Platzhalter duerfen nicht deployed
  werden.
- Das Backup-Image muss `/bin/bash`, `pg_dump`, `gzip`, `sha256sum`, `aws`,
  `wget` und CA-Zertifikate enthalten.
- Der CronJob muss `restartPolicy: OnFailure`, `concurrencyPolicy: Forbid` und
  Bash mit `-e -u -o pipefail` nutzen.
- Secret-Werte gehoeren nur in Kubernetes Secrets oder spaeter in
  SOPS/External-Secrets, nicht in Git.
- Ein `pg_dump`-Backup zaehlt erst als erledigt, wenn ein Restore-Test in eine
  Test-/Restore-DB erfolgreich dokumentiert wurde.

Security-Standard:

- Keine Secrets, Tokens, Passwoerter, Kubeconfigs, privaten SSH-Keys oder
  `.env` Inhalte in Prompts, Logs oder Dokumentation ausgeben.
- Secrets muessen als Kubernetes Secrets, External Secrets oder verschluesselte
  GitOps-Werte geplant werden.
- Keine Secret-Werte in Helm `values.yaml`, wenn diese Datei in Git landet.
- Neue Apps sollen mit non-root Containern laufen, sofern das Image das
  unterstuetzt.
- Readiness-/Liveness-/Startup-Probes einplanen.
- Requests und Limits setzen.
- Admin-Oberflaechen nur bewusst oeffentlich machen; sonst intern, mit Auth
  oder separater Freigabe.
- NetworkPolicies sind fuer produktive Apps einzuplanen, aber nicht blind
  aktivieren, solange die App-Kommunikationspfade nicht bekannt sind.

Deployment-Standard:

- Neue Apps sollen als Helm-Chart oder klare Kubernetes-Manifeste deploybar sein.
- Alle app-spezifischen Werte muessen in Values/Config liegen, nicht hart im
  Template.
- Jede App bekommt einen eigenen Namespace, ausser es gibt einen klaren Grund
  dagegen.
- Namespace, Domains, PVC-Groessen, Secrets, SMTP, externe Ports und Backup
  muessen vor Deployment bestaetigt sein.
- Langfristiges Ziel ist GitOps, bevorzugt Argo CD. Bis GitOps fertig ist, muessen
  manuelle Helm-Schritte sauber dokumentiert werden.

## Verbotene Annahmen Fuer Neue Apps

Neue Projekte duerfen nicht annehmen:

- dass Traefik existiert oder genutzt wird;
- dass `local-path` fuer neue Apps akzeptabel ist;
- dass NodePorts offen sind;
- dass eine App eigene StorageClasses erstellen darf;
- dass cert-manager fehlt;
- dass der Cluster ein Cloud-LoadBalancer-Setup hat;
- dass Longhorn-Backups Datenbanken alleine konsistent sichern;
- dass Secrets bereits existieren;
- dass private Registries ohne Pull Secret funktionieren;
- dass `configuration-snippet` in nginx erlaubt ist.

## Pflicht-Preflight Fuer Neue App-Projekte

Vor einem Deployment muss ein Agent mindestens diese Punkte pruefen:

```bash
kubectl config current-context
kubectl get nodes -o wide
kubectl get ingressclass
kubectl get storageclass
kubectl get clusterissuer
kubectl get ns
kubectl get svc -A
kubectl get ingress -A
```

Erwartete Kernaussagen:

- Der Zielcluster ist der activi K3s Cluster.
- Alle drei Nodes sind `Ready`.
- IngressClass `nginx` ist vorhanden.
- StorageClass `longhorn` ist Default.
- `local-path` ist nicht Default.
- ClusterIssuer `letsencrypt-prod` ist vorhanden und Ready.
- Keine neuen NodePorts fuer die App ohne Freigabe.

## Pflicht-Vorlage Fuer App-Antwortdateien

Jedes App-Projekt soll eine eigene Datei verwenden, zum Beispiel:

```text
docs/apps/<app-name>-target-values.md
```

Diese Datei muss mindestens enthalten:

- App-Name.
- Namespace.
- Zielmodus, z. B. Neuinstallation oder Migration.
- Migrationsquelle, falls vorhanden.
- Domains.
- IngressClass.
- TLS-Issuer.
- Service-Typ.
- StorageClass.
- PVCs und Groessen.
- Datenbanktyp.
- Backup-Strategie.
- Velero-Plan fuer den App-Namespace.
- Longhorn-Plan fuer produktive PVCs.
- Datenbankbewusste Backup-Methode, bei PostgreSQL inklusive Angabe ob
  CloudNativePG/Barman, `pg_dump` oder beides verwendet wird.
- Restore-Test-Plan und erwarteter Restore-Nachweis.
- Secrets-Namen.
- Registry/ImagePullSecrets.
- SMTP/Outbound Mail, falls noetig.
- Externe Ports, falls noetig.
- Monitoring-Anforderungen.
- ResourceQuotas/LimitRanges.
- NetworkPolicies.
- Rollback-Weg.
- Offene Entscheidungen.
- Deployment-Freigabe.

Vor Deployment muss die Datei mit dem lokalen Gate geprueft werden:

```bash
./verify-app-onboarding-gate.sh docs/apps/<app-name>-target-values.md
```

`PASS` bedeutet: alle Pflichtentscheidungen sind dokumentiert. `PASS_WITH_GAPS`
bedeutet: Planung ist nutzbar, aber Deployment ist noch nicht freigegeben oder
es gibt offene Entscheidungen. `FAIL` bedeutet: stoppen und nacharbeiten.

## Deploy-Pipeline Nebenprojekt

Fuer kuenftige App-Deployments ist ein lokaler Pipeline-Assistent als
Nebenprojekt geplant:

```text
docs/DEPLOY-PIPELINE-SIDEPROJECT-2026-05-27.md
```

Sobald dieses System gebaut und verifiziert ist, soll es den manuellen
App-Onboarding-Prozess fuehren. Es ersetzt nicht GitOps, Argo CD, Flux,
GitHub Actions oder menschliche Freigaben. Es erzeugt Phasen-Prompts,
Fix-Prompts, Reports und Pruefungen.

Verbindliche Leitplanken fuer dieses Pipeline-System:

- Script-first arbeiten, wenn dadurch Risiko nicht steigt.
- Keine Agenten automatisch fernsteuern.
- Keine Secrets ausgeben oder decodieren.
- Keine echten Deploys ohne explizite Freigabe.
- Keine DNS-, Longhorn-, Velero-, cert-manager-, IngressClass- oder globalen
  Cluster-Aenderungen ohne separate Freigabe.
- Locks gegen parallele Bearbeitung derselben App/Phase verwenden.
- Reports nur mit `RESULT: PASS`, `RESULT: PASS_WITH_GAPS` oder
  `RESULT: FAIL` akzeptieren.
- `PASS_WITH_GAPS` nur mit dokumentiertem `ACCEPTED_GAPS: yes` fortsetzen.
- Deploy-Phasen niemals automatisch weiterfuehren.

Bis das Pipeline-System live verifiziert ist, bleibt der bestehende
App-Onboarding-Fragebogen plus manuelle Agenten-Prompts der verbindliche Weg.

## Stop-Punkte Fuer App-Agenten

Sofort stoppen und fragen, wenn:

- ein erwarteter Cluster-Standard abweicht;
- ein Secret fehlt und nicht klar ist, wie es erzeugt werden soll;
- eine App NodePort, HostPort oder HostNetwork braucht;
- eine App eine eigene StorageClass erstellen will;
- eine App Datenbankdaten ohne DB-bewusstes Backup speichern soll;
- eine produktive PostgreSQL-App ohne konkreten `pg_dump`-/WAL-/Restore-Plan
  deployed werden soll;
- Ingress/TLS nicht eindeutig ist;
- DNS oder Firewall geaendert werden muessten;
- produktive PVCs oder Namespaces geloescht/geaendert werden muessten;
- ein Befehl Secret-Inhalte ausgeben wuerde.

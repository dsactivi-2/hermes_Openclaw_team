# App Onboarding Fragekatalog - activi K3s - 2026-05-24

Dieser Fragekatalog ist fuer jedes neue Projekt zu verwenden, bevor ein Agent
Helm-Charts, Kubernetes-Manifeste oder Preflight-Skripte an den activi K3s
Cluster anpasst.

Der Fragekatalog trennt bewusst:

- **K3s-Ist-Zustand:** Was im Cluster bereits gilt.
- **App-Soll-Zustand:** Was die neue App braucht.
- **Offene Entscheidung:** Was Denis noch bestaetigen muss.

Ein Agent darf offene Entscheidungen nicht selbst erraten.

## 1. Ziel und Scope

1. Wie heisst die App oder der Stack?
2. Soll die App produktiv, staging oder nur als Test laufen?
3. Ist es eine neue App oder Migration aus Docker/VM/anderem Cluster?
4. Gibt es bestehende Daten, die uebernommen werden muessen?
5. Gibt es einen Rollback-Weg, falls das Deployment fehlschlaegt?

## 2. Namespace und Release

1. Welcher Namespace soll verwendet werden?
2. Soll der Namespace neu erstellt werden?
3. Wie soll der Helm-Release heissen?
4. Soll die App spaeter per GitOps/Argo CD verwaltet werden?
5. Gibt es Namenskonventionen fuer Ressourcen?

## 3. Domains, Ingress und TLS

1. Welche Domains/Subdomains braucht die App?
2. Welche Domain ist die Hauptdomain?
3. Welche Domains sind nur Admin- oder interne Oberflaechen?
4. Soll alles oeffentlich erreichbar sein?
5. Soll etwas nur intern/VPN/SSH-Tunnel erreichbar sein?
6. Wird IngressClass `nginx` verwendet?
7. Wird ClusterIssuer `letsencrypt-prod` verwendet?
8. Werden nginx-Snippets benoetigt?
9. Sind Rate Limits erforderlich?
10. Sind besondere Security Headers erforderlich?

Verbindlicher Standard, wenn nichts anderes freigegeben ist:

- IngressClass: `nginx`
- TLS: `cert-manager` mit `letsencrypt-prod`
- Service: `ClusterIP`
- Keine NodePorts

## 4. Storage und PVCs

1. Welche Daten schreibt die App dauerhaft?
2. Welche PVCs braucht die App?
3. Welche Groesse braucht jedes PVC initial?
4. Muss ein PVC besonders schnell sein?
5. Muss ein PVC besonders lange aufbewahrt werden?
6. Soll Reclaim bewusst `Retain` sein?
7. Duerfen PVCs automatisch geloescht werden?
8. Gibt es bestehende Daten, die importiert werden muessen?

Verbindlicher Standard:

- StorageClass fuer neue produktive App-PVCs: `longhorn`
- Keine Nutzung von `local-path` fuer neue Apps.
- Keine neue StorageClass ohne Freigabe.

## 5. Datenbanken

1. Braucht die App eine Datenbank?
2. Welche Datenbank: Postgres, MariaDB, Redis, Qdrant, andere?
3. Soll die Datenbank im Cluster laufen?
4. Soll die Datenbank extern/managed laufen?
5. Ist HA/Replikation erforderlich?
6. Ist Point-in-Time-Recovery erforderlich?
7. Welche Backup-Methode ist app-konsistent?
8. Gibt es Migrationen oder Seed-Daten?
9. Gibt es bestehende Dumps, die importiert werden muessen?

Standardempfehlung fuer Postgres im Cluster:

- Kubernetes StatefulSet + Longhorn ist fuer einfache Starts moeglich.
- Fuer produktionskritische Postgres-Workloads ist CloudNativePG als Zielpfad
  vorgesehen.
- Zusaetzlich zu Longhorn ist ein datenbankbewusstes Backup erforderlich,
  zum Beispiel WAL/Operator-Backup und/oder `pg_dump`.
- Fuer `pg_dump` gilt das Template unter
  `templates/app-backup/pgdump-cronjob.template.yaml` als Standardbasis.
- Pro App muessen DB-Service, Backup-User, DB-Name, S3-Prefix, Secret-Namen und
  Restore-Test konkret bestaetigt werden.

## 6. Backup und Restore

1. Welche App-Daten muessen wiederherstellbar sein?
2. Welche Kubernetes-Ressourcen muessen per Velero gesichert werden?
3. Welche PVCs muessen per Longhorn Backup gesichert werden?
4. Welche Datenbank-Backups sind erforderlich?
   - CloudNativePG/Barman WAL?
   - `pg_dump` CronJob?
   - Beides?
5. Wie oft muss gesichert werden?
6. Wie lange muessen Backups aufbewahrt werden?
7. Was ist der erwartete Restore-Test?
8. Kann ein einzelner Namespace wiederhergestellt werden?
9. Gibt es Daten, die nicht in S3/Object Storage duerfen?
10. Wie lautet der app-spezifische S3-Prefix fuer Datenbank-Dumps?
11. Wie wird der Backup-Erfolg extern ueberwacht, z. B. Healthchecks/Webhook?

Cluster-Standard:

- Velero fuer Kubernetes-Ressourcen/Namespaces.
- Longhorn fuer PVC-/Volume-Daten.
- Datenbankbewusste Backups fuer Datenbanken.
- etcd-S3 fuer Cluster-State.
- Restic fuer Host-/OS-Dateien.
- Produktive PostgreSQL-Apps duerfen erst nach erfolgreichem Restore-Test als
  backupseitig fertig gelten.

## 7. Secrets und Credentials

1. Welche Secrets braucht die App?
2. Existieren diese Secrets bereits?
3. Wie sollen die Secrets heissen?
4. Woher kommen die Werte?
5. Duerfen Secrets manuell erstellt werden?
6. Sollen Secrets spaeter mit SOPS oder External Secrets verwaltet werden?
7. Gibt es API Tokens, SMTP Passwoerter, DB Passwoerter oder Signing Keys?
8. Gibt es bestehende Keys, die zwingend uebernommen werden muessen?

Regeln:

- Keine Secret-Werte in Chat, Logs oder Doku ausgeben.
- Nur Secret-Namen, Metadaten, Owner, Rechte oder Existenz dokumentieren.
- Bestehende Identitaets-Keys nicht neu erzeugen, wenn eine Migration
  stattfindet.

## 8. Container Images und Registry

1. Welche Images werden verwendet?
2. Sind die Images public oder private?
3. Wird GHCR, DockerHub oder eine andere Registry genutzt?
4. Wird ein ImagePullSecret benoetigt?
5. Wie heisst das ImagePullSecret?
6. Gibt es feste Versionstags?
7. Gibt es Images mit `latest`, die ersetzt werden muessen?
8. Gibt es Security-Scan-Anforderungen?

## 9. Netzwerk, Ports und Protokolle

1. Welche HTTP/HTTPS-Ports braucht die App intern?
2. Braucht die App UDP?
3. Braucht die App `hostNetwork`, `hostPort` oder direkte Public Ports?
4. Braucht die App WebSockets, gRPC oder lange HTTP-Verbindungen?
5. Braucht die App externe Callback-URLs?
6. Muss Firewall oder DNS geaendert werden?

Standard:

- HTTP/HTTPS ueber Ingress.
- Keine NodePorts.
- UDP/hostNetwork nur mit separater Freigabe.

## 10. Mail, Webhooks und externe Dienste

1. Braucht die App SMTP?
2. Welche Absenderadresse soll verwendet werden?
3. Welcher SMTP Provider, Port und TLS-Modus?
4. Braucht die App eingehende Webhooks?
5. Braucht die App ausgehende Webhooks?
6. Gibt es Rate Limits oder IP-Allowlists externer Dienste?

## 11. Security und Zugriff

1. Wer darf die App nutzen?
2. Gibt es Admin-Rollen?
3. Gibt es SSO/OAuth/OIDC?
4. Soll Registrierung offen oder geschlossen sein?
5. Soll MFA verpflichtend sein?
6. Braucht die App eigene RBAC-Regeln im Cluster?
7. Braucht die App NetworkPolicies?
8. Gibt es Admin-Domains, die nicht oeffentlich sein sollen?

## 12. Ressourcen, Probes und Skalierung

1. Erwartete Nutzerzahl?
2. Erwartete Datenmenge?
3. CPU-/RAM-Anforderungen?
4. Braucht die App mehrere Replicas?
5. Ist die App stateless oder stateful?
6. Welche Readiness/Liveness/Startup-Probes sind sinnvoll?
7. Gibt es Worker, CronJobs oder Hintergrundprozesse?

## 13. Monitoring und Betrieb

1. Welche Healthchecks braucht die App?
2. Welche Metriken sind wichtig?
3. Welche Logs sind relevant?
4. Welche Alerts sollen entstehen?
5. Gibt es Zertifikats-, Backup- oder Queue-Alerts?
6. Gibt es einen externen Uptime-Check?

## 14. Deployment-Freigabe

Vor echtem Deployment muss beantwortet sein:

1. Namespace bestaetigt?
2. Domains bestaetigt?
3. Ingress/TLS bestaetigt?
4. PVCs und Groessen bestaetigt?
5. Datenbankstrategie bestaetigt?
6. Backupstrategie bestaetigt?
7. Secrets vorhanden oder Erzeugung freigegeben?
8. Registry/Pull Secrets bestaetigt?
9. Rollback-Weg beschrieben?
10. Preflight ohne Failures?

## 15. Antwortformat Fuer Neue Projekte

Neue App-Agenten sollen ihre Antworten in diesem Format liefern:

```text
App-Name:
Namespace:
Zielmodus:
Migrationsquelle:
Helm-Release:
Domains:
IngressClass:
TLS-Issuer:
Service-Typ:
StorageClass:
PVCs:
Datenbank:
Backup-Strategie:
Velero:
Longhorn:
DB-Backup:
DB-Backup-Template:
DB-Backup-Secret:
DB-Backup-S3-Prefix:
Restore-Test:
Secrets:
Registry/ImagePullSecrets:
SMTP:
Externe Ports:
Security/Zugriff:
Monitoring:
ResourceQuotas/LimitRanges:
NetworkPolicies:
Rollback:
Offene Entscheidungen:
Stop-Punkte:
Deployment-Freigabe:
Naechster sicherer Schritt:
```

Vor Deployment muss die Antwortdatei mit dem lokalen Gate geprueft werden:

```bash
./verify-app-onboarding-gate.sh docs/apps/<app-name>-target-values.md
```

`PASS_WITH_GAPS` ist fuer reine Planung akzeptabel. Ein echtes Deployment darf
erst starten, wenn keine harten `FAIL`-Punkte vorhanden sind und die
Deployment-Freigabe explizit erteilt wurde.

# Matrix Stack Runbook und Agenten-Briefing

Dieses Dokument ist der primaere Einstiegspunkt fuer einen ausfuehrenden Agenten.
Es beschreibt exakt, was im Projekt liegt, was installiert werden muss, welche
Konfigurationen zu setzen sind, in welcher Reihenfolge gearbeitet wird und wann
gestoppt werden muss.

Arbeitsverzeichnis:

```bash
cd /Users/activi/Documents/Matrix
```

Repository-Zweck: Betrieb eines privaten Matrix-Stacks fuer `activi.io` mit
Synapse, Element Web, Synapse/Ketesa Admin UI, Element Admin, Traefik, Postgres,
coturn, lokalen Tests per OrbStack, optionalen Hermes-Agenten und optionalem
K3s/Longhorn-Deployment.

## 1. Nicht verhandelbare Regeln

1. Keine Secret-Datei in Git committen.
2. `.env`, `.env.production`, `synapse-data/*.signing.key`, gerenderte
   Runtime-Konfigurationen und `backups/` bleiben lokal und geheim.
3. Auf einem Produktionsserver niemals `docker-compose.orbstack.yml` verwenden.
   Diese Datei ist nur fuer lokale OrbStack-Tests.
4. Federation bleibt im ersten Produktions-Deployment deaktiviert. Der Wert
   `SYNAPSE_LISTENER_RESOURCES=client` ist absichtlich.
5. Offene Registrierung bleibt deaktiviert. Der Wert
   `SYNAPSE_ENABLE_REGISTRATION=false` ist Pflicht.
6. Die Synapse Signing Key bestimmt die Matrix-Serveridentitaet. Eine bestehende
   Produktion darf nie versehentlich mit einer neuen Key gestartet werden.
7. Hermes-Agenten werden erst gestartet, wenn Matrix, Element, DNS, TLS, SMTP,
   TURN und Backups geprueft sind.
8. Basic Auth Hashes in `.env` muessen bcrypt-Hashes sein. Dollarzeichen im
   Hash muessen in `.env` als `$$` escaped werden.
9. Bei jedem FAIL in `server-prepare.sh`, `predeploy-audit.sh`,
   `healthcheck.sh` oder `restore-check.sh` stoppen und Ursache beheben.

## 2. Architekturentscheidungen

- Primaerer lokaler Validierungsweg: Docker Compose mit OrbStack-Override.
- Primaerer Produktionsweg: Docker Compose auf einem Linux-Server.
- Alternativer Produktionsweg: K3s + Longhorn via Helm Chart.
- Matrix-Modus fuer erstes Deployment: private island / intern, keine
  Federation.
- Public Entry Point: Traefik.
- Datenbank: Postgres 17.
- Homeserver: Synapse.
- Web Client: Element Web.
- Standalone Synapse Admin UI: Ketesa.
- Element Admin wird mitgeliefert, kann aber bei standalone Synapse nur
  eingeschraenkt nuetzlich sein, weil es auf Element Server Suite/MAS Annahmen
  ausgelegt ist.
- TURN: coturn.
- Lokale SMTP-Tests: Mailpit.
- Optionale Automations-/Beratungsagenten: Hermes `sena` und `activi`.

## 3. Was wo liegt

### Root-Dateien

- `docker-compose.yml`: Hauptstack fuer Traefik, Postgres, Synapse, Element,
  Element Admin, Ketesa, coturn und optionale Hermes-Agenten.
- `docker-compose.orbstack.yml`: lokaler Override fuer OrbStack; publiziert
  lokale Ports `8081`, `8082`, `8025`, `8443` und ergaenzt Mailpit.
- `.env`: lokale echte Umgebung. Geheim. Nicht committen.
- `.env.example`: lokales Beispiel.
- `.env.production.example`: Produktionsbeispiel.
- `.gitignore`: schuetzt Secrets, Runtime-Dateien und Backups.
- `RUNBOOK.md`: dieses Dokument.
- `SERVER_DEPLOY.md`: kurze Server-Checkliste; dieses Runbook ist massgeblich.
- `K3S_LONGHORN.md`: kompakte K3s/Longhorn-Anleitung; dieses Runbook ist
  massgeblich fuer die Gesamtuebergabe.

### Deploy- und Konfigurationsdateien

- `deploy/server.env.example`: Vorlage fuer `.env` auf einem Produktionsserver.
- `templates/element-config.json.tmpl`: Element Web Produktionsconfig.
- `templates/element-config.local.json.tmpl`: Element Web lokale Config.
- `templates/ketesa-config.json.tmpl`: Ketesa Produktionsconfig.
- `templates/ketesa-config.local.json.tmpl`: Ketesa lokale Config.
- `templates/traefik/dynamic.yml.tmpl`: Traefik Produktionsrouting.
- `templates/traefik/dynamic.local.yml.tmpl`: Traefik lokales Routing.
- `templates/synapse/homeserver.yaml.tmpl`: Synapse Produktionsconfig.
- `templates/synapse/homeserver.local.yaml.tmpl`: Synapse lokale Config.
- `element-config.json`: gerendert, geheimnisarm, nicht committen.
- `element-config.local.json`: gerendert, lokal, nicht committen.
- `ketesa-config.json`: gerendert, nicht committen.
- `ketesa-config.local.json`: gerendert, lokal, nicht committen.
- `traefik/dynamic.yml`: gerendert, enthaelt Basic Auth Hashes, nicht committen.
- `traefik/dynamic.local.yml`: gerendert, lokal, nicht committen.
- `synapse-data/homeserver.yaml`: gerendert, enthaelt Secrets, nicht committen.
- `synapse-data/homeserver.local.yaml`: gerendert, lokal, nicht committen.
- `synapse-data/homeserver.yaml.production.example`: altes/kompaktes Beispiel.
- `synapse-data/*.signing.key`: Synapse Serveridentitaet. Geheim.
- `synapse-data/media_store/`: lokale Medienablage, nicht committen.

### Skripte

- `scripts/render-config.sh`: rendert alle Runtime-Konfigurationen aus `.env`
  und `templates/`.
- `scripts/server-prepare.sh`: Produktions-Preflight. Prueft `.env`,
  Pflichtvariablen, Placeholder, Signing Key, gerenderte Config, Compose und
  Image-Plattformen.
- `scripts/predeploy-audit.sh`: tiefer lokaler Audit mit Login, Testuser,
  Raum, Nachricht, Media Upload, SMTP, Backup und Restore-Check.
- `scripts/healthcheck.sh`: schneller Healthcheck fuer laufenden lokalen Stack.
- `scripts/backup.sh`: erstellt Backup von Postgres, Runtime Config, Secrets,
  Synapse Media und Traefik ACME.
- `scripts/restore-check.sh`: prueft Backup-Dateien ohne Restore in den
  laufenden Stack.
- `scripts/install-images.sh`: zieht, taggt, pusht oder listet Images.
- `scripts/push-ghcr-multiarch.sh`: spiegelt Upstream-Images als
  Multi-Arch-Manifeste nach GHCR.
- `scripts/check-image-platforms.sh`: prueft `linux/amd64` und `linux/arm64`
  fuer alle referenzierten Images.
- `scripts/deploy-preflight.sh`: aelterer Deploy-Preflight.
- `scripts/preflight-audit.sh`: aelterer Audit.
- `scripts/k3s-longhorn-preflight.sh`: Preflight fuer K3s/Longhorn.

### Agenten

- `agents/README.md`: Erklaerung des Agenten-Add-ons.
- `agents/sena/SOUL.md`: Persona fuer `sena`.
- `agents/sena/config.yaml`: Hermes Runtime Defaults fuer `sena`.
- `agents/sena/.env.example`: benoetigte Agent-Secrets.
- `agents/sena/skills/sena-agent-builder/SKILL.md`: rollenspezifischer Skill.
- `agents/activi/SOUL.md`: Persona fuer `activi`.
- `agents/activi/config.yaml`: Hermes Runtime Defaults fuer `activi`.
- `agents/activi/.env.example`: benoetigte Agent-Secrets.
- `agents/activi/skills/activi-ops-admin/SKILL.md`: Ops/Admin Skill.
- `agents/shared/CONTEXT.md`: nicht geheime Projektkontextdatei fuer beide
  Agenten.
- `.agents/skills/hermes-agent/SKILL.md`: gemeinsamer Hermes Skill.
- `.agents/skills/hermes-agent-skill-authoring/SKILL.md`: Skill-Autorenskill.
- `.agents/skills/agentmail/SKILL.md`: optionaler AgentMail Skill.

### Kubernetes und Helm

- `helm/matrix-stack/Chart.yaml`: Helm Chart Metadaten.
- `helm/matrix-stack/values.yaml`: Standardwerte fuer K3s/Longhorn.
- `helm/matrix-stack/values-k3s-longhorn.yaml`: K3s/Longhorn Overlay.
- `helm/matrix-stack/templates/*.yaml`: Kubernetes Manifeste fuer Namespace,
  Secrets, ConfigMaps, StatefulSets, Deployments, Ingress, coturn, Backups und
  Storage.
- `k8s/examples/matrix-stack-secret.example.yaml`: Secret-Beispiel.
- `k8s/examples/ghcr-pull-secret.example.sh`: GHCR Pull Secret Beispiel.

### Backups

- `backups/<timestamp>/MANIFEST.txt`: Backup-Metadaten.
- `backups/<timestamp>/postgres-synapse.sql`: Postgres Dump.
- `backups/<timestamp>/config-and-secrets.tgz`: Konfiguration und Secrets.
- `backups/<timestamp>/synapse-media.tgz`: Synapse Media Volume.
- `backups/<timestamp>/traefik-acme.tgz`: Let's Encrypt/ACME Volume.

Backups enthalten Secrets und muessen verschluesselt und off-server gesichert
werden.

## 4. Service-Landkarte

### Docker Compose Services

- `traefik`: Reverse Proxy, HTTP/HTTPS, Let's Encrypt, Security Headers,
  Basic Auth fuer Admin-Oberflaechen.
- `db`: Postgres 17 fuer Synapse.
- `synapse`: Matrix Homeserver, nutzt `/data/homeserver.yaml`.
- `synapse-permissions`: einmaliger Helper fuer Volume-Rechte auf
  `/data/media_store`.
- `element`: Element Web Client.
- `element-admin`: Element Admin UI.
- `ketesa`: Standalone Synapse Admin UI.
- `coturn`: TURN Server fuer VoIP; nutzt Host Network.
- `mailpit`: nur im OrbStack-Override, lokales SMTP-Testpostfach.
- `sena`: optionaler Hermes-Agent, Compose Profile `hermes`.
- `activi`: optionaler Hermes-Agent, Compose Profile `hermes`.

### Produktionsdomains

- `MATRIX_DOMAIN=matrix.activi.io`: Matrix Client API und Synapse.
- `ELEMENT_DOMAIN=space.activi.io`: Element Web.
- `ELEMENT_ADMIN_DOMAIN=admin.matrix.activi.io`: Element Admin.
- `KETESA_DOMAIN=synapse-admin.activi.io`: Ketesa/Synapse Admin.
- `TRAEFIK_DOMAIN=traefik.activi.io`: Traefik Dashboard.

### Lokale OrbStack URLs

- `LOCAL_ELEMENT_URL=http://127.0.0.1:8081`: Element Web und lokale Matrix API.
- `LOCAL_ADMIN_URL=http://127.0.0.1:8082`: Ketesa und lokale Admin API.
- `LOCAL_MAILPIT_URL=http://127.0.0.1:8025`: Mailpit UI.
- `https://127.0.0.1:8443`: lokale HTTPS-Route mit Self-Signed/TLS-Kontext;
  Browsertests bevorzugt ueber HTTP `8081`.

## 5. Was installiert sein muss

### Lokal auf macOS mit OrbStack

Pflicht:

- Git.
- Docker CLI.
- Docker Compose v2.
- OrbStack oder kompatible Docker Engine.
- `curl`.
- `grep`, `sed`, `awk`, `tar`, `df`, `date`.

Empfohlen:

- Zugriff auf GHCR, falls private Images gezogen werden.
- Browser fuer Element/Ketesa Tests.

Pruefung:

```bash
docker info
docker compose version
curl --version
```

Erwartung:

- Docker daemon reachable.
- Compose v2 antwortet.
- `curl` ist vorhanden.

### Produktionsserver mit Docker Compose

Pflicht:

- Linux Server mit fester oeffentlicher IP.
- Docker Engine.
- Docker Compose v2.
- Git.
- OpenSSL.
- Ausgehender Zugriff auf GHCR und Upstream Registries.
- Eingehende Firewall-Regeln:
  - TCP `80` fuer Let's Encrypt HTTP-01 und Redirect.
  - TCP `443` fuer HTTPS.
  - TCP `3478` und UDP `3478` fuer TURN.
  - TCP `5349` nur wenn TLS TURN genutzt wird.

Nicht starten:

- Keine Hermes-Agenten beim ersten Produktionsstart.
- Kein Federation Listener.
- Keine offene Registrierung.

### K3s/Longhorn Ziel

Pflicht:

- Laufender K3s Cluster.
- Longhorn installiert und healthy.
- nginx IngressClass `nginx`.
- cert-manager installiert.
- ClusterIssuer `letsencrypt-prod` ready.
- Namespace `matrix`.
- Secret `matrix-stack-secrets`.
- GHCR Pull Secret `ghcr-pull-secret`, falls GHCR Packages privat sind.
- DNS zeigt auf die K3s Ingress/LB IP.

## 6. Konfigurationsmatrix

Alle deployment-spezifischen Werte kommen aus `.env` oder aus Kubernetes
Secrets/Values. Runtime-Dateien werden daraus gerendert. Nicht manuell in
gerenderten Dateien herumeditieren, wenn dieselbe Aenderung in `.env` oder
`templates/` gehoert.

### Projekt und Domains

- `PROJECT_NAME`: Compose-Projektname, Standard `matrix`.
- `APP_BRAND`: Anzeigename, Standard `Activi Space`.
- `BASE_DOMAIN`: Basisdomain, Standard `activi.io`.
- `MATRIX_DOMAIN`: Synapse/Matrix Host.
- `ELEMENT_DOMAIN`: Element Web Host.
- `ELEMENT_ADMIN_DOMAIN`: Element Admin Host.
- `KETESA_DOMAIN`: Ketesa Host.
- `TRAEFIK_DOMAIN`: Traefik Dashboard Host.
- `MATRIX_BASE_URL`: externe Matrix Basis-URL.
- `MATRIX_HOMESERVER_URL`: Homeserver URL fuer Clients.
- `ELEMENT_BASE_URL`: externe Element URL.
- `KETESA_BASE_URL`: externe Ketesa URL.
- `ACME_EMAIL`: E-Mail fuer Let's Encrypt.
- `SERVER_PUBLIC_IP`: echte oeffentliche IP des Produktionsservers.

### Datenbank

- `POSTGRES_DB=synapse`.
- `POSTGRES_USER=synapse`.
- `POSTGRES_HOST=db`.
- `POSTGRES_PORT=5432`.
- `DB_PASSWORD`: starkes Secret, neu generieren.
- `POSTGRES_CP_MIN` und `POSTGRES_CP_MAX`: Synapse DB Pool.

### Synapse

- `MATRIX_ADMIN_USER`: geplanter Admin Login, z.B. `activi`.
- `MATRIX_ADMIN_PASSWORD`: starkes Admin-Passwort.
- `MATRIX_ADMIN_USER_ID`: z.B. `@activi:matrix.activi.io`.
- `REGISTRATION_SHARED_SECRET`: starkes Secret fuer Admin-Registrierung.
- `SYNAPSE_REPORT_STATS=false`.
- `SYNAPSE_LISTENER_RESOURCES=client`.
- `SYNAPSE_ENABLE_REGISTRATION=false`.
- `SYNAPSE_MSC4186_ENABLED=true`.
- `SYNAPSE_MAX_UPLOAD_SIZE=100M`.
- `SYNAPSE_LOCAL_MEDIA_LIFETIME=180d`.
- `SYNAPSE_REMOTE_MEDIA_LIFETIME=30d`.
- `TRUSTED_KEY_SERVER=matrix.org`.

### TURN

- `TURN_REALM=activi.io`.
- `TURN_HOST=matrix.activi.io` in Produktion.
- `LOCAL_TURN_HOST=127.0.0.1` lokal.
- `TURN_PORT=3478`.
- `TURN_USERNAME=matrix`.
- `TURN_PASSWORD`: starkes Secret.
- `TURN_USER_LIFETIME=1h`.
- `TURN_ALLOW_GUESTS=false`.

### SMTP

- `SMTP_HOST`: Produktions-SMTP Host.
- `SMTP_PORT`: meist `587`.
- `SMTP_USER`: SMTP Benutzer.
- `SMTP_PASSWORD`: SMTP Passwort.
- `SMTP_REQUIRE_TLS=true` fuer Produktion.
- `SMTP_FROM_NAME`: Anzeigename.
- `SMTP_FROM_EMAIL`: Absenderadresse.
- `SMTP_ENABLE_NOTIFS=true`.
- `SMTP_NOTIF_FOR_NEW_USERS=false`.
- Lokal wird Mailpit ueber `LOCAL_SMTP_HOST=mailpit` und
  `LOCAL_SMTP_PORT=1025` verwendet.

### Traefik und Basic Auth

- `SYNAPSE_ADMIN_BASIC_AUTH_USERS`: htpasswd bcrypt Hash fuer Synapse Admin API.
- `TRAEFIK_DASHBOARD_BASIC_AUTH_USERS`: htpasswd bcrypt Hash fuer Dashboard.
- `TRAEFIK_STS_SECONDS=31536000`.
- `TRAEFIK_PUBLIC_RATE_AVERAGE=100`.
- `TRAEFIK_PUBLIC_RATE_BURST=200`.
- `TRAEFIK_ADMIN_RATE_AVERAGE=20`.
- `TRAEFIK_ADMIN_RATE_BURST=40`.

Hash erzeugen:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'REPLACE_WITH_PASSWORD'
```

Dann jedes `$` im Hash fuer `.env` als `$$` schreiben.

### Images

Produktions-Images aus `deploy/server.env.example`:

```env
TRAEFIK_IMAGE=ghcr.io/dsactivi-2/matrix/traefik:v3.3
POSTGRES_IMAGE=ghcr.io/dsactivi-2/matrix/postgres:17-alpine
SYNAPSE_IMAGE=ghcr.io/dsactivi-2/matrix/synapse:v1.153.0
ELEMENT_IMAGE=ghcr.io/dsactivi-2/matrix/element-web:v1.12.18
ELEMENT_ADMIN_IMAGE=ghcr.io/dsactivi-2/matrix/element-admin:0.1.11
KETESA_IMAGE=ghcr.io/dsactivi-2/matrix/ketesa:v1.2.1-7-g646f925
HERMES_IMAGE=nousresearch/hermes-agent@sha256:b6e41c155d6bfce5ad83c5d0fec670086db8a43250e4511c9474134be5482d33
COTURN_IMAGE=ghcr.io/dsactivi-2/matrix/coturn:4.11.0-r0
MAILPIT_IMAGE=ghcr.io/dsactivi-2/matrix/mailpit:v1.21
```

Image-Mapping:

- `traefik:v3.3` -> GHCR Projekt-Tag.
- `postgres:17-alpine` -> GHCR Projekt-Tag.
- `matrixdotorg/synapse:latest` -> `synapse:v1.153.0`.
- `vectorim/element-web:latest` -> `element-web:v1.12.18`.
- `oci.element.io/element-admin:latest` -> `element-admin:0.1.11`.
- `ghcr.io/etkecc/ketesa:latest` -> `ketesa:v1.2.1-7-g646f925`.
- `coturn/coturn:latest` -> `coturn:4.11.0-r0`.
- `axllent/mailpit:v1.21` -> `mailpit:v1.21`.
- Hermes bleibt auf dem offiziellen digest-pinned Multi-Platform Image.

## 7. Lokaler Ablauf mit OrbStack

Ziel: lokalen Stack validieren, bevor Produktion beruehrt wird.

### 7.1 Umgebung vorbereiten

```bash
cd /Users/activi/Documents/Matrix
cp .env.example .env
chmod 600 .env
```

Dann `.env` ausfuellen. Pflicht:

- `ACME_EMAIL`.
- `DB_PASSWORD`.
- `REGISTRATION_SHARED_SECRET`.
- `TURN_PASSWORD`.
- `SYNAPSE_ADMIN_BASIC_AUTH_USERS`.
- `TRAEFIK_DASHBOARD_BASIC_AUTH_USERS`.
- lokale URLs koennen auf Defaults bleiben.

### 7.2 Runtime-Konfiguration rendern

```bash
./scripts/render-config.sh
```

Erwartung:

```text
Rendered Matrix config from .env
```

Danach muessen existieren:

- `element-config.json`.
- `element-config.local.json`.
- `ketesa-config.json`.
- `ketesa-config.local.json`.
- `traefik/dynamic.yml`.
- `traefik/dynamic.local.yml`.
- `synapse-data/homeserver.yaml`.
- `synapse-data/homeserver.local.yaml`.

### 7.3 Compose validieren

```bash
docker compose -f docker-compose.yml -f docker-compose.orbstack.yml config >/tmp/matrix-compose.yml
docker compose --profile hermes config >/tmp/matrix-compose-hermes.yml
```

Erwartung: beide Befehle beenden mit Exitcode `0`.

### 7.4 Images installieren

Nur listen:

```bash
./scripts/install-images.sh all list
```

Alle fuer lokal benoetigten Images ziehen und Projekt-Tags setzen:

```bash
./scripts/install-images.sh all pull-and-tag
```

Wenn nur Core benoetigt wird:

```bash
./scripts/install-images.sh core pull-and-tag
```

### 7.5 Core Stack starten

```bash
docker compose -f docker-compose.yml -f docker-compose.orbstack.yml up -d
docker compose -f docker-compose.yml -f docker-compose.orbstack.yml ps
```

Erwartung:

- `traefik` laeuft.
- `db` ist healthy.
- `synapse` ist healthy.
- `element` laeuft.
- `element-admin` laeuft.
- `ketesa` laeuft.
- `coturn` laeuft.
- `mailpit` laeuft.

### 7.6 Admin User erzeugen

Wenn der geplante Admin noch nicht existiert:

```bash
docker compose -f docker-compose.yml -f docker-compose.orbstack.yml exec synapse \
  register_new_matrix_user \
  -c /data/homeserver.local.yaml \
  http://localhost:8008 \
  --admin
```

Eingaben:

- Username: Wert aus `MATRIX_ADMIN_USER`, z.B. `activi`.
- Password: Wert aus `MATRIX_ADMIN_PASSWORD`.
- Admin: `yes`.

Der erwartete Admin User ist `@activi:matrix.activi.io`.

### 7.7 Lokalen Healthcheck ausfuehren

```bash
./scripts/healthcheck.sh
```

Erwartung:

- `FAIL: 0`.
- Element Config erreichbar.
- Matrix Client API erreichbar.
- Ketesa Config erreichbar.
- Synapse Admin API erreichbar.
- Mailpit UI erreichbar.
- Postgres akzeptiert Verbindungen.

### 7.8 Vollstaendigen lokalen Audit ausfuehren

```bash
./scripts/predeploy-audit.sh
```

Erwartung:

- `Predeploy result: PASS`.
- Keine FAIL-Zeile.

Der Audit prueft:

- Tooling.
- Compose.
- statische Konfiguration.
- Containerstatus.
- HTTP Surface.
- Admin Login.
- Admin-Rechte.
- Erstellen eines wegwerfbaren Testusers.
- Login des Testusers.
- TURN Advertisement.
- Raum-Erstellung.
- Nachricht senden.
- Space-Erstellung.
- Media Upload.
- SMTP zu Mailpit.
- Backup.
- Restore-Check.

Wenn `predeploy-audit.sh` fehlschlaegt, nicht deployen.

## 8. Produktionsablauf mit Docker Compose

Ziel: reproduzierbarer Server-Deploy ohne lokale Mac-spezifische Annahmen.

### 8.1 Server vorbereiten

Installieren:

- Docker Engine.
- Docker Compose v2.
- Git.
- OpenSSL.

Firewall oeffnen:

- TCP `80`.
- TCP `443`.
- TCP `3478`.
- UDP `3478`.
- Optional TCP `5349`.

Pruefen:

```bash
docker info
docker compose version
git --version
openssl version
```

### 8.2 Repository klonen

```bash
git clone https://github.com/dsactivi-2/matrix-stack.git
cd matrix-stack
```

Wenn dieses Repository nicht der echte Remote-Name ist, den korrekten Remote aus
dem Projektkontext verwenden. Nach dem Klonen muss `docker-compose.yml` im
aktuellen Verzeichnis liegen.

### 8.3 Produktions-`.env` erstellen

```bash
cp deploy/server.env.example .env
chmod 600 .env
```

Danach `.env` editieren und jeden Platzhalter ersetzen:

- keine `CHANGE_ME`.
- keine `REPLACE_WITH`.
- kein `OWNER_OR_ORG`.
- keine Beispiel-Domain ausser sie ist absichtlich.
- `SERVER_PUBLIC_IP` ist die echte Server-IP.
- `REGISTRY_PREFIX=ghcr.io/dsactivi-2/matrix`.

Secrets erzeugen:

```bash
openssl rand -base64 48
```

Fuer jeden Secret-Wert einzeln ausfuehren. Nicht denselben Wert fuer
`DB_PASSWORD`, `REGISTRATION_SHARED_SECRET`, `TURN_PASSWORD` und Admin-Passwort
wiederverwenden.

Basic Auth Hashes erzeugen:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'REPLACE_WITH_ADMIN_PASSWORD'
```

Hash in `.env` eintragen und `$` als `$$` escapen.

### 8.4 Synapse Signing Key entscheiden

Fall A: bestehende Matrix-Identitaet soll uebernommen werden.

```text
synapse-data/homeserver.signing.key
```

Diese Datei sicher auf den Server nach `synapse-data/homeserver.signing.key`
kopieren. Rechte restriktiv setzen.

Fall B: komplett neue Matrix-Identitaet ist erlaubt.

`ALLOW_NEW_SIGNING_KEY=1` darf nur bewusst gesetzt werden. Danach gehoert die
neu erzeugte Key dauerhaft zu dieser Serveridentitaet und muss gesichert werden.

Niemals aus Versehen eine neue Signing Key fuer eine bestehende Produktion
erzeugen.

### 8.5 Server-Preflight ausfuehren

```bash
./scripts/server-prepare.sh
```

Erwartung:

- Required environment variables are present.
- No placeholder values detected.
- SERVER_PUBLIC_IP is not a local placeholder.
- Open registration disabled.
- Federation listener disabled.
- Synapse signing key present oder bewusst erlaubte neue Identitaet.
- Runtime config rendered.
- Rendered config has no placeholders.
- Compose config resolves.
- All referenced images provide `linux/amd64` and `linux/arm64`.

Wenn Signing Key bewusst neu erzeugt werden darf:

```bash
ALLOW_NEW_SIGNING_KEY=1 ./scripts/server-prepare.sh
```

Nur in Fall B verwenden.

### 8.6 Images ziehen

```bash
docker compose pull
```

Erwartung:

- Alle Images werden gezogen oder sind bereits vorhanden.
- Kein Auth-Fehler gegen GHCR.
- Kein fehlendes Manifest fuer Server-Architektur.

Wenn GHCR private Packages verwendet werden, vorher einloggen:

```bash
docker login ghcr.io
```

### 8.7 Core Stack starten

```bash
docker compose up -d
docker compose ps
```

Nicht verwenden:

```bash
docker compose -f docker-compose.yml -f docker-compose.orbstack.yml up -d
```

Erwartung:

- `db` wird healthy.
- `synapse-permissions` beendet erfolgreich.
- `synapse` wird healthy.
- `traefik`, `element`, `element-admin`, `ketesa`, `coturn` laufen.

Logs bei Problemen:

```bash
docker compose logs --tail=200 db
docker compose logs --tail=200 synapse
docker compose logs --tail=200 traefik
docker compose logs --tail=200 element
docker compose logs --tail=200 ketesa
docker compose logs --tail=200 coturn
```

### 8.8 DNS setzen

Cloudflare oder DNS Provider:

| Type | Name | Ziel | Proxy |
| --- | --- | --- | --- |
| A | `matrix` | `SERVER_PUBLIC_IP` | DNS only zuerst |
| A | `space` | `SERVER_PUBLIC_IP` | DNS only zuerst |
| A | `admin.matrix` | `SERVER_PUBLIC_IP` | DNS only zuerst |
| A | `synapse-admin` | `SERVER_PUBLIC_IP` | DNS only zuerst |
| A | `traefik` | `SERVER_PUBLIC_IP` | DNS only zuerst |

Pruefen:

```bash
dig +short matrix.activi.io
dig +short space.activi.io
dig +short admin.matrix.activi.io
dig +short synapse-admin.activi.io
dig +short traefik.activi.io
curl -I http://matrix.activi.io
```

Erwartung:

- Jede Domain zeigt auf `SERVER_PUBLIC_IP`.
- HTTP Port `80` erreicht Traefik.
- Nach DNS-Propagation stellt Let's Encrypt Zertifikate aus.

Cloudflare Proxy erst aktivieren, wenn Let's Encrypt und direkter Zugriff
funktionieren.

### 8.9 Produktionsadmin erstellen

Wenn Admin noch nicht existiert:

```bash
docker compose exec synapse register_new_matrix_user \
  -c /data/homeserver.yaml \
  http://localhost:8008 \
  --admin
```

Eingaben:

- Username: `MATRIX_ADMIN_USER`.
- Password: `MATRIX_ADMIN_PASSWORD`.
- Admin: `yes`.

Danach login ueber Element testen.

### 8.10 Produktionsaudit

Fuer remote Produktion kann `predeploy-audit.sh` nicht unveraendert alle lokalen
OrbStack-Pfade pruefen. Nutze zuerst HTTP/API-Pruefungen manuell:

```bash
curl -fsS https://matrix.activi.io/_matrix/client/versions
curl -fsS https://matrix.activi.io/.well-known/matrix/client
curl -I https://space.activi.io/config.json
curl -I https://synapse-admin.activi.io/config.json
curl -I https://traefik.activi.io
```

Erwartung:

- Matrix Client Versions liefert JSON mit `versions`.
- Element Config liefert HTTP `200`.
- Ketesa Config liefert HTTP `200`.
- Traefik Dashboard ohne Auth liefert `401 Unauthorized`.

Synapse Admin API muss zusaetzlich durch Basic Auth geschuetzt sein:

```bash
curl -I https://matrix.activi.io/_synapse/admin/v1/server_version
```

Erwartung ohne Auth:

- `401 Unauthorized` oder blockiert durch Admin Middleware.

### 8.11 Backup direkt nach Erststart

Vor echten Nutzern:

```bash
./scripts/backup.sh
./scripts/restore-check.sh
```

Erwartung:

- Backup-Verzeichnis unter `backups/<timestamp>`.
- `postgres-synapse.sql` lesbar.
- `config-and-secrets.tgz` lesbar.
- `synapse-media.tgz` lesbar.
- `traefik-acme.tgz` lesbar.
- Restore-Check beendet ohne Fehler.

Danach Backup verschluesselt off-server kopieren.

### 8.12 Hermes-Agenten spaeter aktivieren

Erst wenn Core stabil ist:

```bash
docker compose --profile hermes up -d sena activi
docker compose --profile hermes ps
```

Vorher muessen in `.env` echte Werte existieren:

- `SENA_MATRIX_USER_ID`.
- `SENA_MATRIX_ACCESS_TOKEN`.
- `SENA_MATRIX_ALLOWED_USERS`.
- `ACTIVI_MATRIX_USER_ID`.
- `ACTIVI_MATRIX_ACCESS_TOKEN`.
- `ACTIVI_MATRIX_ALLOWED_USERS`.
- LLM Provider API Keys, falls Hermes diese im jeweiligen Runtime-Kontext
  benoetigt.

Hermes darf nicht gestartet werden, wenn Tokens auf `CHANGE_ME...` stehen.

## 9. K3s/Longhorn Ablauf

Nur verwenden, wenn Ziel nicht Docker Compose, sondern K3s + Longhorn ist.

### 9.1 Voraussetzungen pruefen

```bash
kubectl get nodes
kubectl get storageclass longhorn
kubectl get ingressclass nginx
kubectl get clusterissuer letsencrypt-prod
```

Erwartung:

- Nodes sind Ready.
- StorageClass `longhorn` existiert.
- IngressClass `nginx` existiert.
- ClusterIssuer `letsencrypt-prod` ist Ready.

### 9.2 Preflight ohne Clusterzugriff

```bash
./scripts/k3s-longhorn-preflight.sh
```

Mit Read-Only Clusterchecks:

```bash
RUN_CLUSTER_CHECKS=1 ./scripts/k3s-longhorn-preflight.sh
```

### 9.3 Namespace und Secrets anlegen

```bash
kubectl create namespace matrix
cp k8s/examples/matrix-stack-secret.example.yaml /tmp/matrix-stack-secret.yaml
vi /tmp/matrix-stack-secret.yaml
kubectl apply -f /tmp/matrix-stack-secret.yaml
```

In `/tmp/matrix-stack-secret.yaml` ersetzen:

- `db-password`.
- `matrix-admin-password`.
- `registration-shared-secret`.
- `smtp-user`.
- `smtp-password`.
- `turn-password`.
- `homeserver.signing.key`.

Die `homeserver.signing.key` muss bei bestehender Identitaet die vorhandene Key
sein.

### 9.4 GHCR Pull Secret anlegen

```bash
cp k8s/examples/ghcr-pull-secret.example.sh /tmp/ghcr-pull-secret.sh
vi /tmp/ghcr-pull-secret.sh
bash /tmp/ghcr-pull-secret.sh
```

Werte ersetzen:

- `CHANGE_ME_GITHUB_USERNAME`.
- `CHANGE_ME_GHCR_READ_TOKEN`.

### 9.5 Helm installieren

```bash
helm upgrade --install matrix ./helm/matrix-stack \
  --namespace matrix \
  --create-namespace \
  -f helm/matrix-stack/values-k3s-longhorn.yaml
```

### 9.6 K3s verifizieren

```bash
kubectl get pods,pvc,ingress -n matrix
kubectl rollout status statefulset/matrix-matrix-stack-postgres -n matrix
kubectl rollout status statefulset/matrix-matrix-stack-synapse -n matrix
kubectl logs -n matrix statefulset/matrix-matrix-stack-synapse --tail=100
```

Erwartung:

- Pods laufen.
- PVCs sind Bound.
- Ingress existiert.
- Synapse startet ohne Signing-Key- oder DB-Fehler.

## 10. Image-Registry Ablauf

Nur ausfuehren, wenn Images neu gespiegelt oder geprueft werden muessen.

Image-Mapping anzeigen:

```bash
./scripts/install-images.sh all list
```

Lokal ziehen und taggen:

```bash
./scripts/install-images.sh all pull-and-tag
```

Projekt-Tags pushen:

```bash
./scripts/install-images.sh core push
```

Multi-Arch Mirror verwenden:

```bash
./scripts/push-ghcr-multiarch.sh
```

Plattformen pruefen:

```bash
./scripts/check-image-platforms.sh
```

Erwartung:

```text
All stack images provide linux/amd64 and linux/arm64.
```

Wenn ein Image keine Zielplattform hat, nicht auf ARM/AMD64 gemischt deployen,
bis das Manifest korrigiert ist.

## 11. Backup- und Restore-Regeln

Backup erstellen:

```bash
./scripts/backup.sh
```

Backup pruefen:

```bash
./scripts/restore-check.sh
```

Bestimmtes Backup pruefen:

```bash
./scripts/restore-check.sh backups/YYYYMMDD-HHMMSS
```

Backup-Inhalte:

- Postgres SQL Dump.
- `.env`.
- Compose-Dateien.
- Templates.
- Agent-Kontext.
- Element/Ketesa Config.
- Traefik Config.
- Synapse Config.
- Synapse Signing Key.
- Synapse Media Volume.
- Traefik ACME Volume.

Regeln:

- Backup enthaelt Secrets.
- Backup nicht in Git.
- Backup verschluesselt off-server speichern.
- Restore-Prozess erst an Kopie testen, nicht direkt auf Produktion.

## 12. Sicherheits- und Betriebsfallen

### Synapse Admin API

`/_synapse/admin/...` darf nicht anonym oeffentlich erreichbar sein. Die
Traefik Middleware `synapse-admin-auth` muss greifen. Erwartetes Verhalten ohne
Basic Auth:

```text
401 Unauthorized
```

### Traefik Dashboard

Dashboard nur mit Basic Auth. Erwartetes Verhalten ohne Basic Auth:

```text
401 Unauthorized
```

### Federation

Erster Deploy bleibt private island:

```env
SYNAPSE_LISTENER_RESOURCES=client
```

Federation erst spaeter aktivieren, wenn DNS, TLS, Moderation,
Abuse-Handling, Well-Known und Betriebskonzept explizit fertig sind.

### Registrierung

Offene Registrierung bleibt aus:

```env
SYNAPSE_ENABLE_REGISTRATION=false
```

Benutzer werden durch Admins angelegt.

### TURN

Voice/Video braucht erreichbares TURN:

- TCP/UDP `3478` offen.
- `TURN_HOST` korrekt.
- Synapse liefert TURN ueber `/voip/turnServer`.
- NAT/Firewall darf UDP nicht blockieren.

### SMTP

Passwort-Reset und Benachrichtigungen brauchen SMTP:

- Lokal: Mailpit.
- Produktion: echter SMTP Provider.
- `SMTP_REQUIRE_TLS=true` in Produktion.

### Cloudflare

Fuer Erstzertifikate:

- DNS only verwenden.
- Proxy erst aktivieren, wenn Let's Encrypt erfolgreich war.
- Bei Proxybetrieb WebSocket/Matrix Sync testen.

## 13. Fehlerbehebung

### Compose config scheitert

```bash
docker compose config
```

Pruefen:

- `.env` Syntax.
- nicht escaped `$` in Basic Auth Hashes.
- fehlende Pflichtvariablen.
- falsche Anfuehrungszeichen.

### Synapse startet nicht

```bash
docker compose logs --tail=300 synapse
docker compose logs --tail=300 db
```

Pruefen:

- `DB_PASSWORD` stimmt mit Postgres Volume/Initialisierung ueberein.
- `synapse-data/homeserver.yaml` wurde gerendert.
- Signing Key vorhanden.
- Postgres ist healthy.

### Let's Encrypt scheitert

```bash
docker compose logs --tail=300 traefik
curl -I http://matrix.activi.io
```

Pruefen:

- DNS zeigt auf Server.
- Port `80` ist offen.
- Cloudflare Proxy ist fuer Erstsetup aus.
- `ACME_EMAIL` gesetzt.

### Element zeigt falschen Homeserver

```bash
curl -fsS http://127.0.0.1:8081/config.json
curl -fsS https://space.activi.io/config.json
```

Pruefen:

- `element-config*.json` neu gerendert.
- `MATRIX_HOMESERVER_URL` korrekt.
- Lokaler Override nutzt `element-config.local.json`.

### Ketesa Login scheitert

Pruefen:

- Admin User existiert.
- Admin Passwort stimmt.
- Ketesa Config zeigt auf korrekten Homeserver.
- Admin API Route ist erreichbar.
- Basic Auth ist korrekt gesetzt, wenn ueber Produktionsdomain.

### Backup scheitert

```bash
docker compose ps
docker compose logs --tail=100 db
./scripts/backup.sh
```

Pruefen:

- `db` laeuft.
- `synapse` Container existiert.
- `traefik` Container existiert.
- Schreibrechte auf `backups/`.

## 14. Abnahme-Checkliste fuer einen ausfuehrenden Agenten

Ein Deployment gilt erst als abgeschlossen, wenn alle Punkte wahr sind:

- `.env` existiert und enthaelt keine Placeholder.
- `.env` ist nicht in Git.
- Synapse Signing Key ist bewusst vorhanden oder bewusst neu erzeugt.
- `./scripts/server-prepare.sh` besteht auf dem Server.
- `docker compose config` besteht.
- `docker compose up -d` startet Core Services.
- `docker compose ps` zeigt keine unerwarteten Exits.
- DNS zeigt auf die korrekte Server-IP.
- HTTPS Zertifikate sind ausgestellt.
- `https://matrix.activi.io/_matrix/client/versions` liefert JSON.
- `https://space.activi.io/config.json` liefert Element Config.
- Ketesa ist erreichbar.
- Traefik Dashboard ist ohne Basic Auth nicht erreichbar.
- Synapse Admin API ist ohne Basic Auth nicht erreichbar.
- Admin User kann sich anmelden.
- Testnachricht in einem privaten Raum funktioniert.
- Media Upload funktioniert.
- SMTP ist getestet.
- TURN wird von Synapse an Clients ausgeliefert.
- Backup wurde erstellt.
- Restore-Check des Backups besteht.
- Off-server Backup ist abgelegt.
- Hermes-Agenten sind entweder bewusst deaktiviert oder erst nach Core-Abnahme
  mit echten Tokens aktiviert.

Wenn einer dieser Punkte fehlschlaegt, ist das Deployment nicht fertig.

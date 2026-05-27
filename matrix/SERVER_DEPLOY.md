# Server Deploy Checklist

This checklist prepares the production server without committing secrets or runtime state.

## 1. Server Prerequisites

Install Docker with Compose v2 on the server. Open these inbound ports:

- `80/tcp` for Let's Encrypt HTTP challenge and HTTP redirect
- `443/tcp` for HTTPS
- `3478/tcp` and `3478/udp` for TURN
- `5349/tcp` only if TLS TURN is added later

Do not start the Hermes profile during the first deploy.

## 2. Clone The Stack

```bash
git clone https://github.com/dsactivi-2/matrix-stack.git
cd matrix-stack
```

## 3. Create The Server `.env`

```bash
cp deploy/server.env.example .env
chmod 600 .env
```

Edit `.env` on the server and replace every `CHANGE_ME...` value.

Important values:

- `SERVER_PUBLIC_IP`
- `DB_PASSWORD`
- `REGISTRATION_SHARED_SECRET`
- `TURN_PASSWORD`
- SMTP credentials
- `SYNAPSE_ADMIN_BASIC_AUTH_USERS`
- `TRAEFIK_DASHBOARD_BASIC_AUTH_USERS`
- `MATRIX_ADMIN_PASSWORD`

Generate strong random secrets on the server:

```bash
openssl rand -base64 48
```

Generate Basic Auth hashes on the server:

```bash
docker run --rm httpd:2.4-alpine htpasswd -nbB admin 'REPLACE_WITH_ADMIN_PASSWORD'
```

Escape `$` as `$$` before putting the hash into `.env`.

## 4. Preserve Or Create The Synapse Signing Key

If this production server must keep the same Matrix identity as the local setup, copy this file securely to the server before starting Synapse:

```text
synapse-data/homeserver.signing.key
```

If this is a clean first production identity, Synapse can generate a new key on first start. Keep that generated key forever and include it in encrypted backups.

## 5. Prepare Runtime Config

```bash
./scripts/server-prepare.sh
```

This checks for placeholders, renders config files, validates Compose, and verifies that all referenced images provide `linux/amd64` and `linux/arm64`.

## 6. Start Core Stack

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Do not use `docker-compose.orbstack.yml` on the server.

## 7. DNS

After the server IP is final, point these records to `SERVER_PUBLIC_IP`:

- `matrix.activi.io`
- `space.activi.io`
- `admin.matrix.activi.io`
- `synapse-admin.activi.io`
- `traefik.activi.io`

Wait for DNS to resolve before expecting Let's Encrypt to succeed.

## 8. First Production Audit

After DNS and TLS are live:

```bash
./scripts/predeploy-audit.sh
```

For a remote production run, set the public URLs in `.env` and keep `COMPOSE_FILES=docker-compose.yml`.

## 9. Backup

Before creating real users:

```bash
./scripts/backup.sh
./scripts/restore-check.sh
```

Then move encrypted backups to off-server storage.

## 10. Later Add-Ons

Only after Matrix, Element, SMTP, TURN, DNS, TLS, and backups are verified:

```bash
docker compose --profile hermes up -d sena activi
```

The Hermes agent tokens must exist in `.env` before enabling this profile.

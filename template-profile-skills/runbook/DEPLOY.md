# DEPLOY — Deployment-Prozedur

## Pre-Deployment Checkliste

- [ ] Backup vorhanden (jünger als 24h)
- [ ] Preflight-Check durchgelaufen
- [ ] Änderungen committet und gepusht
- [ ] Policy-Level bekannt
- [ ] Wartungsfenster (Mi 02-04 UTC) eingehalten — oder Approval für Ausserhalb

## Deploy: Hermes-Profil

```bash
# 1. Config setzen
hermes -p <profil> config set model.default <modell>

# 2. API-Key setzen (falls nötig)
cat >> ~/.hermes/profiles/<profil>/.env << 'EOF'
KEY=VALUE
EOF

# 3. Gateway neustarten (falls aktiv)
hermes -p <profil> gateway restart
```

## Deploy: OpenClaw

```bash
# 1. Container starten
docker compose -f /opt/openclaw/docker-compose.yml up -d

# 2. Slot konfigurieren
openclaw slot set <agent-name>

# 3. Status prüfen
docker ps | grep openclaw
```

## Deploy: k3s

```bash
# 1. Manifest apply
kubectl apply -f k8s/<namespace>/<manifest>.yaml

# 2. Rollout überwachen
kubectl rollout status deployment/<name> -n <namespace>

# 3. Pods prüfen
kubectl get pods -n <namespace>
```

## Post-Deployment Healthcheck

```bash
# Profile
hermes -p <profil> config | grep "Model"

# Services
curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>

# Docker
docker ps --format "table {{.Names}}\t{{.Status}}" | grep <service>

# k3s
kubectl get pods -n <namespace> --field-selector=status.phase!=Running
```
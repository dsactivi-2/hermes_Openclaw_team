# dograh K3s Deploy Runbook

Status: Deployed in namespace `moneymaker`.

## Live pre-checks (read-only)

- Namespace `moneymaker` exists (observed via `kubectl get ns moneymaker`).
- Namespace inventory showed only `configmap/kube-root-ca.crt` at time of check.
- No dograh/postgres/redis/minio resources were found by name/grep in `moneymaker` at time of check.
- DNS resolves:
  - `mm.activi-apps.io -> 88.99.215.210` (confirmed via `dig` and server-side host lookup).
  - `minio-mm.activi-apps.io -> 88.99.215.210` (configured for the MinIO Console).

## Post-deploy notes (important)

- `DATABASE_URL` must use the async SQLAlchemy driver format:
  - required: `postgresql+asyncpg://...`
  - not compatible: `postgresql://...` (caused Dograh API CrashLoopBackOff due to missing `psycopg2`)
- The runtime fix was applied by updating `secret/dograh-app-secrets` key `DATABASE_URL` in namespace `moneymaker`.
  - No secret values are recorded here.

## Hard pre-deploy blockers

- GHCR pull secret:
  - Dograh draft manifests assume a namespace-local `imagePullSecret` named `ghcr-pull-secret` in namespace `moneymaker`.
  - The existing `ghcr-pull-secret` in namespace `matrix` does not apply to `moneymaker`.
  - No secret is created by this agent; it must be created in a separate approved block.
- pgvector availability:
  - The CNPG Postgres image in the draft is set to the same digest used by `manifests/hindsight/05-cnpg-cluster.yaml`.
  - The repo notes that `pgvector` was verified in that pinned image (`manifests/hindsight/README.md`).
  - Server-side dry-run does not validate extension availability at runtime; production deploy must still verify `CREATE EXTENSION vector` succeeds.

## Target V1 architecture

- Namespace: `moneymaker`
- UI:
  - Deployment `dograh-ui`
  - Service `dograh-ui` (ClusterIP, port 3010)
- API:
  - Deployment `dograh-api`
  - Service `dograh-api` (ClusterIP, port 8000)
- Ingress (`nginx` IngressClass):
  - Host: `mm.activi-apps.io`
  - `/` -> `dograh-ui`
  - `/api` -> `dograh-api`
  - TLS via cert-manager ClusterIssuer `letsencrypt-prod`
- Postgres:
  - CloudNativePG Cluster `dograh-postgres` (3 instances)
  - pgvector enabled via `postInitApplicationSQL: CREATE EXTENSION vector`
- Redis:
  - Single-node Deployment (no PVC in V1)
- Object storage:
  - MinIO Service exposes internal S3 API on `:9000` and Console on `:9001`
  - S3 API remains internal for Dograh runtime use
  - Console is exposed via `https://minio-mm.activi-apps.io`
  - Longhorn PVC via StatefulSet volumeClaimTemplate

## MinIO Console

- Host: `minio-mm.activi-apps.io`
- Ingress: `dograh-minio-console`
- TLS Secret: `dograh-minio-console-tls`
- Certificate status after deploy: `Ready=True`
- Backend service: `dograh-minio`
- Backend port: `console` / `9001`
- External test: `https://minio-mm.activi-apps.io` returns `HTTP/2 200`
- The S3 API port `9000` is not exposed publicly by this ingress.

## Manifests

Directory:

`/Users/activi/Documents/activi K3s/manifests/dograh/`

## ENV / Secrets matrix (no values)

### ConfigMap keys (`dograh-api-config`)

Non-secret values:

- `ENVIRONMENT`
- `DEPLOYMENT_MODE`
- `AUTH_PROVIDER`
- `FASTAPI_WORKERS`
- `ENABLE_TELEMETRY`
- `MINIO_BUCKET`
- `MINIO_SECURE`
- `MINIO_ENDPOINT`
- `MINIO_PUBLIC_ENDPOINT`
- `BACKEND_API_ENDPOINT`
- `UI_APP_URL`

### Secret keys (schema only)

Secret `dograh-app-secrets`:

- `DATABASE_URL`
- `REDIS_URL`
- `OSS_JWT_SECRET`
- `NEXTAUTH_SECRET`
- `AUTH_SECRET`
- `MINIO_ACCESS_KEY`
- `MINIO_SECRET_KEY`

Note:

- The Dograh API draft sets both `MINIO_ACCESS_KEY`/`MINIO_SECRET_KEY` and also maps
  `MINIO_ROOT_USER`/`MINIO_ROOT_PASSWORD` from the same stored values to remain
  compatible with the reference `compose.yaml` env naming.

Secret `dograh-postgres-app`:

- `username`
- `password`

Secret `dograh-redis-secret`:

- `REDIS_PASSWORD`

## Storage

- CNPG storageClass: `longhorn`
- MinIO PVC storageClass: `longhorn`

## Backup requirements

Unclear: No app-specific backup policy has been validated for dograh yet.

TODO (after V1 deploy approval and verification):

- Decide CNPG backup (Barman plugin/ObjectStore) and/or logical dumps.
- Decide Longhorn recurring jobs group for dograh PVCs.

## n8n (later block)

No changes performed to n8n.

Known endpoints:

- internal: `http://n8n.n8n.svc.cluster.local:5678`
- public: `https://n8n-mm.activi-apps.io`

Unclear: dograh-to-n8n integration method and required credential keys are not proven from the provided Compose file.

## Telnyx (later block)

No Telnyx changes performed.

Unclear: dograh Telnyx environment variables/credential keys are not proven from the provided Compose file.

## Redis risk (V1)

- V1 draft runs Redis without a PVC.
- Risk: Redis state is not durable across pod restarts.
- Acceptable only if Dograh uses Redis as cache/session/ephemeral queue and can tolerate data loss.
- If durability is required: switch to a StatefulSet with a Longhorn PVC in a later approved block.

## Restore-Test Plan (draft)

No restore action has been executed.

### Postgres (CNPG) restore test

- Plan: create a temporary CNPG restore cluster in a test namespace, restore the latest backup, and verify:
  - cluster becomes healthy
  - `pgvector` extension exists
  - table counts are non-zero

### MinIO / Longhorn restore test

- Plan: restore the MinIO Longhorn volume from backup/snapshot into a temporary namespace and verify the MinIO pod can start.

### Velero namespace restore test

- Plan: restore namespace `moneymaker` into a separate restore namespace (e.g. `moneymaker-restore-test-YYYYMMDD`) and verify expected resources appear without touching production.

## Storage decision (current)

- MinIO in K3s remains the runtime storage for Dograh binary/audio for now.
- External Object Storage migration is a separate later block (not part of this change).

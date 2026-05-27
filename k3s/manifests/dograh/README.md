# Dograh K3s Draft Manifests

Status: deployed in namespace `moneymaker` (V1).

Scope (V1):

- dograh API + UI
- CloudNativePG Postgres (pgvector enabled)
- Redis (no PVC in V1)
- MinIO (S3 API internal; Console exposed separately)
- Ingress host `mm.activi-apps.io` with:
  - `/` -> UI
  - `/api` -> API
- MinIO Console host `minio-mm.activi-apps.io` routes to MinIO Console only.
  The S3 API remains internal on `dograh-minio:9000`.

Non-goals (V1):

- coturn, nginx, cloudflared
- inspector, loki/promtail/grafana, sdk
- seed-templates job (can be added later as an explicit job)

Files:

- `01-configmap-api.yaml`: non-secret API config.
- `02-secret-schema.example.yaml`: secret key schema (no real values).
- `03-cnpg-cluster.yaml`: CNPG cluster with `CREATE EXTENSION vector`.
- `04-redis.yaml`: Redis Deployment + Service (ClusterIP).
- `05-minio.yaml`: MinIO StatefulSet + Service + Longhorn PVC.
- `06-api.yaml`: dograh-api Deployment + Service (ClusterIP).
- `07-ui.yaml`: dograh-ui Deployment + Service (ClusterIP).
- `08-ingress.yaml`: Ingress for `mm.activi-apps.io` routing `/` and `/api`.
- `09-pdb.yaml`: optional PDBs (currently allow disruptions).
- `10-minio-console-ingress.yaml`: Ingress for the MinIO Console at
  `minio-mm.activi-apps.io`.

Post-deploy note:

- Dograh API requires `DATABASE_URL` in `postgresql+asyncpg://...` format (not `postgresql://...`).
- MinIO Console is reachable at `https://minio-mm.activi-apps.io`.
- MinIO Console certificate `dograh-minio-console-tls` is `Ready=True`.
- The public MinIO route exposes only service port `console:9001`; S3 port
  `s3:9000` stays internal for Dograh runtime use.

Backup/Ops drafts:

- `/Users/activi/Documents/activi K3s/manifests/dograh/backup/` contains draft-only manifests for Longhorn recurring jobs, Velero schedules, and CNPG backup components.

# Hindsight K3s Draft Manifests

Status: deployed and verified; public dashboard ingress enabled.

These manifests define a fresh Hindsight V1 installation for the activi K3s
cluster. They intentionally do not migrate from Server-1 Docker Hindsight.
Local Mac Hindsight is the primary future migration source. Server-1 data is
only an optional late-stage migration source after separate verification.

## Stop Points

- No file in this directory contains real secret values.
- `03-secret-schema.example.yaml` is only a schema.
- Hindsight, UI, Ollama, curl, pg_dump helper and CNPG/Postgres images are
  digest-pinned in this draft.
- PostgreSQL uses CloudNativePG; old single-pod Postgres manifests are not the
  target.
- `pgvector` was verified in the pinned CloudNativePG Postgres image by
  checking for `vector.control`.
- Auto-retain is verified for the fresh internal install, but production imports
  still require secret redaction and tag governance hardening.
- Public dashboard ingress for `hindsight.activi.io` is enabled. It routes to
  the Hindsight control-plane UI service. The API service remains internal.

## Files

- `00-namespace.yaml`: Namespace `hindsight`.
- `01-resource-policy.yaml`: Initial ResourceQuota and LimitRange draft.
- `02-configmap.yaml`: Non-secret Hindsight runtime configuration.
- `03-secret-schema.example.yaml`: Required secret keys without values.
- `04-cnpg-objectstore.yaml`: Barman Cloud ObjectStore draft for S3 backups.
- `05-cnpg-cluster.yaml`: CloudNativePG cluster draft with pgvector init.
- `06-cnpg-scheduled-backup.yaml`: Scheduled physical backup via Barman plugin.
- `07-api-deployment.yaml`: Hindsight API deployment draft.
- `08-worker-deployment.yaml`: Hindsight worker deployment draft.
- `09-ui-deployment.yaml`: Internal Hindsight Control Plane dashboard draft.
- `10-services.yaml`: ClusterIP services only.
- `11-pgdump-cronjob.template.yaml`: Active logical dump CronJob template.
- `12-velero-schedule.yaml`: Velero namespace schedule draft.
- `13-networkpolicy.yaml`: Default-deny plus expected internal paths.
- `14-podmonitor.yaml`: Prometheus PodMonitors for API, worker and CNPG.
- `15-prometheus-rule.yaml`: Initial Hindsight alert rules.
- `16-longhorn-recurringjobs.yaml`: Dedicated Longhorn recurring job group.
- `17-groq-healthcheck-cronjob.template.yaml`: Active Groq API healthcheck
  CronJob template.
- `18-ollama.yaml`: Internal Ollama service for `bge-m3` embeddings.
- `19-ollama-pull-bge-m3-job.template.yaml`: Model pull job template for
  `bge-m3`, run after Ollama is deployed.
- `20-ingress.yaml`: Public nginx/cert-manager ingress for the Hindsight UI
  dashboard at `https://hindsight.activi.io`.
- `21-pgdump-restore-test-job.template.yaml`: One-shot restore-test job for
  the latest logical dump object.

## Verified State

- Hindsight API, worker, UI and Ollama are deployed internally in namespace
  `hindsight`.
- CloudNativePG PostgreSQL is healthy with three instances.
- `bge-m3` is loaded in the internal Ollama service.
- pg_dump CronJob has completed manual and scheduled runs.
- pg_dump restore-test has verified SHA256 and gzip readability.
- Groq healthcheck CronJob has completed manual and scheduled runs.
- Retain/Recall smoke test passed against a dedicated test bank.
- Public UI ingress `hindsight.activi.io` is live with certificate
  `hindsight-tls` `Ready=True`.
- `https://hindsight.activi.io/` redirects to `/dashboard`; `/dashboard`
  returns `HTTP 200`.
- Baseline gates passed after deployment.

## Next Safe Order

1. Finalize Alertmanager routing/notifications for Hindsight, Groq and backups.
2. Harden secret redaction and tag governance before production imports.
3. Implement bank mapping to `project:<name>`.
4. Import Mental Models and Directives.
5. Inventory local Mac Hindsight read-only, then plan migration.
6. Treat Server-1 Docker Hindsight only as optional late migration source.

Helper scripts:

- `/Users/activi/Documents/activi K3s/run-hindsight-deploy-gate.sh`:
  read-only deploy gate.
- `/Users/activi/Documents/activi K3s/prepare-hindsight-secrets.sh`:
  guarded secret creation/update helper. It does nothing unless
  `HINDSIGHT_SECRET_APPROVED=yes` is set and required values are provided via
  environment variables.
- `/Users/activi/Documents/activi K3s/prepare-hindsight-secrets-from-server-s3.sh`:
  guarded helper for the current cluster. It sources S3 credentials on `k3-1`
  from `/etc/k3s-backup/s3.env` and prompts locally for the Groq key if the
  key is not provided through `GROQ_API_KEY`.

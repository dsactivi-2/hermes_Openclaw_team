# n8n MoneyMaker Manifests

Status: bootstrap deployment

These manifests deploy the first n8n stage for `n8n-mm.activi-apps.com`.

Bootstrap stage:

- Single n8n main instance.
- CloudNativePG PostgreSQL with 3 instances.
- Longhorn PVC for n8n app-local data.
- Public Ingress/TLS.
- No Redis.
- No queue workers.
- No S3 binary-data mode yet.

Production queue mode is gated by the n8n Enterprise license because S3 binary
data support is required for queue mode.


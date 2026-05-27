# n8n MoneyMaker Target Values

Status: single-main production mode active; queue mode parked
Last updated: 2026-05-26

## Identity

App name: n8n MoneyMaker
Namespace: `n8n`
Public domain: `n8n-mm.activi-apps.io`
Ingress IP: `88.99.215.210`
IngressClass: `nginx`
TLS issuer: `letsencrypt-prod`
Service type: `ClusterIP`
StorageClass: `longhorn`

## Bootstrap Status 2026-05-26

Single-main deployment: active
Production queue mode: parked until a compatible license is available

Current live URL:

- `https://n8n-mm.activi-apps.io`

Current blocker for queue-mode upgrade:

- The current active license does not allow multiple main instances.
- The current active license does not allow S3 external binary storage.
- Queue mode with 2 Web/API replicas, 3 workers, Redis, and S3 must wait for a
  compatible license.

Temporary DNS workaround:

- CoreDNS has a targeted host entry for `n8n-mm.activi-apps.io`.
- Remove it after the cluster-wide DNS cleanup is completed and verified.

## Runtime Mode

n8n active target mode: single main instance
n8n future upgrade mode: queue mode after compatible Enterprise license
n8n installation method: official pinned n8n image with custom Kubernetes manifests
n8n image: `docker.n8n.io/n8nio/n8n:1.123.47`

Active topology:

- n8n Web/API: 1 replica.
- n8n Worker: none.
- Redis: scaled to 0 / unused.
- PostgreSQL: CloudNativePG with 3 instances.
- n8n app data: Longhorn PVC.

Expected failover behavior:

- If the node running n8n fails, Kubernetes restarts the n8n pod on another
  available node.
- PostgreSQL data is handled by CloudNativePG replication.
- Filesystem binary data and app-local files are handled by the Longhorn PVC.
- A short downtime is expected while the pod restarts and the Longhorn volume is
  attached to the replacement node.

Future queue topology after compatible license:

- n8n Web/API: 2 replicas, distributed across different nodes where possible.
- n8n Worker: 3 replicas, distributed across all three nodes where possible.
- Redis: 3 instances for queue availability.
- S3 external binary storage.

Queue-mode attempt on 2026-05-26:

- Redis, n8n-main, and n8n-worker manifests passed server-side dry-run.
- Runtime startup was blocked by active license capabilities.
- Live cluster was restored to bootstrap mode.
- Redis is scaled to 0 while unused; Redis PVCs/manifests remain available for a
  later compatible-license retry.

## Database

Database: PostgreSQL in K3s via CloudNativePG
Instances: 3
Storage: 20 GiB per instance on Longhorn
Backup target: Barman/WAL plus pg_dump plus restore test

## n8n Storage

n8n application storage: 20 GiB Longhorn PVC

Binary data mode for active single-main production:

- Use filesystem binary-data storage on the n8n Longhorn PVC.
- This is acceptable while n8n runs as a single active pod.
- Longhorn handles storage replication and failover attachment.
- Very high-volume binary workloads should be revisited before going live at
  larger scale.

Binary data mode for future queue mode after compatible Enterprise license:

- Store n8n binary data in S3/object storage from the initial deployment.
- Do not store binary data in PostgreSQL for V1.
- Do not use filesystem/PVC binary-data storage for queue mode.

S3 target:

- Bucket: `n8n-mm`
- Endpoint: `https://fsn1.your-objectstorage.com`
- S3 location/region value: `fsn1`
- Hetzner network zone shown in console: `eu-central`
- Prefix: `binary-data/`
- Credentials: Kubernetes Secret, never written to Git or docs.

Reason:

- PostgreSQL should stay focused on workflows, credentials, settings, and
  execution metadata.
- n8n queue mode does not support filesystem binary-data storage safely across
  multiple web and worker pods.
- S3/object storage is the correct shared binary-data backend for queue mode.
- S3 binary-data support is gated behind n8n Enterprise, so production queue
  mode must wait until the license key is available.

Longhorn usage:

- Keep the 20 GiB Longhorn PVC only for n8n application-local data, temporary
  runtime files, and non-binary-data needs.
- Binary workflow files, uploads, call artifacts, exports, and similar data must
  use S3/object storage.

## Public Access

Public access: enabled by Ingress and TLS
Initial protection: n8n login plus strong secrets
Cloudflare Access: not enabled for initial deployment
Cloudflare DNS proxy: disabled, DNS only

## Account Setup

Initial owner account: created manually in the browser after deployment.

No initial owner password should be written to Git, docs, or chat.

## SMTP

SMTP: deferred

n8n can be deployed without SMTP. Password reset and invitation emails will be
configured later.

## Execution History

Execution history retention: 30 days

Purpose:

- Keep enough workflow history for debugging.
- Prevent unbounded PostgreSQL growth from old execution data.

## Backups

pg_dump schedule: daily at 02:17
pg_dump retention: 30 days

Longhorn recurring policy for n8n PVCs:

- Hourly snapshots, keep 48.
- Daily backups, keep 14.
- Weekly backups, keep 8.

## Monitoring And Alerts

Monitoring level: intensive

Checks to implement:

- Ingress availability.
- TLS certificate health.
- n8n Web/API health.
- n8n Worker health.
- PostgreSQL health.
- Redis health.
- Backup job success.
- Queue length.
- n8n error rates.
- External webhook latency.
- S3/object-storage checks for binary data.

Alert destination for V1:

- Internal Prometheus/Alertmanager only.

Planned later alert destination:

- Telegram, Slack, or generic webhook after the Alertmanager notification block
  is configured with secrets and tested.

## NetworkPolicy

V1 decision: no NetworkPolicy at initial deployment.

Reason:

- Reduce risk of blocking n8n queue mode, S3, external APIs, webhooks, Redis, or
  PostgreSQL during first deployment.
- Capture real traffic paths first, then harden with a basis NetworkPolicy.

Required follow-up:

- Add a basis NetworkPolicy after n8n is deployed, smoke-tested, and monitored.
- If a compatible license is added later, switch from single-main mode to queue
  mode with Redis and S3 binary data.

## Deploy Method

Deployment method: terminal/kubectl.

Reason:

- Faster and more controlled for many resources.
- Easier to verify with scripts and logs.
- Portainer remains useful for visibility, but not as the primary deployment
  mechanism.

## Open Before Deploy

- Single-main mode is active and may remain the production mode.
- Production queue mode must not proceed until `N8N_LICENSE_ACTIVATION_KEY` is
  available as a Kubernetes Secret and the license is confirmed to allow both
  multiple main instances and S3 external binary storage.
- Confirm final n8n image tag before applying production queue manifests if
  deployment is not performed on 2026-05-26.
- Confirm Redis implementation and persistence settings before production queue
  mode.
- Confirm NetworkPolicy follow-up hardening block after initial deploy.
- Confirm production monitoring checks and alert rules.
- Confirm external notification channel for later Alertmanager integration.

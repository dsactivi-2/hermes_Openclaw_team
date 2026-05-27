# n8n MoneyMaker Deploy Runbook

Status: single-main production mode active; queue mode parked
Last updated: 2026-05-26

## Goal

Deploy n8n for the MoneyMaker project into the activi K3s cluster.

Active single-main stage:

- Single n8n main instance.
- CloudNativePG PostgreSQL.
- Longhorn storage.
- Public HTTPS access at `n8n-mm.activi-apps.io`.
- First owner account setup and license activation completed.
- Kubernetes/Longhorn failover by restarting the single n8n pod on another node.

Optional queue stage after compatible Enterprise license:

- Queue mode.
- Official pinned n8n container image.
- Custom Kubernetes manifests.
- CloudNativePG PostgreSQL.
- Longhorn storage.
- S3/object storage for n8n binary data.
- Public HTTPS access at `n8n-mm.activi-apps.io`.
- Database-aware backups.
- Monitoring and restore-test coverage.

## Current Decisions

Namespace: `n8n`
Domain: `n8n-mm.activi-apps.io`
Ingress target IP: `88.99.215.210`
IngressClass: `nginx`
TLS issuer: `letsencrypt-prod`
Service type: `ClusterIP`
StorageClass: `longhorn`
n8n image: `docker.n8n.io/n8nio/n8n:1.123.47`

## Bootstrap Status 2026-05-26

Single-main deployment completed.

Verified:

- CloudNativePG PostgreSQL is healthy with 3 instances.
- n8n bootstrap Deployment is running.
- n8n license secret is present and mounted into the Deployment.
- Ingress is active for `n8n-mm.activi-apps.io`.
- cert-manager Certificate `n8n-mm-tls` is Ready.
- HTTPS returns HTTP 200 from outside via the Ingress IP.
- HTTPS returns HTTP 200 from inside the cluster.

## Production Queue Attempt 2026-05-26

Attempted production queue-mode rollout after license activation.

Result: stopped and rolled back to bootstrap runtime.

Reason:

- `n8n-main` with 2 replicas failed because the active license does not allow
  `feat:multipleMainInstances`.
- `n8n-worker` with S3 binary-data mode failed because the active license does
  not allow S3 external binary storage.

Actions taken:

- Restored bootstrap `n8n-config`.
- Kept the public `n8n` Service selecting the stable bootstrap Deployment.
- Scaled `n8n-main` and `n8n-worker` to 0.
- Scaled Redis StatefulSet to 0 because it is unused while queue mode is blocked.
- Removed Queue-mode PDBs so they do not interfere with scale-down or future
  node maintenance.

Current active production mode:

- Single n8n main Deployment.
- CloudNativePG PostgreSQL with 3 instances.
- Longhorn app PVC.
- Filesystem binary-data mode on the Longhorn app PVC.
- Kubernetes restarts this single n8n pod on another node after node failure.
- Longhorn re-attaches the PVC on the replacement node; short downtime is
  expected during failover.

To retry production queue mode, first upgrade/confirm a license that explicitly
allows both:

- Multiple main instances.
- S3 external binary storage.

Temporary DNS note:

- A targeted CoreDNS `NodeHosts` entry was added:
  `88.99.215.210 n8n-mm.activi-apps.io`.
- Reason: CoreDNS/Node resolver returned NXDOMAIN for the new DNS record while
  public resolvers already returned `88.99.215.210`.
- This is a temporary workaround and should be removed after the broader cluster
  DNS cleanup is completed and verified.

## Active Components

- n8n main: 1 replica.
- CloudNativePG PostgreSQL: 3 instances, 20 GiB each.
- n8n app PVC: 20 GiB Longhorn.
- n8n binary data: filesystem on Longhorn PVC.
- Ingress/TLS for `n8n-mm.activi-apps.io`.
- Longhorn recurring jobs for productive PVCs.

## Parked Queue Components

- Redis queue after compatible license: 3 instances.
- n8n Web/API after compatible license: 2 replicas.
- n8n Worker after compatible license: 3 replicas.
- n8n binary data after compatible license: S3/object storage.
- pg_dump CronJob and restore-test job.
- Velero schedule for namespace resources.
- Intensive Prometheus monitoring and alert rules.

## Binary Data Plan

Active single-main decision:

- Use n8n filesystem binary-data storage on the n8n Longhorn PVC.
- This is the current production mode while running a single active n8n pod.
- Longhorn replicates and re-attaches the volume after node failure.
- Short downtime during failover is expected.

Future queue decision after compatible Enterprise license:

- Use n8n S3/object-storage binary-data storage from the initial deployment.
- Do not store binary data in PostgreSQL.
- Do not use filesystem/PVC binary-data storage in queue mode.

Why:

- PostgreSQL backups stay smaller and more reliable.
- n8n queue mode has multiple web and worker pods, so binary data needs a shared
  backend all pods can access.
- S3/object storage is the correct backend for larger file-heavy workflow data.
- n8n S3/object-storage binary data is Enterprise-gated, so production queue mode
  waits for the license activation key.

Longhorn usage:

- The 20 GiB n8n Longhorn PVC remains for app-local runtime needs.
- Workflow binary data such as call recordings, transcriptions, PDFs, images,
  and exports must use S3/object storage.

S3 target:

- Bucket: `n8n-mm`
- Endpoint: `https://fsn1.your-objectstorage.com`
- S3 location/region value: `fsn1`
- Hetzner network zone shown in console: `eu-central`
- Prefix: `binary-data/`
- Credentials must be provided only through Kubernetes Secrets.

## Backup Plan

pg_dump:

- Schedule: daily at 02:17.
- Retention: 30 days.
- Must include SHA256 and restore-test validation.

Longhorn recurring jobs for n8n PVCs:

- Hourly snapshots, keep 48.
- Daily backups, keep 14.
- Weekly backups, keep 8.

## Monitoring And Alerts

Initial monitoring level: intensive

Required checks:

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

Initial alert destination:

- Internal Prometheus/Alertmanager only.

Later alert destination:

- Telegram, Slack, or generic webhook.
- This must be a separate block because notification endpoints are secrets and
  need explicit setup and test evidence.

## NetworkPolicy

V1 decision:

- Do not apply NetworkPolicy during the initial n8n deployment.

Reason:

- Avoid accidentally blocking PostgreSQL, external APIs, webhooks, monitoring,
  or future n8n worker communication during the first stable single-main phase.
- Single-main mode should establish a known-good baseline first.

Mandatory follow-up:

- After smoke tests and monitoring are stable, create a basis NetworkPolicy that
  permits only the verified traffic paths.

## Deploy Method

Deployment method:

- Terminal/kubectl.

Portainer usage:

- Use Portainer for visibility and manual inspection.
- Do not use Portainer as the primary deploy mechanism for this n8n release.

## Deploy Order

### Active Single-Main

1. Run preflight checks for cluster, DNS, ingress, cert-manager, storage, CNPG,
   Longhorn, Velero, and monitoring.
2. Generate or apply secrets without printing secret values.
3. Deploy CloudNativePG PostgreSQL.
4. Wait for PostgreSQL 3-instance health.
5. Deploy n8n bootstrap main instance and app PVC.
6. Deploy Service and Ingress.
7. Verify TLS certificate readiness.
8. Verify internal service connectivity.
9. Open browser setup and create the first n8n owner account manually.
10. Activate or request n8n Enterprise license in the UI.
11. Run baseline gates.

### Optional Queue Upgrade After Compatible License

1. Add `N8N_LICENSE_ACTIVATION_KEY` as Kubernetes Secret.
2. Verify the active license allows both `multipleMainInstances` and S3 external
   binary storage.
3. Configure n8n S3/object-storage binary-data secret and non-secret settings.
4. Deploy Redis queue.
5. Switch n8n to queue mode with Web/API and Worker components.
6. Deploy backup jobs and run first restore test.
7. Deploy monitoring rules and run external blackbox check.
8. Verify internal Alertmanager visibility for n8n alerts.
9. Document and apply NetworkPolicy follow-up.
10. Run baseline gates.

## Must Verify After Deploy

- `n8n` namespace has no problem pods.
- n8n main Deployment has 1 available replica.
- Parked queue Deployments, if present, are scaled to 0 until license upgrade.
- PostgreSQL has 3 healthy instances.
- Redis queue is scaled to 0 until license upgrade.
- `https://n8n-mm.activi-apps.io` serves n8n over valid TLS.
- No NodePort or LoadBalancer service was created.
- n8n app PVC uses `longhorn`.
- n8n binary data uses filesystem mode on the Longhorn app PVC.
- PostgreSQL PVCs use `longhorn`.
- pg_dump backup completes.
- Restore test completes.
- Monitoring probe succeeds.
- n8n alerts are visible internally in Prometheus/Alertmanager.
- NetworkPolicy hardening is documented as a required follow-up if not yet
  applied.

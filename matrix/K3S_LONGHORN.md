# Matrix Stack on K3s + Longhorn

This path is separate from the Docker Compose / OrbStack setup. Use it when the
target server runs K3s and Longhorn-backed persistent volumes.

## Architecture

- Postgres runs as a Kubernetes `StatefulSet` with a Longhorn PVC.
- Synapse runs as a Kubernetes `StatefulSet` with a Longhorn media PVC.
- Synapse config is rendered inside an init container from ConfigMap + Secret.
- `synapse-permissions` is replaced by Kubernetes `fsGroup` and init rendering.
- Element, Element Admin, and Ketesa run as stateless `Deployment` workloads.
- ingress-nginx is used through standard Kubernetes `Ingress`.
- TLS is expected through cert-manager and the `letsencrypt-prod` `ClusterIssuer`.
- TURN uses `hostNetwork: true` because UDP/TCP TURN is simpler and more stable
  on small K3s clusters than routing it through normal Ingress.
- Backups run as a Kubernetes `CronJob` writing `pg_dump` files to a Longhorn PVC.

## Prerequisites

- K3s HA cluster is running.
- Longhorn is installed and healthy.
- nginx `IngressClass` named `nginx` exists.
- cert-manager is installed.
- A `ClusterIssuer` named `letsencrypt-prod` exists and is ready.
- DNS points the Matrix domains to the K3s ingress/load balancer IP.
- GHCR private package access is configured if the packages remain private.
- GHCR packages are private, so `ghcr-pull-secret` must exist in the `matrix`
  namespace.

## Files

- Helm chart: `helm/matrix-stack`
- K3s/Longhorn values: `helm/matrix-stack/values-k3s-longhorn.yaml`
- Secret template: `k8s/examples/matrix-stack-secret.example.yaml`
- Preflight: `scripts/k3s-longhorn-preflight.sh`

## Preflight

```bash
./scripts/k3s-longhorn-preflight.sh
```

With live read-only cluster checks:

```bash
RUN_CLUSTER_CHECKS=1 ./scripts/k3s-longhorn-preflight.sh
```

## Secret Setup

Create the namespace and a real secret from the example. Do not commit the real
secret.

```bash
kubectl create namespace matrix
cp k8s/examples/matrix-stack-secret.example.yaml /tmp/matrix-stack-secret.yaml
vi /tmp/matrix-stack-secret.yaml
kubectl apply -f /tmp/matrix-stack-secret.yaml
```

Create the GHCR pull secret:

```bash
cp k8s/examples/ghcr-pull-secret.example.sh /tmp/ghcr-pull-secret.sh
vi /tmp/ghcr-pull-secret.sh
bash /tmp/ghcr-pull-secret.sh
```

The `homeserver.signing.key` value must be the existing Synapse signing key.
Do not generate a new key for this deployment. A new key would create a new
Matrix server identity for `matrix.activi.io`.

## Install

```bash
helm upgrade --install matrix ./helm/matrix-stack \
  --namespace matrix \
  --create-namespace \
  -f helm/matrix-stack/values-k3s-longhorn.yaml
```

## Verify

```bash
kubectl get pods,pvc,ingress -n matrix
kubectl rollout status statefulset/matrix-matrix-stack-postgres -n matrix
kubectl rollout status statefulset/matrix-matrix-stack-synapse -n matrix
kubectl logs -n matrix statefulset/matrix-matrix-stack-synapse --tail=100
```

## Longhorn Notes

The chart uses the existing `longhorn` StorageClass and does not create a new
cluster-wide StorageClass. This matches the activi K3s cluster standard.

For critical Matrix data, avoid deleting PVCs automatically. Longhorn recurring
snapshots/backups are useful, but Postgres still needs database-aware backups
such as `pg_dump` or a future CloudNativePG/WAL-based setup.

The chart keeps storage sizes configurable:

```yaml
postgres:
  storage:
    size: 30Gi
    storageClassName: longhorn

synapse:
  media:
    storage:
      size: 100Gi
      storageClassName: longhorn

backup:
  storage:
    size: 50Gi
    storageClassName: longhorn
```

## nginx Ingress Notes

The chart avoids nginx `configuration-snippet` because this is often disabled by
cluster policy. It uses safe nginx annotations for:

- SSL redirect
- proxy body size for uploads
- proxy read/send timeout for Matrix sync
- optional rate limits through values

Rate limits are disabled by default to avoid breaking Matrix sync and media
uploads during the first deploy.

## Open Decisions Before Production

- GHCR packages stay private and use `ghcr-pull-secret`.
- SMTP provider, port, TLS mode, and credentials.
- TURN domain: `turn.matrix.activi.io`.

## Expected Cluster Defaults

```text
IngressClass: nginx
StorageClass: longhorn
ClusterIssuer: letsencrypt-prod
Namespace: matrix
Helm release: matrix
Image pull secret: ghcr-pull-secret
TURN domain: turn.matrix.activi.io
Synapse signing key: existing key must be reused
```

## Current Default Sizing

- Postgres PVC: `30Gi`
- Synapse media PVC: `100Gi`
- Backup PVC: `50Gi`
- Synapse memory: request `1Gi`, limit `3Gi`
- Postgres memory: request `512Mi`, limit `2Gi`

Adjust these in `helm/matrix-stack/values-k3s-longhorn.yaml` before production.

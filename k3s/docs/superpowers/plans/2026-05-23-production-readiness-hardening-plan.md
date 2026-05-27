# Production Readiness and Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the K3s stack from "technically deployable" to production-ready with tested Kubernetes resource backup, database-aware backup, monitoring, security, GitOps, backup deletion protection, and disaster-recovery validation.

**Architecture:** Keep the existing backup layers separated by data class. Add Velero for Kubernetes resources, CloudNativePG for Postgres on Longhorn with S3/WAL backups, monitoring for failure visibility, GitOps for reproducible desired state, and a real DR test for proof.

**Tech Stack:** K3s, Longhorn, Portainer Business, ingress-nginx, cert-manager, Velero, CloudNativePG, S3-compatible Object Storage, Restic, Argo CD or equivalent GitOps, Prometheus-compatible monitoring.

---

## File Map

- Modify: `/Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md`
- Modify: `/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md`
- Modify: `/Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md`
- Modify after each implementation block: `/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md`
- Extend after each implementation block: `/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh`
- Extend after each implementation block: `/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh`

## Required Preflight Before Every Task

- [ ] **Step 1: Run current audit**

Run:

```bash
cd "/Users/activi/Documents/activi K3s"
./audit-recent-stack-claims.sh
```

Expected:

```text
RESULT: PASS
Warnings: 0
Failures: 0
```

- [ ] **Step 2: Run full verify**

Run:

```bash
cd "/Users/activi/Documents/activi K3s"
./verify-k3s-stack-complete.sh
```

Expected:

```text
RESULT: PASS
Warnings: 0
Failures: 0
```

- [ ] **Step 3: Create fresh backup checkpoint**

Use the existing backup mechanisms. Do not print secrets.

Expected artifacts:

```text
fresh K3s etcd S3 snapshot
fresh Server-1 Restic snapshot while Docker apps remain on Server 1
fresh Longhorn SystemBackup when Kubernetes/Longhorn resources are affected
fresh Longhorn volume backup when a Longhorn PVC is affected
```

## Task 1: Final Portainer Business Setup

**Goal:** Finish Portainer as the admin UI without changing cluster storage or app workloads.

- [ ] **Step 1: Verify current Portainer state**

Run:

```bash
kubectl -n portainer get deploy,svc,ingress,pvc
kubectl -n portainer get certificate
```

Expected:

```text
Portainer deployment is available.
Service is ClusterIP.
Ingress host is portainer.activi.io.
Certificate is Ready.
Active PVC is portainer-longhorn on longhorn.
Old local-path PVC is still present as rollback evidence.
```

- [ ] **Step 2: UI checklist**

Check in Portainer UI without posting secrets:

```text
Business license visible
Access Tokens: none or intentional only
Git Credentials: none or intentional only
Registry: DockerHub intentional and working
Helm repositories: Bitnami/global repo visible
Kubernetes Environment local opens and lists 3 nodes
Notifications reviewed; historical errors acknowledged or cleared
```

- [ ] **Step 3: Document result**

Update:

```text
/Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
```

## Task 2: Velero for Kubernetes Resources

**Goal:** Add Velero as a Kubernetes-resource backup and restore layer.

- [ ] **Step 1: Prepare plan**

Document target:

```text
Provider: S3-compatible Object Storage
Scope: Kubernetes resources and namespaces
PVC data: not primary Velero responsibility because Longhorn handles volumes
Retention: start conservative, then adjust
Restore test: required before production app rollout
```

- [ ] **Step 2: Install only after backup checkpoint**

Install Velero with S3 backup location. Do not create destructive restore jobs.

- [ ] **Step 3: Test with a small namespace**

Create a harmless test namespace and object set, back it up, delete only test objects, restore only test objects, and verify.

- [ ] **Step 4: Add schedule**

Create a recurring Velero schedule for cluster resources.

- [ ] **Step 5: Extend verification**

Extend:

```text
/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh
/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh
```

Expected checks:

```text
velero namespace exists
backup location Available
schedule exists
latest test backup Completed
no failed Velero pods
```

## Task 3: CloudNativePG and Database-Aware Backups

**Goal:** Run Postgres in Kubernetes on Longhorn with database-consistent backups.

- [ ] **Step 1: Install CloudNativePG**

Install the operator only after backup checkpoint.

- [ ] **Step 2: Deploy test Postgres cluster**

Use Longhorn PVCs. Do not migrate Hindsight yet.

- [ ] **Step 3: Configure S3/WAL backup**

Expected:

```text
base backup goes to S3
WAL archiving enabled
restore target documented
```

- [ ] **Step 4: Add pg_dump layer**

Create a logical dump job for test DB, then verify a restore into a separate test database.

- [ ] **Step 5: Extend verification**

Expected checks:

```text
CloudNativePG operator Ready
test cluster healthy
latest base backup successful
WAL archiving healthy
latest pg_dump exists and is readable
restore test successful
```

## Task 4: Longhorn Volume RecurringJobs for Production PVCs

**Goal:** Automate Longhorn volume protection without catching test/default volumes accidentally.

- [ ] **Step 1: Label only target volumes**

Start with Portainer Longhorn volume. Do not use Longhorn `default` group.

- [ ] **Step 2: Create recurring jobs**

Create snapshot and backup jobs with explicit group such as `portainer-prod`.

- [ ] **Step 3: Verify first run**

Expected:

```text
snapshot completed
backup completed
retention visible
test volumes not included
```

## Task 5: Monitoring and Alerting

**Goal:** Make failures visible without manual UI inspection.

- [ ] **Step 1: Choose monitoring stack**

Prefer a Kubernetes-native stack compatible with Prometheus metrics.

- [ ] **Step 2: Add required alert classes**

Minimum alerts:

```text
Node NotReady
Problem pods
Longhorn volume degraded/faulted
Longhorn backup failure
Velero backup failure
CloudNativePG backup/WAL failure
cert-manager certificate expiry
S3/restic backup failure
disk pressure
memory pressure
```

- [ ] **Step 3: Verify notification path**

Send a test alert to the chosen channel before declaring monitoring complete.

## Task 6: Security Hardening

**Goal:** Reduce blast radius after basic platform stability is proven.

- [ ] **Step 1: RBAC review**

Review Portainer users, Kubernetes service accounts, and admin access. Do not remove access without a rollback user.

- [ ] **Step 2: NetworkPolicies**

Add namespace-by-namespace policies after app topology is known. Start with test namespace.

- [ ] **Step 3: Pod Security Standards**

Enforce baseline/restricted where compatible, test per namespace.

- [ ] **Step 4: Image scanning and admission**

Choose tooling before enforcing. Start in audit mode where available.

- [ ] **Step 5: Secret management**

Plan SOPS, External Secrets, or Vault. Do not move existing secrets until restore path is documented.

## Task 7: GitOps

**Goal:** Store desired state outside the live cluster.

- [ ] **Step 1: Choose GitOps controller**

Recommended default: Argo CD.

- [ ] **Step 2: Create repository structure**

Minimum structure:

```text
clusters/activi-k3s/
apps/
infrastructure/
secrets/
docs/
```

- [ ] **Step 3: Import non-secret desired state**

Start with namespaces, ingress, cert-manager issuers, Portainer references, Velero schedules, CloudNativePG manifests, monitoring manifests.

- [ ] **Step 4: Add secret encryption**

Use SOPS or External Secrets before storing secret material.

## Task 8: Backup Deletion Protection

**Goal:** Protect backups from accidental deletion, credential misuse, and ransomware.

- [ ] **Step 1: Check Object Lock and versioning**

Document current S3 bucket settings without printing credentials.

- [ ] **Step 2: Separate credentials**

Use least-privilege credentials per backup class where supported:

```text
etcd snapshots
Restic server1
OS-Restic server2
OS-Restic server3
Longhorn
Velero
CloudNativePG
```

- [ ] **Step 3: Rotate exposed credentials**

Rotate any key whose identifier appeared in chat, then rerun all backup checks.

## Task 9: Disaster-Recovery Test

**Goal:** Prove that the stack can be restored on replacement infrastructure.

- [ ] **Step 1: Prepare DR runbook**

Document exact restore order:

```text
provision 3 replacement nodes
install prerequisites
restore K3s/etcd or rebuild cluster
restore GitOps/Velero Kubernetes resources
restore Longhorn volumes
restore CloudNativePG databases
restore remaining Restic host files if needed
switch DNS/firewall
verify apps
```

- [ ] **Step 2: Execute non-production DR drill**

Use isolated test nodes or an isolated namespace where possible. Do not point production DNS until verified.

- [ ] **Step 3: Document gaps**

List any manual step, missing credential, missing manifest, or restore ambiguity.

## Task 10: Upgrade Strategy

**Goal:** Keep the platform maintainable after production use starts.

- [ ] **Step 1: Define upgrade order**

Recommended order per maintenance window:

```text
backup checkpoint
audit/full verify
non-critical components
cert-manager/ingress-nginx
Portainer
Velero
CloudNativePG
Longhorn
K3s
post-upgrade audit/full verify
```

- [ ] **Step 2: Define rollback criteria**

Stop and roll back when:

```text
API connectivity unstable
Longhorn degraded unexpectedly
certificates not Ready
Portainer inaccessible
Velero/DB backups failing
problem pods outside expected rollout window
```

# Hindsight Daily Ops Report (2026-05-26)

- Gesamtstatus: FAIL
- ALERT_REQUIRED: ja
- Run-ID: 2026-05-26T153431
- Workspace: project:activi-k3s

## Kritische Fehler
- Hindsight Deploy Gate FAIL (RUN_BASELINE=0)
- Namespace hindsight not readable/absent via kubectl
- Baseline gates FAIL (or timed out)

## Warnungen
- Groq healthcheck CronJob not found/readable (may be missing)

## Offene Gaps
- CNPG Cluster CRD/cluster not readable (cnpg might be absent or RBAC restricted)
- Velero schedules not readable (velero ns missing or RBAC restricted)
- Longhorn recurringjobs not readable (longhorn-system missing or RBAC restricted)
- Weekly quality checks not executed here: requires project-specific tooling/data sources; see runbook in repo to implement safely.

## Ausgefuehrte Checks (Logs in /private/tmp/hindsight-daily-ops/2026-05-26T153431)
- kubectl: ns/deploy/pods/events + CNPG/PVC/CronJobs/Jobs + optional Velero/Longhorn
- ./verify-hindsight-bank-mapping.sh
- ./verify-hindsight-secret-redaction.sh
- ./verify-hindsight-manifests.sh
- RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh
- (optional) ./run-baseline-gates.sh (max 10 min)

## Logpfade
- Run-Dir: /private/tmp/hindsight-daily-ops/2026-05-26T153431
- Report (tmp): /private/tmp/hindsight-daily-ops/2026-05-26T153431/hindsight-daily-ops-report-2026-05-26.md
- Report (dest): /Users/activi/Documents/activi K3s/docs/apps/hindsight-daily-ops-report-2026-05-26.md

## Alert-Regeln / Naechste Schritte
- ALERT_REQUIRED=true: Keine automatischen Reparaturen. Bitte Freigabe erteilen, falls Reparatur gewuenscht (z.B. Restart/Rollout/Helm/Kubectl apply).
- Diagnose: siehe Logdateien unter /private/tmp/hindsight-daily-ops/2026-05-26T153431 (stdout/stderr/code je Check).

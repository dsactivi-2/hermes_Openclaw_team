# Hindsight Daily Ops Report (2026-05-27)

- Gesamtstatus: FAIL
- ALERT_REQUIRED: ja
- Run-ID: 2026-05-27T085808
- Laufzeit: 0:01:27
- Workspace: project:activi-k3s
- Report-Pfad: `/Users/activi/Documents/activi K3s/docs/apps/hindsight-daily-ops-report-2026-05-27.md`

## Kritische Fehler
- Live-Hindsight-Checks konnten nicht gegen den Cluster ausgefuehrt werden: `kubectl` fiel bei allen Namespace-/Pod-/CNPG-/Backup-Abfragen mit `Error in configuration: context was not found for specified context: orbstack` aus.
- `RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh` meldete `RESULT: FAIL`.
- `./run-baseline-gates.sh` meldete FAIL; die enthaltenen SSH- und DNS-Pruefungen scheiterten in dieser Umgebung mit `Operation not permitted`.
- `verify-hindsight-predeploy-gates.sh` meldete `RESULT: FAIL`, weil im Draft jetzt ein public Ingress vorliegt und die alte Gate-Regel weiter "Ingress vor separater Freigabe verboten" erzwingt.

## Warnungen
- API-Health, UI-Reachability, Ollama-Modellliste und Retain/Recall-Live-Smoke konnten nicht live bestaetigt werden, weil `kubectl exec` bereits am fehlenden Kontext scheiterte.
- Die SSH-basierten Baseline-/Deploy-Gates sind in dieser Sandbox nicht aussagekraeftig fuer den echten Clusterzustand; die FAILs stammen aus Netz-/Sandbox-Blockaden, nicht aus einem bestaetigten Produktionsausfall.
- Notification-Pfad fuer Hindsight ist nicht dokumentiert/fertig konfiguriert.

## Offene Gaps
- Live-Podzahlen, Restart-Zaehler, aktuelle Events und echte CronJob-LastScheduleTimes konnten heute nicht direkt aus dem Cluster gelesen werden.
- Retain/Recall: Es wurde kein synthetischer Smoke-Test ausgefuehrt, weil kein sicherer Live-Zugriff auf die Hindsight-API moeglich war.
- Weekly extra quality check heute nicht faellig, da lokales Datum Mittwoch, 2026-05-27 ist.
- `NOTIFICATION_CHANNEL_MISSING`: Es gibt keinen nachweisbaren sicheren Hindsight-Notifier in `docs/`, `ops/`, `scripts/` oder `.github/`. Es fehlen mindestens: Empfaenger/Kanal, Aufrufskript/Command und die benannte Receiver-/Webhook-/Env-Konfiguration.

## Wichtigste Zahlen
- Live-Clusterzahlen heute: nicht verfuegbar wegen `kubectl`-Kontextfehler.
- Sekundaerevidenz aus Repo-Inventar `reports/k3s-cleanup-inventory_2026-05-27_04-04-02`:
- Namespace `hindsight`: vorhanden, Alter ca. 25h.
- App-Deployments: `hindsight-api`, `hindsight-worker`, `hindsight-ui`, `hindsight-ollama` jeweils `1/1`.
- Laufende Hindsight-Pods im Inventar: 7 (`api`, `worker`, `ui`, `ollama`, `postgres-1`, `postgres-2`, `postgres-3`).
- Abgeschlossene Hindsight-Jobs/Pods im Inventar: 8, darunter `hindsight-groq-healthcheck-*`, `hindsight-postgres-pgdump-*`, `hindsight-postgres-pgdump-restore-test`, `hindsight-ollama-pull-bge-m3`.
- Sichtbare Restarts im Inventar fuer die laufenden Hindsight-Pods: 0.
- CNPG / Postgres laut Inventar: 3 Instanzen (`hindsight-postgres-1..3`), alle `2/2 Running`.
- PVCs laut Inventar: 4/4 `Bound` (`hindsight-ollama-data`, `hindsight-postgres-1`, `-2`, `-3`), StorageClass `longhorn`.
- Letzter sichtbarer `pg_dump`-Job im Inventar: `hindsight-postgres-pgdump-29664101`, `Complete`, Alter `23m` relativ zum Inventarzeitpunkt 04:04 CEST.
- Letzter sichtbarer Groq-Healthcheck im Inventar: `hindsight-groq-healthcheck-29664120`, `Complete`, Alter `4m4s` relativ zum Inventarzeitpunkt 04:04 CEST.
- Restore-Test-Evidenz im Inventar: `hindsight-postgres-pgdump-restore-test`, `Complete`, Alter `24h`.

## Hindsight K3s State
- Live-Check: FAIL wegen fehlendem `kubectl`-Kontext `orbstack`.
- Sekundaerevidenz 04:04 CEST:
- Namespace `hindsight` war vorhanden.
- Deployments `hindsight-api`, `hindsight-worker`, `hindsight-ui`, `hindsight-ollama` waren jeweils `1/1`.
- Keine `CrashLoopBackOff`-/`Failed`-Pods fuer Hindsight im Inventar sichtbar.
- Ingress `hindsight.activi.io` war im Inventar vorhanden.

## CloudNativePG / Postgres
- Live-Check: FAIL wegen fehlendem `kubectl`-Kontext.
- Sekundaerevidenz 04:04 CEST:
- Pods `hindsight-postgres-1`, `-2`, `-3` liefen jeweils `2/2`.
- PVCs fuer alle drei Postgres-Instanzen waren `Bound` auf `longhorn`.
- Inventar und Runbook deuten auf gesunden `hindsight-postgres`-Cluster hin; direkte CRD-Abfrage heute war nicht moeglich.

## Hindsight Components Health
- API: Live-Healthprobe nicht moeglich; Sekundaerevidenz zeigt `hindsight-api` `1/1 Running`.
- UI: Live-Reachability nicht moeglich; Sekundaerevidenz zeigt `hindsight-ui` `1/1 Running` und Ingress `hindsight.activi.io`.
- Worker: Live-Check nicht moeglich; Sekundaerevidenz zeigt `hindsight-worker` `1/1 Running`.
- Ollama: Live-`ollama list` nicht moeglich; Sekundaerevidenz zeigt `hindsight-ollama` `1/1 Running`.
- `bge-m3`: live nicht verifiziert; Sekundaerevidenz zeigt erfolgreichen Job `hindsight-ollama-pull-bge-m3`.

## Backups
- `pg_dump` CronJob live nicht lesbar; Sekundaerevidenz zeigt CronJob `hindsight-postgres-pgdump`, `suspend=False`, letzter Job `Complete`.
- Restore-Test live nicht lesbar; Sekundaerevidenz zeigt Job `hindsight-postgres-pgdump-restore-test` `Complete`.
- Longhorn RecurringJobs live nicht lesbar; Manifest-Check PASS bestaetigt dedizierte Hindsight-RecurringJobs im Draft.
- Velero Schedule live nicht lesbar; Manifest-Check PASS bestaetigt vorhandenes Hindsight-Velero-Schedule-Manifest.

## Groq Healthcheck
- Live-Check nicht lesbar; Sekundaerevidenz zeigt CronJob `hindsight-groq-healthcheck`, `suspend=False`.
- Mehrere aktuelle Jobs im Inventar waren `Complete`.
- Falls der Check spaeter live fehlschlaegt, sind die dokumentierten wahrscheinlichen Ursachen: Credits aufgebraucht, Rate Limit, Groq API down, Auth-Problem, Netzwerkproblem.

## Retain / Recall
- Kein Live-Smoke-Test ausgefuehrt, weil kein sicherer Cluster-/API-Zugriff moeglich war.
- Lokale Hindsight-Pruefungen bestaetigen weiter Bank-Mapping und Secret-Redaction; das ist aber kein End-to-End-Retain/Recall-Beweis fuer die laufende K3s-Instanz.

## Bank Mapping
- `./verify-hindsight-bank-mapping.sh`: PASS.
- Ergebnis laut Log `/tmp/hindsight-bank-mapping-20260527-085808.log`: 12 Passes, 0 Failures.

## Secret Redaction
- `./verify-hindsight-secret-redaction.sh`: PASS.
- Ergebnis laut Log `/tmp/hindsight-secret-redaction-20260527-085809.log`: 5 Passes, 0 Failures.

## Manifest / Gate
- `./verify-hindsight-manifests.sh`: PASS.
- Ergebnis laut Log `/tmp/hindsight-manifests-verify-20260527-085809.log`: 109 Passes, 0 Warnings, 0 Gaps, 0 Failures.
- `RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh`: FAIL.
- Ergebnis laut Log `/tmp/hindsight-deploy-gate-20260527-085809.log`: 5 Passes, 4 Warnings, 33 Failures.
- Hauptgruende: predeploy gate FAIL wegen public Ingress-Regel, Cluster/CRD/Dry-run-Pruefungen wegen nicht erreichbarem `k3-1`.

## Optional Overall Check
- `./run-baseline-gates.sh`: ausgefuehrt, aber FAIL.
- Die FAILs stammen in dieser Umgebung aus gesperrten SSH-/DNS-Zugriffen (`Operation not permitted`) und `/dev/fd/*`-Beschraenkungen in Unter-Skripten.

## Notification
- ALERT_REQUIRED bleibt `ja`.
- Kein sicherer voll konfigurierter Hindsight-Benachrichtigungskanal im Repo gefunden.
- `NOTIFICATION_CHANNEL_MISSING`
- Fehlende Details:
- Empfaenger/Kanal fuer Hindsight-Ops-Alerts.
- Dokumentierter Notifier-Command oder Script-Pfad.
- Benannte Receiver-/Webhook-/Env-Konfiguration fuer Alertmanager oder direkten Versand.

## Ausgefuehrte Checks
| Check | Exit-Code | Kurzresultat |
| --- | ---: | --- |
| `kubectl get ns hindsight` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight get deploy ...` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight get pods -o wide` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight get svc -o wide` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight get cronjob` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight exec deploy/hindsight-api ...` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight exec deploy/hindsight-ui ...` | 1 | FAIL, fehlender Kontext `orbstack` |
| `kubectl -n hindsight exec deploy/hindsight-ollama -- ollama list` | 1 | FAIL, fehlender Kontext `orbstack` |
| `./verify-hindsight-bank-mapping.sh` | 0 | PASS |
| `./verify-hindsight-secret-redaction.sh` | 0 | PASS |
| `./verify-hindsight-manifests.sh` | 0 | PASS |
| `RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh` | 1 | FAIL |
| `timeout 600 ./run-baseline-gates.sh` | 1 | FAIL |

## Logpfade / Reproduktion
- Run-Dir: `/private/tmp/hindsight-daily-ops/2026-05-27T085808`
- Live-check stderr-Beispiel: `/private/tmp/hindsight-daily-ops/2026-05-27T085808/ns_hindsight.stderr.txt`
- Bank-Mapping-Log: `/tmp/hindsight-bank-mapping-20260527-085808.log`
- Secret-Redaction-Log: `/tmp/hindsight-secret-redaction-20260527-085809.log`
- Manifest-Log: `/tmp/hindsight-manifests-verify-20260527-085809.log`
- Deploy-Gate-Log: `/tmp/hindsight-deploy-gate-20260527-085809.log`
- Baseline-stdout: `/private/tmp/hindsight-daily-ops/2026-05-27T085808/baseline_gates.stdout.txt`
- Sekundaerevidenz:
- `/Users/activi/Documents/activi K3s/reports/k3s-cleanup-inventory_2026-05-27_04-04-02/01_get_pods_all_wide.stdout.txt`
- `/Users/activi/Documents/activi K3s/reports/k3s-cleanup-inventory_2026-05-27_04-04-02/02_get_workloads_core.stdout.txt`
- `/Users/activi/Documents/activi K3s/reports/k3s-cleanup-inventory_2026-05-27_04-04-02/03_get_namespaces.stdout.txt`
- `/Users/activi/Documents/activi K3s/reports/k3s-cleanup-inventory_2026-05-27_04-04-02/05_get_events_recent.stdout.txt`

## Naechste empfohlene Schritte
- Lokalen `kubectl`-Zugriff reparieren: gueltigen K3s-Kontext setzen oder den verwaisten `orbstack`-Current-Context entfernen, dann die Hindsight-Live-Checks erneut laufen lassen.
- Wenn die Gates ausserhalb dieser Sandbox laufen sollen: auf einer Umgebung mit erlaubtem SSH/DNS/Netzwerk erneut `RUN_BASELINE=0 ./run-hindsight-deploy-gate.sh` und `./run-baseline-gates.sh` ausfuehren.
- Predeploy-Gate-Regel an den inzwischen dokumentierten Public-Ingress-Zielzustand anpassen oder die Rule explizit fuer "post-approval public ingress" versionieren.
- Optional nach Freigabe: separaten read-only End-to-End-Healthlauf von einem Host mit Clusterzugriff ausfuehren, insbesondere API-Health, `ollama list`, aktuelle Restart-Zaehler und Retain/Recall-Smoketest mit synthetischen Werten.

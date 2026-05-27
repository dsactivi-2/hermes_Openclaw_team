# Deploy Pipeline Side Project - 2026-05-27

Dieses Dokument beschreibt das Nebenprojekt fuer eine lokale Deploy-Pipeline
im Repo `/Users/activi/Documents/activi K3s`. Ziel ist ein wiederverwendbares
Playbook-System, das kuenftige Kubernetes-App-Deployments schneller,
reproduzierbarer und sicherer fuehrt.

Status: geplant und als Agentenauftrag vorbereitet. Noch nicht als gebautes
und verifiziertes Pipeline-System bestaetigt.

## Ziel

Die Deploy-Pipeline soll kein vollautomatisches CI/CD-System sein. Sie soll ein
lokaler, kontrollierter Pipeline-Assistent fuer Agentenarbeit werden.

Sie soll:

- Phasen-Prompts erzeugen;
- Fix-Prompts erzeugen;
- Reports pro App und Phase ablegen oder referenzieren;
- Reports auf `RESULT: PASS`, `RESULT: PASS_WITH_GAPS` oder `RESULT: FAIL`
  pruefen;
- Freigabe-Gates erzwingen;
- Locks gegen parallele Bearbeitung derselben App/Phase fuehren;
- Preflight-, Dry-run- und Postdeploy-Pruefungen standardisieren;
- Dokumentations- und Backup/Ops-Pflichten sichtbar machen.

Sie soll nicht:

- Codex, Hermes, OpenClaw oder andere Agenten automatisch fernsteuern;
- echte Deploys ohne explizite Freigabe ausfuehren;
- Secrets lesen, decodieren, speichern oder ausgeben;
- DNS, Longhorn, Velero, cert-manager, IngressClass oder andere globale
  Cluster-Komponenten automatisch aendern;
- Argo CD, Flux, GitHub Actions oder GitLab CI ersetzen.

## Geplante Struktur

```text
deploy-pipeline.sh
pipelines/
  k8s-app/
    master_prompt.md
    fix_prompt.md
    report_contract.md
    gates.md
    phases/
      01-discovery.md
      02-design.md
      03-draft.md
      04-dry-run.md
      05-preflight.md
      06-deploy-approval.md
      07-deploy.md
      08-postdeploy.md
      09-backup-ops.md
      10-docs.md
    checks/
      check-phase.sh
  templates/
    web-app/
    worker-app/
    cnpg-app/
    redis-app/
    minio-app/
    ingress-tls/
    backup-ops/
    monitoring-probes/
pipeline-state/
pipeline-reports/
docs/APP-DEPLOYMENT-PLAYBOOK.md
```

## Geplante Befehle

```bash
./deploy-pipeline.sh init <app>
./deploy-pipeline.sh next <app>
./deploy-pipeline.sh prompt <app> <phase>
./deploy-pipeline.sh report <app> <phase> <report-file>
./deploy-pipeline.sh verify <app> <phase>
./deploy-pipeline.sh fix <app> <phase>
./deploy-pipeline.sh status <app>
./deploy-pipeline.sh phases
./deploy-pipeline.sh list
./deploy-pipeline.sh locks
./deploy-pipeline.sh lock <app>
./deploy-pipeline.sh unlock <app>
./deploy-pipeline.sh clean-lock <app>
./deploy-pipeline.sh git-summary <app>
./deploy-pipeline.sh doctor
./deploy-pipeline.sh help
```

## Phasen

1. `01-discovery`
   Read-only Inventar und alle fehlenden Pflichtfragen sammeln. Kein Code, kein
   Deploy.

2. `02-design`
   Architekturvorschlag mit Komponenten, Datenfluss, DB, Storage, Ingress,
   Backup, Monitoring, Risiken und offenen Entscheidungen. Kein Code ohne
   Freigabe.

3. `03-draft`
   Lokale YAML-/Helm-/Kustomize-Drafts, Secret-Schema und erste Scripts. Keine
   echten Secret-Werte und keine Cluster-Aenderung.

4. `04-dry-run`
   `helm template`, `helm lint`, `kubectl apply --dry-run=server` und
   `kubeconform`, soweit verfuegbar. Technische Fehler beheben, fachliche
   Unklarheiten fragen.

5. `05-preflight`
   Script-first Preflight mit Namespace, CRDs, StorageClass, Secrets, DNS,
   Ingress-Konflikten, bestehenden Ressourcen, Operators und Problem-Pods.

6. `06-deploy-approval`
   Finale Zusammenfassung und Stop bis zur ausdruecklichen Freigabe
   `DEPLOY NOW`.

7. `07-deploy`
   Echter Deploy nur nach Freigabe. Keine Zusatz-Aenderungen ausserhalb des
   Plans.

8. `08-postdeploy`
   Script-first Pruefung von Pods, Rollouts, PVCs, Longhorn, Ingress, TLS, DNS,
   API-Health, Events und Problem-Pods.

9. `09-backup-ops`
   CNPG/DB-Backup, Longhorn RecurringJobs, Velero Schedule, Restore-Test,
   Monitoring/Alerts und Runbook. Apply nur nach separater Freigabe.

10. `10-docs`
    Runbook/Status aktualisieren: Ist-Zustand, Domains, Ressourcen,
    Secret-Namen, Backup, Restore, Monitoring, Gaps und naechste Schritte.

## Harte Gates

Diese Aktionen duerfen nie automatisch passieren:

- real deploy;
- `kubectl apply`;
- `helm install` oder `helm upgrade`;
- Secrets erstellen oder aendern;
- DNS aendern;
- Longhorn, Velero, cert-manager, IngressClass oder globale Cluster-Settings
  aendern;
- `delete`, produktiver Rollback oder Restore.

Diese Phasen brauchen immer eine klare menschliche Freigabe:

- `06-deploy-approval`;
- `07-deploy`;
- `09-backup-ops`, wenn echte Aenderungen angewendet werden sollen.

## Verify-Vertrag

Ein Phasenreport muss genau eine Ergebniszeile enthalten:

```text
RESULT: PASS
```

oder:

```text
RESULT: PASS_WITH_GAPS
ACCEPTED_GAPS: yes
```

oder:

```text
RESULT: FAIL
```

Regeln:

- `PASS` gibt die naechste Phase frei, ausser es ist ein hartes Gate.
- `PASS_WITH_GAPS` gibt nur weiter frei, wenn `ACCEPTED_GAPS: yes`
  dokumentiert ist.
- `FAIL` erzeugt einen Fix-Prompt und bleibt in derselben Phase.
- Deploy-Phasen duerfen nicht automatisch weitergehen, wenn keine explizite
  Freigabe dokumentiert ist.

## Lock-Regeln

Pro App soll es eine Lock-Datei geben:

```text
pipeline-state/<app>.lock
```

Sie soll enthalten:

- App;
- Phase;
- Owner/Agent;
- Created at;
- Reason.

Wenn ein Lock existiert, muessen `next`, `prompt`, `report`, `verify` und
`fix` warnen oder stoppen. Ziel: keine parallele Bearbeitung derselben
App/Phase.

Parallel erlaubt ist nur Arbeit an getrennten Apps oder klar getrennten Phasen
ohne Shared-State. Nicht parallel erlaubt sind Arbeiten an:

- globalen Cluster-Komponenten;
- DNS;
- cert-manager;
- ingress-nginx;
- Longhorn globalen Settings;
- Velero globalen Settings;
- gleicher App oder gleichem Namespace;
- gleichen Secrets.

## Script-First Standard

Jede wiederholbare oder umfangreiche Pruefung soll als Script erfolgen, wenn
das Risiko dadurch nicht steigt.

Scripts muessen:

- `set -euo pipefail` verwenden;
- klare PASS/WARN/FAIL-Ausgaben liefern;
- keine Secret-Werte ausgeben oder decodieren;
- read-only starten, wenn echte Aenderungen nicht freigegeben sind;
- Logpfade ausgeben;
- mit eindeutigen Stop-Kriterien enden;
- keine wilden `rm` oder destruktiven Befehle enthalten.

## Git-Regeln

Git bleibt Code-Wahrheit.

Die Pipeline soll:

- vor Aenderungen optional `git status --short` anzeigen;
- geaenderte Dateien im Abschlussbericht nennen;
- fremde Aenderungen nicht ueberschreiben;
- keine Commits automatisch erstellen;
- nichts automatisch pushen.

## Hindsight-/Memory-Regeln

- Hindsight ist Memory, nicht Koordinator.
- Pipeline-State ist Deploy-Prozess-Wahrheit.
- Git ist Code-Wahrheit.
- Keine Secrets in Hindsight.
- Empfohlene Memory-Tags:
  - `project:activi-k3s`
  - `component:deploy-pipeline`
  - `type:runbook`
  - `env:local`
  - `framework:<codex|hermes|openclaw>`
  - `status:<planned|in-progress|done|blocked>`

## Portainer-Abgrenzung

Portainer ist fuer Sichtpruefung erlaubt:

- Ressourcen ansehen;
- UI-Verstaendnis;
- Statuskontrolle.

Deploy-Quelle bleibt:

- Git/Repo;
- YAML/Helm/Kustomize;
- Terminal mit `ssh k3-1 'kubectl ...'`;
- Pipeline-Scripts.

## Was spaeter geprueft werden muss

Wenn ein Agent meldet, dass das Pipeline-System gebaut wurde, muss der Main
Agent mindestens pruefen:

1. Existiert `deploy-pipeline.sh` und ist es ausfuehrbar?
2. Existiert die komplette Ordnerstruktur unter `pipelines/`,
   `pipeline-state/` und `pipeline-reports/`?
3. Existieren alle zehn Phasen-Prompts?
4. Existieren `master_prompt.md`, `fix_prompt.md`, `report_contract.md` und
   `gates.md`?
5. Existiert `pipelines/k8s-app/checks/check-phase.sh`?
6. Funktionieren `help`, `phases`, `doctor`, `init`, `next`, `prompt`,
   `report`, `verify`, `fix`, `status`, `lock`, `unlock`, `locks`?
7. Validiert das System App-Namen auf `a-z0-9-`?
8. Stoppt oder warnt das System bei vorhandenen Locks?
9. Akzeptiert `verify` nur Reports mit `RESULT: PASS`,
   `RESULT: PASS_WITH_GAPS` plus `ACCEPTED_GAPS: yes` oder `RESULT: FAIL`?
10. Blockiert es Deploy-Phasen ohne dokumentierte Freigabe?
11. Wurden keine Cluster-Aenderungen ausgefuehrt?
12. Wurden keine Secret-Werte gelesen, decodiert oder ausgegeben?
13. Besteht ein Testlauf mit Dummy-App `demo-app`?
14. Besteht `bash -n` fuer alle neuen Shell-Scripts?
15. Wurde `shellcheck` genutzt, wenn vorhanden, oder als WARN dokumentiert?
16. Ist `docs/APP-DEPLOYMENT-PLAYBOOK.md` vorhanden und ausreichend?

## Erwarteter Agenten-Abschlussbericht

```text
Pipeline System Build Report

1. Angelegte/geaenderte Dateien:
2. Script-Funktionen:
3. Phasen:
4. Gates/Sicherheitsregeln:
5. Verify-Logik:
6. Testlauf mit demo-app:
7. Shellcheck/Syntaxcheck:
8. Keine Cluster-Aenderungen durchgefuehrt: ja/nein
9. Secrets ausgegeben: nein
10. Offene Punkte/Gaps:
11. Git-Regeln dokumentiert: ja/nein
12. Template-Bibliothek angelegt: ja/nein
13. Lock-System eingebaut: ja/nein
14. Parallel-Agent-Regeln dokumentiert: ja/nein
15. Hindsight/Memory-Regeln dokumentiert: ja/nein
16. Portainer-Abgrenzung dokumentiert: ja/nein
17. Periodische Review-Idee dokumentiert: ja/nein
18. Doctor-Check Ergebnis:
19. Naechster Schritt:
20. RESULT: PASS / PASS_WITH_GAPS / FAIL
21. STOPP-Kriterium erreicht: ja/nein
```

## Periodische Review-Idee

Noch keine Automation erstellen. Spaeter kann eine woechentliche Review
pruefen:

- offene `FAIL` Reports;
- veraltete Locks;
- Apps in unklarer Phase;
- fehlende Docs;
- Drift zwischen Runbooks und Live-Zustand;
- Gaps aus `PASS_WITH_GAPS` Reports.


# Local Deploy Pipeline / Playbook System

Dieses System ist ein **lokaler Deploy-Orchestrator fuer kontrollierte Agentenarbeit**. Es erzeugt und verwaltet:

- fertige Prompts (zum manuellen Copy/Paste in Codex/Hermes/OpenClaw)
- Fix-Prompts
- Status / Pipeline-State
- Reports
- Read-only Pruefungen (Preflight/Doctor)

## 1) Kein automatisches Agent-Steuern

Das Pipeline-System **fernbedient keine Agenten** und startet/steuert keine Automationen.

- Output ist immer nur: Prompts, Status, Reports, Checks.
- Der User kopiert Prompts manuell oder nutzt spaeter separate Automationen.

## 2) Kein echtes CI/CD

Dieses System ist **kein Ersatz** fuer:

- Argo CD / Flux
- GitHub Actions / GitLab CI

Es ist ein **lokales** Orchestrierungs- und Dokumentationswerkzeug fuer reproduzierbare Agentenarbeit, nicht ein vollautomatisches Delivery-System.

## 3) Git-Regeln (Code-Wahrheit)

Git bleibt **Code-Wahrheit**.

- Vor Aenderungen (menschlich oder agentisch): `git status --short`
- Keine fremden Aenderungen ueberschreiben (immer Discovery -> Draft -> Review).
- Abschlussbericht nennt geaenderte Dateien (aus `git status --short`).
- Kein Commit automatisch.
- Kein Push automatisch.
- Optional: `./deploy-pipeline.sh git-summary <app>`

## 4) Rollback nur planen (nicht ausfuehren)

Jede Deploy-Phase dokumentiert einen Rollback-Plan, aber fuehrt ihn **nicht** aus:

- Helm: Plan fuer `helm rollback <release> <revision>`
- kubectl apply: Plan fuer Rueckkehr zur vorherigen Manifest-Version (Git-Revision/Tag)
- Secret-/DB-Restore: nur als Plan; **Restore nur mit separater Freigabe**

Verboten ohne separate Freigabe:

- automatischer Rollback
- `delete`
- `reset`
- `restore`

## 5) Template-Bibliothek (nur Skeleton)

Unter `pipelines/templates/` liegen **nur** README/Prompt-Templates/Skeletons.

- Keine produktiven App-Manifeste automatisch aus Templates applyen.
- Templates sind Startpunkte fuer manuelle Copy/Paste Prompts.

## 6) Secret-Regeln (erweitert)

Erlaubt:

- Secret-Namen pruefen
- Secret-Key-Namen pruefen
- Draft-Scripts fuer interaktive Secret-Erstellung erzeugen (ohne Werte)

Verboten:

- Secret-Werte ausgeben
- Secret-Werte decodieren
- Secret-Werte in Reports speichern
- Secret-Werte in Git schreiben

## 7) DNS-Regeln (erweitert)

Erlaubt:

- DNS read-only pruefen
- erwartete A/CNAME Records dokumentieren
- DNS-Gaps melden

Verboten:

- DNS Provider aendern
- Cloudflare/Hetzner DNS Records automatisch setzen
- Proxy-Status aendern

## 8) Parallel-Agent-Lock

Lock-Datei pro App:

- `pipeline-state/<app>.lock`

Wenn Lock existiert, stoppen folgende Commands:

- `next`, `prompt`, `report`, `verify`, `fix`

Lock-Kommandos:

- `./deploy-pipeline.sh lock <app>`
- `./deploy-pipeline.sh unlock <app>`
- `./deploy-pipeline.sh clean-lock <app>`
- `./deploy-pipeline.sh locks`

Lock-Inhalt:

- App
- Phase
- Owner/Agent
- Created at
- Reason

## 9) Parallel-Agent-Regeln

Parallel ist nur erlaubt bei:

- getrennten Apps, getrennten Namespaces, kein Shared-State
- klar getrennten Phasen ohne Ueberschneidung

Nicht parallel erlaubt:

- globale Cluster-Komponenten
- DNS
- cert-manager
- ingress-nginx
- Longhorn globale Settings
- Velero globale Settings
- gleiche App/Namespace
- gleiche Secrets

Regel:

- Jeder Agent prueft **vor Start** Status/Lock und meldet **nach Ende** Ergebnis (Report/Status).

## 10) Hindsight / Memory Regeln

- Git bleibt Code-Wahrheit.
- Pipeline-State bleibt Deploy-Prozess-Wahrheit.
- Hindsight bleibt Memory, nicht Koordinator.
- Keine Secrets in Hindsight.

Empfohlene Tags:

- `project:activi-k3s`
- `component:deploy-pipeline`
- `type:runbook`
- `env:local`
- `framework:codex/hermes/openclaw`
- `status:planned/in-progress/done/blocked`

## 11) Portainer Abgrenzung

Portainer ist erlaubt fuer:

- Sichtpruefung
- UI-Verstaendnis
- Ressourcen ansehen

Deploy-Quelle bleibt:

- Git/Repo
- YAML/Helm
- Terminal (`kubectl`/`helm`)
- Pipeline-Scripts (read-only orchestrator)

## 12) Periodische Qualitaetspruefung (Vorbereitung)

Noch keine Automation, aber vorgesehen:

- woechentlicher Review moeglich
- prueft Pipeline-State, offene Gaps, FAIL Reports, veraltete Locks, Docs-Drift
- spaeter ggf. als Codex-Automation umsetzbar

## 13) Befehle

- `./deploy-pipeline.sh list`
- `./deploy-pipeline.sh phases`
- `./deploy-pipeline.sh status <app>`
- `./deploy-pipeline.sh next <app>`
- `./deploy-pipeline.sh prompt <app>`
- `./deploy-pipeline.sh fix <app>`
- `./deploy-pipeline.sh verify <app>`
- `./deploy-pipeline.sh report <app>`
- `./deploy-pipeline.sh locks`
- `./deploy-pipeline.sh lock <app>`
- `./deploy-pipeline.sh unlock <app>`
- `./deploy-pipeline.sh clean-lock <app>`
- `./deploy-pipeline.sh git-summary <app>`
- `./deploy-pipeline.sh doctor` (read-only Struktur/Lock/Shell-Syntax Check)

## V1: State/Reports sind lokal (nicht in Git)

- `pipeline-state/*.state` ist laufender Prozess-/Arbeitszustand und wird **nicht** in Git versioniert.
- `pipeline-state/*.lock` und `pipeline-reports/` sind ebenfalls **nicht** in Git.
- In Git bleiben nur: `.gitkeep`, Templates, Playbooks, Doku.

## 14) Erweiterter Abschlussbericht

Der Report enthaelt explizit:

- Git-Regeln dokumentiert: ja/nein
- Template-Bibliothek angelegt: ja/nein
- Lock-System eingebaut: ja/nein
- Parallel-Agent-Regeln dokumentiert: ja/nein
- Hindsight/Memory-Regeln dokumentiert: ja/nein
- Portainer-Abgrenzung dokumentiert: ja/nein
- Periodische Review-Idee dokumentiert: ja/nein
- Doctor-Check Ergebnis
- RESULT: `PASS` / `PASS_WITH_GAPS` / `FAIL`

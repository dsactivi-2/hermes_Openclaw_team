# Copy-Paste Startprompt fuer neue Agenten-Session

```text
Du bist der neue Agent fuer das activi K3s-Projekt.

Arbeitsverzeichnis:
/Users/activi/Documents/activi K3s

Sprache:
Deutsch.

Ziel:
Arbeite nicht aus altem Chat-Gedaechtnis. Lies zuerst die Projektunterlagen, pruefe danach den Live-Zustand read-only, und fuehre anschliessend nur den explizit vom User freigegebenen Block aus. Wenn etwas unklar ist oder von den Unterlagen abweicht, stoppe und frage konkret.

Pflichtdateien zuerst lesen:
1. /Users/activi/Documents/activi K3s/docs/SESSION-HANDOVER-2026-05-24.md
2. /Users/activi/Documents/activi K3s/docs/ACCESS-CONNECTIONS-2026-05-24.md
3. /Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
4. /Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
5. /Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
6. /Users/activi/Documents/activi K3s/docs/OPEN-TODOS-2026-05-22.md
7. /Users/activi/Documents/activi K3s/docs/FULL-PROJECT-HANDOVER-PROMPT-2026-05-22.md
8. /Users/activi/Documents/activi K3s/docs/K3S-APP-INTEGRATION-STANDARD-2026-05-24.md
9. /Users/activi/Documents/activi K3s/docs/APP-ONBOARDING-QUESTIONNAIRE-2026-05-24.md

Pflichtregeln:
- Keine Secrets, Tokens, Passwoerter, Kubeconfig-Inhalte oder privaten SSH-Key-Inhalte ausgeben.
- Keine produktiven Ressourcen loeschen.
- Keine DNS-, Cloudflare-, Hetzner-Firewall-, StorageClass-, Longhorn-, Portainer-, Velero-, CloudNativePG-, Monitoring- oder App-Aenderungen ohne explizite, eng begrenzte Freigabe.
- Keine App deployen, bevor der User den konkreten App-Block freigibt.
- Keine Test-/Smoke-Ressourcen loeschen, ausser der User gibt genau das frei.
- Wenn ein Befehl Secret-Inhalte ausgeben wuerde: nicht ausfuehren.
- Wenn ein Schritt unklar ist: stoppen und fragen, nicht raten.

Vor jeder Aenderung diese Baseline ausfuehren:

cd "/Users/activi/Documents/activi K3s"
./audit-recent-stack-claims.sh
./verify-k3s-stack-complete.sh
./audit-production-readiness-gaps.sh
./verify-portainer-api-connectivity.sh

Erwartung:
- audit-recent-stack-claims.sh: PASS
- verify-k3s-stack-complete.sh: PASS
- audit-production-readiness-gaps.sh: PASS_WITH_GAPS ohne Failures
- verify-portainer-api-connectivity.sh: PASS

Wenn ein Skript Failures meldet:
Stoppen und Diagnose melden. Keine automatische Reparatur.

Wichtiger aktueller Stand:
- K3s HA mit 3 Nodes, Version v1.32.1+k3s1.
- Server 1: ssh k3-1, private IP 10.0.1.10.
- Server 2: ssh kube3-2, private IP 10.0.1.20.
- Server 3: ssh -o IdentitiesOnly=yes -i ~/.ssh/k3-3 root@167.235.6.160, private IP 10.0.1.30.
- longhorn ist einzige Default StorageClass.
- local-path existiert nur noch fuer Altbestand und ist nicht Default.
- Portainer Business Edition laeuft produktiv auf Longhorn unter https://portainer.activi.io.
- Alter PVC portainer/portainer auf local-path ist nur Rollback-Altbestand und darf nicht ohne eigenen Cleanup-Block geloescht werden.
- ingress-nginx, cert-manager, Longhorn, Velero, CloudNativePG/Barman und kube-prometheus-stack sind installiert.
- Prometheus Targets waren zuletzt 23/23 up.
- Offene Themen stehen in SESSION-HANDOVER-2026-05-24.md und OPEN-TODOS-2026-05-22.md.

Arbeitsweise:
1. Pflichtdateien lesen.
2. Live-Zustand read-only pruefen.
3. Dem User kurz melden, ob Baseline gruen ist.
4. Nur den explizit freigegebenen Block bearbeiten.
5. Nach jeder Aenderung die passenden Audits erneut ausfuehren.
6. Dokumentation nur aktualisieren, wenn der Live-Zustand wirklich geprueft wurde.
```


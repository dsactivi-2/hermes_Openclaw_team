# Portainer Ingress/TLS Handover Prompt - 2026-05-21

Status 2026-05-21 23:18 CEST: abgeschlossen und nur noch historisch.

Dieser fruehere Handover-Prompt darf nicht mehr als Arbeitsgrundlage fuer eine
neue Session verwendet werden. Der darin geplante Block ist erledigt:

- Ingress `portainer/portainer` fuer `portainer.activi.io` ist erstellt.
- IngressClass ist `nginx`.
- Backend ist Service `portainer`, Port `9443`.
- Annotation `nginx.ingress.kubernetes.io/backend-protocol: HTTPS` ist gesetzt.
- Certificate `portainer/portainer-activi-io-tls` ist `Ready=True`.
- TLS Secret `portainer/portainer-activi-io-tls` existiert als Metadaten, Typ
  `kubernetes.io/tls`, `DATA=2`; Secret-Inhalte duerfen nicht ausgegeben werden.
- `http://portainer.activi.io` leitet mit `308` auf HTTPS um.
- `https://portainer.activi.io` liefert `HTTP/2 200` und Portainer.
- Der fruehere NodePort-Fallback wurde danach geschlossen: Portainer Service ist
  `ClusterIP`, und clusterweit existieren keine `NodePort` Services mehr.

Aktuelle Pruefbelege:

```text
Recent-Audit: RESULT: PASS, Passes: 46, Warnings: 0, Failures: 0
Log: /tmp/k3s-recent-stack-claims-audit-20260521-233143.log

Full-Verify: RESULT: PASS, Passes: 119, Warnings: 0, Failures: 0
Log: /tmp/k3s-stack-complete-verify-20260521-233236.log
```

Naechste aktive Arbeitsgrundlagen sind:

```text
/Users/activi/Documents/activi K3s/docs/PROJECT-STATUS-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/NEXT-SESSION-GUIDE-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/K3S-HETZNER-SKILLS-HANDOVER-2026-05-20.md
/Users/activi/Documents/activi K3s/docs/BACKUP-RUNBOOK-2026-05-20.md
/Users/activi/Documents/activi K3s/audit-recent-stack-claims.sh
/Users/activi/Documents/activi K3s/verify-k3s-stack-complete.sh
```

Naechste offene Bloecke:

1. Ersten automatischen OS-Restic Timerlauf auf Server 2/3 pruefen.
2. Portainer komplett einrichten; Business Edition 3 Nodes Free separat bewerten.
3. Portainer kontrolliert auf Longhorn migrieren; Zielpflicht vor groesseren produktiven App-Installationen.
4. Monitoring/Alerting einrichten.
5. Erst danach produktive Apps installieren oder migrieren.

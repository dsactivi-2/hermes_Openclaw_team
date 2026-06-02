# CHECKLISTEN

## Täglicher Healthcheck (08:00)

- [ ] CPU < 75%
- [ ] RAM < 80%
- [ ] Disk < 80%
- [ ] Alle Services running (docker ps, kubectl get pods)
- [ ] Gateway antwortet
- [ ] Letztes Backup < 24h

## Wöchentlicher Security-Scan (Mi 02:00)

- [ ] UFW Status prüfen
- [ ] fail2ban Status prüfen
- [ ] Offene Ports prüfen (ss -tlnp)
- [ ] SSH Brute-Force prüfen
- [ ] Pending Updates prüfen
- [ ] Letzte 10 Logins prüfen (last)
- [ ] Docker-Images auf known vulnerabilities

## Pre-Deployment

- [ ] Backup vorhanden
- [ ] Preflight-Check OK
- [ ] Wartungsfenster eingehalten
- [ ] Änderungen committet
- [ ] Policy-Level bekannt
- [ ] Rollback-Plan vorhanden

## Post-Deployment

- [ ] Service läuft (systemctl is-active)
- [ ] Health-Endpoint antwortet 200
- [ ] Keine neuen Fehler in Logs
- [ ] Audit-Log geschrieben
- [ ] Team benachrichtigt

## Incident-Response

- [ ] Incident klassifiziert
- [ ] Erste Diagnose abgeschlossen
- [ ] Fix angewandt (mit Approval falls nötig)
- [ ] Validierung durchgeführt
- [ ] Post-Mortem erstellt
- [ ] Präventions-Maßnahme eingetragen
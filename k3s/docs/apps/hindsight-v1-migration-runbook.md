# Hindsight V1 Migration-Runbook - lokale Daten zu activi K3s

Stand: 2026-05-25
Status: Migrationsplanung, keine Server- oder Cluster-Aenderung ohne Freigabe

## 1. Zweck

Dieses Runbook beschreibt die kontrollierte Migration bestehender Hindsight-
Daten in die spaetere K3s-Hindsight-V1-Installation. Primaere Quelle ist das
lokale Mac-Hindsight. Server-1-Docker-Hindsight wird nicht als Zielbasis genutzt
und nur optional ganz am Ende als zusaetzliche Quelle geprueft.

Gueltige Regeln:

- Alt-Systeme bleiben unveraendert.
- Server-1-Docker-Hindsight wird bis zum optionalen Schlussblock ignoriert.
- Alte Dumps sind nur Referenz.
- Fuer die Migration wird spaeter ein frischer lokaler Export oder API-basierter
  Importpfad festgelegt.
- Keine produktive Migration ohne separaten Freigabeblock.

## 2. Bekannte Migrationsquellen

Primaere Quelle:

```text
Mac:
  /Users/activi/.hindsight/
  /Users/activi/Documents/Hindsight 2/

Aktuelle lokale Hinweise:
  Hindsight 0.6.2
  lokale Banks im Format local-codex::<folder>--<hash>
  Zielstandard project:<name>
```

Optionale spaete Quelle:

Aus den Projektunterlagen bekannter Altbestand:

```text
Server:
  Server 1

Runtime:
  Docker / Compose

Compose:
  /root/hindsight/docker-compose.yml

Hindsight Image:
  ghcr.io/vectorize-io/hindsight:latest

Postgres Image:
  pgvector/pgvector:pg16

Ports:
  API 8888
  UI 9999
  Postgres 5432

Volumes:
  hindsight-data
  hindsight_hindsight-data
  hindsight_hindsight-postgres-data

Referenz-Dumps:
  /var/lib/k3s-backup/postgres-dumps/
```

Diese Angaben muessen vor Migration read-only verifiziert werden.

## 3. Migrationsziel

```text
namespace: hindsight
database: CloudNativePG PostgreSQL + Longhorn PVC
backup: Barman Cloud Plugin + pg_dump + Velero + Longhorn
postgres extension: pgvector erforderlich
shared bank: project:<name>
old bank pattern: local-codex::<folder>--<hash>
```

Ziel ist keine 1:1-Blindmigration, sondern ein kontrollierter Import mit
Validierung und Fallback.

## 4. Read-only Inventar vor Migration

Vor jedem Export wird nur lesend ermittelt:

```text
Docker:
  laufende Container
  verwendete Images und Tags
  Compose-Datei ohne Secret-Ausgabe
  Volume-Namen
  Container Health

Postgres:
  DB-Groesse
  Tabellenliste
  Extension-Liste
  pgvector vorhanden
  Anzahl Banks
  Anzahl Documents
  Anzahl Memories/Nodes
  groesste Tabellen

Hindsight:
  API Health
  UI Health
  bekannte Banks
  aktuelle Projektbank
  Mental Models falls vorhanden
  Retain/Recall Zustand
```

Keine Secret-Werte ausgeben. Verbindlich sind nur aggregierte Ergebnisse und
Pfad-/Objektnamen ohne sensitive Inhalte.

## 5. Export-Strategien

### Option A: DB-Dump und Restore

Geeignet, wenn:

- Quell- und Zielversion kompatibel sind
- Schema kompatibel ist
- Hindsight offiziell oder praktisch DB-Restore unterstuetzt
- pgvector-Version passt

Risiko:

- kopiert Altlasten und alte Bank-Namen mit
- Schema- oder Versionsabweichungen koennen brechen
- schwerer zu kuratieren

### Option B: API-/Dokument-Export und Re-Retain

Geeignet, wenn:

- Rohdokumente oder Memory-Quellen sauber exportierbar sind
- Banks bewusst neu strukturiert werden sollen
- `project:<name>` sauber eingefuehrt werden soll
- Tags, Authority und Retention korrigiert werden sollen

Risiko:

- Fact Extraction kann andere Ergebnisse liefern
- benoetigt Retain-Gesundheit im Zielsystem
- Rohquellen muessen verfuegbar sein

### Option C: Hybrid

Empfehlung fuer V1:

- frischen DB-Dump als vollstaendige Sicherung erzeugen
- wichtige Rohquellen und Projektunterlagen kontrolliert neu retainen
- ausgewaehlte Alt-Memories gezielt uebernehmen, falls exportierbar
- alte Bank-Namen auf `project:<name>` mappen
- Docker-Hindsight als Fallback behalten

## 6. Bank-Mapping

Zielstandard:

```text
project:<name>
```

Altbestand:

```text
local-codex::<folder>--<hash>
```

Mapping-Tabelle vor Migration erstellen:

```text
alt_bank_id                         ziel_bank_id           status
local-codex::activi K3s--<hash>     project:activi-k3s     migrieren
local-codex::hindsight-2--<hash>    project:hindsight      pruefen
test-*                              nicht migrieren        testdaten
retain-healthcheck-*                nicht migrieren        testdaten
```

Regel:

- Testbanks nicht produktiv importieren.
- Unklare Banks erst als `status:historical` inventarisieren.
- Kein automatisches Zusammenlegen ohne Pruefung.

## 7. Dokument- und Memory-Klassen

Vor Import klassifizieren:

```text
authority:source-of-truth:
  aktuelle Projektunterlagen, Runbooks, freigegebene Decisions.

authority:historical:
  alte Handover, alte Planungsstaende, Audit-relevante Versionen.

authority:draft:
  Entwuerfe, nicht freigegebene Plaene, alte Agentenantworten.

status:obsolete:
  ersetzte Aussagen, alte technische Annahmen, erledigte Tests.

retention:short:
  Debug- und Testdaten.

retention:long:
  Migrationsergebnisse, Entscheidungen, Runbooks.
```

## 8. Migrationsphasen nach Freigabe

Nur nach separater Freigabe ausfuehren:

1. Server-1 read-only Inventar erstellen.
2. Frischen Postgres-Dump/Export erzeugen.
3. Dump-Integritaet pruefen.
4. Ziel-Hindsight V1 ohne Migration validieren.
5. Zielbank `project:<name>` vorbereiten.
6. 8 Mental Models importieren.
7. Projektunterlagen und Runbooks kontrolliert retainen.
8. Altbanks anhand Mapping uebernehmen oder bewusst auslassen.
9. Recall-Stichproben gegen Alt- und Zielsystem vergleichen.
10. Retain-Test mit neuer Information im Zielsystem ausfuehren.
11. Mental Models refreshen.
12. Validierungsbericht erstellen.
13. Cutover nur nach separater Freigabe.

## 9. Validierung

Migration gilt nur als bestanden, wenn diese Punkte nachweisbar sind:

```text
Struktur:
  Zielbank project:<name> existiert
  keine produktive Nutzung von local-codex::<folder>--<hash> als Zielbank
  Pflicht-Tags sind auf neuen Memories vorhanden

Daten:
  Document-Zaehler plausibel
  Memory-/Node-Zaehler plausibel
  wichtige Runbooks vorhanden
  wichtige Decisions vorhanden
  alte Drafts nicht als aktuelle Wahrheit markiert

Recall:
  bekannte alte Informationen werden gefunden
  bekannte neue Testinformation wird gefunden
  falsche/testhafte Banks werden nicht als Wahrheit genutzt

Retain:
  neuer Retain-Test erzeugt Fakten
  Retain erzeugt nicht wieder 0 Fakten

Mental Models:
  alle 8 Modelle vorhanden
  Refresh erfolgreich
  Modelle nicht leer
  Modelle lesen primar project:<name>

Backup:
  nach Migration pg_dump verfuegbar
  CloudNativePG Backup aktiv
  Velero Namespace Backup geplant oder ausgefuehrt
```

## 10. Cutover

Cutover darf erst erfolgen, wenn:

- Zielsystem technisch validiert ist
- Migration validiert ist
- Backup/Restore validiert ist
- Zugriff fuer Zielagenten funktioniert
- Docker-Hindsight als Fallback weiter laeuft
- User separate Cutover-Freigabe erteilt

Cutover-Aktion:

- Agenten-Konfigurationen auf neue interne Hindsight API/MCP umstellen.
- Erst eine kleine Agentengruppe umstellen.
- Retain/Recall pruefen.
- Dann weitere Agenten umstellen.

## 11. Rollback

Rollback ist einfach, solange Docker-Hindsight nicht veraendert wurde:

- Agenten-Konfiguration zurueck auf Server-1-Docker-Hindsight oder lokalen Fallback.
- K3s-Hindsight nicht als Wahrheit verwenden.
- Fehlerbericht schreiben.
- Keine Daten loeschen.
- Keine Altinstanz stoppen.

## 12. Offene Punkte vor Migration

- frische DB-Groesse von Server 1
- genaue Banks und Zaehler
- Hindsight-Zielversion und Schema-Kompatibilitaet
- offizieller oder praktikabler Exportweg fuer Documents/Memories
- Ziel-PVC-Groesse
- pgvector-Version und CloudNativePG-Initialisierungsweg
- Migrationsformat pro Bank
- Retention-Entscheidungen fuer alte Drafts/Testdaten
- Cutover-Zeitpunkt

## 13. Lokales Bank-Inventar 2026-05-26

Read-only Inventar:

```text
/Users/activi/Documents/activi K3s/docs/apps/hindsight-local-bank-inventory-2026-05-26.md
```

Ergebnis:

- 16 Bank-IDs aus lokalem Hook-State `bank_missions.json` erkannt.
- Historische Gesamtwerte aus den lokalen Projektunterlagen:
  83 Banks, 90 Documents, 254 Chunks, 1909 Memory Units, 7086 Entities.
- Per-Bank-Zaehler brauchen eine laufende lokale Hindsight-API oder direkten
  PostgreSQL-Zugriff und wurden in diesem Block nicht live verifiziert.

Mapping-Vorschlag:

- `local-codex::activi K3s` und `local-codex::activi K3s--899ea982e4`
  -> `project:activi-k3s`
- `local-codex::Hindsight 2--3eab1f4caa` -> `project:hindsight`
- `local-codex::Codex MCP setup--e1b8cd6106` und
  `local-codex::richte-das-global-f-r-codex--205a6a6960` -> `org:shared`
- Prompt-abgeleitete oder unklare Banks -> `org:inbox` zur Triage

Keine Migration wurde ausgefuehrt.

## 14. Codex-Verbindungsumschaltung

Aktueller Stand:

- Lokale Hindsight-Hooks existieren in `/Users/activi/.codex/hooks.json`.
- `/Users/activi/.hindsight/codex.json` nutzt `projectBankMode`.
- `/Users/activi/.hindsight/codex.json` nutzt derzeit lokalen Daemon-Modus,
  weil `hindsightApiUrl` leer ist.
- `/Users/activi/.codex/config.toml` markiert die Hook-State-Eintraege aktuell
  als `enabled = false`.

Codex weiss das richtige Projekt ueber:

1. `.hindsight-project` im Workspace,
2. `projectBankMappings` in `/Users/activi/.hindsight/codex.json`,
3. sonst `org:inbox`.

Lokaler Modus:

```text
Codex -> Hooks -> http://127.0.0.1:9077 -> lokale Hindsight-Instanz
```

K3s-Modus ohne Public Ingress:

```text
ssh k3-1 'kubectl -n hindsight port-forward svc/hindsight-api 9077:80'
```

Dann in `/Users/activi/.hindsight/codex.json`:

```json
"hindsightApiUrl": "http://127.0.0.1:9077"
```

Wichtig: Wenn lokale Hindsight-API und K3s-Portforward denselben Port nutzen,
darf nur eine Quelle auf `127.0.0.1:9077` laufen. Alternativ einen anderen
lokalen Port verwenden und `hindsightApiUrl` entsprechend setzen.

Public-Modus erst nach separater Freigabe:

```text
Codex -> gesicherte Hindsight API URL
```

Nicht fuer den jetzigen Stand:

- Public Ingress nur fuer Codex oeffnen.
- Alte `local-codex::*` Banks blind als Zielbank weiterverwenden.
- Memories ohne Mapping und Secret-Redaction importieren.

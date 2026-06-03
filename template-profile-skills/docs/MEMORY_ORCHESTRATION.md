# MEMORY & ORCHESTRATION — Wer speichert was? Wer weiss was? Wann?

## 1. MEMORY-ARCHITEKTUR (AKTUELL)

```
┌──────────────────────────────────────────────────────────────┐
│                      MEMORY-STACK                            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  HOLOGRAPHIC (Memory Provider, AKTIV)               │     │
│  │                                                     │     │
│  │  • SQLite-DB: ~/.hermes/memory_store.db             │     │
│  │  • Graph + Entity-Resolution + Trust-Scoring        │     │
│  │  • Tools: fact_store, fact_feedback                 │     │
│  │  • Speichert: Fakten + Beziehungen + Vertrauen      │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  BUILT-IN MEMORY (Immer aktiv)                      │     │
│  │                                                     │     │
│  │  • JSON-Dateien: ~/.hermes/memories/                │     │
│  │  • memory tool (add/replace/remove)                 │     │
│  │  • Wird im System Prompt injiziert                  │     │
│  │  • Limit: 4.000 Zeichen                             │     │
│  │  • Speichert: User-Profil + persönliche Notizen     │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  SESSION MEMORY (Automatisch)                       │     │
│  │                                                     │     │
│  │  • SQLite: ~/.hermes/sessions/                      │     │
│  │  • session_search Tool                              │     │
│  │  • Speichert: Alle Gespräche (Transkripte)          │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  HINDSIGHT MCP (Optional, für KI-Voice)             │     │
│  │                                                     │     │
│  │  • Bank: hermes-210                                 │     │
│  │  • Mental Models + Directives + Documents            │     │
│  │  • Speichert: Strukturiertes Langzeit-Wissen        │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## 2. WER SPEICHERT WAS? (Speicher-Matrix)

```
AGENT              HOLOGRAPHIC        BUILT-IN MEMORY     SESSION
─────────────────────────────────────────────────────────────────────
DU (Denis)         User-Profil ✗      ✓ (Name, Sprache)   Transkript
                   Präferenzen ✓

Orchestrator       ✗                  ✓ (Routing-Regeln)  Transkript

dev-op             ✓                  ✓ (Server-Daten)    Transkript
                   (Server-State)     (IPs, Credentials)

agent-builder      ✓                  ✓ (Code-Stil)       Transkript
                   (Projekt-Struktur)

n8n-workflow       ✓                  ✓                   Transkript
                   (API-Endpunkte)

dograh             ✓                  ✓ (Endpunkte)       Transkript
                   (Telnyx-Config)

ki-voice-agent     ✓                  ✓ (Latenz-Opt.)      Transkript
                   (Voice-Pipelines)

xai-voice-dograh   ✓                  ✓                   Transkript
                   (xAI-Config)

research           ✓                  ✓                   Transkript
                   (Paper-Funde)

mlops              ✓                  ✓                   Transkript
                   (Benchmark-Zahlen)

creative           ✓                  ✓                   Transkript
                   (Design-Patterns)
```

## 3. WANN LIEST WER WAS? (Lese-Zeitpunkte)

```
ZEITPUNKT                     WAS WIRD GELESEN              WER
─────────────────────────────────────────────────────────────────────
JEDER TURN (System Prompt)   Built-in Memory (4.000 Z.)    ALLE Agenten
                              + User-Profil (1.375 Z.)

BEI TOOL-AUFRUF              fact_store search/probe       Agent (bei Bedarf)
  (memory_search)

BEI SESSION-START            Letzte Session (10 Turns)     ALLE
  (/resume oder --continue)

BEI UNSICHERHEIT             session_search (FTS5)         Agent
  ("Weiss ich nicht mehr")    + Holographic reflect

BEI CRON-JOB                 Cron-Job Prompt + Skills      Spezifischer Agent

BEI SUBAGENT                 Delegation Context            Neuer Subagent
  (delegate_task)
```

## 4. WANN SPEICHERT WER? (Schreib-Zeitpunkte)

```
EREIGNIS                     WAS SPEICHERT                 WOHIN
─────────────────────────────────────────────────────────────────────
DU korrigiert mich           "User bevorzugt X"           Built-in + Holographic
  ("Merke: ...")

Aufgabe erledigt             "Projekt X deployt auf 210"  Holographic fact_store
  (Erfolgreich)

Nach jedem Turn              Gesprächs-Transkript          Session DB (auto)

Nach 6 Turns                 Memory-Nudge                  Built-in
  (flush_min_turns)

User-Profil-Änderung         "User spricht BS/DE"          User-Profil (auto)

Subagent-Ergebnis            Zusammenfassung               Parent-Session

FEHLER (Policy-Verstoss)     "Aktion X abgelehnt"          Audit-Log (nicht Memory)
```

## 5. WORAN ERKENNT DER AGENT WAS ER LESEN MUSS?

```
REGEL: Der Agent entscheidet SELBST, wann er Memory braucht.

Auslöser für Memory-Lesen:
─────────────────────────────────────────────
1. "Ich erinnere mich nicht an X" → fact_store search
2. "Hatten wir nicht schonmal Y?" → session_search
3. "Was weiss ich über Z?" → fact_store probe(entity)
4. "Wie hängen A und B zusammen?" → fact_store reason([A,B])
5. "Was ist der aktuelle Stand?" → fact_store related(entity)
6. "Ist diese Info noch aktuell?" → fact_feedback (prüft Trust)

DER AGENT MUSS DAS SELBST ERKENNEN.
Ich habe dafür Core-Regeln in jeder SOUL.md:
  "Immer live verifizieren — nie auf Memory verlassen" (dograh)
  "Plan vor Code — nutze plan-Skill" (agent-builder)

WAS NICHT FUNKTIONIERT:
  ✗ Automatischer Memory-Abruf pro Turn (würde Tokens fressen)
  ✗ Memory blind in Session injizieren (Overload)
  ✓ Agent ruft ab WENN er merkt dass ihm was fehlt
```

## 6. WIE WEISS DER ORCHESTRATOR WANN WER AKTIVIERT WERDEN MUSS?

```
ES GIBT KEINEN SEPARATEN ORCHESTRATOR-AGENTEN.
Der Orchestrator BIST DU (Denis) — unterstützt durch:

AKTUELL (Stand heute):
────────────────────────────────────────
1. DU rufst das passende Profil auf:
   "dev-op chat -q 'Server-Health'"
   "agent-builder chat -q 'Baue Skill'"
   "dograh chat -q 'Starte Campaign'"

2. DU weisst welches Profil wofür da ist:
   → siehe HIERARCHY.md oder HIERARCHY_PROCESSES.md

3. Jedes Profil weiss aus seiner SOUL.md:
   - Was es darf (Policy-Level)
   - Was es NICHT darf (Verboten)
   - Wen es fragen muss bei Unsicherheit

OPTIMIERUNG (ZUKUNFT): Automatischer Orchestrator
────────────────────────────────────────────────
1. Ein "orchestrator"-Profil empfängt ALLE Anfragen
2. Analysiert: Was will der User?
3. Routet an das richtige Profil via: hermes -p <profil> chat -q "..."
4. Ergebnis zurück an User

Das ist aktuell NICHT implementiert.
Du bist der Orchestrator.
```

## 7. PRAXIS-BEISPIEL: KOMPLETT-DURCHLAUF

```
1. DU (Telegram): "Prüf den Server und start ne Sales-Campaign"

2. DU ruft auf: dev-op chat -q "Server-Health"
   → dev-op: pre_action_check → "Alles OK"
   → DU sieht Ergebnis

3. DU ruft auf: dograh chat -q "Starte Sales-Campaign für Kunde XYZ"
   → dograh: kurzt Dograh API
   → Liefert Ergebnis

4. DU: "War der letzte Call erfolgreich?"
   → dograh: fact_store probe("sales-campaign") + session_search("call result")
   → Antwortet aus Memory

OHNE ORCHESTRATOR-PROFIL: DU musst wissen welches Profil wofür.
MIT ORCHESTRATOR-PROFIL: Ein Profil routet automatisch.
```

## 8. EMPFEHLUNG: Soll ich ein Orchestrator-Profil bauen?

```
Wenn JA: Ich erstelle ein "orchestrator"-Profil (Policy 0) das:
  • Deine Telegram-Nachrichten analysiert
  • Automatisch das richtige Profil anspricht
  • Ergebnis sammelt und Dir präsentiert
  • Bei Unsicherheit: Dich fragt

Wenn NEIN: Du rufst weiter manuell die Profile auf — das ist flexibler
aber weniger automatisiert.
```
# AGENTS VERIFICATION — Vollständiger Best-Practice-Check

## Prüfkriterien
Jeder Agent muss erfüllen:
1. ✅ **agent.yaml** — existiert, valide YAML, vollständige Felder
2. ✅ **SOUL.md** — existiert, Personality + Core-Regeln
3. ✅ **prompts/system-prompt.md** — existiert, konkrete Arbeitsanweisungen
4. ✅ **Skills zugewiesen** — passende Hermes-Skills für die Aufgabe
5. ✅ **Toolsets zugewiesen** — passende Hermes-Toolsets
6. ✅ **Policy-Level korrekt** — gemäss Aufgaben-Risiko
7. ✅ **Modell optimal** — passend zur Aufgabe (flash/pro/miniature/grok)

---

## 1️⃣ dev-op (devops)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 3, model: flash |
| SOUL.md | ✅ | Präzise/sicherheitsbewusst, Server-Landschaft |
| system-prompt.md | ✅ | pre_action, audit_log, Wartungsfenster |
| **Skills** | ✅ **8 Skills** | hermes-devop, server-maintenance, docker-management, k3s-helm-deployment, k3s-namespace-organization, watchers, webhook-subscriptions, mac-remote-access |
| **Toolsets** | ✅ **5 Tools** | terminal, file, cronjob, memory, web, session_search |
| **Plugins** | ✅ **2 MCP** | hindsight (Bank: hermes-210), native-mcp |
| **Policy-Level** | ✅ **3 (high-risk)** | System-Änderungen nur mit Approval |
| **Modell** | ✅ **flash** | Schnell für Diagnosen, kein Reasoning nötig |
| **Best Practice** | ✅ | pre_action/post_action Guards, Audit-Log |

---

## 2️⃣ n8n-workflow (devops)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 2, model: flash |
| SOUL.md | ✅ | Webhook-First, API-Denken |
| system-prompt.md | ✅ | curl-testen, Error-Workflows, Export |
| **Skills** | ✅ **6 Skills** | n8n-voice-workflows, webhook-subscriptions, native-mcp, airtable, google-workspace, watchers |
| **Toolsets** | ✅ **5 Tools** | terminal, web, browser, file, cronjob |
| **Policy-Level** | ✅ **2 (low-risk)** | API-Calls autonom, keine System-Änderungen |
| **Modell** | ✅ **flash** | Workflow-Logik ist einfach |
| **Best Practice** | ✅ | Webhook-First, Response <5s, JSON-Export |

---

## 3️⃣ agent-builder (agent-builder)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 3, model: pro |
| SOUL.md | ✅ | Plan vor Code, TDD, Skills speichern |
| system-prompt.md | ✅ | TDD, Code-Review, Git-Konvention |
| **Skills** | ✅ **12 Skills** | hermes-agent, hermes-agent-skill-authoring, skill-creator, writing-plans, plan, spike, test-driven-development, subagent-driven-development, requesting-code-review, github-pr-workflow, github-code-review, codebase-inspection |
| **Toolsets** | ✅ **8 Tools** | terminal, file, web, browser, skills, delegation, vision, session_search |
| **Policy-Level** | ✅ **3 (high-risk)** | Code + Deploy braucht Approval |
| **Modell** | ✅ **pro** | 1M Kontext, maximale Code-Qualität |
| **Best Practice** | ✅ | TDD, Plan vor Code, Skill-Persistenz |

---

## 4️⃣ prompting-salesteleagent (sales)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 2, model: pro |
| SOUL.md | ✅ | A/B-Testing, Language Priming, BS/DE |
| system-prompt.md | ✅ | Temp 0.5, </s> Stop, Output-Struktur |
| **Skills** | ✅ **8 Skills** | dograh, n8n-voice-workflows, humanizer, langfuse, evaluating-llms-harness, youtube-content, llm-wiki, project-knowledge-base |
| **Toolsets** | ✅ **5 Tools** | terminal, file, web, browser, memory |
| **Policy-Level** | ✅ **2 (low-risk)** | Nur Prompt-Änderungen |
| **Modell** | ✅ **pro** | Beste Nuancen-Erkennung für Prompts |
| **Best Practice** | ✅ | A/B-Testing mit Langfuse, ultrakurze Prompts |

---

## 5️⃣ sales-qualifier (sales + revops-core)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 2, model: flash |
| SOUL.md | ✅ | Lead-Qualität, YugoGPT-7B |
| system-prompt.md | ✅ | Call-Struktur, JSON-Output |
| **Skills** | ✅ **5 Skills** | dograh, n8n-voice-workflows, webhook-subscriptions, telegram-file-delivery, humanizer |
| **Toolsets** | ✅ **4 Tools** | terminal, web, file, cronjob |
| **Policy-Level** | ✅ **2 (low-risk)** | Nur Calls triggern, keine System-Zugriffe |
| **Modell** | ✅ **flash** | Schnell, einfache Tasks |
| **Best Practice** | ✅ | Strukturierte Lead-Erfassung, YugoGPT-7B Routing |
| **⚠️ Dopplung** | ⚠️ Agent existiert in sales UND revops-core | Absicht: revops-core = both (Hermes+OpenClaw), sales = Hermes only |

---

## 6️⃣ dograh (voice)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 2, model: flash |
| SOUL.md | ✅ | Telnyx, Workflow=Agent, BS/DE |
| system-prompt.md | ✅ | Live-Verifikation, Test-Call vor Bulk |
| **Skills** | ✅ **6 Skills** | dograh, dograh-setup, webhook-subscriptions, n8n-voice-workflows, telegram-file-delivery, systematic-debugging |
| **Toolsets** | ✅ **5 Tools** | terminal, web, file, browser, cronjob |
| **Policy-Level** | ✅ **2 (low-risk)** | Dashboard-Operationen |
| **Modell** | ✅ **flash** | Kein Reasoning nötig |
| **Best Practice** | ✅ | Immer curl vor Memory, Test-Call vor Bulk |

---

## 7️⃣ ki-voice-agent (voice)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 2, model: ministral-3:3b-cloud |
| SOUL.md | ✅ | Latenz-Denken, Pipecat-Pipeline |
| system-prompt.md | ✅ | Niemals 70B+, Ministral bevorzugt |
| **Skills** | ✅ **8 Skills** | pipecat-voice-agent, xai-realtime-voice, voice-agent-orchestrator, voice-agent-memory, hindsight-docs, mac-remote-access, native-mcp, llama-cpp |
| **Toolsets** | ✅ **7 Tools** | terminal, file, web, browser, tts, vision, delegation |
| **Policy-Level** | ✅ **2 (low-risk)** | Voice-Pipelines bauen |
| **Modell** | ✅ **ministral-3:3b-cloud** | ~3.3s Latenz — einzige Wahl für Voice |
| **Best Practice** | ✅ | Latenz <4s, kein 70B+, Mode 3 Default |

---

## 8️⃣ xai-voice-dograh (voice)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 2, model: grok-realtime |
| SOUL.md | ✅ | xAI Realtime, WebSocket, PCM16 |
| system-prompt.md | ✅ | Ein Stream, Turn-Detection, Ephemeral Tokens |
| **Skills** | ✅ **5 Skills** | xai-realtime-voice, dograh, pipecat-voice-agent, native-mcp, voice-agent-memory |
| **Toolsets** | ✅ **5 Tools** | terminal, web, file, browser, tts |
| **Policy-Level** | ✅ **2 (low-risk)** | Voice-Integration |
| **Modell** | ✅ **grok-realtime** | Einzige Wahl für xAI Realtime |
| **⚠️ API-Key** | ⚠️ **XAI_API_KEY fehlt** | Braucht xAI API Key oder OAuth |
| **Best Practice** | ✅ | WebSocket-Stream, Ephemeral Tokens |

---

## 9️⃣ research (research)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 1, model: pro |
| SOUL.md | ✅ | Paper→Wiki, Quellenangabe |
| system-prompt.md | ✅ | arXiv, Blogwatcher, Notion, Polymarket |
| **Skills** | ✅ **7 Skills** | arxiv, blogwatcher, llm-wiki, youtube-content, notion, polymarket, project-knowledge-base |
| **Toolsets** | ✅ **5 Tools** | web, file, memory, cronjob, browser |
| **Policy-Level** | ✅ **1 (read-only)** | Nur Lesezugriff |
| **Modell** | ✅ **pro** | 1M Kontext für Papers |
| **Best Practice** | ✅ | Paper→Summary→Wiki, Quellen-Pflicht |

---

## 🔟 mlops (mlops)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 3, model: pro |
| SOUL.md | ✅ | Evaluieren, Quantisieren, Deployen |
| system-prompt.md | ✅ | lm-eval-harness, W&B, Langfuse, DSPy |
| **Skills** | ✅ **9 Skills** | llama-cpp, huggingface-hub, modal-gguf-deployment, serving-llms-vllm, weights-and-biases, langfuse, dspy, evaluating-llms-harness, hindsight-docs |
| **Toolsets** | ✅ **6 Tools** | terminal, file, web, memory, browser, delegation |
| **Policy-Level** | ✅ **3 (high-risk)** | Deploy + Installation |
| **Modell** | ✅ **pro** | Komplexe Evaluationen + Reasoning |
| **Best Practice** | ✅ | Benchmark vor Quantisierung, Dokumentation |

---

## 1️⃣1️⃣ creative (creative)

| Kriterium | Status | Details |
|-----------|--------|---------|
| agent.yaml | ✅ | runtime: hermes, policy: 1, model: flash |
| SOUL.md | ✅ | Dark Mode, Excalidraw, PowerPoint |
| system-prompt.md | ✅ | Diagramme, Sketch, Image-Gen |
| **Skills** | ✅ **7 Skills** | architecture-diagram, excalidraw, sketch, claude-design, p5js, popular-web-designs, pixel-art |
| **Toolsets** | ✅ **6 Tools** | terminal, file, web, browser, vision, image_gen |
| **Policy-Level** | ✅ **1 (read-only)** | Nur Design |
| **Modell** | ✅ **flash** | Schnell + Vision-fähig |
| **Best Practice** | ✅ | Dark Mode, Dummy-Daten, Grid-basiert |

---

## Zusammenfassung

| Agent | Status | Skills | Toolsets | Policy | Modell |
|-------|--------|--------|----------|--------|--------|
| dev-op | ✅ | 8 | 6 | 3 | flash |
| n8n-workflow | ✅ | 6 | 5 | 2 | flash |
| agent-builder | ✅ | 12 | 8 | 3 | pro |
| prompting-salesteleagent | ✅ | 8 | 5 | 2 | pro |
| sales-qualifier | ✅ | 5 | 4 | 2 | flash |
| dograh | ✅ | 6 | 5 | 2 | flash |
| ki-voice-agent | ✅ | 8 | 7 | 2 | ministral |
| xai-voice-dograh | ⚠️ Key | 5 | 5 | 2 | grok |
| research | ✅ | 7 | 5 | 1 | pro |
| mlops | ✅ | 9 | 6 | 3 | pro |
| creative | ✅ | 7 | 6 | 1 | flash |

**Fazit:** 11/12 Agenten ⭐ production-ready. xai-voice-dograh braucht XAI_API_KEY.
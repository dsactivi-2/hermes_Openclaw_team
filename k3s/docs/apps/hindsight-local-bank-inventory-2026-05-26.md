# Hindsight Local Bank Inventory

Generated: 2026-05-26T11:56:38

Mode: read-only inventory. No memory contents, secret values, tokens, passwords or API keys are included.

## Source Quality

- Live local Hindsight API: not required for this report.
- Primary live source used: local hook state `bank_missions.json` bank IDs only.
- Historical aggregate counts source: `/Users/activi/Documents/Hindsight 2/PROJEKTUNTERLAGEN.md`.
- Limitation: per-bank memory/document counts require the local Hindsight API or direct PostgreSQL access to be running.

## Current Codex Connection State

- Codex hook state in `/Users/activi/.codex/config.toml`: `some_or_all_disabled`.
- `projectBankMode`: `True`
- `inboxBankId`: `org:inbox`
- `frameworkName`: `codex`
- `agentId`: `codex-main`
- `hindsightApiUrl`: `local-daemon-mode`
- `apiPort`: `9077`
- `secretRedactionEnabled`: `True`

Interpretation:

- Bank mapping and redaction code are prepared in the local Hindsight hooks.
- If Codex hooks are disabled, automatic recall/retain will not run until hooks are approved/enabled in Codex.
- `hindsightApiUrl = local-daemon-mode` means Codex uses `http://127.0.0.1:<apiPort>` and may auto-start the local daemon when required.

## Historical Aggregate Counts

- Banks: 83
- Documents: 90
- Chunks: 254
- Memory Units: 1909
- Entities: 7086
- Directives: 0
- Mental Models: 0

## Mapping Proposal

| Old/current bank ID | Suggested target | Action | Reason |
| --- | --- | --- | --- |
| `local-codex::Codex MCP setup--e1b8cd6106` | `org:shared` | `review` | `global_codex_or_platform_topic` |
| `local-codex::Hindsight 2--3eab1f4caa` | `project:hindsight` | `review` | `hindsight_workspace_match` |
| `local-codex::Matrix--3089515b32` | `project:matrix` | `review` | `known_project_name` |
| `local-codex::activi K3s` | `project:activi-k3s` | `migrate` | `k3s_workspace_match` |
| `local-codex::activi K3s--899ea982e4` | `project:activi-k3s` | `migrate` | `k3s_workspace_match` |
| `local-codex::activi--1703fb9a26` | `org:inbox` | `review` | `unknown_bank_needs_triage` |
| `local-codex::erstelle-das-als-systeminstruction-f-r--aeeefc9f8c` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::hermes desktop app WL--8ce10c97f1` | `project:hermes` | `review` | `known_project_name` |
| `local-codex::liste-mir-alle-meien-hooks-auf--8dbc27a797` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::pr-fe-wieso-das-nciht-aktiviert--3ee08bb322` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::prfe-wieso-ich-700-gb-systemdaten--71afb418c2` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::recherchiere-wer-dieser-anbieter-auch-vectorrag--b77e22a129` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::richte-das-global-f-r-codex--205a6a6960` | `org:shared` | `review` | `global_codex_or_platform_topic` |
| `local-codex::was-ist-das-erkl-re-und--9360ff5dbf` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::was-ist-das-f-r-einstellungen--9dce6fd2d2` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |
| `local-codex::was-passiert-hier--a701f0fd37` | `org:inbox` | `review` | `prompt_derived_bank_needs_triage` |

## Summary

- state_banks_seen: 16
- migrate: 2
- review: 14
- keep: 0

## Recommended Codex Connection Switch

Current safe mode:

```text
Codex -> local hooks -> local Hindsight daemon on 127.0.0.1:9077
Bank mapping -> project:<name> / org:inbox
```

To use the K3s Hindsight instance before public ingress exists, use an SSH/kubectl port-forward and set Codex to an explicit local URL:

```text
ssh k3-1 'kubectl -n hindsight port-forward svc/hindsight-api 9077:80'
/Users/activi/.hindsight/codex.json:
  hindsightApiUrl = "http://127.0.0.1:9077"
```

After public/API access is separately approved, Codex can instead point to the secured Hindsight API URL. Until then, do not open public ingress just for Codex.

## Next Safe Actions

1. Review this mapping table.
2. Start local Hindsight API or connect to K3s Hindsight for per-bank counts.
3. Re-run the inventory with live counts.
4. Only after approval, copy selected memories into target `project:<name>` banks.
5. Keep old `local-codex::*` banks as historical source until migration is validated.

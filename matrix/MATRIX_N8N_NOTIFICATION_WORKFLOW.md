# Matrix n8n Notification Workflow

This document describes the disabled/import-only n8n workflow draft generated
by `matrix-n8n-workflow-draft.sh`.

No secrets, passwords, API keys, or Matrix access tokens belong in this file.

## Purpose

`@n8n-bot:matrix.activi-apps.io` is a controlled notification bot. It must not
be used as an event-spam bot. Its job is to send only actionable failures,
escalations, and summaries from n8n to Matrix.

## Allowed Messages

Matrix messages are allowed only for:

- Alerts or errors where human action is required.
- Call-agent failures.
- Escalations.
- Daily summaries.
- Weekly summaries.
- Statistics or aggregate reports.

## Disallowed Messages

Do not send:

- Every successful workflow execution.
- Every call.
- Every workflow start.
- Every workflow success.
- Debug or verbose messages.
- Raw data dumps.
- Full call transcripts.
- Secrets, tokens, passwords, or API keys.
- Event spam.

## Routing

`#alerts:matrix.activi-apps.io` is for true failures, escalations, and cases
where a human must act.

`#n8n:matrix.activi-apps.io` is for daily summaries, weekly summaries,
statistics, and aggregate n8n status reports.

`#ops:matrix.activi-apps.io` is intentionally excluded from this draft.

`#dograh:matrix.activi-apps.io` is intentionally excluded from this block and
must be added only in a later Dograh/Telnyx approval block.

## Send Policy

A Matrix message may be sent only if at least one condition is true:

- `severity` is `critical`, `error`, or `warning_requires_human`.
- `requires_human` is `true`.
- `escalation` is `true`.
- `report_type` is `daily_summary` or `weekly_summary`.
- `call_agent_status` is `failed` or `escalated`.

Everything else must be dropped before any Matrix send node.

## Workflow Draft

Generated file:

- `matrix-n8n-notification-workflow.json`

The workflow is disabled with `active: false`.

The draft contains:

- Manual test trigger.
- Alert/escalation test payload.
- Daily summary test payload.
- Weekly summary test payload.
- Policy gate node that drops non-approved events.
- Route node for `#alerts` and `#n8n`.
- Matrix HTTP send nodes using a placeholder bot access token expression.

The workflow intentionally does not contain:

- n8n credentials.
- Matrix access tokens.
- Bot passwords.
- `#ops` send node.
- `#dograh` send node.
- Productive webhook activation.

## Credential Plan

n8n will later need:

- Homeserver URL: `https://matrix.activi-apps.io`
- Bot user: `@n8n-bot:matrix.activi-apps.io`
- Bot password or access token.
- Target room IDs or aliases for `#alerts` and `#n8n`.

Credentials must be stored in n8n credentials or a secret manager, not in the
workflow JSON, Matrix rooms, git, or documentation.

The draft currently uses the placeholder expression:

```text
{{ $env.MATRIX_BOT_ACCESS_TOKEN }}
```

This is a placeholder only. Before any manual execution, replace the placeholder
with a proper n8n credential or approved secret injection method.

## Import Instructions

Recommended safe path:

1. Open n8n at `https://n8n-mm.activi-apps.io`.
2. Import `matrix-n8n-notification-workflow.json`.
3. Confirm the imported workflow is inactive.
4. Do not execute the workflow until Matrix bot credentials are configured.
5. Configure credentials using n8n credentials or an approved secret source.
6. Test only the daily summary path first.
7. Test an alert path second.
8. Keep workflow inactive until routing and credential handling are approved.

API import was intentionally not performed in this block because it would need
an n8n API key and a credential strategy. No n8n workflow was activated.

## Test Plan

1. Verify Matrix API is reachable.
2. Verify `#alerts` and `#n8n` aliases resolve.
3. Import workflow as inactive.
4. Configure Matrix bot credential outside git.
5. Run a manual daily summary test and verify one message in `#n8n`.
6. Run a manual alert test and verify one message in `#alerts`.
7. Run a blocked sample with no allowed policy fields and verify no Matrix
   message is sent.
8. Confirm no message goes to `#ops` or `#dograh`.

## Later Extensions

Dograh/Telnyx events can be added only in a separate block:

- Telnyx to Dograh.
- Dograh outbound event to n8n.
- n8n filter/format/audit.
- Matrix message to `#dograh` only for allowed summaries, failures, or
  escalations.

`#ops` remains excluded until a separate escalation-routing policy is approved.

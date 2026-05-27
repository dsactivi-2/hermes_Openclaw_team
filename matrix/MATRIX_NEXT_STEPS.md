# Matrix Next Steps Automation Plan

This document records the next Matrix automation steps after the V1 bootstrap.
It is a plan only. It does not contain secrets, tokens, passwords, room IDs, or
live credentials.

## Current Bootstrap State

- Homeserver: `matrix.activi-apps.io`
- Element: `space.activi-apps.io`
- Admin UI: `synapse-admin.activi-apps.io`
- Initial admin: `@activi:matrix.activi-apps.io`
- Admin UI is protected with nginx Basic Auth.
- Federation, open registration, SMTP, TURN, and Element Admin remain disabled.

## Rooms

The current room set is:

- `#ops:matrix.activi-apps.io`
- `#alerts:matrix.activi-apps.io`
- `#dograh:matrix.activi-apps.io`
- `#n8n:matrix.activi-apps.io`
- `#admin-agent:matrix.activi-apps.io`

Room verification is handled by `matrix-rooms-verify.sh`. The script logs in
with the admin user, keeps the access token only in memory, resolves aliases,
checks membership, and checks admin-level power. It does not create or modify
rooms.

## n8n to Matrix Notifications

Recommended first bot identity:

- `@n8n-bot:matrix.activi-apps.io`

Initial target rooms:

- `#n8n:matrix.activi-apps.io`
- `#alerts:matrix.activi-apps.io`
- Optional critical summaries: `#ops:matrix.activi-apps.io`

Required credentials later:

- Bot username or user ID.
- Bot password or access token.
- Homeserver URL: `https://matrix.activi-apps.io`.
- Room IDs or aliases.

Credentials must live in n8n credentials or Kubernetes Secrets. They must not be
posted in Matrix rooms, committed to git, or copied into documentation.

Recommended workflow shape:

1. Trigger: workflow error, webhook, schedule, or service event.
2. Normalize: severity, source, correlation ID, workflow ID, timestamp.
3. Format: short Matrix message with status, action, and link.
4. Send: Matrix Client-Server API or n8n Matrix node.
5. Error handling: bounded retry and escalation to `#ops` if Matrix posting
   fails.
6. Audit: n8n execution ID, target room, event hash, status, timestamp.

## Alertmanager to n8n to Matrix

Use n8n as the first Matrix-facing alert bridge:

1. Alertmanager sends an authenticated webhook to n8n.
2. n8n validates the request.
3. n8n deduplicates and groups repeated alerts.
4. Firing and resolved alerts are formatted differently.
5. Default target room: `#alerts:matrix.activi-apps.io`.
6. Critical summaries can be copied to `#ops:matrix.activi-apps.io`.

Do not change Alertmanager until the n8n webhook URL, authentication method,
workflow draft, and routing policy are approved.

## Dograh and Telnyx Event Flow

Preferred path:

1. Telnyx events are handled by Dograh.
2. Dograh emits supported outbound events to n8n.
3. n8n validates, formats, audits, and posts selected events to Matrix.
4. Matrix remains a notification and coordination surface, not a call-flow
   execution engine.

Initial target room:

- `#dograh:matrix.activi-apps.io`

Critical operational summaries may also go to `#ops:matrix.activi-apps.io`.

## Hermes Admin-Agent

The Admin-Agent should start read-only.

Target rooms:

- `#admin-agent:matrix.activi-apps.io`
- Optional summaries in `#ops:matrix.activi-apps.io`

Allowed first capabilities:

- Matrix readiness summaries.
- Backup/restore status summaries.
- HTTP/TLS status checks.
- n8n/Dograh/Matrix documentation lookup.
- Drafting commands or change plans for human approval.

Not allowed without explicit approval:

- `kubectl` write actions.
- Helm install/upgrade/rollback.
- DNS changes.
- Secret creation, rotation, or decoding.
- User, bot, or room permission changes.
- n8n workflow activation.
- Dograh production configuration changes.

Audit requirement:

- Room.
- Requesting user.
- Requested action.
- Approval decision.
- Result.
- Timestamp.

## Hermes User-Agent

The User-Agent is a later phase.

Rules:

- Separate bot account.
- No admin room access by default.
- No cluster, secret, deploy, DNS, or admin API permissions.
- Can draft n8n/Dograh ideas and support responses.
- Cannot execute productive changes.

## Safety Rules

- No secrets in Matrix rooms.
- Bot tokens only in n8n credentials or Kubernetes Secrets.
- Separate human admin credentials from bot credentials.
- Use least privilege per bot.
- Use human approval for every production-impacting action.
- Keep Matrix independent from Dograh and n8n authentication.
- Keep Federation, open registration, SMTP, TURN, and Element Admin disabled
  until explicitly re-approved.

## Next Approval Blocks

1. Verify room aliases, membership, and admin power with `matrix-rooms-verify.sh`.
2. Create `@n8n-bot:matrix.activi-apps.io` as a separate bot user.
3. Store Matrix bot credentials in n8n credentials or Kubernetes Secrets.
4. Draft a disabled/import-only n8n Matrix notification workflow.
5. Add Alertmanager webhook routing after n8n endpoint and auth are approved.
6. Prepare Hermes Admin-Agent read-only profile after bot account and room
   policy are approved.

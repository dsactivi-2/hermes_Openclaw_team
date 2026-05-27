# Activi Matrix Stack Context

The project runs a private Matrix/Element stack first, with Hermes Agent planned
as an optional second phase. Runtime names and URLs come from `.env`.

Core services:

- Synapse homeserver at `${MATRIX_DOMAIN}`.
- Element Web at `${ELEMENT_DOMAIN}`.
- Element Admin at `${ELEMENT_ADMIN_DOMAIN}`.
- Ketesa/Synapse admin at `${KETESA_DOMAIN}`.
- Postgres, Traefik, coturn, SMTP, backup, and audit scripts.

Current operating posture:

- Open registration is disabled.
- Federation is intentionally disabled for the first deployment phase.
- TURN, SMTP, security headers, rate limits, access logs, backup, restore check,
  and audits are part of the production readiness path.
- Hermes agents are optional and must not block the core Matrix stack.

Project rules for agents:

- Do not approve incomplete user requests without checking assumptions.
- Ask for confirmation when a requested action is incomplete, destructive, or
  depends on missing credentials.
- Prefer docs-backed answers. Use Context7 for library/framework/tool docs.
- Never expose secrets in Matrix rooms, logs, or generated documentation.
- Treat production deploy, DNS, registry pushes, and data restore as high-risk.

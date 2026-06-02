#!/bin/bash
# new_team.sh — Neues Team-Scaffolding
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <team-name> [--runtime=<hermes|openclaw|both>] [--policy=<0-4>]"
    exit 1
fi

TEAM_NAME="$1"
RUNTIME="hermes"
POLICY=2

for arg in "${@:2}"; do
    case $arg in
        --runtime=*) RUNTIME="${arg#*=}" ;;
        --policy=*) POLICY="${arg#*=}" ;;
    esac
done

TEAM_DIR="profiles/teams/$TEAM_NAME"

if [ -d "$TEAM_DIR" ]; then
    echo "❌ Team '$TEAM_NAME' existiert bereits!"
    exit 1
fi

mkdir -p "$TEAM_DIR/skills"

cat > "$TEAM_DIR/team.yaml" << EOF
team_name: $TEAM_NAME
runtime: $RUNTIME
policy_level: $POLICY
created: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
agents: []
channels:
  - telegram
  - cli
EOF

echo "✅ Team '$TEAM_NAME' angelegt ($TEAM_DIR)"
echo "   Runtime: $RUNTIME"
echo "   Policy: $POLICY"
echo "   Nächster Schritt: ./scripts/new_agent.sh <agent-name> $TEAM_NAME"
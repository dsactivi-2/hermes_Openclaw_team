#!/bin/bash
# new_agent.sh — Neuen Agenten im Team anlegen
set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <agent-name> <team-name> [--runtime=<hermes|openclaw>] [--model=<modell>]"
    exit 1
fi

AGENT_NAME="$1"
TEAM_NAME="$2"
RUNTIME="hermes"
MODEL=""

for arg in "${@:3}"; do
    case $arg in
        --runtime=*) RUNTIME="${arg#*=}" ;;
        --model=*) MODEL="${arg#*=}" ;;
    esac
done

TEAM_DIR="profiles/teams/$TEAM_NAME"
AGENT_DIR="$TEAM_DIR/agents/$AGENT_NAME"

if [ ! -d "$TEAM_DIR" ]; then
    echo "❌ Team '$TEAM_NAME' existiert nicht! Erst ./scripts/new_team.sh $TEAM_NAME"
    exit 1
fi

if [ -d "$AGENT_DIR" ]; then
    echo "❌ Agent '$AGENT_NAME' existiert bereits!"
    exit 1
fi

mkdir -p "$AGENT_DIR/prompts"

cat > "$AGENT_DIR/agent.yaml" << EOF
agent_name: $AGENT_NAME
team: $TEAM_NAME
runtime: $RUNTIME
model: ${MODEL:-inherit}
policy_level: $(grep "policy_level:" "$TEAM_DIR/team.yaml" | awk '{print $2}')
created: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
channels:
  - telegram
  - cli
EOF

cat > "$AGENT_DIR/SOUL.md" << EOF
# $AGENT_NAME

## Persönlichkeit
- Kurz, direkt, ergebnisorientiert
- Team: $TEAM_NAME, Runtime: $RUNTIME

## Core-Regeln
1. [Regel 1]
2. [Regel 2]
3. [Regel 3]
EOF

cat > "$AGENT_DIR/prompts/system-prompt.md" << EOF
# System-Prompt für $AGENT_NAME

## Rolle
[Deine Rolle]

## Kontext
[Beschreibung]

## Anweisungen
1. [Anweisung 1]
2. [Anweisung 2]
EOF

echo "✅ Agent '$AGENT_NAME' in Team '$TEAM_NAME' angelegt ($AGENT_DIR)"
echo "   Runtime: $RUNTIME"
echo "   Nächster Schritt: SOUL.md und prompts/system-prompt.md bearbeiten"
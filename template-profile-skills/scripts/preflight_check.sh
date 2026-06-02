#!/bin/bash
# preflight_check.sh — Read-only Systemdiagnose vor Deployment
set -euo pipefail

echo "=== PREFLIGHT CHECK: $(date -u '+%Y-%m-%d %H:%M UTC') ==="

# Strukturprüfung
echo "--- Struktur ---"
for dir in docs runbook scripts profiles/teams; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ⚠️  $dir fehlt"
    fi
done

# YAML-Syntax
echo "--- YAML-Validierung ---"
for f in $(find . -name "*.yaml" -o -name "*.yml" 2>/dev/null); do
    if python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null; then
        echo "  ✅ $f"
    else
        echo "  ❌ $f (Syntaxfehler)"
        FAIL=1
    fi
done

# SOUL.md prüfen
echo "--- Agent-SOUL-Prüfung ---"
for d in profiles/teams/*/agents/*/; do
    if [ -f "$d/SOUL.md" ]; then
        echo "  ✅ $d"
    else
        echo "  ⚠️  $d (keine SOUL.md)"
    fi
done

# Scripts prüfen
echo "--- Scripts ---"
for s in scripts/*.sh; do
    if [ -x "$s" ]; then
        echo "  ✅ $s (ausführbar)"
    else
        echo "  ⚠️  $s (nicht ausführbar — chmod +x empfohlen)"
    fi
done

echo "=== DONE ==="
exit ${FAIL:-0}
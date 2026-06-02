#!/bin/bash
# postdeploy_check.sh — Post-Deployment Validation
set -euo pipefail

echo "=== POSTDEPLOY CHECK: $(date -u '+%Y-%m-%d %H:%M UTC') ==="

# System-Health (lokal)
echo "--- System ---"
echo "Uptime: $(uptime -p)"
echo "CPU: $(top -bn1 | grep '%Cpu' | awk '{print $2}')%"
echo "RAM: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $5}')"

# Profile prüfen
echo "--- Hermes-Profile ---"
for p in /root/.hermes/profiles/*/config.yaml; do
    name=$(basename $(dirname $p))
    model=$(grep 'default:' "$p" 2>/dev/null | head -1 | awk '{print $2}')
    echo "  $name → $model"
done

# Services (wenn verfügbar)
echo "--- Docker (104) ---"
docker ps --format "table {{.Names}}\t{{.Status}}" 2>/dev/null || echo "  Kein Docker"

echo "=== DONE ==="
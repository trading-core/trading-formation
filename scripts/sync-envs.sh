#!/usr/bin/env bash
# Sync rendered .env files to the server after running ./run-services.sh render.
set -euo pipefail

SERVER="kduong-server"
LOCAL="$(cd "$(dirname "$0")/.." && pwd)"
REMOTE="/opt/trading-core/trading-formation"

envs=(
    "docker-compose.yml"
    "backend/account-service/.env"
    "backend/authentication-service/.env"
    "backend/stock-screener/.env"
    "frontend/.env"
)

for f in "${envs[@]}"; do
    if [[ -f "$LOCAL/$f" ]]; then
        ssh "$SERVER" "mkdir -p \$(dirname $REMOTE/$f)"
        scp "$LOCAL/$f" "$SERVER:$REMOTE/$f"
        echo "synced: $f"
    else
        echo "skipped (not found): $f"
    fi
done

echo "Env sync complete."

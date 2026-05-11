#!/usr/bin/env bash
# Sync secrets, push to server, and stream the build log live.
# Fires a Windows desktop notification when the build is ready or fails.
set -euo pipefail

SERVER="kduong-server"
FORMATION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REMOTE="/opt/trading-core/trading-formation"
STATUS_FILE="/opt/trading-core/.build-status"
LOG_FILE="/opt/trading-core/.build.log"

notify() {
    local title="$1" msg="$2"
    powershell.exe -WindowStyle Hidden -command "
        [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
        \$n = New-Object System.Windows.Forms.NotifyIcon
        \$n.Icon = [System.Drawing.SystemIcons]::Information
        \$n.Visible = \$true
        \$n.ShowBalloonTip(10000, '$title', '$msg', [System.Windows.Forms.ToolTipIcon]::Info)
        Start-Sleep 5
        \$n.Dispose()
    " &
}

main() {
    # --- Sync secrets ---
    echo "Syncing secrets to $SERVER..."
    local secrets=(
        "docker-compose.yml"
        "backend/account-service/.env"
        "backend/authentication-service/.env"
        "backend/bot-service/.env"
        "backend/journal-service/.env"
        "backend/reporting-service/.env"
        "backend/stock-screener/.env"
        "backend/storage-service/.env"
        "frontend/.env"
        "traefik-dynamic/static.yml"
    )
    for f in "${secrets[@]}"; do
        if [[ -f "$FORMATION_DIR/$f" ]]; then
            ssh "$SERVER" "mkdir -p \$(dirname $REMOTE/$f)"
            scp "$FORMATION_DIR/$f" "$SERVER:$REMOTE/$f"
            echo "  synced: $f"
        else
            echo "  skipped (not found): $f"
        fi
    done

    # --- Push ---
    echo "Pushing to $SERVER..."
    git -C "$FORMATION_DIR" push server main

    # --- Check if already done ---
    local current
    current=$(ssh "$SERVER" "cat $STATUS_FILE 2>/dev/null || echo 'none'")
    if [[ "$current" == ready* ]]; then
        notify "Trading Core" "Build ready — run ./scripts/deploy.sh"
        echo "Build ready. Run: ./scripts/deploy.sh"
        return
    elif [[ "$current" == failed* ]]; then
        notify "Trading Core" "Build FAILED"
        echo "Build failed."
        return
    fi

    # --- Stream build log until sentinel ---
    echo "Streaming build log... (Ctrl-C to stop)"

    coproc LOGTAIL { ssh "$SERVER" "tail -n +1 -f $LOG_FILE 2>/dev/null"; }

    local result="failed"
    cleanup() {
        kill "$LOGTAIL_PID" 2>/dev/null
        wait "$LOGTAIL_PID" 2>/dev/null
        trap - INT
    }
    trap 'cleanup; echo ""; echo "Stopped."' INT

    while IFS= read -r line <&"${LOGTAIL[0]}"; do
        echo "$line"
        if [[ "$line" == "=== BUILD READY ===" ]]; then
            result="ready"
            break
        elif [[ "$line" == "=== BUILD FAILED ===" ]]; then
            result="failed"
            break
        fi
    done

    cleanup

    if [[ "$result" == "ready" ]]; then
        notify "Trading Core" "Build ready — run ./scripts/deploy.sh"
        echo "Build ready. Run: ./scripts/deploy.sh"
    else
        notify "Trading Core" "Build FAILED"
        echo "Build failed."
    fi
}

main "$@"

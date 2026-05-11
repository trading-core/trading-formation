#!/usr/bin/env bash
# Poll the server build status and fire a Windows desktop notification when done.
set -euo pipefail

SERVER="kduong-server"
STATUS_FILE="/opt/trading-core/.build-status"

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

echo "Watching build on $SERVER... (Ctrl-C to stop)"

last=""
while true; do
    current=$(ssh "$SERVER" "cat $STATUS_FILE 2>/dev/null || echo 'pending'")

    if [[ "$current" != "$last" ]]; then
        echo "[$(date +%H:%M:%S)] $current"
        last="$current"

        if [[ "$current" == ready* ]]; then
            notify "Trading Core" "Build ready — run ./scripts/deploy.sh"
            echo "Build ready. Run: ./scripts/deploy.sh"
            exit 0
        elif [[ "$current" == failed* ]]; then
            notify "Trading Core" "Build FAILED — check: ssh kduong-server 'cat /opt/trading-core/.build.log'"
            echo "Build failed. Check logs: ssh kduong-server 'cat /opt/trading-core/.build.log'"
            exit 1
        fi
    fi

    sleep 30
done

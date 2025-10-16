# Execute commands on Batocera remotely
# Convenience script for common development tasks
#
# Usage:
#   .\remote-cmd.ps1 restart     # Restart Flask
#   .\remote-cmd.ps1 stop        # Stop Flask
#   .\remote-cmd.ps1 logs        # View logs
#   .\remote-cmd.ps1 update      # Update deps
#   .\remote-cmd.ps1 status      # Check status

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("restart", "stop", "start", "logs", "update", "status", "shell")]
    [string]$Command,

    [string]$Host = "192.168.1.53",
    [string]$User = "root",
    [switch]$Follow  # For logs command
)

$RemotePath = "/userdata/roms/anki"

Write-Host "========================================"
Write-Host "  Remote Command: $Command"
Write-Host "========================================"
Write-Host ""

switch ($Command) {
    "restart" {
        Write-Host "Restarting Flask app..." -ForegroundColor Yellow
        ssh "$User@$Host" "cd $RemotePath && ./dev-restart.sh"
    }

    "stop" {
        Write-Host "Stopping Flask app..." -ForegroundColor Yellow
        ssh "$User@$Host" "cd $RemotePath && ./dev-stop.sh"
    }

    "start" {
        Write-Host "Starting Flask app..." -ForegroundColor Yellow
        ssh "$User@$Host" "cd $RemotePath && ./start-anki-viewer.sh" -ErrorAction Continue
    }

    "logs" {
        if ($Follow) {
            Write-Host "Following Flask logs (Ctrl+C to exit)..." -ForegroundColor Yellow
            Write-Host ""
            ssh "$User@$Host" "tail -f $RemotePath/flask.log"
        } else {
            Write-Host "Flask logs (last 50 lines):" -ForegroundColor Yellow
            Write-Host ""
            ssh "$User@$Host" "tail -n 50 $RemotePath/flask.log"
        }
    }

    "update" {
        Write-Host "Updating dependencies..." -ForegroundColor Yellow
        ssh "$User@$Host" "cd $RemotePath && ./dev-update.sh"
    }

    "status" {
        Write-Host "Checking Flask status..." -ForegroundColor Yellow
        Write-Host ""

        $result = ssh "$User@$Host" @"
cd $RemotePath
if [ -f .flask.pid ]; then
    PID=\$(cat .flask.pid)
    if kill -0 \$PID 2>/dev/null; then
        echo "Status: RUNNING (PID: \$PID)"
    else
        echo "Status: STOPPED (stale PID file)"
    fi
else
    if pgrep -f 'flask run' > /dev/null; then
        echo "Status: RUNNING (no PID file)"
    else
        echo "Status: STOPPED"
    fi
fi

# Check port
if netstat -tln 2>/dev/null | grep -q ':5000 '; then
    echo "Port 5000: LISTENING"
else
    echo "Port 5000: NOT LISTENING"
fi

# Check venv
if [ -d venv ]; then
    echo "Venv: INSTALLED"
else
    echo "Venv: NOT INSTALLED"
fi

# Check app.py
if [ -f app.py ]; then
    echo "App: FOUND"
else
    echo "App: NOT FOUND"
fi
"@

        Write-Host $result
        Write-Host ""
        Write-Host "Access: http://${Host}:5000" -ForegroundColor Cyan
    }

    "shell" {
        Write-Host "Opening SSH shell to Batocera..." -ForegroundColor Yellow
        Write-Host "Directory: $RemotePath" -ForegroundColor Cyan
        Write-Host ""
        ssh -t "$User@$Host" "cd $RemotePath && bash"
    }
}

Write-Host ""

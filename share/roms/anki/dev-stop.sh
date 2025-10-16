#!/bin/bash
#
# Development Stop Script
# Stop the Flask app cleanly
#
# Usage:
#   ./dev-stop.sh
#

set -e

APP_DIR="/userdata/roms/anki"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Anki Viewer - Stop Flask"
echo "========================================"
echo ""

cd "$APP_DIR"

echo -e "${YELLOW}Stopping Flask...${NC}"

# Stop by PID file
if [ -f .flask.pid ]; then
    FLASK_PID=$(cat .flask.pid)
    if kill -0 "$FLASK_PID" 2>/dev/null; then
        echo "Stopping Flask (PID: $FLASK_PID)..."
        kill "$FLASK_PID" 2>/dev/null || true
        sleep 1
        # Force kill if still running
        kill -9 "$FLASK_PID" 2>/dev/null || true
    fi
    rm -f .flask.pid
fi

# Fallback: kill all Flask processes on our port
pkill -f "flask run" || true

echo -e "${GREEN}✓ Flask stopped${NC}"
echo ""

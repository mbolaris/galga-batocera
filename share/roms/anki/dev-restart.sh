#!/bin/bash
#
# Development Restart Script
# Quickly restart the Flask app (useful during development)
#
# Usage:
#   ./dev-restart.sh
#

set -e

APP_DIR="/userdata/roms/anki"
VENV_DIR="$APP_DIR/venv"
PORT=5000

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Anki Viewer - Quick Restart"
echo "========================================"
echo ""

cd "$APP_DIR"

# Step 1: Stop existing Flask
echo -e "${YELLOW}Stopping Flask...${NC}"
pkill -f "flask run" || true
rm -f "$APP_DIR/.flask.pid"
sleep 1
echo -e "${GREEN}✓ Stopped${NC}"
echo ""

# Step 2: Check prerequisites
if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: Virtual environment not found!"
    echo "Run ./start-anki-viewer.sh or ./dev-update.sh first"
    exit 1
fi

if [ ! -f app.py ]; then
    echo "ERROR: app.py not found!"
    exit 1
fi

# Step 3: Start Flask
echo -e "${YELLOW}Starting Flask...${NC}"
source "$VENV_DIR/bin/activate"

export FLASK_APP="$APP_DIR/app.py"
export FLASK_ENV=development

nohup python -m flask run --host=0.0.0.0 --port=$PORT > flask.log 2>&1 &
FLASK_PID=$!
echo $FLASK_PID > .flask.pid

echo -e "${GREEN}✓ Started (PID: $FLASK_PID)${NC}"
echo ""

# Wait for Flask to be ready
echo -e "${YELLOW}Waiting for Flask to be ready...${NC}"
MAX_WAIT=10
COUNTER=0
while [ $COUNTER -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$PORT/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Flask is ready!${NC}"
        break
    fi
    sleep 1
    COUNTER=$((COUNTER + 1))
    echo -n "."
done
echo ""

if [ $COUNTER -eq $MAX_WAIT ]; then
    echo "WARNING: Flask may not be ready"
    echo "Check logs: tail -f $APP_DIR/flask.log"
fi

echo "========================================"
echo -e "${GREEN}  Flask Restarted!${NC}"
echo "========================================"
echo ""
echo "Access at:"
echo "  http://localhost:$PORT"
echo "  http://$(hostname -I | awk '{print $1}'):$PORT"
echo ""
echo "Logs: tail -f $APP_DIR/flask.log"
echo "Stop:  pkill -f 'flask run' or ./dev-stop.sh"
echo ""

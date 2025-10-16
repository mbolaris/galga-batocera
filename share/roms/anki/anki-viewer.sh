#!/bin/bash
#
# Anki Deck Viewer - EmulationStation Launcher
# Place this in /userdata/roms/anki/ on Batocera
#
# This script is designed to be launched from EmulationStation.
# It starts the Flask app in the background and opens it in a browser.
# When the browser exits, the Flask app is automatically terminated.
#

set -e

APP_DIR="/userdata/roms/anki"
VENV_DIR="$APP_DIR/venv"
FLASK_APP="$APP_DIR/app.py"
PORT=5000
FLASK_PID_FILE="$APP_DIR/.flask.pid"
FLASK_LOG="$APP_DIR/flask.log"

echo "========================================"
echo "  Anki Deck Viewer - ES Launcher"
echo "========================================"

# Change to app directory
cd "$APP_DIR"

# Function to cleanup Flask process
cleanup_flask() {
    echo ""
    echo "Cleaning up Flask process..."

    if [ -f "$FLASK_PID_FILE" ]; then
        FLASK_PID=$(cat "$FLASK_PID_FILE")
        if kill -0 "$FLASK_PID" 2>/dev/null; then
            echo "Stopping Flask (PID: $FLASK_PID)..."
            kill "$FLASK_PID" 2>/dev/null || true
            sleep 1
            # Force kill if still running
            kill -9 "$FLASK_PID" 2>/dev/null || true
        fi
        rm -f "$FLASK_PID_FILE"
    fi

    # Fallback: kill any Flask processes on our port
    pkill -f "flask run.*$PORT" || true

    echo "Cleanup complete"
}

# Register cleanup on exit
trap cleanup_flask EXIT INT TERM

# Step 1: Check if venv exists
if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: Virtual environment not found at $VENV_DIR"
    echo ""
    echo "Please run start-anki-viewer.sh first to set up the environment:"
    echo "  cd /userdata/roms/anki"
    echo "  ./start-anki-viewer.sh"
    echo ""
    echo "Press any key to exit..."
    read -n 1
    exit 1
fi

# Step 2: Check if app.py exists
if [ ! -f "$FLASK_APP" ]; then
    echo "ERROR: Flask app not found at $FLASK_APP"
    echo "Press any key to exit..."
    read -n 1
    exit 1
fi

# Step 3: Activate venv and start Flask in background
echo "Starting Flask app in background..."
source "$VENV_DIR/bin/activate"

# Kill any existing Flask process
cleanup_flask

# Start Flask in background with logging
export FLASK_APP="$FLASK_APP"
export FLASK_ENV=development
nohup python -m flask run --host=0.0.0.0 --port=$PORT > "$FLASK_LOG" 2>&1 &
FLASK_PID=$!
echo $FLASK_PID > "$FLASK_PID_FILE"

echo "Flask started (PID: $FLASK_PID)"
echo "Logs: $FLASK_LOG"

# Step 4: Wait for Flask to be ready
echo "Waiting for Flask to start..."
MAX_WAIT=10
COUNTER=0
while [ $COUNTER -lt $MAX_WAIT ]; do
    if curl -s http://localhost:$PORT/ > /dev/null 2>&1; then
        echo "Flask is ready!"
        break
    fi
    sleep 1
    COUNTER=$((COUNTER + 1))
done

if [ $COUNTER -eq $MAX_WAIT ]; then
    echo "WARNING: Flask may not be ready, but continuing anyway..."
    echo "Check logs at: $FLASK_LOG"
fi

sleep 2

# Step 5: Launch browser
echo "Launching browser..."
echo "========================================"
echo ""

# Try multiple browser options (Batocera may have different browsers)
BROWSER_LAUNCHED=false

# Option 1: Firefox via flatpak
if command -v flatpak >/dev/null 2>&1; then
    if flatpak list | grep -q firefox; then
        echo "Launching Firefox (flatpak)..."
        flatpak run org.mozilla.firefox --kiosk http://localhost:$PORT
        BROWSER_LAUNCHED=true
    fi
fi

# Option 2: System Firefox
if [ "$BROWSER_LAUNCHED" = false ] && command -v firefox >/dev/null 2>&1; then
    echo "Launching Firefox (system)..."
    firefox --kiosk http://localhost:$PORT
    BROWSER_LAUNCHED=true
fi

# Option 3: Chromium
if [ "$BROWSER_LAUNCHED" = false ] && command -v chromium >/dev/null 2>&1; then
    echo "Launching Chromium..."
    chromium --kiosk --app=http://localhost:$PORT
    BROWSER_LAUNCHED=true
fi

# Option 4: Generic xdg-open (opens default browser)
if [ "$BROWSER_LAUNCHED" = false ] && command -v xdg-open >/dev/null 2>&1; then
    echo "Launching default browser..."
    xdg-open http://localhost:$PORT
    # xdg-open doesn't block, so we need to keep the script running
    echo ""
    echo "Browser launched. Press any key to stop the Flask app and exit..."
    read -n 1
    BROWSER_LAUNCHED=true
fi

# Fallback: No browser available
if [ "$BROWSER_LAUNCHED" = false ]; then
    echo "ERROR: No browser found!"
    echo ""
    echo "The Flask app is running at:"
    echo "  http://localhost:$PORT"
    echo "  http://$(hostname -I | awk '{print $1}'):$PORT"
    echo ""
    echo "You can access it from another device on your network."
    echo ""
    echo "Press any key to stop the Flask app and exit..."
    read -n 1
fi

# When browser closes, cleanup will happen automatically via trap
echo ""
echo "Browser closed. Shutting down..."

exit 0

#!/bin/bash
#
# Development Update Script
# Run this on Batocera to pull latest changes and update the Flask app
#
# Usage:
#   ./dev-update.sh              # Pull from git and update deps
#   ./dev-update.sh --skip-git   # Only update deps, don't pull
#   ./dev-update.sh --deps-only  # Only reinstall dependencies
#

set -e

APP_DIR="/userdata/roms/anki"
VENV_DIR="$APP_DIR/venv"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "========================================"
echo "  Anki Viewer - Development Update"
echo "========================================"
echo ""

cd "$APP_DIR"

# Parse arguments
SKIP_GIT=false
DEPS_ONLY=false

for arg in "$@"; do
    case $arg in
        --skip-git)
            SKIP_GIT=true
            ;;
        --deps-only)
            DEPS_ONLY=true
            ;;
    esac
done

# Step 1: Stop running Flask instances
echo -e "${YELLOW}[1/4] Stopping Flask instances...${NC}"
pkill -f "flask run" || true
rm -f "$APP_DIR/.flask.pid"
echo -e "${GREEN}      ✓ Flask stopped${NC}"
echo ""

# Step 2: Pull from Git (unless skipped)
if [ "$DEPS_ONLY" = false ]; then
    if [ "$SKIP_GIT" = false ]; then
        if [ -d .git ]; then
            echo -e "${YELLOW}[2/4] Pulling latest changes from Git...${NC}"
            git fetch origin
            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            echo "      Current branch: $CURRENT_BRANCH"

            # Check if there are changes
            if git diff --quiet HEAD origin/$CURRENT_BRANCH; then
                echo -e "${GREEN}      ✓ Already up to date${NC}"
            else
                echo "      Pulling changes..."
                git pull origin $CURRENT_BRANCH
                echo -e "${GREEN}      ✓ Git pull complete${NC}"
            fi
        else
            echo -e "${YELLOW}[2/4] Not a git repository, skipping...${NC}"
        fi
    else
        echo -e "${YELLOW}[2/4] Skipping git pull (--skip-git flag)${NC}"
    fi
else
    echo -e "${YELLOW}[2/4] Skipping git pull (--deps-only flag)${NC}"
fi
echo ""

# Step 3: Update Python dependencies
echo -e "${YELLOW}[3/4] Updating Python dependencies...${NC}"

if [ ! -d "$VENV_DIR" ]; then
    echo "      Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

if [ -f requirements.txt ]; then
    echo "      Installing/updating packages from requirements.txt..."
    pip install --upgrade pip -q
    pip install -r requirements.txt --upgrade
    echo -e "${GREEN}      ✓ Dependencies updated${NC}"
else
    echo -e "${RED}      ! Warning: requirements.txt not found${NC}"
fi

deactivate
echo ""

# Step 4: Verify files
echo -e "${YELLOW}[4/4] Verifying installation...${NC}"

if [ ! -f app.py ]; then
    echo -e "${RED}      ✗ app.py not found!${NC}"
    exit 1
fi

if [ ! -x start-anki-viewer.sh ]; then
    chmod +x start-anki-viewer.sh
    echo "      Fixed permissions for start-anki-viewer.sh"
fi

if [ ! -x anki-viewer.sh ]; then
    chmod +x anki-viewer.sh
    echo "      Fixed permissions for anki-viewer.sh"
fi

echo -e "${GREEN}      ✓ All files verified${NC}"
echo ""

echo "========================================"
echo -e "${GREEN}  Update Complete!${NC}"
echo "========================================"
echo ""
echo "To start the app:"
echo "  ./start-anki-viewer.sh"
echo ""
echo "Or launch from EmulationStation (if configured)"
echo ""

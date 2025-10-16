#!/bin/sh
# Example port launcher for Batocera
# Place this script in /userdata/roms/ports or on the SMB share under share/roms/ports

# set up environment variables or library paths here if needed
export LD_LIBRARY_PATH=/userdata/ports/example_game/lib:$LD_LIBRARY_PATH

# Example executable location under /userdata
GAME_BIN="/userdata/ports/example_game/example_game.bin"

if [ ! -x "$GAME_BIN" ]; then
  echo "Example game binary not found or not executable: $GAME_BIN"
  exit 1
fi

exec "$GAME_BIN" "$@"

#!/bin/bash

# Configuration
TOS_DIR="/userdata/system/tos428"
FOURWAYFILE="$TOS_DIR/roms4way.txt"
ROM_LIST="/userdata/system/roms_merged_controller.txt"
MERGE_ENABLED_FILE="/tmp/merge_controller_enabled"

case "$1" in
    gameStart)
        rom=$(basename "$5")

        # TOS Directional Setting (if applicable)
        if grep -q "^$rom$" "$FOURWAYFILE"; then
            way=4
        else
            way=8
        fi
        port=$($TOS_DIR/ld-linux-armhf.so.3 --library-path "${TOS_DIR}" "${TOS_DIR}/tos428cl.exe" getport)
        $TOS_DIR/ld-linux-armhf.so.3 --library-path "${TOS_DIR}" "${TOS_DIR}/tos428cl.exe" "$port" setway,all,"$way" >/dev/null 2>&1

        # Enable/Disable Merging
        if grep -q "^$rom$" "$ROM_LIST"; then
            echo "True" > "$MERGE_ENABLED_FILE"
        else
            echo "False" > "$MERGE_ENABLED_FILE"
        fi
        ;;

    gameStop)
        # Clean up the flag file
        rm -f "$MERGE_ENABLED_FILE"
        ;;
esac
#!/bin/bash

# Configuration
TOS_DIR="/userdata/system/tos428"
FOURWAYFILE="$TOS_DIR/roms4way.txt"

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
        ;;

    gameStop)
        # Clean up 
        ;;
esac

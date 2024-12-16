#!/bin/bash

# Paths and Configuration
readonly CONTROLLER_SWITCHER_DIR="/userdata/system/tos428"
readonly CONTROLLER_CONFIG_DIR="/userdata/system/controller_config"

# Configuration Files
readonly FOUR_WAY_ROMS_LIST="${CONTROLLER_SWITCHER_DIR}/roms4way.txt"
readonly MERGED_CONTROLLER_ROMS_LIST="${CONTROLLER_CONFIG_DIR}/single-controller-roms.txt"
readonly CONTROLLER_MERGE_STATE="/tmp/merge_controller_enabled"

# Controller Switcher Binaries
readonly SWITCHER_LOADER="${CONTROLLER_SWITCHER_DIR}/ld-linux-armhf.so.3"
readonly SWITCHER_BINARY="${CONTROLLER_SWITCHER_DIR}/tos428cl.exe"

# Configure Game Controls
configure_game_controls() {
    local rom_name="$1"
    local directional_mode

    # Determine directional control mode
    if grep -q "^${rom_name}$" "$FOUR_WAY_ROMS_LIST"; then
        directional_mode=4
    else
        directional_mode=8
    fi

    # Configure controller switcher
    local switcher_port
    switcher_port=$("${SWITCHER_LOADER}" --library-path "${CONTROLLER_SWITCHER_DIR}" "${SWITCHER_BINARY}" getport)

    "${SWITCHER_LOADER}" --library-path "${CONTROLLER_SWITCHER_DIR}" "${SWITCHER_BINARY}" \
        "${switcher_port}" "setway,all,${directional_mode}" >/dev/null 2>&1
}

# Set Controller Merge State
set_controller_merge_state() {
    local rom_name="$1"

    if grep -q "^${rom_name}$" "${MERGED_CONTROLLER_ROMS_LIST}"; then
        echo "True" > "${CONTROLLER_MERGE_STATE}"
    else
        echo "False" > "${CONTROLLER_MERGE_STATE}"
    fi
}

# Main Script Logic
case "$1" in
    gameStart)
        rom_name=$(basename "$5")
        configure_game_controls "${rom_name}"
        set_controller_merge_state "${rom_name}"
        ;;
    gameStop)
        rm -f "${CONTROLLER_MERGE_STATE}"
        ;;
esac

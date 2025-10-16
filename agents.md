Agents guidance for working with Batocera (Raspberry Pi 5)
=========================================================

This file documents constraints and best-practices for automated agents and contributors who will customize Batocera Linux on Raspberry Pi devices.

Key constraints (read and follow)
- Batocera is a read-only Buildroot-based system. Most system files are not writable.
- User data and persistent customization belongs under /userdata. On the host/PC this is exposed via the SMB share \\\\BATOCERA\\share (\"share\" partition).
- You have SSH access to Batocera as the root user (for direct devices). Prefer making persistent changes under /userdata instead of changing the base system.
- Do NOT use apt, dnf, or other distribution package managers; they are not available in Buildroot images.

Where to put custom apps and scripts
- /userdata/roms/ports is the canonical place to add custom launch scripts (for EmulationStation). Scripts here can be made executable and launched like normal ROMs.
- /userdata/system/custom.sh is commonly used for small boot-time customization hooks. See `share/system/custom.sh` in this repo for an example of a script shipped on the share partition.
- Use /userdata/config or /userdata/.config for persistent configuration files, environment variables, or service wrappers.

EmulationStation and menu entries
- EmulationStation reads system definitions from es_systems.cfg. Batocera may use overlay XML files; it's safe to add custom XML overlays under /userdata/system/configs/emulationstation or by editing the `share/configs/emulationstation` area on the SMB share.
- To add a custom menu entry, create a system XML describing the path to the ROM (or port script) and the appropriate command to run. Place the script in /userdata/roms/[system]/ and make it executable.

Packaging and distribution recommendations
- Avoid modifying the base image. Keep packages self-contained under /userdata.
- Prefer: flatpak (if available and supported on the device image), self-contained Python virtualenvs in /userdata (e.g., /userdata/venvs/myapp), or statically linked binaries copied into /userdata/bin.
- If large files are needed, store them in the SMB share `share/` and reference them from /userdata at runtime.

Security and maintenance
- Because many Batocera devices are single-user and run as root, avoid storing sensitive secrets in plaintext in /userdata.
- Use minimal wrapper scripts that set up env vars and then exec the real program so updates are simple.

Example patterns
- Custom port launcher (placed at /userdata/roms/ports/mygame.sh):
  #!/bin/sh
  # set up environment
  export LD_LIBRARY_PATH=/userdata/ports/mygame/lib:$LD_LIBRARY_PATH
  exec /userdata/ports/mygame/mygame.bin "$@"

- EmulationStation XML overlay (place under share/configs/emulationstation/ or /userdata/system/configs/emulationstation):
  <system>
    <name>ports</name>
    <fullname>Ports</fullname>
    <path>/userdata/roms/ports</path>
    <extension>.sh</extension>
    <command>bash %ROM%</command>
    <platform>ports</platform>
  </system>

Repository notes
- This repository contains a `share/` subtree that mirrors what can be put on the SMB share (\\BATOCERA\\share). Use that area for files you want to copy onto the Batocera share.
- Example files in this repo:
  - `share/system/custom.sh` — example boot/customization hook
  - `share/scripts/game_start.sh` — launcher helper scripts

Agent behaviour rules (persistent)
- Always prefer solutions that place files under /userdata or the SMB share (\\BATOCERA\\share).
- Do not attempt to run package manager installs that require modifying the base image.
- Where possible, produce small, self-contained scripts or bundles that can be copied into /userdata and executed without system changes.

If something cannot be done within these constraints, document why and provide a safe, user-approved alternative (for example: an SD image rebuild or manual system update instructions).

Contact
- Repository owner: mbolaris

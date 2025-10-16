# galga-batocera
Batocera customizations for Raspberry Pi

This repository contains customizations and apps for Batocera Linux, including a complete Flask-based Anki deck viewer with EmulationStation integration.

## Quick Links

- [agents.md](agents.md) - Agent and contributor guidelines for Batocera development
- [Anki Viewer](share/roms/anki/) - Flask app for viewing Anki flashcard decks
- [Development Workflow](share/roms/anki/DEVELOPMENT.md) - Complete dev guide
- [EmulationStation Integration](share/roms/anki/ES-INTEGRATION.md) - Add app to ES menu

## What's Included

### Anki Deck Viewer (Flask App)

A polished web application for studying Anki flashcard decks on Batocera:

- **Full Anki `.apkg` support** - Reads actual Anki decks with SQLite parser
- **Multiple card types** - Basic, cloze deletion, and image-only cards
- **Flask-based web UI** - Access at `http://batocera-ip:5000`
- **Keyboard shortcuts** - Space to flip, arrows to navigate, 'R' for random, '?' for help
- **Multi-deck support** - Switch between decks without restarting
- **Self-contained** - All deps in local Python venv, no system modifications
- **EmulationStation integration** - Launch from ES menu like any other app
- **Full development workflow** - Deploy from Windows PC via VSCode, SSH, or SMB
- **Source**: https://github.com/mbolaris/anki

**Key Files:**
- [share/roms/anki/](share/roms/anki/) - Complete Flask application
- [share/system/configs/emulationstation/es_systems_anki.cfg](share/system/configs/emulationstation/es_systems_anki.cfg) - ES system definition
- [dev-tools/](dev-tools/) - PowerShell deployment scripts
- [Makefile](Makefile) - Quick development commands

### Other Customizations

- [share/system/custom.sh](share/system/custom.sh) - Boot-time customization hook
- [share/system/scripts/](share/system/scripts/) - Helper scripts
- [share/roms/ports/](share/roms/ports/) - Example port launchers

## Repository Structure

```
galga-batocera/
├── share/                    # Mirrors \\BATOCERA\share
│   ├── roms/
│   │   ├── anki/            # Anki Deck Viewer Flask app
│   │   │   ├── app.py
│   │   │   ├── start-anki-viewer.sh
│   │   │   ├── anki-viewer.sh (ES launcher)
│   │   │   ├── requirements.txt
│   │   │   ├── dev-*.sh (development scripts)
│   │   │   ├── README.md
│   │   │   ├── INSTALL.md
│   │   │   ├── DEVELOPMENT.md
│   │   │   └── ES-INTEGRATION.md
│   │   └── ports/           # Custom port launchers
│   ├── system/
│   │   ├── configs/
│   │   │   └── emulationstation/
│   │   │       └── es_systems_anki.cfg
│   │   ├── custom.sh
│   │   └── scripts/
│   └── ...
├── dev-tools/               # Windows development tools
│   ├── deploy.ps1
│   └── remote-cmd.ps1
├── .vscode/                 # VSCode settings
│   ├── settings.json
│   ├── tasks.json
│   ├── launch.json
│   └── extensions.json
├── Makefile                 # Development commands
├── README.md                # This file
└── agents.md                # Batocera development guidelines
```

## 🎉 Deployment Status

**✅ DEPLOYED TO BATOCERA (GALAGA - 192.168.1.53)**

The Anki Deck Viewer is now live! Access it at: **http://192.168.1.53:5000**

See [DEPLOYMENT-COMPLETE.md](DEPLOYMENT-COMPLETE.md) for full details and next steps.

## Quick Start

### Deploy Anki Viewer to Batocera

**✅ Already Deployed!** The app is ready at `/userdata/roms/anki` on your Batocera device.

### One-Time Setup: SSH Keys (Faster Deployments)

To avoid entering passwords during deployment, set up SSH key authentication:

```cmd
setup-ssh-key.bat
```

This will:
- Generate an SSH key if you don't have one
- Copy it to GALAGA for password-less access
- Only needs to be done once

After this, deployments are much faster with fewer password prompts!

### Install/Update from GitHub (Recommended)

To install or update to the latest version from https://github.com/mbolaris/anki:

**From Windows:**
```cmd
deploy-anki-from-github.bat
```

**From Batocera (SSH):**
```bash
ssh root@192.168.1.53
cd /userdata/roms/anki
./install-from-github.sh
```

**For clean install (removes existing):**
```cmd
deploy-anki-from-github.bat clean
```

This will:
- Clone the latest version from GitHub
- Install to `/userdata/roms/anki`
- Preserve your deck files in `/userdata/roms/anki/decks/`
- Restart the Flask app automatically

### Alternative Deployment Methods

**Option 1: Using Make**
```powershell
cd c:\shared\bolaris\galga-batocera
make deploy BATOCERA_HOST=192.168.1.53
```

**Option 2: Using SMB Share (Manual)**
1. Copy deployment scripts to `\\BATOCERA\share\roms\anki\`
2. SSH into Batocera and run the GitHub installer:
   ```bash
   cd /userdata/roms/anki
   ./install-from-github.sh
   ```

### Access the App

Once deployed and running:
- **Web interface:** `http://192.168.1.53:5000`
- **EmulationStation:** Select "Anki Deck Viewer" from menu
- **SSH:** `ssh root@192.168.1.53` then `cd /userdata/roms/anki`

## Development

See [DEVELOPMENT.md](share/roms/anki/DEVELOPMENT.md) for complete development workflow guide.

**Quick commands:**
```powershell
make deploy         # Deploy files
make restart        # Deploy and restart Flask
make update         # Deploy and update dependencies
make status         # Check Flask status
make logs           # View logs
make logs-follow    # Follow logs in real-time
make shell          # SSH into Batocera
```

**VSCode integration:**
- Press `Ctrl+Shift+B` to deploy and restart
- Press `F5` to run Flask locally
- `Ctrl+Shift+P` → "Tasks: Run Task" for more options

## Documentation

- **[agents.md](agents.md)** - Batocera development constraints and best practices
- **[share/roms/anki/README.md](share/roms/anki/README.md)** - Anki Viewer overview
- **[share/roms/anki/INSTALL.md](share/roms/anki/INSTALL.md)** - Installation guide
- **[share/roms/anki/DEVELOPMENT.md](share/roms/anki/DEVELOPMENT.md)** - Development workflow
- **[share/roms/anki/ES-INTEGRATION.md](share/roms/anki/ES-INTEGRATION.md)** - EmulationStation setup
- **[share/README-ports.md](share/README-ports.md)** - Custom ports guide

## Batocera Guidelines

Files under `share/` mirror the SMB `\\BATOCERA\\share` area and are safe to copy to the device's `share` partition or edit directly from the PC.

**Key Principles:**
- Batocera uses a read-only Buildroot system
- User data lives in `/userdata` (mounted from `share` partition)
- No `apt` or system package managers available
- Use self-contained solutions (venvs, flatpak, static binaries)
- Custom apps go in `/userdata/roms/ports` or custom system directories
- EmulationStation config overlays in `/userdata/system/configs/emulationstation/`

See [agents.md](agents.md) for complete guidelines.

## Contributing

This repository follows Batocera best practices:
1. All customizations are self-contained in `/userdata`
2. No base system modifications
3. Portable and reproducible
4. Version controlled with Git

See [agents.md](agents.md) for contributor guidelines.

## License

This project contains customizations for Batocera Linux. Batocera itself is licensed under GPLv3.

## References

- [Batocera Official Site](https://batocera.org/)
- [Batocera Wiki](https://wiki.batocera.org/)
- [EmulationStation](https://emulationstation.org/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [ankipandas](https://github.com/klieret/ankipandas)

@echo off
REM Deploy Anki Viewer from GitHub to Batocera
REM This script copies the installer to GALAGA and runs it

echo ========================================
echo   Anki Viewer - GitHub Deployment
echo ========================================
echo.

set BATOCERA_HOST=192.168.1.53
set BATOCERA_USER=root
set LOCAL_SCRIPT=share\roms\anki\install-from-github.sh
set REMOTE_PATH=/userdata/roms/anki

echo Source: https://github.com/mbolaris/anki
echo Target: %BATOCERA_USER%@%BATOCERA_HOST%:%REMOTE_PATH%
echo.

REM Check if clean install requested
set CLEAN_FLAG=
if /i "%1"=="clean" (
    set CLEAN_FLAG=clean
    echo [CLEAN INSTALL MODE - Will remove existing installation]
    echo.
)

echo [1/4] Copying installer script to GALAGA...
scp "%LOCAL_SCRIPT%" %BATOCERA_USER%@%BATOCERA_HOST%:%REMOTE_PATH%/
if errorlevel 1 (
    echo ERROR: Failed to copy installer script
    pause
    exit /b 1
)

echo [2/4] Making installer executable and fixing line endings...
ssh %BATOCERA_USER%@%BATOCERA_HOST% "cd %REMOTE_PATH% && sed -i 's/\r$//' install-from-github.sh && chmod +x install-from-github.sh"
if errorlevel 1 (
    echo ERROR: Failed to prepare installer
    pause
    exit /b 1
)

echo [3/4] Running GitHub installer on GALAGA...
echo.
ssh %BATOCERA_USER%@%BATOCERA_HOST% "cd %REMOTE_PATH% && ./install-from-github.sh %CLEAN_FLAG%"
if errorlevel 1 (
    echo ERROR: Installation failed
    pause
    exit /b 1
)

echo [4/4] Restarting Flask app...
ssh %BATOCERA_USER%@%BATOCERA_HOST% "cd %REMOTE_PATH% && ./dev-restart.sh 2>/dev/null || ./start-anki-viewer.sh > /tmp/anki-start.log 2>&1 &"

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Anki Viewer installed from latest GitHub version
echo Access at: http://%BATOCERA_HOST%:5000
echo.
echo To update later, just run this script again!
echo For clean install: deploy-anki-from-github.bat clean
echo.
pause

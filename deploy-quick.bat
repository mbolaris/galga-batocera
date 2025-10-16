@echo off
REM Quick Deploy Script for Anki Viewer
REM Handles file copying and line ending conversion automatically

echo ========================================
echo   Anki Viewer - Quick Deploy
echo ========================================
echo.

set BATOCERA_HOST=192.168.1.53
set BATOCERA_USER=root
set LOCAL_PATH=c:\shared\bolaris\galga-batocera\share\roms\anki
set REMOTE_PATH=/userdata/roms/anki

echo Deploying to: %BATOCERA_USER%@%BATOCERA_HOST%:%REMOTE_PATH%
echo.

REM Copy main files
echo [1/4] Copying Python files...
scp "%LOCAL_PATH%\app.py" %BATOCERA_USER%@%BATOCERA_HOST%:%REMOTE_PATH%/
scp "%LOCAL_PATH%\requirements.txt" %BATOCERA_USER%@%BATOCERA_HOST%:%REMOTE_PATH%/

echo [2/4] Copying shell scripts...
scp "%LOCAL_PATH%\*.sh" %BATOCERA_USER%@%BATOCERA_HOST%:%REMOTE_PATH%/

echo [3/4] Fixing line endings and permissions...
ssh %BATOCERA_USER%@%BATOCERA_HOST% "cd %REMOTE_PATH% && dos2unix *.sh *.py 2>/dev/null || sed -i 's/\r$//' *.sh *.py && chmod +x *.sh"

echo [4/4] Restarting Flask...
ssh %BATOCERA_USER%@%BATOCERA_HOST% "cd %REMOTE_PATH% && ./dev-restart.sh"

echo.
echo ========================================
echo   Deployment Complete!
echo ========================================
echo.
echo Access the app at: http://%BATOCERA_HOST%:5000
echo.
pause

@echo off
REM Setup SSH Key for Password-less Access to GALAGA
REM Run this once to enable password-less SSH and SCP

echo ========================================
echo   SSH Key Setup for GALAGA
echo ========================================
echo.

set BATOCERA_HOST=192.168.1.53
set BATOCERA_USER=root

echo Target: %BATOCERA_USER%@%BATOCERA_HOST%
echo.

REM Check if SSH key exists
if not exist "%USERPROFILE%\.ssh\id_rsa.pub" (
    echo [1/2] No SSH key found - generating new key...
    ssh-keygen -t rsa -b 2048 -f "%USERPROFILE%\.ssh\id_rsa" -N "" -q
    echo       ✓ SSH key generated
) else (
    echo [1/2] SSH key already exists
)

echo [2/2] Installing SSH key on GALAGA...
echo       This will ask for your Batocera password ONE last time
echo.

REM Copy the SSH key to GALAGA
type "%USERPROFILE%\.ssh\id_rsa.pub" | ssh %BATOCERA_USER%@%BATOCERA_HOST% "mkdir -p /root/.ssh && chmod 700 /root/.ssh && cat >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys && echo 'SSH key installed successfully'"

if errorlevel 1 (
    echo.
    echo ERROR: Failed to install SSH key
    pause
    exit /b 1
)

echo.
echo ========================================
echo   SSH Key Setup Complete!
echo ========================================
echo.
echo You can now use SSH and SCP without entering a password!
echo.
echo Test it:
echo   ssh root@192.168.1.53 "echo 'Password-less SSH working!'"
echo.
echo Deploy without passwords:
echo   deploy-anki-from-github.bat
echo.
pause

@echo off
REM Automated SSH to Batocera
REM Usage: ssh-batocera.bat [command]
REM   ssh-batocera.bat           - Interactive shell
REM   ssh-batocera.bat hostname  - Run hostname command

set BATOCERA_HOST=192.168.1.53
set BATOCERA_USER=root

if "%1"=="" (
    echo Connecting to %BATOCERA_USER%@%BATOCERA_HOST%...
    powershell.exe -ExecutionPolicy Bypass -Command "$password = [System.Environment]::GetEnvironmentVariable('BATOCERA_PASSWORD', [System.EnvironmentVariableTarget]::User); if ([string]::IsNullOrEmpty($password)) { Write-Host 'ERROR: BATOCERA_PASSWORD not set' -ForegroundColor Red; exit 1 }; echo $password | ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no %BATOCERA_USER%@%BATOCERA_HOST%"
) else (
    powershell.exe -ExecutionPolicy Bypass -Command "$password = [System.Environment]::GetEnvironmentVariable('BATOCERA_PASSWORD', [System.EnvironmentVariableTarget]::User); if ([string]::IsNullOrEmpty($password)) { Write-Host 'ERROR: BATOCERA_PASSWORD not set' -ForegroundColor Red; exit 1 }; echo $password | ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no %BATOCERA_USER%@%BATOCERA_HOST% '%*'"
)

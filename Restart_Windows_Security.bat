@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :RunScript
) else (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

:RunScript
:: Navigate to the directory where the batch file is located
pushd "%~dp0"

:: Execute the PowerShell script
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Library\RUN_RestartWindowsSecurity-WinAuto.ps1"

:: Keep the window open if an error occurs or to see the final output
if %ERRORLEVEL% NEQ 0 pause
popd
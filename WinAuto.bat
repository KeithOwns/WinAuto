@echo off
pushd %~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\Main\WinAuto.ps1"
pause

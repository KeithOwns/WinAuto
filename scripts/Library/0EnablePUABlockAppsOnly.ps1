<#
.SYNOPSIS
    Enables ONLY the "Block apps" setting for PUA protection.

.DESCRIPTION
    This script forces the following setting to ON (Enabled):
    - Windows Defender PUA Protection (Block apps).
    
    It does NOT modify the "Block downloads" (Edge SmartScreen) setting.
    It reloads Windows Security to reflect changes.

.NOTES
    File Name: EnablePUABlockAppsOnly.ps1
    Author: Gemini
#>

# Check for Administrator privileges
# Required to modify Windows Defender settings and refresh the UI
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges to modify Windows Defender settings."
    Write-Warning "Please right-click the script and select 'Run with PowerShell' as Administrator."
    
    # Print 5 empty lines before exiting
    Write-Output "`n`n`n`n`n"
    exit
}

# Clear the PowerShell window before output
Clear-Host

Write-Host "--- Enabling 'Block apps' (PUA) Only ---`n" -ForegroundColor Magenta

# --- Setting: Enable "Block apps" (Windows Defender Engine) ---
Write-Host "Configuring 'Block apps'..." -ForegroundColor Cyan

try {
    # Set PUAProtection to Enabled (1)
    Set-MpPreference -PUAProtection Enabled -ErrorAction Stop
    Write-Host "Success: 'Block apps' is now ENABLED." -ForegroundColor Green
}
catch {
    Write-Error "Failed to enable 'Block apps'. Error: $_"
}

# --- Reload Interface ---
Write-Host "`nReloading Windows Security interface..." -ForegroundColor Gray
Get-Process SecHealthUI -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1
# Opens directly to the Reputation-based protection page
Start-Process "windowsdefender://reputation"

# Print 5 empty lines at the bottom before exiting
Write-Output "`n`n`n`n`n"
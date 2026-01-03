#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 11 Privacy & Core UI Optimizer
.DESCRIPTION
    Standardized for WinAuto. Non-blocking core privacy hardening.
#>

param([switch]$AutoRun)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- FUNCTIONS ---

function Configure-Privacy {
    Write-Host ""
    Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus Configuring Privacy Settings$Reset"
    try {
        if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) { New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Force | Out-Null }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force
        
        if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection")) { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null }
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force
        
        if (-not (Test-Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null }
        Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData" -Value 1 -Type DWord -Force
        
        Write-Success "Privacy hardening applied."
    } catch { Write-Failure "Privacy settings error: $($_.Exception.Message)" }
}

# --- MAIN EXECUTION ---
Write-Header "PRIVACY & UI OPTIMIZATION"

Configure-Privacy

Write-Host ""
Write-Boundary
Write-Centered "$FGGreen OPTIMIZATION COMPLETE $Reset"
Write-Boundary
Write-Host ""


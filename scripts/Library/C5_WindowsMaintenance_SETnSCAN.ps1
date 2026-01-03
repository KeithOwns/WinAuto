#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows Maintenance & Optimization Master Module
.DESCRIPTION
    Standardized Maintenance module for WinAuto.
    Runs Disk Optimization, Power Settings, Visual Effects, and System Cleanup.
#>

param([switch]$AutoRun)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- ERROR LOGGING SETUP ---
if (-not $Global:WinAutoErrorLogPath) {
    $Global:WinAutoErrorLogPath = "$env:WinAutoLogDir\Maintenance_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    if (-not (Test-Path $env:WinAutoLogDir)) { New-Item -Path $env:WinAutoLogDir -ItemType Directory -Force | Out-Null }
    "--- MAINTENANCE ERROR LOG START: $(Get-Date) ---" | Out-File -FilePath $Global:WinAutoErrorLogPath -Encoding UTF8 -Force
}

# Global Error Trap
Trap {
    Write-Log -Message "Unhandled Script Error: $($_.Exception.Message)" -Level ERROR
    Continue
}

# --- FUNCTIONS ---

function Invoke-MaintenanceTasks {
    Write-Boundary
    Write-Centered "$FGDarkCyan$Char_EnDash MAINTENANCE TASKS $Char_EnDash$Reset"
    
    & "$PSScriptRoot\RUN_CreateRestorePoint-WinAuto.ps1"
    & "$PSScriptRoot\RUN_OptimizeDisks-WinAuto.ps1"
    & "$PSScriptRoot\SET_PowerPlanHigh-WinAuto.ps1"
    & "$PSScriptRoot\SET_VisualEffectsPerformance-WinAuto.ps1"
    & "$PSScriptRoot\RUN_SystemCleanup-WinAuto.ps1"
    
    Write-Log "All maintenance tasks completed" "SUCCESS"
    Write-Boundary
}

# --- MAIN ---

try {
    if ($AutoRun) {
        Invoke-MaintenanceTasks
    } else {
        $showMenu = $true
        while ($showMenu) {
            Clear-Host
            Write-Header "MAINTENANCE & OPTIMIZATION"
            
            Write-Host ""
            Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}Disk Optimization${Reset}"
            Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Power Settings${Reset}"
            Write-LeftAligned " ${FGBlack}${BGYellow}[3]${Reset} ${FGGray}Visual Effects${Reset}"
            Write-LeftAligned " ${FGBlack}${BGYellow}[4]${Reset} ${FGGray}System Cleanup${Reset}"
            Write-Host ""
            Write-LeftAligned " ${FGBlack}${BGYellow}[A]${Reset} ${FGGray}Run ${FGYellow}ALL${FGGray} Tasks${Reset}"
            Write-Boundary
            
            $res = Invoke-AnimatedPause -ActionText "RUN ALL" -Timeout 15
            
            if ($res.VirtualKeyCode -eq 13 -or $res.Character -eq 'A' -or $res.Character -eq 'a') {
                Invoke-MaintenanceTasks
                Start-Sleep -Seconds 2
            } elseif ($res.Character -eq '1') {
                & "$PSScriptRoot\RUN_OptimizeDisks-WinAuto.ps1"
                Start-Sleep -Seconds 2
            } elseif ($res.Character -eq '2') {
                & "$PSScriptRoot\SET_PowerPlanHigh-WinAuto.ps1"
                Start-Sleep -Seconds 2
            } elseif ($res.Character -eq '3') {
                & "$PSScriptRoot\SET_VisualEffectsPerformance-WinAuto.ps1"
                Start-Sleep -Seconds 2
            } elseif ($res.Character -eq '4') {
                & "$PSScriptRoot\RUN_SystemCleanup-WinAuto.ps1"
                Start-Sleep -Seconds 2
            } else {
                $showMenu = $false
            }
        }
    }

    $FooterText = "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved."
    Write-Centered "$FGCyan$FooterText$Reset"
    Write-Host ""

} catch {
    Write-Host "`n$FGRed$Char_RedCross Critical Maintenance Error: $($_.Exception.Message)$Reset"
    Write-Log "Critical Maintenance Error: $($_.Exception.Message)" "ERROR"
    exit 1
}

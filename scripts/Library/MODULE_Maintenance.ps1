#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Module: Full Windows Maintenance & Optimization
.DESCRIPTION
    Fully automated maintenance of Windows 11. Non-blocking.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
$Global:WinAutoCompactMode = $true

# --- ERROR LOGGING SETUP ---
$Global:WinAutoErrorLogPath = "$env:WinAutoLogDir\Maintenance_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
if (-not (Test-Path $env:WinAutoLogDir)) { New-Item -Path $env:WinAutoLogDir -ItemType Directory -Force | Out-Null }
"--- MAINTENANCE ERROR LOG START: $(Get-Date) ---" | Out-File -FilePath $Global:WinAutoErrorLogPath -Encoding UTF8 -Force

# Global Error Trap
Trap {
    Write-Log -Message "Unhandled Script Error: $($_.Exception.Message)" -Level ERROR
    Continue
}

# --- MAIN EXECUTION ---
Write-Header "WINDOWS MAINTENANCE PHASE"

# 1. SYSTEM PRE-CHECK
Write-Log "Starting Maintenance Phase" -Level INFO
& "$PSScriptRoot\CHECK_System_PreCheck.ps1"

# 2. UPDATES
& "$PSScriptRoot\C1_WindowsUpdate_SETnSCAN.ps1" -AutoRun

# 3. REPAIR
& "$PSScriptRoot\RUN_WindowsSFC_REPAIR.ps1"

# 4. OPTIMIZATION
& "$PSScriptRoot\RUN_OptimizeDisks-WinAuto.ps1"
& "$PSScriptRoot\RUN_SystemCleanup-WinAuto.ps1"

Write-Host ""
Write-Centered "$FGGreen MAINTENANCE COMPLETE $Reset"
Write-Log "Maintenance Phase Complete. Errors (if any) logged to: $Global:WinAutoErrorLogPath" -Level INFO
$Global:WinAutoErrorLogPath = $null # Reset
Write-Footer


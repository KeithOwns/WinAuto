#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Master Entry Point: The Windows Automation Project
.DESCRIPTION
    Unified launcher for all WinAuto modules. 
    Standardized UI, automated timeouts, and modular execution.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
$Global:WinAutoCompactMode = $true
$Global:WinAutoManualActions = @()

# Ensure log directory exists
if (-not (Test-Path $Global:WinAutoLogDir)) { New-Item -Path $Global:WinAutoLogDir -ItemType Directory -Force | Out-Null }
Write-Log "WinAuto Session Started" -Level INFO

# --- MAIN EXECUTION ---
Clear-Host
Write-Header "WINAUTO: MASTER CONTROL"

Write-Host ""
Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}Configuration ${FGDarkGray}(Security, Privacy, UI Tweaks)${Reset}"
Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Maintenance   ${FGDarkGray}(Updates, Repair, Optimization)${Reset}"
Write-Host ""
Write-LeftAligned " ${FGBlack}${BGYellow}[A]${Reset} ${FGYellow}Run ALL${FGGray} Modules${Reset}"

Write-Boundary

$res = Invoke-AnimatedPause -ActionText "EXECUTE" -Timeout 10

if ($res.VirtualKeyCode -eq 13 -or $res.Character -eq 'A' -or $res.Character -eq 'a') {
    # Run ALL
    & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1"
    & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1"
} elseif ($res.Character -eq '1') {
    & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1"
} elseif ($res.Character -eq '2') {
    & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1"
} else {
    Write-LeftAligned "$FGGray Exiting WinAuto...$Reset"
    Start-Sleep -Seconds 1
    exit
}

# --- FINAL SUMMARY (Manual Actions collected from modules) ---
if ($Global:WinAutoManualActions.Count -gt 0) {
    Write-Host ""
    Write-Boundary $FGYellow
    Write-Centered "$FGYellow MANUAL ACTIONS REQUIRED $Reset"
    foreach ($m in $Global:WinAutoManualActions) {
        Write-Host ""
        Write-LeftAligned "$FGWhite$Char_Warn $($m.Action)$Reset"
        $lines = $m.Instructions -split "`n"
        foreach ($l in $lines) { Write-LeftAligned "   $l" }
    }
    Write-Boundary $FGYellow
}

Write-Host ""
Write-Boundary
Write-Centered "$FGGreen ALL REQUESTED TASKS COMPLETE $Reset"
Write-Boundary
Write-Log "WinAuto Session Completed Successfully" -Level SUCCESS

# Final Footer
$FooterText = "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved."
Write-Centered "$FGCyan$FooterText$Reset"
Write-Host ""


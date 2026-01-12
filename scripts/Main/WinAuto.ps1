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

# --- LOGGING SETUP ---
. "$PSScriptRoot\..\Library\MODULE_Logging.ps1"
Init-Logging

# Disable Console QuickEdit to prevent hanging
Set-ConsoleSnapRight -Columns 64
Disable-QuickEdit

Write-Log "WinAuto Session Started" -Level INFO

# Default to Standard Mode (Roadmap features OFF)
$Global:EnhancedSecurity = $false

# --- MAIN EXECUTION ---
while ($true) {
    Clear-Host
    Write-Header "WINAUTO: MASTER CONTROL"

    $lastConfig = Get-WinAutoLastRun -Module "Configuration"
    $lastMaint  = Get-WinAutoLastRun -Module "Maintenance"
    $enStatus   = if ($Global:EnhancedSecurity) { "${FGGreen}ON" } else { "${FGDarkGray}OFF" }

    Write-Host ""
    Write-LeftAligned " ${FGYellow}Smart Run${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}Configuration ${FGDarkGray}(Last: $lastConfig)${Reset}"
    if ($Global:ShowDetails) { Write-LeftAligned "      ${FGDarkGray}Sec, Firewall, Privacy, UI Tweaks${Reset}" }
    Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Maintenance   ${FGDarkGray}(Last: $lastMaint)${Reset}"
    if ($Global:ShowDetails) { Write-LeftAligned "      ${FGDarkGray}Updates, Cleanup, Repair, Optimization${Reset}" }
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[E]${Reset} ${FGYellow}Enhanced Security${FGGray} (Toggle: $enStatus${FGGray})${Reset}"
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[I]${Reset} ${FGGray}Install Applications${Reset}"
    Write-Host ""
    $DetailText = if ($Global:ShowDetails) { "Collapse Details" } else { "Expand Details" }
    Write-LeftAligned " ${FGBlack}${BGYellow}[Space]${Reset} ${FGGray}$DetailText${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[H]${Reset} ${FGCyan}Help / System Impact${Reset}"

    Write-Boundary

    $res = Invoke-AnimatedPause -ActionText "EXECUTE" -Timeout 0

    if ($res.VirtualKeyCode -eq 13 -or $res.Character -eq 'S' -or $res.Character -eq 's') {
        # Smart Run
        & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1" -SmartRun -EnhancedSecurity:$Global:EnhancedSecurity
        & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1" -SmartRun -EnhancedSecurity:$Global:EnhancedSecurity
        Start-Sleep -Seconds 2
    } elseif ($res.Character -eq '1') {
        # Force Run
        & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1" -EnhancedSecurity:$Global:EnhancedSecurity
        Start-Sleep -Seconds 2
    } elseif ($res.Character -eq '2') {
        # Force Run
        & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1" -EnhancedSecurity:$Global:EnhancedSecurity
        Start-Sleep -Seconds 2
    } elseif ($res.Character -eq 'E' -or $res.Character -eq 'e') {
        $Global:EnhancedSecurity = -not $Global:EnhancedSecurity
        continue
    } elseif ($res.Character -eq 'I' -or $res.Character -eq 'i') {
        # Install C++ Redistributables
        & "$PSScriptRoot\..\Library\RUN_Install_CppRedist-WinAuto.ps1"
        Write-Boundary
        Write-Centered "Press any key to return to menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } elseif ($res.Character -eq ' ' -or $res.VirtualKeyCode -eq 32) {
        $Global:ShowDetails = -not $Global:ShowDetails
        continue
    } elseif ($res.Character -eq 'H' -or $res.Character -eq 'h') {
        Clear-Host
        Write-Header "SYSTEM IMPACT MANIFEST"
        Write-Host ""
        
        # Check for Manifest file
        $manifestPath = "$PSScriptRoot\..\..\docs\MANIFEST\MANIFEST.md"
        if (Test-Path $manifestPath) {
            $content = Get-Content $manifestPath
            # Simple pager
            if ($content.Count -gt 30) {
                 $content | Select-Object -First 30 | ForEach-Object { Write-LeftAligned $_ }
                 Write-Host ""
                 Write-Centered "$FGCyan... (Press any key to read more) ...$Reset"
                 $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                 $content | Select-Object -Skip 30 | ForEach-Object { Write-LeftAligned $_ }
            } else {
                $content | ForEach-Object { Write-LeftAligned $_ }
            }
        } else {
            Write-LeftAligned "$FGRed$Char_Warn Manifest file not found.$Reset"
        }
        
        Write-Host ""
        Write-Boundary
        Write-Centered "Press any key to return to menu..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-LeftAligned "$FGGray Exiting WinAuto...$Reset"
        Start-Sleep -Seconds 1
        break
    }
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

try { Stop-Transcript -ErrorAction SilentlyContinue } catch {}


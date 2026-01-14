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
$Global:WinAutoFirstLoad = $true
$Global:InstallApps = $false

# Registry Paths (Shared Initialization)
$Global:RegPath_WU_UX  = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
$Global:RegPath_WU_POL = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$Global:RegPath_Winlogon_User = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" 
$Global:RegPath_Winlogon_Machine = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

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
    $iStatus    = if ($Global:InstallApps) { "${FGGreen}ON" } else { "${FGDarkGray}OFF" }

    Write-Host ""
    Write-LeftAligned "=>${FGBlack}${BGYellow}[S]${Reset}${FGYellow}mart Run${Reset}"
    Write-Host ""
    Write-LeftAligned "  ${FGYellow}[C]${Reset}${FGGray}onfiguration ${FGDarkGray}(Last: $lastConfig)${Reset}"
    Write-LeftAligned "      ${FGYellow}[E]${Reset}${FGGray}nhanced Security${FGGray} (Toggle: $enStatus${FGGray})${Reset}"
    if ($Global:ShowDetails) { Write-LeftAligned "      ${FGDarkGray}Sec, Firewall, Privacy, UI Tweaks${Reset}" }
    Write-Host ""
    Write-LeftAligned "  ${FGYellow}[M]${Reset}${FGGray}aintenance   ${FGDarkGray}(Last: $lastMaint)${Reset}"
    Write-LeftAligned "      ${FGYellow}[I]${Reset}${FGGray}nstall Applications${FGGray} (Toggle: $iStatus${FGGray})${Reset}"
    if ($Global:ShowDetails) { Write-LeftAligned "      ${FGDarkGray}Updates, Cleanup, Repair, Optimization${Reset}" }
    Write-Host ""
    $DetailText = if ($Global:ShowDetails) { "Details (Collapse)" } else { "Details (Expand)" }
    Write-LeftAligned "  ${FGYellow}Space${Reset} ${FGGray}$DetailText${Reset}"
    Write-Host ""
    Write-LeftAligned "  ${FGYellow}[H]${Reset}${FGCyan}elp / System Impact${Reset}"
    Write-LeftAligned "  ${FGRed}[Esc] Exit Script${Reset}"

    Write-Boundary

    # Timeout logic: Only on first load
    $ActionText = "RUN"
    $TimeoutSecs = if ($Global:WinAutoFirstLoad -ne $false) { 10 } else { 0 }
    $Global:WinAutoFirstLoad = $false

    $res = Invoke-AnimatedPause -ActionText $ActionText -Timeout $TimeoutSecs

    if ($res.VirtualKeyCode -eq 27) {
        # Esc
        Write-LeftAligned "$FGGray Exiting WinAuto...$Reset"
        Start-Sleep -Seconds 1
        break
    } elseif ($res.VirtualKeyCode -eq 13 -or $res.Character -eq 'S' -or $res.Character -eq 's') {
        # Smart Run
        & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1" -SmartRun -EnhancedSecurity:$Global:EnhancedSecurity
        & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1" -SmartRun -EnhancedSecurity:$Global:EnhancedSecurity
        
        # Install Apps if toggled ON
        if ($Global:InstallApps) { & "$PSScriptRoot\..\Library\RUN_InstallAppsConfigurable-WinAuto.ps1" }
        
        Start-Sleep -Seconds 2
    } elseif ($res.Character -eq 'C' -or $res.Character -eq 'c') {
        # Force Run Config
        & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1" -EnhancedSecurity:$Global:EnhancedSecurity
        Start-Sleep -Seconds 2
    } elseif ($res.Character -eq 'M' -or $res.Character -eq 'm') {
        # Force Run Maint
        & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1" -EnhancedSecurity:$Global:EnhancedSecurity
        
        # Install Apps if toggled ON
        if ($Global:InstallApps) { & "$PSScriptRoot\..\Library\RUN_InstallAppsConfigurable-WinAuto.ps1" }
        
        Start-Sleep -Seconds 2
    } elseif ($res.Character -eq 'E' -or $res.Character -eq 'e') {
        $Global:EnhancedSecurity = -not $Global:EnhancedSecurity
        continue
    } elseif ($res.Character -eq 'I' -or $res.Character -eq 'i') {
        $Global:InstallApps = -not $Global:InstallApps
        continue
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


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
$Global:RegPath_WU_UX = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
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

# --- DASHBOARD SPECIFIC UI OVERRIDES ---
# Local override to support precise Mockup prompts (e.g. "Press -> [Enter] for...")
$DashboardTick = {
    param($ElapsedTimespan, $ActionText = "RUN", $Timeout = 10, $PromptCursorTop, $SelectionChar = $null, $PreActionWord = "to")
    if ($null -eq $PromptCursorTop) { $PromptCursorTop = [Console]::CursorTop }

    # Dynamic prompt logic matching Mockups
    if ($SelectionChar) {
        if ($SelectionChar -eq "->") {
            # Initial Mockup Special Case: "Press -> [Enter] for SmartRun"
            $PromptStr = "$FGWhite$Char_Keyboard Press ${FGYellow}->${Reset}${FGWhite} ${FGBlack}${BGYellow}[Enter]${Reset}$FGWhite $PreActionWord ${FGYellow}$ActionText${Reset} $FGWhite| ${FGRed}[Esc]${Reset}$FGWhite to ${FGRed}EXIT$Reset"
        }
        else {
            # Standard Dynamic with Hotkey option
            $PromptStr = "$FGWhite$Char_Keyboard Move ${FGYellow}->${Reset}$FGWhite and Press ${FGBlack}${BGYellow}[Enter]${Reset}$FGWhite or ${FGBlack}${BGYellow}[$SelectionChar]${Reset}$FGWhite $PreActionWord ${FGYellow}$ActionText${Reset} $FGWhite| ${FGRed}[Esc]${Reset}$FGWhite to ${FGRed}EXIT$Reset"
        }
    }
    else {
        # Standard fallback text: "Press [Enter] to RUN"
        $PromptStr = "$FGWhite$Char_Keyboard Press ${FGBlack}${BGYellow}[Enter]${Reset}$FGWhite $PreActionWord ${FGYellow}$ActionText${Reset}   $FGWhite| Press ${FGRed}[Esc]${Reset}$FGWhite to ${FGRed}EXIT$Reset"
    }
    
    try { 
        [Console]::SetCursorPosition(0, $PromptCursorTop)
        Write-Host (" " * 80) -NoNewline # Clear line
        [Console]::SetCursorPosition(0, $PromptCursorTop)
        Write-Centered $PromptStr 
    }
    catch {}
}

function Invoke-AnimatedPause {
    param([string]$ActionText = "CONTINUE", [int]$Timeout = 10, [string]$SelectionChar = $null, [string]$PreActionWord = "to")
    Write-Host ""
    $PromptCursorTop = [Console]::CursorTop
    
    if ($Timeout -le 0) {
        & $DashboardTick -ElapsedTimespan ([timespan]::Zero) -ActionText $ActionText -Timeout 0 -PromptCursorTop $PromptCursorTop -SelectionChar $SelectionChar -PreActionWord $PreActionWord
        return $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    $LocalTick = {
        param($Elapsed)
        & $DashboardTick -ElapsedTimespan $Elapsed -ActionText $ActionText -Timeout $Timeout -PromptCursorTop $PromptCursorTop -SelectionChar $SelectionChar -PreActionWord $PreActionWord
    }

    # Re-use shared Wait function as it is generic, just pass new tick
    $res = Wait-KeyPressWithTimeout -Seconds $Timeout -OnTick $LocalTick
    Write-Host ""
    return $res
}

# Default to Standard Mode (Roadmap features OFF)
$Global:EnhancedSecurity = $false

# --- MAIN EXECUTION ---
$MenuSelection = 0  # 0=Smart, 1=Config, 2=Maintenance
# Per-section expansion flags
$ExpandS = $false; $ExpandC = $false; $ExpandM = $false

while ($true) {
    Write-Header "WINAUTO: MASTER CONTROL"
    
    $lastConfig = Get-WinAutoLastRun -Module "Configuration"
    $lastMaint = Get-WinAutoLastRun -Module "Maintenance"
    
    # Toggle Display Strings
    $enStatus = if ($Global:EnhancedSecurity) { "ON" } else { "OFF" }
    $enhancedBracket = if ($Global:EnhancedSecurity) { "${FGYellow}[E]${Reset}" } else { "${FGGray}[E]${Reset}" }
    
    $iStatus = if ($Global:InstallApps) { "ON" } else { "OFF" }
    $installBracket = if ($Global:InstallApps) { "${FGGreen}[I]${Reset}" } else { "${FGGray}[I]${Reset}" }

    # Arrows
    $ArrS = if ($MenuSelection -eq 0) { "${FGYellow}->${Reset}" } else { "  " }
    $ArrC = if ($MenuSelection -eq 1) { "${FGYellow}->${Reset}" } else { "  " }
    $ArrM = if ($MenuSelection -eq 2) { "${FGYellow}->${Reset}" } else { "  " }
    
    # Check "Simplified Mode" condition: No expansion flags set
    $IsSimplified = (-not $ExpandS) -and (-not $ExpandC) -and (-not $ExpandM)

    if ($IsSimplified) {
        # --- SIMPLIFIED DASHBOARD (MATCHING MOCKUP) ---
        Write-Host ""
        
        # [SmartRun] (Note: No split [S] in simplified mockup)
        # Mockup: "   -> [SmartRun]" (Line 6 Initial)
        if ($MenuSelection -eq 0) {
            # Selected SmartRun
            Write-LeftAligned "$ArrS ${FGBlack}${BGYellow}[SmartRun]${Reset}" -Indent 1
        }
        else {
            Write-LeftAligned "$ArrS ${FGYellow}[SmartRun]${Reset}" -Indent 1
        }
        
        Write-Host ""
        Write-Host "" # Spacer
        
        # [C]onfiguration
        # Mockup: "-> [C]onfiguration ..."
        # Style: [C] is yellow/highlighted but rest is white/gray? 
        # Mockup just shows text. I will use standard standard styling but ensure [C] bracket.
        
        if ($MenuSelection -eq 1) {
            # Active Selection
            Write-LeftAligned "$ArrC ${FGBlack}${BGYellow}[C]onfiguration${Reset}              ${FGDarkGray}(Last: $lastConfig)${Reset}" -Indent 1
        }
        else {
            Write-LeftAligned "$ArrC ${FGYellow}[C]onfiguration${Reset}              ${FGDarkGray}(Last: $lastConfig)${Reset}" -Indent 1
        }

        # Enhanced status line
        $eColor = if ($Global:EnhancedSecurity) { $FGGreen } else { $FGDarkGray }
        Write-LeftAligned "     ${FGGray}with $enhancedBracket${FGGray}nhanced Security ($eColor$enStatus${FGGray})${Reset}" -Indent 1
        Write-Host ""

        # [M]aintenance
        if ($MenuSelection -eq 2) {
            Write-LeftAligned "$ArrM ${FGBlack}${BGYellow}[M]aintenance${Reset}                ${FGDarkGray}(Last: $lastMaint)${Reset}" -Indent 1
        }
        else {
            Write-LeftAligned "$ArrM ${FGYellow}[M]aintenance${Reset}                ${FGDarkGray}(Last: $lastMaint)${Reset}" -Indent 1
        }

        # Install status line
        $iColor = if ($Global:InstallApps) { $FGGreen } else { $FGDarkGray }
        Write-LeftAligned "     ${FGGray}with $installBracket${FGGray}nstall Applications ($iColor$iStatus${FGGray})${Reset}" -Indent 1
        Write-Host ""
        
        # Helper Text Simplified
        Write-Boundary
        Write-Host ""
        Write-Centered "${FGDarkGray}Press [Key] to SELECT Option${Reset}"
        Write-Centered "${FGDarkGray}Press Space to EXPAND Details${Reset}"
    }
    else {
        # --- DETAILED OUTLINE DASHBOARD (EXPANDED MOCKUP) ---
        Write-Host ""
        
        # [S]mart Run
        if ($MenuSelection -eq 0) {
            Write-LeftAligned "$ArrS ${FGBlack}${BGYellow}[S]${Reset}${FGYellow}mart Run${Reset}" -Indent 1
        }
        else {
            Write-LeftAligned "$ArrS ${FGYellow}[S]${Reset}${FGYellow}mart Run${Reset}" -Indent 1
        }

        if ($ExpandS) {
            Write-LeftAligned "   ${FGDarkGray}Method: Orchestration Loop${Reset}" -Indent 1
            Write-LeftAligned "   ${FGDarkGray}Actions:${Reset}" -Indent 1
            Write-LeftAligned "   - System Hardening Check (Registry & Logic)" -Indent 1
            Write-LeftAligned "   - Maintenance Cycle (Component Check/Days)" -Indent 1
            Write-LeftAligned "   - Auto-Cleanup (File System)" -Indent 1
        }
        
        Write-Boundary # Separator per Expanded Mockup

        # [C]onfiguration
        if ($MenuSelection -eq 1) {
            Write-LeftAligned "$ArrC ${FGBlack}${BGYellow}[C]${Reset}${FGGray}onfiguration${Reset}              ${FGDarkGray}(Last: $lastConfig)${Reset}" -Indent 1
        }
        else {
            Write-LeftAligned "$ArrC ${FGYellow}[C]${Reset}${FGGray}onfiguration${Reset}              ${FGDarkGray}(Last: $lastConfig)${Reset}" -Indent 1
        }
        
        if ($ExpandC) {
            Write-LeftAligned "   ${FGDarkGray}Security Actions:${Reset}" -Indent 1
            Write-LeftAligned "   - Real-Time Protection      | PS WMI (MpPreference)" -Indent 1
            Write-LeftAligned "   - PUA Protection (Defender) | PS WMI (MpPreference)" -Indent 1
            Write-LeftAligned "   - Memory Integrity          | RegEdit (HKLM)" -Indent 1
            Write-LeftAligned "   - Kernel Stack Protection   | UI Automation" -Indent 1
            Write-LeftAligned "   - Windows Firewall          | Set-NetFirewallProfile" -Indent 1
            Write-LeftAligned "   ${FGDarkGray}UI & UX Actions:${Reset}" -Indent 1
            Write-LeftAligned "   - Taskbar/Widgets/Search    | RegEdit (HKCU)" -Indent 1
        }
        
        # Enhanced Toggle Line (Expanded Mockup Line 30: "[E]nhanced Security (Toggle) ON")
        $eColor = if ($Global:EnhancedSecurity) { $FGGreen } else { $FGDarkGray }
        Write-LeftAligned "   $enhancedBracket${FGGray}nhanced Security (Toggle) $eColor$enStatus${Reset}" -Indent 1
        
        if ($Global:EnhancedSecurity) {
            Write-LeftAligned "   - Expedited Updates         | UI Automation" -Indent 1
            Write-LeftAligned "   - Restart ASAP              | UI Automation" -Indent 1
            Write-LeftAligned "   - Metered Connection        | UI Automation" -Indent 1
        }

        Write-Boundary # Separator

        # [M]aintenance
        if ($MenuSelection -eq 2) {
            Write-LeftAligned "$ArrM ${FGBlack}${BGYellow}[M]${Reset}${FGGray}aintenance${Reset}                ${FGDarkGray}(Last: $lastMaint)${Reset}" -Indent 1
        }
        else {
            Write-LeftAligned "$ArrM ${FGYellow}[M]${Reset}${FGGray}aintenance${Reset}                ${FGDarkGray}(Last: $lastMaint)${Reset}" -Indent 1
        }
        
        if ($ExpandM) {
            Write-LeftAligned "   ${FGDarkGray}Orchestrated Maintenance:${Reset}" -Indent 1
            Write-LeftAligned "   - Windows Update Check      | COM Object & UI Automation" -Indent 1
            Write-LeftAligned "   - SFC System Scan           | Command Line (sfc.exe)" -Indent 1
            Write-LeftAligned "   - DISM Repair               | Command Line (dism.exe)" -Indent 1
            Write-LeftAligned "   - WinGet/Store App Updates  | Command Line / UI Automation" -Indent 1
            Write-LeftAligned "   - Drive Opt & Cleanup       | PS / FSR" -Indent 1
        }
        
        # Install Apps Toggle (Expanded Mockup Line 46: "[I]nstall Applications (Toggle) OFF")
        $iColor = if ($Global:InstallApps) { $FGGreen } else { $FGDarkGray }
        Write-LeftAligned "   $installBracket${FGGray}nstall Applications (Toggle) $iColor$iStatus${Reset}" -Indent 1

        Write-Boundary # Separator
        
        # Helper Text Detailed (NO ARROWS TEXT)
        Write-Host ""
        Write-Centered "${FGDarkGray}Press [Key] to SELECT Option${Reset}"
    }

    # Timeout logic: Only on first load
    $ActionText = "RUN"
    $TimeoutSecs = if ($Global:WinAutoFirstLoad -ne $false) { 10 } else { 0 }
    $Global:WinAutoFirstLoad = $false
    
    # Dynamic Footer Prompt Logic
    if ($IsSimplified -and $MenuSelection -eq 0) {
        # Initial View Special Case
        $Act = "SmartRun"
        $Sel = "->" # Special trigger
        $Pre = "for"
    }
    else {
        # Standard View (Option C or Detailed)
        $Act = "RUN"
        $Sel = $null
        $Pre = "to"
    }

    $res = Invoke-AnimatedPause -ActionText $Act -Timeout $TimeoutSecs -SelectionChar $Sel -PreActionWord $Pre

    # --- NAVIGATION LOGIC ---
    if ($res.VirtualKeyCode -eq 38) {
        # Up
        $MenuSelection--
        if ($MenuSelection -lt 0) { $MenuSelection = 2 }
        continue
    }
    elseif ($res.VirtualKeyCode -eq 40) {
        # Down
        $MenuSelection++
        if ($MenuSelection -gt 2) { $MenuSelection = 0 }
        continue
    }
    elseif ($res.VirtualKeyCode -eq 39) {
        # Right
        if ($MenuSelection -eq 1) { $Global:EnhancedSecurity = $true }
        if ($MenuSelection -eq 2) { $Global:InstallApps = $true }
        continue
    }
    elseif ($res.VirtualKeyCode -eq 37) {
        # Left
        if ($MenuSelection -eq 1) { $Global:EnhancedSecurity = $false }
        if ($MenuSelection -eq 2) { $Global:InstallApps = $false }
        continue
    }

    if ($res.VirtualKeyCode -eq 27) {
        # Esc
        Write-LeftAligned "$FGGray Exiting WinAuto...$Reset"
        Start-Sleep -Seconds 1
        break
    }
    elseif ($res.VirtualKeyCode -eq 13 -or $res.Character -eq 'S' -or $res.Character -eq 's') {
        # Enter Handling based on Selection OR explicit S
        # But wait, explicit S/C/M hotkeys might conflict with Enter on current selection logic if they deviate.
        # User prompt says "Press [Enter] or [S] to RUN".
        # If selection is on C, prompt says "Press [Enter] or [C] to RUN".
        
        $Target = $MenuSelection
        # Override if specific char pressed
        if ($res.Character -eq 'S' -or $res.Character -eq 's') { $Target = 0 }
        elseif ($res.Character -eq 'C' -or $res.Character -eq 'c') { $Target = 1 }
        elseif ($res.Character -eq 'M' -or $res.Character -eq 'm') { $Target = 2 }
        
        if ($Target -eq 0) {
            # Smart Run
            & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1" -SmartRun -EnhancedSecurity:$Global:EnhancedSecurity
            & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1" -SmartRun -EnhancedSecurity:$Global:EnhancedSecurity
            if ($Global:InstallApps) { & "$PSScriptRoot\..\Library\RUN_InstallAppsConfigurable-wa.ps1" }
        }
        elseif ($Target -eq 1) {
            & "$PSScriptRoot\..\Library\MODULE_Configuration.ps1" -EnhancedSecurity:$Global:EnhancedSecurity
        }
        elseif ($Target -eq 2) {
            & "$PSScriptRoot\..\Library\MODULE_Maintenance.ps1" -EnhancedSecurity:$Global:EnhancedSecurity
            if ($Global:InstallApps) { & "$PSScriptRoot\..\Library\RUN_InstallAppsConfigurable-wa.ps1" }
        }
        Start-Sleep -Seconds 2
    }
    elseif ($res.Character -eq 'E' -or $res.Character -eq 'e') {
        $Global:EnhancedSecurity = -not $Global:EnhancedSecurity
        continue
    }
    elseif ($res.Character -eq 'I' -or $res.Character -eq 'i') {
        $Global:InstallApps = -not $Global:InstallApps
        continue
    }
    elseif ($res.Character -eq ' ' -or $res.VirtualKeyCode -eq 32) {
        # Space now toggles expansion for the CURRENT selection
        if ($MenuSelection -eq 0) { $ExpandS = -not $ExpandS }
        elseif ($MenuSelection -eq 1) { $ExpandC = -not $ExpandC }
        elseif ($MenuSelection -eq 2) { $ExpandM = -not $ExpandM }
        continue
    }
    elseif ($res.Character -eq 'H' -or $res.Character -eq 'h') {
        Clear-Host
        Write-Header "SYSTEM IMPACT MANIFEST"
        Write-Host ""
        $manifestPath = "$PSScriptRoot\..\..\docs\MANIFEST\MANIFEST.md"
        if (Test-Path $manifestPath) {
            Get-Content $manifestPath | Select-Object -First 40 | ForEach-Object { Write-LeftAligned $_ }
        }
        else {
            Write-LeftAligned "$FGRed$Char_Warn Manifest file not found.$Reset"
        }
        Write-Host ""
        Write-Boundary
        Write-Centered "Press any key to return..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    else {
        # Any other key loop back
        Start-Sleep -Milliseconds 100
        continue
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


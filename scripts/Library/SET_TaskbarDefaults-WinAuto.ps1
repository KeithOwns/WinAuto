#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures Taskbar defaults: Search (Icon+Label), TaskView (Off), Widgets (Off).
.DESCRIPTION
    Standardized for WinAuto. Tweaks HKCU registry for taskbar elements.
.PARAMETER Undo
    Reverses the setting (Sets defaults back to Windows 11 standard).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "TASKBAR CONFIGURATION"

$adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$search = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

# Inner helper for robust setting
function Set-KeySafe {
    param($P, $N, $V)
    try {
        if (-not (Test-Path $P)) { New-Item -Path $P -Force -ErrorAction SilentlyContinue | Out-Null }
        Set-ItemProperty -Path $P -Name $N -Value $V -Type DWord -Force -ErrorAction Stop
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Failed to set $N : $($_.Exception.Message)$Reset"
        Write-Log "Taskbar Config Error ($N): $($_.Exception.Message)" -Level ERROR
    }
}

if ($Undo) {
    Set-KeySafe $search "SearchboxTaskbarMode" 1
    Set-KeySafe $adv "ShowTaskViewButton" 1
    Set-KeySafe $adv "TaskbarDa" 1
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Taskbar defaults reverted.$Reset"
} else {
    # Search: Search icon and label (Value 2)
    Set-KeySafe $search "SearchboxTaskbarMode" 2
    # Taskview: OFF
    Set-KeySafe $adv "ShowTaskViewButton" 0
    # Widgets: OFF
    Set-KeySafe $adv "TaskbarDa" 0
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Taskbar configuration applied.$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""


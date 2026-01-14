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

try {
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $search = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
    
    if ($Undo) {
        Set-RegistryDword -Path $search -Name "SearchboxTaskbarMode" -Value 1 -LogPath $Global:WinAutoLogPath # Icon Only
        Set-RegistryDword -Path $adv -Name "ShowTaskViewButton" -Value 1 -LogPath $Global:WinAutoLogPath
        Set-RegistryDword -Path $adv -Name "TaskbarDa" -Value 1 -LogPath $Global:WinAutoLogPath # Widgets
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Taskbar defaults reverted.$Reset"
    } else {
        # Search: Search icon and label (Value 2 on Win11)
        Set-RegistryDword -Path $search -Name "SearchboxTaskbarMode" -Value 2 -LogPath $Global:WinAutoLogPath
        # Taskview: OFF
        Set-RegistryDword -Path $adv -Name "ShowTaskViewButton" -Value 0 -LogPath $Global:WinAutoLogPath
        # Widgets: OFF
        Set-RegistryDword -Path $adv -Name "TaskbarDa" -Value 0 -LogPath $Global:WinAutoLogPath
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Taskbar defaults configured (Search: Icon+Label, Taskview: Off, Widgets: Off).$Reset"
    }
} catch { 
    Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
    Write-Log "Taskbar Config Error: $($_.Exception.Message)" -Level ERROR
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""


#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Aligns the Windows 11 Taskbar to the Left or Center.
.DESCRIPTION
    Standardized for WinAuto. Tweaks HKCU registry for taskbar alignment.
.PARAMETER Undo
    Reverses the setting (Sets Taskbar to Center).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "TASKBAR ALIGNMENT"

try {
    $target = if ($Undo) { 1 } else { 0 } # 0 = Left, 1 = Center
    $pos = if ($Undo) { "Center" } else { "Left" }

    Write-LeftAligned "$FGYellow Aligning Taskbar to $pos...$Reset"

    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $path -Name "TaskbarAl" -Value $target -Type DWord -Force

    Write-LeftAligned "$FGGreen$Char_HeavyCheck Taskbar Aligned to $pos successful.$Reset"
    
    # Restart explorer to apply
    Write-LeftAligned "$FGDarkCyan Restarting File Explorer to apply UI changes...$Reset"
    Stop-Process -Name explorer -Force

} catch { Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset" }

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Restores the Classic Context Menu or Reverts to Win11 Standard.
.DESCRIPTION
    Standardized for WinAuto. Tweaks CLSID registry for the context menu.
.PARAMETER Undo
    Reverses the setting (Sets to Windows 11 Standard Menu).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "CONTEXT MENU STYLE"

try {
    $key = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    
    if ($Undo) {
        Write-LeftAligned "$FGYellow Reverting to Windows 11 standard context menu...$Reset"
        if (Test-Path (Split-Path $key -Parent)) {
            Remove-Item -Path (Split-Path $key -Parent) -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Reverted to Standard successfully.$Reset"
    } else {
        Write-LeftAligned "$FGYellow Restoring Classic context menu...$Reset"
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        Set-ItemProperty -Path $key -Name "(default)" -Value "" -Force
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Classic Context Menu restored.$Reset"
    }

    # Restart explorer
    Write-LeftAligned "$FGDarkCyan Restarting File Explorer to apply UI changes...$Reset"
    Stop-Process -Name explorer -Force

} catch { Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset" }

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







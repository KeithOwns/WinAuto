#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Optimizes Visual Effects for Performance.
.DESCRIPTION
    Standardized for WinAuto. Tweaks HKCU registry for best performance.
.PARAMETER Undo
    Reverses the setting (Sets to 'Let Windows Choose').
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "VISUAL EFFECTS"

try {
    $target = if ($Undo) { 0 } else { 2 } # 2 = Best Perf, 0 = Windows Choose
    $status = if ($Undo) { "Reset to Default" } else { "Optimized for Performance" }

    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value $target -Type DWord -Force

    # UI Tweaks
    $adv = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    $v = if ($Undo) { 1 } else { 0 }
    Set-ItemProperty -Path $adv -Name "ListviewAlphaSelect" -Value $v -Type DWord -Force
    Set-ItemProperty -Path $adv -Name "ListviewShadow" -Value $v -Type DWord -Force
    Set-ItemProperty -Path $adv -Name "TaskbarAnimations" -Value $v -Type DWord -Force

    Write-LeftAligned "$FGGreen$Char_HeavyCheck Visual effects $status successful.$Reset"
    Write-LeftAligned "$FGGray Note: Requires logout or restart to fully apply.$Reset"

} catch {
    $errMsg = "$($_.Exception.Message)"
    Write-LeftAligned "$FGRed$Char_RedCross Error: $errMsg$Reset"
    Write-Log "Visual Effects Error: $errMsg" -Level ERROR
}

Write-Host ""







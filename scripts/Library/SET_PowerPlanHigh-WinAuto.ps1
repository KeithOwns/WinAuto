#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sets the System Power Plan to High Performance or Balanced.
.DESCRIPTION
    Standardized for WinAuto.
.PARAMETER Undo
    Reverses the setting (Sets Power Plan to Balanced).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "POWER SETTINGS"

try {
    $planName = if ($Undo) { "Balanced" } else { "High Performance" }
    $planGuid = if ($Undo) { "381b4222-f694-41f0-9685-ff5bb260df2e" } else { "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }

    Write-LeftAligned "$FGYellow Setting power plan to $planName...$Reset"
    
    # Ensure plan exists (imports if needed, though standard ones usually do)
    powercfg /setactive $planGuid
    
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Power plan set to $planName successful.$Reset"

} catch {
    $errMsg = "$($_.Exception.Message)"
    Write-LeftAligned "$FGRed$Char_RedCross Error: $errMsg$Reset"
    Write-Log "Power Plan Error: $errMsg" -Level ERROR
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







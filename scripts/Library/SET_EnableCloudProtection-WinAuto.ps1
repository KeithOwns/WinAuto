#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Cloud-delivered Protection.
.DESCRIPTION
    Standardized for WinAuto. Configures Microsoft Active Protection Service (MAPS).
.PARAMETER Undo
    Reverses the setting (Disables Cloud-delivered Protection).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "CLOUD PROTECTION"

# --- MAIN ---

try {
    # MAPSReporting: 0 = Disabled, 2 = Advanced (Recommended)
    $target = if ($Undo) { 0 } else { 2 }
    $status = if ($Undo) { "DISABLED" } else { "ENABLED (Advanced)" }

    Set-MpPreference -MAPSReporting $target -ErrorAction Stop

    # Verify
    $current = (Get-MpPreference).MAPSReporting
    if ($current -eq $target) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck  Cloud-delivered Protection is $status.$Reset"
    } else {
        Write-LeftAligned "$FGDarkYellow$Char_Warn Cloud-delivered Protection verification failed.$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed: $($_.Exception.Message)$Reset"
}


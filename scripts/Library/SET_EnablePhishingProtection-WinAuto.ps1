#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enables or Disables Enhanced Phishing Protection at User Level.
.DESCRIPTION
    Standardized for WinAuto. Removes or Re-applies GPO lock.
.PARAMETER Undo
    Reverses the setting (Re-applies GPO lock to Disable).
#>

[CmdletBinding()]
param(
    [switch]$Undo,
    [switch]$RemoveOnly,
    [switch]$Force
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "PHISHING PROTECTION"

# --- MAIN ---

$statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }

# Note: GPO logic removed for later implementation in custom versions.

if (-not $Undo -and -not $RemoveOnly) {
    Write-LeftAligned "$FGDarkYellow$Char_Warn Phishing Protection requires manual toggle in Windows Security.$Reset"
    try { Start-Process "windowsdefender://threatsettings/" } catch {}
}

# Since we aren't doing anything programmatic anymore, we just exit or show status if needed.
# But per request, we just show the warning if applicable. 
# The previous logic had a success message based on GPO application. 
# I will remove the misleading success message since no action is taken.

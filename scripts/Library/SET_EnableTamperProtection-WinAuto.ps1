#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Attempts to enable Tamper Protection.
.DESCRIPTION
    Standardized for WinAuto. Note: Tamper Protection is often protected from programmatic changes.
    This script attempts to set the registry key but may fail if Defender self-protection is active.
.PARAMETER Undo
    Attempts to disable Tamper Protection (not recommended).
#>

param(
    [switch]$Undo
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "TAMPER PROTECTION"

# --- MAIN ---

try {
    # TamperProtection: 5 = Enabled, 0 = Disabled
    $target = if ($Undo) { 0 } else { 5 }
    $status = if ($Undo) { "DISABLED" } else { "ENABLED" }

    $path = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features"
    if (!(Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }

    Set-ItemProperty -Path $path -Name "TamperProtection" -Value $target -Type DWord -Force

    # Verify
    $current = (Get-ItemProperty -Path $path -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection
    if ($current -eq $target) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck  Tamper Protection is $status.$Reset"
    } else {
        Write-LeftAligned "$FGDarkYellow$Char_Warn Tamper Protection change may require manual action in Windows Security UI.$Reset"
    }

} catch {
    Write-LeftAligned "$FGDarkYellow$Char_Warn Could not modify Tamper Protection: $($_.Exception.Message)$Reset"
    Write-LeftAligned "$FGGray  This setting often requires manual activation in the Windows Security UI.$Reset"
}


#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks the current Microsoft Defender Security Intelligence Version.
.DESCRIPTION
    Standardized for WinAuto.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "DEFENDER DEFINITION VERSION"

try {
    $ver = (Get-MpComputerStatus).AntivirusSignatureVersion
    Write-LeftAligned "$FGWhite Current Security Intelligence Version:$Reset"
    Write-LeftAligned "  $FGCyan$ver$Reset"
} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Failed to retrieve version.$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







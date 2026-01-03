#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks the status of the Microsoft Vulnerable Driver Blocklist.
.DESCRIPTION
    Standardized for WinAuto. Checks HKLM CI Config for blocklist status.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "MS VULNERABLE DRIVER BLOCKLIST"

try {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Config"
    $regValueName = "VulnerableDriverBlocklistEnable"
    
    $val = (Get-ItemProperty -Path $regPath -Name $regValueName -ErrorAction SilentlyContinue).$regValueName
    
    if ($val -eq 1) {
        Write-LeftAligned "$FGGreen$Char_BallotCheck Status: ENABLED$Reset"
    } elseif ($val -eq 0) {
        Write-LeftAligned "$FGRed$Char_RedCross Status: DISABLED$Reset"
    } else {
        # Missing value usually means Enabled by default on newer builds
        Write-LeftAligned "$FGGreen$Char_BallotCheck Status: ENABLED (Default)$Reset"
    }

} catch {
    Write-LeftAligned "$FGRed$Char_Warn Error reading registry: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







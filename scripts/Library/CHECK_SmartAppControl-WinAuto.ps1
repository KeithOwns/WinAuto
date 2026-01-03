#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks the status of Windows 11 Smart App Control.
.DESCRIPTION
    Standardized for WinAuto. Determines if SAC is On, Off, or Eval.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "SMART APP CONTROL"

try {
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"
    $regName = "VerifiedAndReputablePolicyState"
    $status  = "Not Supported"

    if (Test-Path $regPath) {
        $val = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
        $status = switch ($val) {
            0 { "OFF" }
            1 { "ON" }
            2 { "EVALUATION MODE" }
            Default { "OFF" }
        }
    }

    $color = if($status -eq "ON"){$FGGreen} elseif($status -eq "OFF"){$FGRed} else {$FGYellow}
    Write-LeftAligned "$FGWhite Status: $color$status$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







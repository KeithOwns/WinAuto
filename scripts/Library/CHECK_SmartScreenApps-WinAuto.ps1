#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Checks the status of the 'Check apps and files' (SmartScreen) setting.
.DESCRIPTION
  Standardized for WinAuto. Checks HKLM Policy and Explorer settings.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Functions

function Get-AppSmartScreenStatus {
    $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
    $userPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    
    $status = "On"
    $source = "Windows Default"
    $isPolicy = $false

    # 1. Policy
    $pv = (Get-ItemProperty -Path $policyPath -Name "EnableSmartScreen" -ErrorAction SilentlyContinue).EnableSmartScreen
    if ($null -ne $pv) {
        $isPolicy = $true
        $source = "Group Policy"
        $status = if($pv -eq 1){"On"}else{"Off"}
    }

    # 2. User
    if (-not $isPolicy) {
        $uv = (Get-ItemProperty -Path $userPath -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue).SmartScreenEnabled
        if ($uv -eq "Off") { $status = "Off"; $source = "User Setting" }
    }

    return [PSCustomObject]@{ Status = $status; Source = $source }
}

#endregion

# --- MAIN ---

Write-Header "APPS & FILES SMARTSCREEN"

try {
    $res = Get-AppSmartScreenStatus
    $color = if($res.Status -eq "On"){$FGGreen} else {$FGRed}
    Write-LeftAligned "$FGWhite Status : $color$($res.Status)$Reset"
    Write-LeftAligned "$FGWhite Source : $FGGray$($res.Source)$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Detects the state of 'SmartScreen for Microsoft Edge' in Windows 11.
.DESCRIPTION
    Standardized for WinAuto. Checks Machine/User Policy and Personal settings.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Functions

function Get-EdgeSmartScreenStatus {
    $RegPath_MachinePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    $RegPath_UserPolicy    = "HKCU:\SOFTWARE\Policies\Microsoft\Edge"
    $RegPath_UserSetting   = "HKCU:\Software\Microsoft\Edge\SmartScreenEnabled"
    $RegPath_UserSetting2  = "HKCU:\Software\Microsoft\Edge"
    
    $Status = "On"
    $Source = "Windows Default"
    $IsConfigured = $false

    if (Test-Path $RegPath_MachinePolicy) {
        $val = (Get-ItemProperty -Path $RegPath_MachinePolicy -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue).SmartScreenEnabled
        if ($null -ne $val) { $IsConfigured = $true; $Source = "Group Policy (Machine)"; $Status = if($val -eq 1){"On"}else{"Off"} }
    }

    if (-not $IsConfigured -and (Test-Path $RegPath_UserPolicy)) {
        $val = (Get-ItemProperty -Path $RegPath_UserPolicy -Name "SmartScreenEnabled" -ErrorAction SilentlyContinue).SmartScreenEnabled
        if ($null -ne $val) { $IsConfigured = $true; $Source = "Group Policy (User)"; $Status = if($val -eq 1){"On"}else{"Off"} }
    }

    if (-not $IsConfigured -and (Test-Path $RegPath_UserSetting)) {
        $val = (Get-ItemProperty -Path $RegPath_UserSetting -Name "(default)" -ErrorAction SilentlyContinue).'(default)'
        if ($null -ne $val) { $IsConfigured = $true; $Source = "User Setting"; $Status = if($val -eq 1){"On"}else{"Off"} }
    }

    return [PSCustomObject]@{ Status = $Status; Source = $Source }
}

#endregion

# --- MAIN ---

Write-Header "EDGE SMARTSCREEN CHECK"

try {
    $res = Get-EdgeSmartScreenStatus
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







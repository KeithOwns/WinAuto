#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Hardens or Restores Network Protocols (NetBIOS, LLMNR).
.DESCRIPTION
    Standardized for WinAuto. Disables (Harden) or Enables (Undo) legacy protocols.
.PARAMETER Undo
    Reverses the hardening (Enables NetBIOS and LLMNR).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "NETWORK PROTOCOL HARDENING"

try {
    $targetValue = if ($Undo) { 1 } else { 0 } # 0 = Disable LLMNR, 1 = Enable
    $netbiosVal = if ($Undo) { 1 } else { 2 } # 1 = Enable, 2 = Disable
    $action = if ($Undo) { "Restoring" } else { "Hardening" }
    $status = if ($Undo) { "Enabled" } else { "Disabled" }

    Write-LeftAligned "$FGYellow $action network protocols...$Reset"

    # 1. LLMNR
    $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    # Note: EnableMulticast=0 means LLMNR is Disabled.
    # So if $Undo is false, target is 0. If $Undo is true, we remove or set to 1.
    $llmnrVal = if ($Undo) { 1 } else { 0 }
    Set-ItemProperty -Path $path -Name "EnableMulticast" -Value $llmnrVal -Type DWord -Force
    Write-LeftAligned "  $FGGreen$Char_HeavyCheck LLMNR is now $status.$Reset"

    # 2. NetBIOS
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    foreach ($a in $adapters) {
        $a.SetTcpipNetbios($netbiosVal) | Out-Null
    }
    Write-LeftAligned "  $FGGreen$Char_HeavyCheck NetBIOS over TCP/IP is now $status.$Reset"

    Write-Host ""
    Write-Boundary $FGDarkGray
    Write-Centered "RESTART RECOMMENDED"
    Write-Boundary $FGDarkGray

} catch { Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset" }

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







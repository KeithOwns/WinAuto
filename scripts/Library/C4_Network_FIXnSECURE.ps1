#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Network Repair & Security Hardening Module
.DESCRIPTION
    Performs common network fixes (Flush DNS, Reset Winsock) and hardens
    network security by disabling legacy protocols (NetBIOS, LLMNR).
#>

param([switch]$AutoRun, [switch]$Undo)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- FUNCTIONS ---

function Create-RestorePoint {
    Write-Host ""
    Write-LeftAligned "$FGYellow Creating System Restore Point...$Reset"
    try {
        Checkpoint-Computer -Description "WinAuto Network Fix $(Get-Date -Format 'yyyyMMdd_HHmm')" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-LeftAligned "$FGGreen$Char_BallotCheck Restore Point created.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Skip Restore Point: $($_.Exception.Message)$Reset"
    }
}

function Reset-NetworkStack {
    Write-Host ""
    Write-LeftAligned "$FGYellow Resetting Network Stack...$Reset"
    
    Create-RestorePoint
    
    try {
        # Winsock Reset
        $res = netsh winsock reset 2>&1
        Write-LeftAligned "$FGGreen$Char_BallotCheck Winsock reset successful.$Reset"
        
        # IP Reset
        $res = netsh int ip reset 2>&1
        Write-LeftAligned "$FGGreen$Char_BallotCheck TCP/IP stack reset successful.$Reset"
        
        # Flush DNS
        Clear-DnsClientCache
        Write-LeftAligned "$FGGreen$Char_BallotCheck DNS Cache flushed.$Reset"
        
        # Release/Renew (Optional, can disconnect session)
        # ipconfig /release & ipconfig /renew
        # Skipped to prevent remote disconnects.
        
        Write-LeftAligned "$FGYellow Note: A restart is required to apply these changes.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error resetting network: $($_.Exception.Message)$Reset"
    }
}

function Secure-Protocols {
    Write-Host ""
    Write-LeftAligned "$FGYellow Hardening Network Protocols...$Reset"
    
    Create-RestorePoint
    
    try {
        # Disable LLMNR (Local Link Multicast Name Resolution) via Registry
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
        Set-ItemProperty -Path $path -Name "EnableMulticast" -Value 0 -Type DWord
        Write-LeftAligned "$FGGreen$Char_BallotCheck LLMNR Disabled (Registry).$Reset"
        
        # Disable NetBIOS over TCP/IP
        # This iterates through all adapters
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($adapter in $adapters) {
            $adapter.SetTcpipNetbios(2) | Out-Null # 0=Use DHCP, 1=Enable, 2=Disable
        }
        Write-LeftAligned "$FGGreen$Char_BallotCheck NetBIOS over TCP/IP Disabled on active adapters.$Reset"
        
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error hardening network: $($_.Exception.Message)$Reset"
    }
}

function Restore-Protocols {
    Write-Host ""
    Write-LeftAligned "$FGYellow Restoring Network Protocols (Undo Hardening)...$Reset"
    
    try {
        # Re-Enable LLMNR
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "EnableMulticast" -Value 1 -Type DWord
            Write-LeftAligned "$FGGreen$Char_BallotCheck LLMNR Enabled.$Reset"
        }
        
        # Re-Enable NetBIOS (Set to DHCP Default = 0)
        $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($adapter in $adapters) {
            $adapter.SetTcpipNetbios(0) | Out-Null
        }
        Write-LeftAligned "$FGGreen$Char_BallotCheck NetBIOS over TCP/IP Restored to DHCP Default.$Reset"
        
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error restoring protocols: $($_.Exception.Message)$Reset"
    }
}

function Set-SecureDNS {
    Write-Host ""
    Write-LeftAligned "$FGYellow Configuring Secure DNS (Cloudflare)...$Reset"
    
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ("1.1.1.1", "1.0.0.1") -ErrorAction SilentlyContinue
            Write-LeftAligned "  Configured $($adapter.Name)"
        }
        Write-LeftAligned "$FGGreen$Char_BallotCheck DNS set to Cloudflare (1.1.1.1).$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error setting DNS: $($_.Exception.Message)$Reset"
    }
}

function Reset-DNS {
    Write-Host ""
    Write-LeftAligned "$FGYellow Resetting DNS to DHCP...$Reset"
    
    try {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        foreach ($adapter in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            Write-LeftAligned "  Reset $($adapter.Name)"
        }
        Write-LeftAligned "$FGGreen$Char_BallotCheck DNS reset to Auto (DHCP).$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error resetting DNS: $($_.Exception.Message)$Reset"
    }
}

# --- AUTO RUN ---
if ($AutoRun) {
    Write-Header "NETWORK SECURITY HARDENING"
    if ($Undo) {
        Restore-Protocols
        Reset-DNS
    } else {
        Secure-Protocols
        Set-SecureDNS
    }
    exit
}

# --- MAIN MENU ---
$menu = $true
while ($menu) {

    Write-Header "NETWORK TOOLKIT"
    
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}Repair Network Stack ${FGDarkGray}(Reset Winsock/IP/DNS)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Harden Protocols ${FGDarkGray}(Disable NetBIOS/LLMNR)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[3]${Reset} ${FGGray}Set Secure DNS ${FGDarkGray}(Cloudflare)${Reset}"
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[A]${Reset} ${FGYellow}Run Repair & Harden${Reset}"
    
    Write-Boundary
    $prompt = "${FGWhite}$Char_Keyboard  Type${FGYellow} ID ${FGWhite}to Execute${FGWhite}|${FGDarkGray}any other to ${FGWhite}EXIT$Char_Eject${Reset}"
    Write-Centered $prompt
    
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $c = $key.Character.ToString().ToUpper()
    
    switch ($c) {
        '1' { Reset-NetworkStack; Start-Sleep -Seconds 1 }
        '2' { Secure-Protocols; Start-Sleep -Seconds 1 }
        '3' { Set-SecureDNS; Start-Sleep -Seconds 1 }
        'A' { Reset-NetworkStack; Secure-Protocols; Start-Sleep -Seconds 1 }
        Default { $menu = $false }
    }
}






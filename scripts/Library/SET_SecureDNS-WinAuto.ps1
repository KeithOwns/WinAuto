#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures Secure DNS or Restores DHCP DNS.
.DESCRIPTION
    Standardized for WinAuto. Sets DNS to Cloudflare (1.1.1.1) or restores DHCP.
.PARAMETER Undo
    Reverses the setting (Sets DNS to DHCP/Auto).
#>

param([switch]$Undo)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "DNS CONFIGURATION"

try {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    
    if ($Undo) {
        Write-LeftAligned "$FGYellow Restoring DHCP DNS for all active adapters...$Reset"
        foreach ($a in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
            Write-LeftAligned "  $FGGreen$Char_HeavyCheck Reset: $($a.Name)$Reset"
        }
    } else {
        $dns = ("1.1.1.1", "1.0.0.1")
        Write-LeftAligned "$FGYellow Setting Secure DNS (Cloudflare) for all active adapters...$Reset"
        foreach ($a in $adapters) {
            Set-DnsClientServerAddress -InterfaceIndex $a.InterfaceIndex -ServerAddresses $dns -ErrorAction SilentlyContinue
            Write-LeftAligned "  $FGGreen$Char_HeavyCheck Set: $($a.Name)$Reset"
        }
    }

} catch { Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset" }

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







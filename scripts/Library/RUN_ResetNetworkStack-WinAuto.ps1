#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Resets the Network Stack (Winsock, TCP/IP, DNS).
.DESCRIPTION
    Standardized for WinAuto.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "NETWORK STACK RESET"

try {
    Write-LeftAligned "$FGYellow Initializing network stack reset...$Reset"
    
    Write-LeftAligned "  $FGWhite$Char_HeavyMinus Resetting Winsock...$Reset"
    netsh winsock reset | Out-Null
    
    Write-LeftAligned "  $FGWhite$Char_HeavyMinus Resetting TCP/IP...$Reset"
    netsh int ip reset | Out-Null
    
    Write-LeftAligned "  $FGWhite$Char_HeavyMinus Flushing DNS Cache...$Reset"
    Clear-DnsClientCache | Out-Null
    
    Write-Host ""
    Write-LeftAligned "$FGGreen$Char_HeavyCheck Network stack reset successful.$Reset"
    
    Write-Host ""
    Write-Boundary $FGDarkGray
    Write-Centered "RESTART REQUIRED"
    Write-Boundary $FGDarkGray

} catch { Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset" }

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







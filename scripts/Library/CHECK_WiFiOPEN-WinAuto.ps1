#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks if active Wi-Fi is unsecured (open).
.DESCRIPTION
    Standardized for WinAuto. Uses netsh to check Authentication method.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "WI-FI SECURITY CHECK"

try {
    $NetshOutput = netsh wlan show interfaces | Select-String -Pattern "Authentication"
    
    if ($NetshOutput) {
        $AuthMethod = ($NetshOutput -split ':' | Select-Object -Last 1).Trim()

        if ($AuthMethod -match "Open|None|Unsecured" -and $AuthMethod -notmatch "WPA2-Open") {
            Write-Boundary $FGRed
            Write-LeftAligned "$FGRed$Char_RedCross WARNING: UNSECURED NETWORK DETECTED!$Reset"
            Write-LeftAligned "  Authentication: $AuthMethod"
            Write-Boundary $FGRed
        } else {
            Write-LeftAligned "$FGGreen$Char_BallotCheck Network is SECURED.$Reset"
            Write-LeftAligned "  Authentication: $FGGray$AuthMethod$Reset"
        }
    } else {
        Write-LeftAligned "$FGMagenta$Char_Warn No active Wi-Fi connection found.$Reset"
    }
} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Blue Screen (BSOD) Analyzer
.DESCRIPTION
    Scans Windows Event Logs for recent critical BugCheck events to help diagnose
    system instability.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "BSOD CRASH HISTORY"

$cutoff = (Get-Date).AddDays(-30)
Write-LeftAligned "Scanning System log (Last 30 Days)..."

try {
    # Event ID 1001 in System log usually corresponds to BugCheck (Saved Dump)
    $crashes = Get-EventLog -LogName System -Source "Microsoft-Windows-WER-SystemErrorReporting" -After $cutoff -ErrorAction SilentlyContinue | Where-Object { $_.EventID -eq 1001 }
    
    if (-not $crashes) {
        # Fallback to BugCheck source
        $crashes = Get-EventLog -LogName System -Source "BugCheck" -After $cutoff -ErrorAction SilentlyContinue
    }

    Write-Host ""
    
    if (@($crashes).Count -eq 0) {
        Write-LeftAligned "$FGGreen$Char_BallotCheck No BSOD events found in the last 30 days.$Reset"
        Write-LeftAligned "System appears stable."
    } else {
        Write-LeftAligned "$FGRed$Char_Warn Found $(@($crashes).Count) critical crash events!$Reset"
        Write-Host ""
        
        foreach ($crash in $crashes) {
            $date = $crash.TimeGenerated.ToString("yyyy-MM-dd HH:mm")
            # Extract bugcheck code if possible from message
            $msg = $crash.Message -replace "`n|`r", " "
            
            Write-LeftAligned "$FGRed$date$Reset"
            Write-LeftAligned "$FGGray$msg$Reset"
            Write-Host ""
        }
        
        Write-Boundary
        Write-LeftAligned "Recommendation: Run Memory Diagnostic and Check_Drivers."
    }

} catch {
    Write-Host "  $FGRed$Char_Warn Error reading Event Log: $($_.Exception.Message)$Reset"
}

Write-Host ""
$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""






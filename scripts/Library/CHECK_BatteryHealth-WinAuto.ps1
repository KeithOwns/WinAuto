#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Battery Health Report Generator
.DESCRIPTION
    Generates a Windows Battery Report (HTML) and opens it automatically.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "BATTERY HEALTH CHECK"

$ReportPath = Join-Path ($env:WinAutoLogDir) "Battery_Report.html"

try {
    Write-LeftAligned "Generating report..."
    
    # Powercfg output is chatty, silence it or capture it
    $null = powercfg /batteryreport /output "$ReportPath"
    
    if (Test-Path $ReportPath) {
        Write-LeftAligned "$FGGreen$Char_BallotCheck Report generated successfully!$Reset"
        Write-LeftAligned "Path: $ReportPath"
        Write-Host ""
        Write-LeftAligned "Opening in browser..."
        Start-Process "$ReportPath"
    } else {
        Write-LeftAligned "$FGRed$Char_Warn Report generation failed.$Reset"
    }
} catch {
    Write-LeftAligned "$FGRed$Char_Warn Error: $($_.Exception.Message)$Reset"
}

Write-Host ""
Invoke-AnimatedPause -Timeout 10
Write-Host ""

# --- FOOTER ---
Write-Centered "$Char_Copyright 2026, www.AIIT.support. All Rights Reserved." $FGCyan
Write-Host ""








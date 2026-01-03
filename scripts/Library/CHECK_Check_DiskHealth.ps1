#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disk Health Analyzer (S.M.A.R.T.)
.DESCRIPTION
    Checks physical disks for health status, temperature, and wear.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "DISK HEALTH CHECK"

try {
    $disks = Get-PhysicalDisk | Sort-Object DeviceId
    
    foreach ($disk in $disks) {
        Write-Host ""
        $model = $disk.FriendlyName
        $type = $disk.MediaType
        $bus = $disk.BusType
        
        # Header for Disk
        Write-BodyTitle "Disk $($disk.DeviceId): $model ($type - $bus)"
        
        # Health
        $hColor = if ($disk.HealthStatus -eq 'Healthy') { $FGGreen } else { $FGRed }
        Write-LeftAligned "  Status: $hColor$($disk.HealthStatus)$Reset"
        
        # S.M.A.R.T. / Reliability
        try {
            $stats = Get-StorageReliabilityCounter -PhysicalDisk $disk -ErrorAction SilentlyContinue
            if ($stats) {
                # Temperature
                if ($stats.Temperature -gt 0) {
                    $tempC = $stats.Temperature
                    $tColor = if ($tempC -gt 60) { $FGRed } elseif ($tempC -gt 50) { $FGYellow } else { $FGGreen }
                    Write-LeftAligned "  Temperature: $tColor${tempC}Â°C$Reset"
                }
                
                # Read Errors
                if ($stats.ReadErrorsTotal -gt 0) {
                    Write-LeftAligned "  Read Errors: $FGRed$($stats.ReadErrorsTotal)$Reset"
                } else {
                    Write-LeftAligned "  Read Errors: ${FGGreen}0$Reset"
                }
                
                # Wear (SSD)
                if ($stats.Wear -ne $null) {
                    $wear = $stats.Wear
                    $wColor = if ($wear -gt 90) { $FGRed } elseif ($wear -gt 80) { $FGYellow } else { $FGGreen }
                    Write-LeftAligned "  Wear Level: $wColor$wear% Used$Reset"
                }
            } else {
                Write-LeftAligned "  $FGGray(No detailed S.M.A.R.T. data available)$Reset"
            }
        } catch {
            Write-LeftAligned "  $FGGray(Could not retrieve reliability counters)$Reset"
        }
    }

} catch {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_Warn Error checking disks: $($_.Exception.Message)$Reset"
}

Write-Host ""
$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""






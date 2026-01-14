#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System Pre-Flight Check for WinAuto
.DESCRIPTION
    Quickly assesses system readiness for updates and maintenance.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

function Write-Line { 
    param($Label, $Value, $Color=$FGWhite) 
    Write-Host "  $Label " -NoNewline
    Write-Host "$Color$Value$Reset"
}

# --- CHECKS ---

Write-Header "SYSTEM PRE-FLIGHT CHECK"

# 1. OS Info
$os = Get-CimInstance Win32_OperatingSystem
Write-LeftAligned "$FGWhite Operating System$Reset"
Write-Line "OS Name:" $os.Caption
Write-Line "Version:" "$($os.Version) (Build $($os.BuildNumber))"

# 2. Uptime
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeStr = "{0} days, {1} hours, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

$uptimeColor = $FGGreen
if ($uptime.Days -gt 7) { $uptimeColor = $FGRed }
elseif ($uptime.Days -gt 3) { $uptimeColor = $FGYellow }

Write-LeftAligned "$FGWhite System Uptime$Reset"
Write-Line "Uptime:" $uptimeStr $uptimeColor

if ($uptime.Days -gt 7) { 
    Write-Host "  $FGRed$Char_Warn Warning: System hasn't rebooted in over a week.$Reset" 
}

# 3. Disk Space (C:)
$drive = Get-Volume -DriveLetter C
$freeGB = [math]::Round($drive.SizeRemaining / 1GB, 2)
$totalGB = [math]::Round($drive.Size / 1GB, 2)
$pctFree = [math]::Round(($drive.SizeRemaining / $drive.Size) * 100, 1)

$diskColor = $FGGreen
if ($freeGB -lt 10) { $diskColor = $FGRed }
elseif ($freeGB -lt 20) { $diskColor = $FGYellow }

Write-LeftAligned "$FGWhite Disk Space (C:)$Reset"
Write-Line "Free Space:" "$freeGB GB ($pctFree%) of $totalGB GB" $diskColor

if ($freeGB -lt 10) { 
    Write-Host "  $FGRed$Char_Warn Critical: Low disk space.$Reset" 
}

# 4. System Health (Event Log)
Write-LeftAligned "$FGWhite System Health (Last 24h)$Reset"
try {
    $filter = @{
        LogName = 'System'
        StartTime = (Get-Date).AddHours(-24)
        Level = 1, 2, 3 # 1=Crit, 2=Error, 3=Warn
    }
    
    $events = Get-WinEvent -FilterHashtable $filter -ErrorAction Stop
    
    $critCount = ($events | Where-Object { $_.Level -le 2 }).Count
    $warnCount = ($events | Where-Object { $_.Level -eq 3 }).Count
    
    $cColor = if ($critCount -gt 0) { $FGRed } else { $FGGreen }
    $wColor = if ($warnCount -gt 0) { $FGYellow } else { $FGGreen }
    
    Write-Line "System Errors:" "$critCount" $cColor
    Write-Line "Warnings:" "$warnCount" $wColor

} catch {
    if ($_.Exception.Message -match "No events were found") {
        Write-Line "System Errors:" "0" $FGGreen
        Write-Line "Warnings:" "0" $FGGreen
    } else {
        Write-Host "  $FGRed$Char_Warn Error reading Event Log: $($_.Exception.Message)$Reset"
    }
}

# 5. Pending Reboot
$rebootPending = $false
# Check Component Based Servicing
$RegPath1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
if (Test-Path $RegPath1) { $rebootPending = $true }

# Check Windows Update
$RegPath2 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
if (Test-Path $RegPath2) { $rebootPending = $true }

# Check File Rename Ops
try {
    $pendingFileRename = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
    if ($pendingFileRename) { $rebootPending = $true }
} catch {}

Write-LeftAligned "$FGWhite Status$Reset"
if ($rebootPending) {
    Write-Host "  $FGRed$Char_Warn REBOOT PENDING$Reset"
    Write-Host "  It is highly recommended to restart before running maintenance." -ForegroundColor DarkGray
} else {
    Write-Host "  $FGGreen$Char_BallotCheck System Ready$Reset"
}

Write-Host ""
Write-Boundary
Invoke-AnimatedPause -Timeout 10
Write-Host ""






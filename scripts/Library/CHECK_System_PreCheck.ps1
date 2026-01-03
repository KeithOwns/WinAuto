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
    param($Label, $Value, $Color="White") 
    Write-Host "  $Label " -NoNewline
    Write-Host $Value -ForegroundColor $Color 
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

$uptimeColor = "Green"
if ($uptime.Days -gt 7) { $uptimeColor = "Red" }
elseif ($uptime.Days -gt 3) { $uptimeColor = "Yellow" }

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

$diskColor = "Green"
if ($freeGB -lt 10) { $diskColor = "Red" }
elseif ($freeGB -lt 20) { $diskColor = "Yellow" }

Write-LeftAligned "$FGWhite Disk Space (C:)$Reset"
Write-Line "Free Space:" "$freeGB GB ($pctFree%) of $totalGB GB" $diskColor

if ($freeGB -lt 10) { 
    Write-Host "  $FGRed$Char_Warn Critical: Low disk space.$Reset" 
}

# 4. System Health (Event Log)
Write-LeftAligned "$FGWhite System Health (Last 24h)$Reset"
$cutoff = (Get-Date).AddHours(-24)
try {
    $errors = Get-EventLog -LogName System -EntryType Error,Warning -After $cutoff -ErrorAction SilentlyContinue
    $critCount = ($errors | Where-Object { $_.EntryType -eq 'Error' }).Count
    $warnCount = ($errors | Where-Object { $_.EntryType -eq 'Warning' }).Count
    
    $cColor = "Green"
    if ($critCount -gt 0) { $cColor = "Red" }
    
    $wColor = "Green"
    if ($warnCount -gt 0) { $wColor = "Yellow" }
    
    Write-Line "System Errors:" "$critCount" $cColor
    Write-Line "Warnings:" "$warnCount" $wColor
} catch {
    Write-Host "  $FGRed$Char_Warn Unable to read Event Log.$Reset"
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






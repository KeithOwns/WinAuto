#Requires -RunAsAdministrator
<#
.SYNOPSIS
    WinAuto Suite Cleanup Utility
.DESCRIPTION
    Removes artifacts created by the suite: Scheduled Tasks, Remote folders, Logs.
    Optionally deletes the suite itself (Self-Destruct) for client cleanup.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "SUITE CLEANUP"

# 1. Scheduled Task
Write-Host ""
Write-LeftAligned "Checking for Scheduled Tasks..."
$TaskName = "WinAuto Maintenance"
try {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-LeftAligned "$FGGreen$Char_BallotCheck Removed task: $TaskName$Reset"
    } else {
        Write-LeftAligned "$FGGray  No task found.$Reset"
    }
} catch {
    Write-LeftAligned "$FGRed$Char_Warn Error checking tasks: $($_.Exception.Message)$Reset"
}

# 2. Remote Artifacts
Write-Host ""
Write-LeftAligned "Checking for Remote Deployments..."
if (Test-Path "C:\WinAuto_Remote") {
    Remove-Item "C:\WinAuto_Remote" -Recurse -Force
    Write-LeftAligned "$FGGreen$Char_BallotCheck Removed C:\WinAuto_Remote$Reset"
} else {
    Write-LeftAligned "$FGGray  No remote folder found.$Reset"
}

# 3. Temp Logs
Write-Host ""
Write-LeftAligned "Cleaning Temp Logs..."
$logPath = "$env:WinAutoLogDir\Maint_*.log"
$logs = @(Get-ChildItem $logPath -ErrorAction SilentlyContinue)
if ($logs.Count -gt 0) {
    $logs | Remove-Item -Force
    Write-LeftAligned "$FGGreen$Char_BallotCheck Removed $($logs.Count) log files.$Reset"
} else {
    Write-LeftAligned "$FGGray  No logs found.$Reset"
}

# 4. Self Destruct
Write-Host ""
Write-Boundary $FGDarkBlue
Write-Centered "$FGRed$Char_Trash SELF DESTRUCT $Reset"
Write-LeftAligned "Do you want to delete this entire script folder?"
Write-LeftAligned "Warning: This action cannot be undone."
Write-Host ""

$prompt = "${FGWhite}$Char_Keyboard  Type${FGYellow} DELETE ${FGWhite}to Confirm${FGWhite}|${FGDarkGray}any other to ${FGWhite}KEEP$Reset"
Write-Centered $prompt

$val = Read-Host "  $Char_Finger Input"

if ($val -eq "DELETE") {
    Write-Host ""
    Write-LeftAligned "$FGYellow Scheduling deletion...$Reset"
    
    # We can't delete the folder while running inside it easily.
    # Trick: Create a self-deleting batch file in Temp.
    
    $BatchPath = Join-Path $env:TEMP "WinAuto_SelfDestruct.bat"
    $TargetDir = (Get-Item $PSScriptRoot).Parent.FullName # scripts folder
    $ParentDir = (Get-Item $TargetDir).Parent.FullName # WinAuto folder
    
    # Check if we are running from the standard repo structure
    # If so, delete the 'WinAuto' root. If strictly standalone, delete 'scripts'.
    # Safe bet: Delete the parent of 'Main' which is 'scripts'.
    
    $DelPath = $TargetDir
    if ((Split-Path $TargetDir -Leaf) -eq "scripts") {
         # If we are in 'WinAuto\scripts', try to delete 'WinAuto'
         $DelPath = $ParentDir
    }
    
    $batchContent = @"
@echo off
timeout /t 3 /nobreak > NUL
rmdir /s /q "$DelPath"
del "%~f0"
"@
    Set-Content -Path $BatchPath -Value $batchContent
    
    Start-Process -FilePath $BatchPath -WindowStyle Hidden
    Write-LeftAligned "$FGGreen$Char_BallotCheck Deletion scheduled in 3 seconds. Exiting.$Reset"
    Start-Sleep -Seconds 1
    exit
} else {
    Write-Host ""
    Write-LeftAligned "$FGGreen$Char_BallotCheck Files kept.$Reset"
    
    Invoke-AnimatedPause -Timeout 10
}
Write-Host ""









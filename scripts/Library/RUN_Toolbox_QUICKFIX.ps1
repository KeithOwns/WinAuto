#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Quick Fix Toolbox
.DESCRIPTION
    Targeted repairs for common Windows annoyances (Printer, Audio, Search, Icons).
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- FIXES ---

function Reset-PrintSpooler {
    Write-Host ""
    Write-LeftAligned "$FGYellow Resetting Print Spooler...$Reset"
    try {
        Stop-Service -Name Spooler -Force
        $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*.*"
        Remove-Item $spoolPath -Force -ErrorAction SilentlyContinue
        Start-Service -Name Spooler
        Write-LeftAligned "$FGGreen$Char_BallotCheck Printer queue cleared and service restarted.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Error: $($_.Exception.Message)$Reset"
    }
}

function Reset-Audio {
    Write-Host ""
    Write-LeftAligned "$FGYellow Restarting Audio Services...$Reset"
    try {
        Stop-Service -Name "Audiosrv" -Force -ErrorAction SilentlyContinue
        Stop-Service -Name "AudioEndpointBuilder" -Force -ErrorAction SilentlyContinue
        Start-Service -Name "AudioEndpointBuilder"
        Start-Service -Name "Audiosrv"
        Write-LeftAligned "$FGGreen$Char_BallotCheck Audio services restarted.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Error: $($_.Exception.Message)$Reset"
    }
}

function Clear-IconCache {
    Write-Host ""
    Write-LeftAligned "$FGYellow Clearing Icon Cache (Explorer will restart)...$Reset"
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        $iconDb = "$env:LOCALAPPDATA\IconCache.db"
        if (Test-Path $iconDb) { Remove-Item $iconDb -Force }
        Start-Process explorer.exe
        Write-LeftAligned "$FGGreen$Char_BallotCheck Icon cache cleared.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Error: $($_.Exception.Message)$Reset"
        Start-Process explorer.exe
    }
}

function Rebuild-SearchIndex {
    Write-Host ""
    Write-LeftAligned "$FGYellow Rebuilding Search Index (Background task)...$Reset"
    try {
        Stop-Service -Name "WSearch" -Force
        # Trigger rebuild via registry logic usually, or just restart service for simple refresh
        # Full rebuild requires deleting .edb
        $searchPath = "$env:ProgramData\Microsoft\Search\Data\Applications\Windows\Windows.edb"
        if (Test-Path $searchPath) { Remove-Item $searchPath -Force -ErrorAction SilentlyContinue }
        Start-Service -Name "WSearch"
        Write-LeftAligned "$FGGreen$Char_BallotCheck Search Index reset initiated.$Reset"
    } catch {
        Write-LeftAligned "$FGRed$Char_Warn Error: $($_.Exception.Message)$Reset"
    }
}

function Trigger-Activation {
    Write-Host ""
    Write-LeftAligned "$FGYellow Attempting Windows Activation...$Reset"
    # Run slmgr /ato
    Start-Process cscript.exe -ArgumentList "//B $env:SystemRoot\System32\slmgr.vbs /ato" -Wait -NoNewWindow
    Write-LeftAligned "$FGGreen$Char_BallotCheck Activation command sent.$Reset"
}

# --- MENU ---
$menu = $true
while ($menu) {

    Write-Header "QUICK FIX TOOLBOX"
    
    Write-Host ""
    Write-LeftAligned " ${FGBlack}${BGYellow}[1]${Reset} ${FGGray}Reset Print Spooler ${FGDarkGray}(Fix Stuck Jobs)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[2]${Reset} ${FGGray}Reset Audio Services ${FGDarkGray}(Fix No Sound)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[3]${Reset} ${FGGray}Clear Icon Cache ${FGDarkGray}(Fix Broken Icons)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[4]${Reset} ${FGGray}Rebuild Search Index ${FGDarkGray}(Fix Start Menu)${Reset}"
    Write-LeftAligned " ${FGBlack}${BGYellow}[5]${Reset} ${FGGray}Trigger Activation ${FGDarkGray}(Force Check)${Reset}"
    
    Write-Boundary
    $PromptCursorTop = [Console]::CursorTop
    $TickAction = {
        param($ElapsedTimespan)
        $WiggleFrame = [Math]::Floor($ElapsedTimespan.TotalMilliseconds / 500); $IsRight = ($WiggleFrame % 2) -eq 1
        $CurrentChars = if ($IsRight) { @(" ", $Char_Finger, "[", "E", "n", "t", "e", "r", "]", " ") } else { @($Char_Finger, " ", "[", "E", "n", "t", "e", "r", "]", " ") }
        $FilledCount = [Math]::Floor($ElapsedTimespan.TotalSeconds); if ($FilledCount -gt 10) { $FilledCount = 10 }
        $DynamicPart = ""
        for ($i = 0; $i -lt 10; $i++) {
            $Char = $CurrentChars[$i]
            if ($i -lt $FilledCount) { $DynamicPart += "${BGYellow}${FGBlack}$Char${Reset}" } else { $DynamicPart += if ($Char -eq " ") { " " } else { "${FGYellow}$Char${Reset}" } }
        }
        $p = "${FGWhite}$Char_Keyboard  Press ${FGDarkGray}$DynamicPart${FGDarkGray}${FGWhite}to${FGDarkGray} ${FGYellow}EXIT${FGDarkGray} ${FGWhite}|${FGDarkGray} or Type Selection$Char_Skip${Reset}"
        try { [Console]::SetCursorPosition(0, $PromptCursorTop); Write-Centered $p } catch {}
    }
    
    $key = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
    Write-Host ""
    if ($key.VirtualKeyCode -eq 13) { $c = "EXIT" } else { $c = $key.Character.ToString().ToUpper() }
    
    switch ($c) {
        '1' { Reset-PrintSpooler; Start-Sleep -Seconds 1 }
        '2' { Reset-Audio; Start-Sleep -Seconds 1 }
        '3' { Clear-IconCache; Start-Sleep -Seconds 1 }
        '4' { Rebuild-SearchIndex; Start-Sleep -Seconds 1 }
        '5' { Trigger-Activation; Start-Sleep -Seconds 1 }
        Default { $menu = $false }
    }
}






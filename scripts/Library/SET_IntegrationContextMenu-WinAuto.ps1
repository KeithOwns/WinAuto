#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Context Menu Integrator
.DESCRIPTION
    Adds "WinAuto Suite" to the Desktop Right-Click Context Menu for quick access.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- STYLE ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Char_HeavyLine = [char]0x2501; $Char_BallotCheck = [char]0x2611; $Char_Warn = [char]0x26A0
$Esc = [char]0x1B; $Reset = "$Esc[0m"; $Bold = "$Esc[1m"
$FGCyan = "$Esc[96m"; $FGGreen = "$Esc[92m"; $FGWhite = "$Esc[97m"; $FGRed = "$Esc[91m"
$FGDarkBlue = "$Esc[34m"
# Added for Timeout Functionality
$FGBlack = "$Esc[30m"; $FGDarkGray = "$Esc[90m"; $BGYellow = "$Esc[103m"; $FGGray = "$Esc[37m"
$Char_Finger = [char]0x261B; $Char_Keyboard = [char]0x2328; $Char_Skip = [char]0x23ED

function Write-Centered { param($Text, $Width = 60) $clean = $Text -replace "$Esc\[[0-9;]*m", ""; $pad = [Math]::Floor(($Width - $clean.Length) / 2); if ($pad -lt 0) { $pad = 0 }; Write-Host (" " * $pad + $Text) }
function Write-Header { param($Title) Write-Host ""; Write-Centered "$Bold$FGCyan $Char_HeavyLine WinAuto $Char_HeavyLine $Reset"; Write-Centered "$Bold$FGCyan$Title$Reset"; Write-Host "$FGDarkBlue$([string]$Char_HeavyLine * 60)$Reset" }

function Wait-KeyPressWithTimeout {
    param(
        [int]$Seconds,
        [scriptblock]$OnTick
    )
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($StopWatch.Elapsed.TotalSeconds -lt $Seconds) {
        if ($OnTick) { & $OnTick $StopWatch.Elapsed }
        if ([Console]::KeyAvailable) {
            $StopWatch.Stop()
            return $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        Start-Sleep -Milliseconds 100
    }
    $StopWatch.Stop()
    return [PSCustomObject]@{ VirtualKeyCode = 13 }
}

# --- MAIN ---

Write-Header "CONTEXT MENU INTEGRATION"

    # Path to the WinAuto master script
    $ScriptPath = "$PSScriptRoot\..\Main\WinAuto.ps1"
$AutoPath = "$PSScriptRoot\C6_WinAuto_Master_AUTO.ps1"
$IcoPath = "shell32.dll,238"

Write-Host "  Adding to Desktop Context Menu..." -ForegroundColor Yellow

try {
    # Ensure HKCR drive is mapped
    if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
    }

    # 1. Main Menu Item
    $regPath = "HKCR:\DesktopBackground\Shell\WinAuto"
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    
    Set-ItemProperty -Path $regPath -Name "(default)" -Value "WinAuto Suite"
    Set-ItemProperty -Path $regPath -Name "Icon" -Value $IconPath
    Set-ItemProperty -Path $regPath -Name "Position" -Value "Bottom"
    
    # SubMenu structure in modern Windows 11 context menu is complex (sparse package).
    # Classic method adds to 'Show more options'.
    # For simplified access, we'll just add "Run WinAuto" as a command.
    
    $commandPath = "$regPath\command"
    if (-not (Test-Path $commandPath)) { New-Item -Path $commandPath -Force | Out-Null }
    
    # Command executes PowerShell invisibly to launch the batch/script
    # Ideally point to the BAT launcher if it exists, or powershell direct.
    # Using 'Main' folder path relative might break if moved.
    # We will embed the absolute path.
    
    $runCmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    
    # Admin fix: We can't force RunAs in shell key easily without UAC prompt loop.
    # Trick: Use 'powershell Start-Process -Verb RunAs'
    $finalCmd = "powershell.exe -WindowStyle Hidden -Command `"Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""$ScriptPath""' -Verb RunAs`""
    
    Set-ItemProperty -Path $commandPath -Name "(default)" -Value $finalCmd
    
    Write-Host "  $FGGreen$Char_BallotCheck Added 'WinAuto Suite' to Context Menu.$Reset"
    Write-Host "  (Right-click Desktop > Show more options)" -ForegroundColor Gray

} catch {
    Write-Host "  $FGRed$Char_Warn Failed to add registry keys: $($_.Exception.Message)$Reset"
}

Write-Host ""
# Animated Timeout
$PromptCursorTop = [Console]::CursorTop
$TickAction = {
    param($ElapsedTimespan)
    $WiggleFrame = [Math]::Floor($ElapsedTimespan.TotalMilliseconds / 500)
    $IsRight = ($WiggleFrame % 2) -eq 1
    if ($IsRight) { $CurrentChars = @(" ", $Char_Finger, "[", "E", "n", "t", "e", "r", "]", " ") } 
    else { $CurrentChars = @($Char_Finger, " ", "[", "E", "n", "t", "e", "r", "]", " ") }
    $FilledCount = [Math]::Floor($ElapsedTimespan.TotalSeconds)
    if ($FilledCount -gt 10) { $FilledCount = 10 }
    $DynamicPart = ""
    for ($i = 0; $i -lt 10; $i++) {
        $Char = $CurrentChars[$i]
        if ($i -lt $FilledCount) { $DynamicPart += "${BGYellow}${FGBlack}$Char${Reset}" } 
        else { if ($Char -eq " ") { $DynamicPart += " " } else { $DynamicPart += "${FGYellow}$Char${Reset}" } }
    }
    $PromptStr = "${FGWhite}$Char_Keyboard  Press ${FGDarkGray}$DynamicPart${FGDarkGray}${FGWhite}to${FGDarkGray} ${FGYellow}EXIT${FGDarkGray} ${FGWhite}|${FGDarkGray} or any other key ${FGWhite}to SKIP$Char_Skip${Reset}"
    try { [Console]::SetCursorPosition(0, $PromptCursorTop); Write-Centered $PromptStr } catch {}
}

$null = Start-Sleep -Seconds 1
Write-Host ""




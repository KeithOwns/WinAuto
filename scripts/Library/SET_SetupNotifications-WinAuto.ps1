#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Notification Setup for Automation
.DESCRIPTION
    Configures Webhook or Email notifications for the Automated Suite results.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- STYLE ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Char_HeavyLine = [char]0x2501; $Char_BallotCheck = [char]0x2611; $Char_Warn = [char]0x26A0
$Esc = [char]0x1B; $Reset = "$Esc[0m"; $Bold = "$Esc[1m"
$FGCyan = "$Esc[96m"; $FGGreen = "$Esc[92m"; $FGYellow = "$Esc[93m"; $FGRed = "$Esc[91m"; $FGWhite = "$Esc[97m"
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

Write-Header "NOTIFICATION SETUP"

$ConfigPath = "$PSScriptRoot\Notification_Config.json"

Write-Host "  Select Notification Type:"
Write-Host "  [1] Webhook (Discord/Slack/Teams)"
Write-Host "  [2] Disable Notifications"
Write-Host ""
$choice = Read-Host "  Selection"

$config = @{ Enabled = $false; Type = "None"; Url = "" }

if ($choice -eq '1') {
    $url = Read-Host "  Enter Webhook URL"
    if (-not [string]::IsNullOrWhiteSpace($url)) {
        $config.Enabled = $true
        $config.Type = "Webhook"
        $config.Url = $url
        Write-Host "  $FGGreen$Char_BallotCheck Webhook configured.$Reset"
    }
} elseif ($choice -eq '2') {
    Write-Host "  $FGRed Notifications disabled.$Reset"
}

$json = $config | ConvertTo-Json
Set-Content -Path $ConfigPath -Value $json -Encoding UTF8

Write-Host ""
Write-Host "  Configuration saved to: $ConfigPath"
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

$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""




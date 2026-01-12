#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System Restore Manager for WinAuto
.DESCRIPTION
    Lists available system restore points and allows the user to restore the computer
    to a previous state.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "SYSTEM RESTORE MANAGER"

try {
    $points = Get-ComputerRestorePoint -ErrorAction Stop
} catch {
    Write-Host ""
    Write-LeftAligned "$FGRed$Char_Warn Failed to retrieve restore points."
    Write-LeftAligned "System Protection might be disabled."
    
    $null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
    exit
}

if (@($points).Count -eq 0) {
    Write-Host ""
    Write-LeftAligned "$FGYellow No restore points found."
    
    $null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
    exit
}

# Display Points
Write-Host ""
$points | Sort-Object SequenceNumber -Descending | ForEach-Object {
    $date = $_.CreationTime.ToString('yyyy-MM-dd HH:mm')
    $id = "$FGYellow[$($_.SequenceNumber)]$Reset"
    Write-LeftAligned "$id $FGWhite$date$Reset - $FGGray$($_.Description)$Reset"
}

Write-Host ""
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
    $p = "${FGWhite}$Char_Keyboard  Type${FGYellow} ID ${FGWhite}to Restore${FGWhite}|${FGDarkGray}or Press ${FGDarkGray}$DynamicPart${FGDarkGray}${FGWhite}to ${FGWhite}EXIT$Char_Eject${Reset}"
    try { [Console]::SetCursorPosition(0, $PromptCursorTop); Write-Centered $p } catch {}
}

$key = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""
if ($key.VirtualKeyCode -eq 13) { $val = "EXIT" } else { $val = $key.Character.ToString() }

if ($val -match '^\d+$') {
    $id = [int]$val
    $selected = $points | Where-Object { $_.SequenceNumber -eq $id }
    
    if ($selected) {
        Write-Host ""
        Write-LeftAligned "$FGRed$Char_Warn WARNING: System Restore will restart your computer immediately.$Reset"
        $confirm = Read-Host "  Are you sure you want to restore to '$($selected.Description)'? (Y/N)"
        
        if ($confirm -match '^[Yy]') {
            Write-Host ""
            Write-LeftAligned "$FGYellow Initiating System Restore...$Reset"
            try {
                Restore-Computer -RestorePoint $id -Confirm:$false
            } catch {
                Write-LeftAligned "$FGRed Failed to start restore: $($_.Exception.Message)$Reset"
                $null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
            }
        }
    } else {
        Write-LeftAligned "ID not found."
        Start-Sleep -Seconds 1
    }
}
Write-Host ""







#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Snaps the current window to the right half of the screen.
.DESCRIPTION
    Standardized for WinAuto. Simulates Win+Right.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- NATIVE ---
$code = @"
using System;
using System.Runtime.InteropServices;
public class Win32Snap {
    [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
}
"@
try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}

# --- MAIN ---
Write-LeftAligned "$FGYellow Snapping window to right...$Reset"

$VK_LWIN = 0x5B; $VK_RIGHT = 0x27; $KEYEVENTF_KEYUP = 0x0002

[Win32Snap]::keybd_event($VK_LWIN, 0, 0, [UIntPtr]::Zero)
[Win32Snap]::keybd_event($VK_RIGHT, 0, 0, [UIntPtr]::Zero)
[Win32Snap]::keybd_event($VK_RIGHT, 0, $KEYEVENTF_KEYUP, [UIntPtr]::Zero)
[Win32Snap]::keybd_event($VK_LWIN, 0, $KEYEVENTF_KEYUP, [UIntPtr]::Zero)

Write-LeftAligned "$FGGreen$Char_HeavyCheck Success!$Reset"
Start-Sleep -Seconds 1




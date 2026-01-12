#Requires -RunAsAdministrator
#Requires -Version 5.1
<#
.SYNOPSIS
    Resizes console to 64 columns and snaps to right edge.
.DESCRIPTION
    Standardized for WinAuto. Adjusts window dimensions and position.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- NATIVE METHODS ---
$code = @"
using System;
using System.Runtime.InteropServices;
namespace WinAuto {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    public class WinUtils {
        [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll")] public static extern int GetSystemMetrics(int nIndex);
        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    }
}
"@
try { Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue } catch {}

# --- MAIN ---
try {
    Write-LeftAligned "$FGYellow Snapping window to right (64W)...$Reset"

    $targetWidth = 64
    $targetHeight = 50
    $currentHeight = $Host.UI.RawUI.WindowSize.Height
    if ($currentHeight -gt $targetHeight) { $targetHeight = $currentHeight }

    $window = $Host.UI.RawUI.WindowSize
    $window.Width = $targetWidth
    $window.Height = $targetHeight

    $buffer = $Host.UI.RawUI.BufferSize
    if ($buffer.Height -lt $targetHeight) {
        $buffer.Height = $targetHeight
        $Host.UI.RawUI.BufferSize = $buffer
    }

    $Host.UI.RawUI.WindowSize = $window
    $buffer = $Host.UI.RawUI.BufferSize
    $buffer.Width = $targetWidth
    $Host.UI.RawUI.BufferSize = $buffer

    $hWnd = [WinAuto.WinUtils]::GetConsoleWindow()
    $screenW = [WinAuto.WinUtils]::GetSystemMetrics(0) # SM_CXSCREEN
    $screenH = [WinAuto.WinUtils]::GetSystemMetrics(1) # SM_CYSCREEN

    $targetW = [Math]::Floor($screenW / 3)
    $targetX = $screenW - $targetW

    # We need to respect the console font/buffer width if possible, but MoveWindow sets the pixel size.
    # The original script prioritized 64 columns text width. 
    # If we want to strictly follow "Right Third", we should set pixel width to targetW.
    
    $null = [WinAuto.WinUtils]::MoveWindow($hWnd, $targetX, 0, $targetW, $screenH, $true)

    Write-LeftAligned "$FGGreen$Char_HeavyCheck Success! Console resized and snapped.$Reset"

} catch {
    Write-LeftAligned "$FGRed$Char_RedCross Failed: $($_.Exception.Message)$Reset"
}

Start-Sleep -Seconds 1




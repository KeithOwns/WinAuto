#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Checks if 'Kernel-mode Hardware-enforced Stack Protection' is enabled.
.DESCRIPTION
    Standardized for WinAuto. Queries the Registry for the KernelShadowStacks scenario.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- MAIN ---

Write-Header "DEVICE SECURITY AUDIT"

Write-LeftAligned "$FGWhite$Char_HeavyMinus KERNEL STACK PROTECTION$Reset"

# 1. Define Registry Path for Kernel Shadow Stacks
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks"
$regName = "Enabled"

# 2. Check the Registry Value
try {
    if (Test-Path $regPath) {
        $val = (Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue).$regName
        $status = ($val -eq 1)
    } else {
        $status = $false
    }
}
catch {
    $status = $false
}

# 3. Output the Result
if ($status) {
    Write-LeftAligned "$FGGreen$Char_BallotCheck  Kernel-mode Hardware-enforced Stack Protection is ENABLED.$Reset"
}
else {
    Write-LeftAligned "$FGDarkRed$Char_RedCross Kernel-mode Hardware-enforced Stack Protection is DISABLED.$Reset"
}

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""


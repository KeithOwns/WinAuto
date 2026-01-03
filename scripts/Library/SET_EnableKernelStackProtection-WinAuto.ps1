#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables or Disables Kernel-mode Hardware-enforced Stack Protection in Windows Security.
.DESCRIPTION
    Standardized for WinAuto. Includes 10s timeout for interaction.
.PARAMETER Undo
    Reverses the setting (Disables Kernel Stack Protection).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Undo,
    [Parameter()]
    [switch]$Force
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "KERNEL STACK PROTECTION"

$targetValue = if ($Undo) { 0 } else { 1 }
$statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }

#region Functions

function Test-AdministratorPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())        
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-KernelStackProtectionCompatibility {
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10 -or $osVersion.Build -lt 22621) {
        return $false
    }
    return $true
}

function Get-KernelStackProtectionStatus {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks"
    try {
        if (Test-Path $registryPath) {
            $enabled = Get-ItemProperty -Path $registryPath -Name "Enabled" -ErrorAction SilentlyContinue
            if ($null -ne $enabled) { return $enabled.Enabled }
        }
        return 0
    } catch { return -1 }
}

function Set-KernelStackProtection {
    param([int]$Value)
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\KernelShadowStacks"
    try {
        if (-not (Test-Path $registryPath)) { New-Item -Path $registryPath -Force | Out-Null }
        Set-ItemProperty -Path $registryPath -Name "Enabled" -Value $Value -Type DWord -Force
        if ($Value -eq 1) {
            Set-ItemProperty -Path $registryPath -Name "WasEnabledBy" -Value 2 -Type DWord -Force
        }
        return $true
    } catch {
        return $false
    }
}

#endregion

# --- MAIN ---

if (-not (Test-AdministratorPrivileges)) {
    Write-LeftAligned "$FGDarkYellow$Char_Warn Requires Administrator privileges.$Reset"
    exit 1
}

if (-not (Test-KernelStackProtectionCompatibility)) { exit 1 }

$currentStatus = Get-KernelStackProtectionStatus
if ($currentStatus -eq $targetValue) {
    Write-LeftAligned "$FGGreen$Char_BallotCheck  Kernel Stack Protection is $statusText.$Reset"
    exit 0
}

# Set the value
$res = Set-KernelStackProtection -Value $targetValue

if ($res) {
    Write-LeftAligned "$FGGreen$Char_BallotCheck  Kernel Stack Protection is $statusText.$Reset"
} else {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed to modify Kernel Stack Protection.$Reset"
    exit 1
}

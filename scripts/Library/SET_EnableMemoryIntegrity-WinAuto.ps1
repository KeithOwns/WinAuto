#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Enables or Disables Memory Integrity (Hypervisor-protected Code Integrity) in Windows Security.
.DESCRIPTION
    Standardized for WinAuto. Includes 10s timeout for interaction.
.PARAMETER Undo
    Reverses the setting (Disables Memory Integrity).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Undo,
    [Parameter()]
    [switch]$Force
)

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

Write-Header "MEMORY INTEGRITY"

$targetValue = if ($Undo) { 0 } else { 1 }
$statusText = if ($Undo) { "DISABLED" } else { "ENABLED" }

#region Functions

function Test-AdministratorPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())        
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-HypervisorSupport {
    try {
        $hypervisorPresent = (Get-ComputerInfo -Property HyperVisorPresent).HyperVisorPresent
        return $hypervisorPresent
    } catch { return $false }
}

function Test-MemoryIntegrityCompatibility {
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 10 -or ($osVersion.Major -eq 10 -and $osVersion.Build -lt 17134)) {
        return $false
    }
    return $true
}

function Get-MemoryIntegrityStatus {
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
    try {
        if (Test-Path $registryPath) {
            $enabled = Get-ItemProperty -Path $registryPath -Name "Enabled" -ErrorAction SilentlyContinue
            if ($null -ne $enabled) { return $enabled.Enabled }
        }
        return 0
    } catch { return -1 }
}

function Set-MemoryIntegrity {
    param([int]$Value)
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
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

if (-not (Test-MemoryIntegrityCompatibility)) { exit 1 }

$currentStatus = Get-MemoryIntegrityStatus
if ($currentStatus -eq $targetValue) {
    Write-LeftAligned "$FGGreen$Char_BallotCheck  Memory Integrity is $statusText.$Reset"
    exit 0
}

# Hypervisor Check (Only for enabling)
if (-not $Undo -and -not (Test-HypervisorSupport)) {
    Write-LeftAligned "$FGDarkYellow$Char_Warn Hypervisor support (Virtualization) not detected in BIOS/UEFI.$Reset"
}

# Set the value
$res = Set-MemoryIntegrity -Value $targetValue

if ($res) {
    Write-LeftAligned "$FGGreen$Char_BallotCheck  Memory Integrity is $statusText.$Reset"
} else {
    Write-LeftAligned "$FGRed$Char_RedCross  Failed to modify Memory Integrity.$Reset"
    exit 1
}

#Requires -RunAsAdministrator
<#
.SYNOPSIS
    System Inventory & Reporting Tool
.DESCRIPTION
    Generates a detailed text report of system hardware, software, and security status.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

# --- GATHERING ---

Write-Header "SYSTEM INVENTORY"

$reportPath = Join-Path ($env:WinAutoLogDir) "SystemInventory_$($env:COMPUTERNAME).txt"
$report = [System.Collections.Generic.List[string]]::new()

function Add-Section { param($Title) $report.Add(""); $report.Add("=" * 40); $report.Add(" $Title"); $report.Add(("=" * 40)) }
function Add-Item { 
    param($Key, $Value, $Color = $FGGray) 
    try {
        $valStr = if ($Value -eq $null) { "N/A" } else { $Value.ToString() }
        $report.Add("{0,-25} : {1}" -f @([string]$Key, $valStr)) 
    } catch {
        $report.Add("{0,-25} : [Error Formatting]" -f [string]$Key)
    }
} # Adjusted alignment

# 1. System Info
Write-LeftAligned "$FGYellow Gathering System Info..."
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$bios = Get-CimInstance Win32_BIOS

Add-Section "SYSTEM INFORMATION"
Add-Item "Hostname" $env:COMPUTERNAME
Add-Item "Manufacturer" $cs.Manufacturer
Add-Item "Model" $cs.Model
Add-Item "Serial Number" $bios.SerialNumber
Add-Item "OS Name" $os.Caption
Add-Item "OS Version" "$($os.Version) (Build $($os.BuildNumber))"
Add-Item "Install Date" $os.LastBootUpTime.ToString("yyyy-MM-dd HH:mm:ss")

# 2. Hardware
Write-LeftAligned "$FGYellow Gathering Hardware Info..."
Add-Section "HARDWARE"
$cpu = Get-CimInstance Win32_Processor
Add-Item "Processor" $cpu.Name
Add-Item "Cores" $cpu.NumberOfCores
Add-Item "Threads" $cpu.ThreadCount
Add-Item "RAM" "$([math]::Round($cs.TotalPhysicalMemory / 1GB, 2)) GB"

$disks = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' -and $_.DriveLetter } | Sort-Object DriveLetter
if ($disks) {
    foreach ($d in $disks) {
        $part = Get-Partition -DriveLetter $d.DriveLetter -ErrorAction SilentlyContinue
        $diskInfo = $null
        if ($part) {
            $diskInfo = Get-Disk -Number $part.DiskNumber -ErrorAction SilentlyContinue
        }
        
        $diskModel = $(if ($diskInfo) { $diskInfo.Model } else { "Unknown" })
        $diskType = $(if ($diskInfo.BusType -eq 'SSD') { "SSD" } else { "HDD" }) # Basic check

        $diskSizeTotal = [math]::Round($d.Size / 1GB, 2)
        $diskSizeFree = [math]::Round($d.SizeRemaining / 1GB, 2)
        $diskPctFree = [math]::Round(($d.SizeRemaining / $d.Size) * 100, 1)

        Add-Item "Disk $($d.DriveLetter):" "$diskModel ($diskType)"
        Add-Item "  Total Size" "$diskSizeTotal GB"
        Add-Item "  Free Space" "$diskSizeFree GB ($diskPctFree%)"
    }
} else {
    Add-Item "Fixed Disks" "None detected"
}

# 3. Security
Write-LeftAligned "$FGYellow Gathering Security Info..."
Add-Section "SECURITY"
try {
    # BitLocker Status
    $bitlocker = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
    $blStatus = $(if ($bitlocker) { if ($bitlocker.ProtectionStatus -eq 'On') { "Enabled" } else { "Disabled" } } else { "Unknown/Not Applicable" })
    $blColor = $(if ($bitlocker.ProtectionStatus -eq 'On') { $FGGreen } elseif ($bitlocker.ProtectionStatus -eq 'Off') { $FGRed } else { $FGYellow })
    Add-Item "BitLocker (C:)" $blStatus $blColor

    # Antivirus Status
    $avInfo = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntivirusProduct" -ErrorAction SilentlyContinue | Where-Object {$_.productState -and $_.displayName -ne "Microsoft Defender"}
    $defender = Get-MpComputerStatus
    $defenderVer = $defender.AntivirusSignatureVersion

    if ($avInfo) {
        Add-Item "Antivirus" "$($avInfo.displayName) (Active)" $FGGreen
    } else {
        $defenderStatus = $(if ($defender.AntivirusEnabled) {"Enabled"} else {"Disabled"})
        $defenderColor = $(if ($defender.AntivirusEnabled) {$FGGreen} else {$FGRed})
        Add-Item "Antivirus" "Windows Defender ($defenderStatus)" $defenderColor
    }
    Add-Item "Signatures" $defenderVer $FGGreen # Assuming latest if Defender is active.
    
} catch {
    Add-Item "Security Checks" "Error: $($_.Exception.Message)" "Red"
}

# 4. Network
Write-LeftAligned "$FGYellow Gathering Network Info..."
Add-Section "NETWORK"
$netAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
foreach ($adapter in $netAdapters) {
    $ipInfo = Get-NetIPAddress -InterfaceAlias $adapter.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $ipAddr = if ($ipInfo) { $ipInfo.IPAddress } else { "N/A" }
    Add-Item "Adapter" "$($adapter.Name) ($($adapter.MacAddress))"
    Add-Item "  IP Address" $ipAddr
}

# 5. Software
Write-LeftAligned "$FGYellow Gathering Installed Apps..."
Add-Section "INSTALLED APPLICATIONS"

$UninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$installedApps = foreach ($key in $UninstallKeys) {
    Get-ItemProperty $key -ErrorAction SilentlyContinue | 
        Where-Object { 
            $hasName = $_.PSObject.Properties['DisplayName'] -ne $null
            if ($hasName -and $_.DisplayName) {
                $isSystem = $false
                if ($_.PSObject.Properties['SystemComponent'] -ne $null) {
                    $isSystem = [bool]$_.SystemComponent
                }
                -not $isSystem
            } else { $false }
        } | 
        Select-Object DisplayName, DisplayVersion
}

$uniqueApps = $installedApps | Sort-Object DisplayName -Unique

if ($uniqueApps) {
    foreach ($app in $uniqueApps) {
        Add-Item $app.DisplayName $app.DisplayVersion
    }
} else {
    Add-Item "Applications" "No apps found via Registry." "Yellow"
}

# --- SAVE ---
Write-Boundary
Write-LeftAligned "$FGGreen$Char_BallotCheck Inventory Collection Complete.$Reset"
Write-LeftAligned "Report saved to: $reportPath" -ForegroundColor Gray

try {
    $report | Out-File -FilePath $reportPath -Encoding UTF8 -Force
} catch {
    Write-LeftAligned "$FGRed$Char_Warn Failed to save report: $($_.Exception.Message)$Reset"
}

Write-Host ""
$null = Wait-KeyPressWithTimeout -Seconds 10 -OnTick $TickAction
Write-Host ""






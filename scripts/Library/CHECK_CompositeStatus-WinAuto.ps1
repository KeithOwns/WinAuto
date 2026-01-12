#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Automated System Configuration & Security Status Report
.DESCRIPTION
    Aggregates all 'CHECK' only functions from the WinAuto composite scripts.
    Generates a read-only status report without modifying any settings.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"

#region Internal Logic Helpers (Adapted from C1/C2)

function Get-RegistryValue {
    param($Path, $Name)
    try { if (Test-Path $Path) { return (Get-ItemProperty $Path -Name $Name -ErrorAction SilentlyContinue).$Name } } catch {}
    return $null
}

function Get-StatusLine {
    param([bool]$IsEnabled, [string]$Text)
    if ($IsEnabled) { return "$FGDarkGreen$Char_BallotCheck  $FGGray$Text$Reset" } 
    else { return "$FGDarkRed$Char_RedCross $FGGray$Text$Reset" }
}

function Get-ThirdPartyAV {
    try {
        $av = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ErrorAction SilentlyContinue
        foreach ($a in $av) { if ($a.displayName -notmatch "Defender|Windows Security") { return $a.displayName } }
    } catch {}
    return $null
}

#endregion

# --- MAIN REPORTING FLOW ---

Write-Header "AUTOMATED SYSTEM AUDIT"

# 1. WINDOWS UPDATE (From C1)
Write-LeftAligned "$FGWhite$Char_HeavyMinus WINDOWS UPDATE STATUS$Reset"
try {
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
    $Pending = $SearchResult.Updates.Count
    
    if ($Pending -eq 0) {
        Write-LeftAligned "$FGGreen$Char_BallotCheck System is up to date.$Reset"
    } else {
        Write-LeftAligned "$FGYellow$Char_Warn $Pending pending updates found.$Reset"
    }
} catch { Write-LeftAligned "$FGRed$Char_RedCross Update service inaccessible.$Reset" }

# 2. VIRUS & THREAT PROTECTION (From C2)
Write-Host ""
Write-LeftAligned "$FGWhite$Char_HeavyMinus SECURITY PROTECTION$Reset"
$av = Get-ThirdPartyAV
if ($av) {
    Write-LeftAligned "$FGCyan$Char_Warn Managed by: $av$Reset"
} else {
    try {
        $mp = Get-MpPreference
        Write-LeftAligned (Get-StatusLine ($mp.DisableRealtimeMonitoring -eq $false) "Real-time Protection")
        Write-LeftAligned (Get-StatusLine ($mp.PUAProtection -eq 1) "PUA Blocking")
        
        $tp = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -ErrorAction SilentlyContinue).TamperProtection
        Write-LeftAligned (Get-StatusLine ($tp -eq 1 -or $tp -eq 5) "Tamper Protection")
    } catch { Write-LeftAligned "$FGRed$Char_RedCross Defender status unavailable.$Reset" }
}

# 3. FIREWALL & NETWORK (From C2)
Write-Host ""
Write-LeftAligned "$FGWhite$Char_HeavyMinus NETWORK SECURITY$Reset"
try {
    $profiles = @('Domain', 'Private', 'Public')
    foreach ($p in $profiles) {
        $fw = Get-NetFirewallProfile -Name $p -ErrorAction SilentlyContinue
        Write-LeftAligned (Get-StatusLine ($fw.Enabled -eq 'True') "$p Firewall")
    }
} catch { Write-LeftAligned "$FGRed$Char_RedCross Firewall status unavailable.$Reset" }

# 4. CORE ISOLATION (From C2)
Write-Host ""
Write-LeftAligned "$FGWhite$Char_HeavyMinus DEVICE SECURITY$Reset"
$memInt = (Get-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" "Enabled") -eq 1
Write-LeftAligned (Get-StatusLine $memInt "Memory Integrity (HVCI)")

$lsa = (Get-RegistryValue "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" "RunAsPPL") -ge 1
Write-LeftAligned (Get-StatusLine $lsa "LSA Protection")

# 5. SYSTEM HEALTH (From CHECK_System_PreCheck)
Write-Host ""
Write-LeftAligned "$FGWhite$Char_HeavyMinus SYSTEM READINESS$Reset"
$os = Get-CimInstance Win32_OperatingSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$upColor = if($uptime.Days -gt 7){$FGRed}elseif($uptime.Days -gt 3){$FGYellow}else{$FGGreen}
Write-LeftAligned "  Uptime: $upColor$($uptime.Days) days, $($uptime.Hours) hours$Reset"

$drive = Get-Volume -DriveLetter C
$freeGB = [math]::Round($drive.SizeRemaining / 1GB, 2)
$diskColor = if($freeGB -lt 10){$FGRed}elseif($freeGB -lt 20){$FGYellow}else{$FGGreen}
Write-LeftAligned "  Free Space (C:): $diskColor$freeGB GB$Reset"

Write-Host ""
Write-Boundary $FGDarkBlue
Start-Sleep -Seconds 1
Write-Host ""







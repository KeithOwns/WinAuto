# file: Install-RequiredApps.ps1
param(
    [ValidateSet('Desktop','Laptop','Auto')]
    [string]$DeviceType = 'Auto'
)

# --- [USER PREFERENCE] CLEAR SCREEN START ---
Clear-Host
# --------------------------------------------

# --- STYLE & FORMATTING CONFIGURATION (From scriptRULES-W11.ps1) ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Unicode Characters
$Char_HeavyLine   = [char]0x2501 # ━
$Char_LightLine   = [char]0x2500 # ─
$Char_HeavyMinus  = [char]0x2796 # ➖
$Char_EmDash      = [char]0x2014 # —
$Char_EnDash      = [char]0x2013 # –
$Char_HeavyCheck  = [char]0x2705 # ✅
$Char_BallotCheck = [char]0x2611 # ☑
$Char_RedCross    = [char]0x274E # ❎
$Char_Warn        = [char]0x26A0 # ⚠
$Char_Finger      = [char]0x261B # ☛
$Char_Loop        = [char]::ConvertFromUtf32(0x1F504) # 🔄
$Char_Copyright   = [char]0x00A9 # ©
$Char_Keyboard    = [char]0x2328 # ⌨
$Char_Skip        = [char]0x23ED # ⏭

# ANSI Colors
$Esc = [char]0x1B
$Reset = "$Esc[0m"
$Bold = "$Esc[1m"
$FGCyan       = "$Esc[96m"  # Header Title
$FGBlue       = "$Esc[94m"  # Icons
$FGDarkBlue   = "$Esc[34m"  # Boundaries
$FGGreen      = "$Esc[92m"  # Success
$FGRed        = "$Esc[91m"  # Failure
$FGMagenta    = "$Esc[95m"  # Error
$FGYellow     = "$Esc[93m"  # Keys
$FGDarkCyan   = "$Esc[36m"  # Script Text
$FGWhite      = "$Esc[97m"  # Body Title
$FGGray       = "$Esc[37m"  # System Text
$FGDarkGray   = "$Esc[90m"  # Body Boundary
$FGDarkGreen  = "$Esc[32m"  # Enabled
$FGDarkRed    = "$Esc[31m"  # Disabled
$FGDarkYellow = "$Esc[33m"  # Warning
$BGDarkGreen  = "$Esc[42m"
$BGDarkGray   = "$Esc[100m"
$BGYellow     = "$Esc[103m"

# Helper Functions for Formatting
function Write-Centered {
    param([string]$Text, [int]$Width = 60)
    $cleanText = $Text -replace "$Esc\[[0-9;]*m", ""
    $padLeft = [Math]::Floor(($Width - $cleanText.Length) / 2)
    if ($padLeft -lt 0) { $padLeft = 0 }
    Write-Host (" " * $padLeft + $Text)
}

function Write-LeftAligned {
    param([string]$Text, [int]$Indent = 2)
    Write-Host (" " * $Indent + $Text)
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    $TopTitle = " $Char_HeavyLine PatchW11 $Char_HeavyLine"
    Write-Centered "$Bold$FGCyan$TopTitle$Reset"
    Write-Centered "$Bold$FGCyan$Title$Reset"
    Write-Boundary $FGDarkBlue
}

function Write-BodyTitle {
    param([string]$Title)
    Write-LeftAligned "$Bold$FGWhite$Char_HeavyMinus $Title$Reset"
}

function Write-Boundary {
    param([string]$Color = $FGDarkBlue)
    Write-Host "$Color$([string]$Char_HeavyLine * 60)$Reset"
}

function Write-ScriptText {
    param($Text, $Color=$FGGray)
    Write-LeftAligned "$Color$Text$Reset"
}

function Get-StatusLine {
    param([bool]$IsEnabled, [string]$Text)
    if ($IsEnabled) { return "$FGDarkGreen$Char_BallotCheck  $FGGray$Text$Reset" }
    else { return "$FGDarkRed$Char_RedCross $FGGray$Text$Reset" }
}

# -------------------------------------------------------------------

<#
.SYNOPSIS
  Installs a list of required applications in a guided process.
#>

function Write-Stamp {
  param([string]$Tag = "")
  # Output suppressed per user request
  # $who = "Keith - GPT-5 Thinking"
  # $ts  = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
  # if ([string]::IsNullOrWhiteSpace($Tag)) { Write-Host "  $FGGray[$ts] $who$Reset" }
  # else { Write-Host "  $FGGray[$ts] $who - $Tag$Reset" }
}

# --- PREREQUISITE CHECK ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-LeftAligned "$FGRed$Char_RedCross This script must be run with Administrator privileges.$Reset"
    Write-LeftAligned "$FGGray Right-click the script and select 'Run as administrator'.$Reset"
    Write-Stamp "Admin check failed"
    return
}

# --- START HEADER ---
Write-Header "APP INSTALLER"

# --- [NEW] CONFIGURE DEFENDER SETTINGS ---
Write-Host ""
Write-ScriptText "Attempting to disable 'Controlled Folder Access'..."
Write-Stamp "Disabling Controlled Folder Access"

try {
    # Disable Controlled Folder Access
    Set-MpPreference -EnableControlledFolderAccess Disabled -ErrorAction Stop
    
    # Verify the setting
    $newPrefs = Get-MpPreference
    if ($newPrefs.EnableControlledFolderAccess -eq 0) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Controlled Folder Access has been disabled.$Reset"
        Write-Stamp "Controlled Folder Access disabled"
    } else {
        Write-LeftAligned "$FGDarkRed$Char_RedCross Failed to disable Controlled Folder Access.$Reset"
        Write-ScriptText "The current state is: $($newPrefs.EnableControlledFolderAccess). This may be set by Group Policy." $FGDarkYellow
        Write-Stamp "Failed to disable Controlled Folder Access (State: $($newPrefs.EnableControlledFolderAccess))"
    }
} catch {
    Write-LeftAligned "$FGRed$Char_Warn [ERROR] An error occurred while trying to disable Controlled Folder Access:$Reset"
    Write-ScriptText $_.Exception.Message $FGRed
    Write-ScriptText "This is often because the setting is managed by Group Policy (GPO) or Intune." $FGDarkYellow
    Write-Stamp "Error disabling Controlled Folder Access: $($_.Exception.Message)"
}
Write-Boundary $FGDarkGray
# --- [END NEW] ---

# --- SETTINGS ---
$MinWingetVersion = [version]'1.5.0'
$StartTime = Get-Date
$TranscriptLogPath = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath ("App-Install-Transcript-{0:yyyyMMdd-HHmmss}.txt" -f $StartTime)
$SummaryLogPath    = Join-Path -Path ([Environment]::GetFolderPath('Desktop')) -ChildPath ("App-Install-Summary-{0:yyyyMMdd-HHmmss}.txt" -f $StartTime)
Start-Transcript -Path $TranscriptLogPath -Append | Out-Null
$Summary = [System.Collections.Generic.List[object]]::new()
$SoftSuccessCodes = @(0,3010,-2145124332,0x8024001E,0x8024200B)
$ScriptExitCode = 0

# --- BASE CONFIGURATION (Alphabetical by AppName) ---
$BaseApps = @(
  @{ AppName="Adobe Creative Cloud"; MatchName="*Adobe Creative Cloud*"; Type="WINGET"; CheckMethod="Registry"; WingetId="Adobe.CreativeCloud"; InstallOrder=50 },
  @{ AppName="Box";                  MatchName="Box";                  Type="MSI";    CheckMethod="Registry"; InstallOrder=40; Url="https://e3.boxcdn.net/box-installers/desktop/releases/win/Box-x64.msi" },
  @{ AppName="Box for Office";       MatchName="*Box for Office*";     Type="EXE";    CheckMethod="Registry"; InstallOrder=41; Url="https://e3.boxcdn.net/box-installers/boxforoffice/currentrelease/BoxForOffice.exe"; SilentArgs="/quiet /norestart"; PreInstallDelay=10 },
  @{ AppName="Box Tools";            MatchName="*Box Tools*";          Type="EXE";    CheckMethod="Registry"; InstallOrder=42; Url="https://e3.boxcdn.net/box-installers/boxedit/win/currentrelease/BoxToolsInstaller.exe"; SilentArgs="/quiet /norestart ALLUSERS=1" }
)

# --- CONDITIONAL MODULES ---
$AirMediaModule = @{
  AppName      = "Crestron AirMedia"
  MatchName    = "*AirMedia*"
  Type         = "WINGET"
  CheckMethod  = "Registry"
  WingetScope  = 'Machine'
  WingetId     = "Crestron.AirMedia"
  InstallOrder = 100
}

# --- FUNCTIONS ---
function Add-Tls {
  if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12|Tls13') {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13 }
    catch {
      Write-Host "  $FGDarkYellow Could not enable TLS 1.3, using TLS 1.2 only: $($_.Exception.Message)$Reset"
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
  }
}

function Test-AppConfiguration {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$App)
  $errors = @()
  if (-not $App.ContainsKey('AppName') -or [string]::IsNullOrWhiteSpace($App.AppName)) { $errors += "Missing required field: AppName" }
  if ($App.ContainsKey('IsPrerequisite') -and $App.IsPrerequisite) { return $true }
  if (-not $App.ContainsKey('Type')) { $errors += "Missing required field: Type for app '$($App.AppName)'" }
  if ($App.Type -eq 'WINGET' -and -not $App.ContainsKey('WingetId')) { $errors += "WINGET type requires WingetId for app '$($App.AppName)'" }
  if (($App.Type -eq 'MSI' -or $App.Type -eq 'EXE') -and -not ($App.ContainsKey('Url') -or $App.ContainsKey('Urls') -or $App.ContainsKey('InstallerPath'))) {
    $errors += "$($App.Type) type requires Url, Urls, or InstallerPath for app '$($App.AppName)'"
  }
  if ($errors.Count -gt 0) { Write-Error "Configuration errors:`n$($errors -join "`n")"; return $false }
  return $true
}

function Get-File {
  [CmdletBinding()]
  param([Parameter(Mandatory)][string]$Url,[Parameter(Mandatory)][string]$Out)
  Add-Tls
  Write-ScriptText "Downloading from: $Url" $FGGray
  for ($i=1; $i -le 3; $i++) {
    try {
      $ProgressPreference = 'SilentlyContinue'
      Invoke-WebRequest -Uri $Url -OutFile $Out -UseBasicParsing -ErrorAction Stop
      $ProgressPreference = 'Continue'
      if (Test-Path $Out) {
        $fileSize = (Get-Item $Out).Length
        Write-ScriptText "Download complete: $([math]::Round($fileSize/1MB,2)) MB" $FGGray
      }
      return
    } catch {
      if ($i -lt 3) { Write-ScriptText "Download attempt $i failed. Retrying in $($i*10) seconds..." $FGDarkYellow; Start-Sleep -Seconds (10*$i) }
      else { throw "Download failed after 3 attempts: $($_.Exception.Message)" }
    }
  }
}

function Get-MsiUrlFromLanding {
  param([Parameter(Mandatory)][string]$LandingUrl)
  Add-Tls
  $html = Invoke-WebRequest -Uri $LandingUrl -UseBasicParsing -ErrorAction Stop
  $msi = ($html.Links | Where-Object { $_.href -match '\.msi($|\?)' } | Select-Object -First 1).href
  if (-not $msi) { throw "No MSI link found at: $LandingUrl" }
  if ($msi -notmatch '^https?://') {
    $uri = [Uri]$LandingUrl; $base = "$($uri.Scheme)://$($uri.Host)"
    $msi = if ($msi.StartsWith('/')) { "$base$msi" } else { "$base/$msi" }
  }
  return $msi
}

function Ensure-WingetSources {
  try {
    Write-ScriptText "Checking Windows Package Manager sources..." $FGDarkYellow
    $null = Start-Process -FilePath "winget.exe" -ArgumentList @("source","update","--disable-interactivity") -Wait -PassThru -ErrorAction SilentlyContinue
    $en = Start-Process -FilePath "winget.exe" -ArgumentList @("source","enable","msstore","--disable-interactivity") -Wait -PassThru -ErrorAction SilentlyContinue
    if ($en -and $en.ExitCode -ne 0) {
      Start-Process -FilePath "winget.exe" -ArgumentList @("source","add","-n","msstore","-a","https://storeedgefd.dsx.mp.microsoft.com/v9.0","--disable-interactivity") -Wait -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "  $FGGreen$Char_HeavyCheck Winget sources ready.$Reset"
  } catch { Write-ScriptText "Winget source prep failed: $($_.Exception.Message)" $FGDarkYellow }
}

function Assert-WingetVersion {
  param([Parameter(Mandatory)][version]$Minimum)
  $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
  if (-not $winget) { Write-Host "  $FGRed$Char_Cross Windows Package Manager (winget) not installed.$Reset"; return $false }
  try { $raw = & winget --version 2>$null; $verText = ($raw | Select-Object -First 1).ToString().Trim().TrimStart('v','V'); $ver = [version]$verText }
  catch { Write-Host "  $FGRed$Char_Cross Unable to determine winget version.$Reset"; return $false }
  if ($ver -lt $Minimum) { Write-Host "  $FGRed$Char_Cross winget $verText detected. Version $($Minimum.ToString()) or newer required.$Reset"; return $false }
  Write-Host "  $FGGreen$Char_HeavyCheck winget $verText OK.$Reset"
  return $true
}

function Test-AppInstalled {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$App)

  if ($App.ContainsKey('CheckMethod') -and $App.CheckMethod -eq 'Appx') {
    $name = if ($App.ContainsKey('AppxName') -and $App.AppxName) { $App.AppxName } elseif ($App.ContainsKey('MatchName') -and $App.MatchName) { $App.MatchName } else { $App.AppName }
    $pkg = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $name -or $_.PackageFamilyName -like "$name*" -or $_.Name -like "$name*" } | Select-Object -First 1
    return [bool]$pkg
  }

  if ($App.ContainsKey('CheckMethod') -and $App.CheckMethod -eq 'File') {
    $path = if ($App.ContainsKey('FilePath')) { $App['FilePath'] } else { $null }
    return ([bool]$path -and (Test-Path -Path $path))
  }

  $scope = if ($App.ContainsKey('RegistryScope')) { $App.RegistryScope } else { 'Machine' }
  $roots = @()
  if ($scope -eq 'Machine' -or $scope -eq 'All') {
    $roots += "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $roots += "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
  }
  if ($scope -eq 'User' -or $scope -eq 'All') {
    $roots += "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $roots += "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
  }

  $pattern = if ($App.ContainsKey('MatchName')) { $App.MatchName } else { $App.AppName }
  foreach ($r in $roots) {
    if (-not (Test-Path $r)) { continue }
    foreach ($k in (Get-ChildItem $r -ErrorAction SilentlyContinue)) {
      $dn = $k.GetValue('DisplayName',$null)
      if ($dn -and ($dn -like $pattern)) { return $true }
    }
  }
  return $false
}

function Install-WithWingetRetry {
  param([Parameter(Mandatory)][hashtable]$App)
  $base = @("install","--id",$App.WingetId,"-e","--accept-package-agreements","--accept-source-agreements","--silent","--disable-interactivity")
  if ($App.ContainsKey('Source') -and $App.Source) { $base += @("--source",$App.Source) }

  # Attempt 1
  $args1 = @($base)
  if ($App.ContainsKey('WingetScope') -and $App.WingetScope) { $args1 += @("--scope",$App.WingetScope) }
  $p1 = Start-Process -FilePath "winget.exe" -ArgumentList $args1 -Wait -PassThru -ErrorAction SilentlyContinue
  $c1 = if ($null -ne $p1) { $p1.ExitCode } else { 0 }
  if ($c1 -eq 0) { return 0 }

  # Attempt 2
  try { Start-Process winget.exe -ArgumentList @("source","update","--disable-interactivity") -Wait -ErrorAction SilentlyContinue | Out-Null } catch {}
  $alt = if ($App.ContainsKey('WingetScope') -and $App.WingetScope -eq 'Machine') { 'User' } else { 'Machine' }
  $args2 = @($base) + @("--scope",$alt)
  $p2 = Start-Process -FilePath "winget.exe" -ArgumentList $args2 -Wait -PassThru -ErrorAction SilentlyContinue
  $c2 = if ($null -ne $p2) { $p2.ExitCode } else { 0 }
  if ($c2 -eq 0) { return 0 }

  Write-ScriptText "winget failed for {0}. Codes: first={1}, second={2}." -f $App.AppName,$c1,$c2 $FGDarkYellow
  return $c2
}

function Wait-UntilDetected {
  param([Parameter(Mandatory)][hashtable]$App,[int]$TimeoutSec=150,[int]$IntervalSec=5)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  do {
    if (Test-AppInstalled -App $App) { return $true }
    Start-Sleep -Seconds $IntervalSec
  } while ((Get-Date) -lt $deadline)
  return $false
}

function Invoke-GenericInstall {
  [CmdletBinding()]
  param([Parameter(Mandatory)][hashtable]$App)
  $AppName = $App.AppName
  $InstallerType = $App.Type
  Write-Host ""
  Write-ScriptText "Starting installation for '$AppName' (Type: $InstallerType)..." $FGDarkCyan

  # [NEW] Pre-Installation Delay Support
  if ($App.ContainsKey('PreInstallDelay') -and $App.PreInstallDelay -gt 0) {
      Write-ScriptText "Waiting $($App.PreInstallDelay) seconds before installation as requested..." $FGDarkYellow
      Start-Sleep -Seconds $App.PreInstallDelay
  }

  $tmp = $null; $exit = $null

  try {
    switch ($InstallerType) {
      "MSI" {
        $installerFilePath = $null
        if ($App.ContainsKey('InstallerPath') -and (Test-Path -Path $App.InstallerPath)) {
          $installerFilePath = $App.InstallerPath
          Write-ScriptText "Using network/local installer at: $installerFilePath" $FGGray
        } else {
          Write-ScriptText "Local installer not found. Attempting download..." $FGGray
          $urls = @()
          if ($App.ContainsKey('Urls')) { $urls = @($App.Urls) } elseif ($App.ContainsKey('Url')) { $urls = @($App.Url) }
          
          if ($urls.Count -eq 0) { throw "No URL(s) specified for MSI." }
          $resolvedUrl = $null
          foreach ($u in $urls) {
            try {
              if ($u -match '\.msi($|\?)|//aka\.ms/') { $resolvedUrl = $u } else { $resolvedUrl = Get-MsiUrlFromLanding -LandingUrl $u }
              break
            } catch { continue }
          }
          if (-not $resolvedUrl) { throw "Could not resolve a valid MSI URL." }
          $InstallerFileName = if ($App.ContainsKey('OutFileName')) { $App.OutFileName } else { [IO.Path]::GetFileName(([Uri]$resolvedUrl).AbsolutePath) }
          if ([string]::IsNullOrWhiteSpace($InstallerFileName)) { $InstallerFileName = "$($App.AppName.Replace(' ','-'))-installer.msi" }
          $installerFilePath = Join-Path -Path $env:TEMP -ChildPath $InstallerFileName
          Write-ScriptText "Downloading '$AppName' MSI..." $FGGray
          Get-File -Url $resolvedUrl -Out $installerFilePath
          $tmp = $installerFilePath
        }
        $msiArgs = "/i `"$installerFilePath`" /qn /norestart"
        if ($App.ContainsKey('MsiParams') -and $App.MsiParams) { $msiArgs += " $($App.MsiParams)" }
        $p = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -ErrorAction Stop
        $exit = $p.ExitCode
      }
      "EXE" {
        $installerFilePath = $null
        if ($App.ContainsKey('InstallerPath') -and (Test-Path -Path $App.InstallerPath)) {
          $installerFilePath = $App.InstallerPath
        } elseif ($App.ContainsKey('Url')) {
          $InstallerFileName = if ($App.ContainsKey('OutFileName')) { $App.OutFileName } else { [IO.Path]::GetFileName(([Uri]$App.Url).AbsolutePath) }
          if ([string]::IsNullOrWhiteSpace($InstallerFileName) -or $InstallerFileName -eq "files") { $InstallerFileName = "$($App.AppName.Replace(' ','-'))-installer.exe" }
          $installerFilePath = Join-Path -Path $env:TEMP -ChildPath $InstallerFileName
          Write-ScriptText "Downloading '$AppName' EXE..." $FGGray
          Get-File -Url $App.Url -Out $installerFilePath
          $tmp = $installerFilePath
        }
        else { throw "No valid InstallerPath or Url found." }
        $args = if ($App.ContainsKey('SilentArgs')) { $App.SilentArgs } else { "/quiet /norestart" }
        $p = Start-Process -FilePath $installerFilePath -ArgumentList $args -Wait -PassThru -ErrorAction Stop
        $exit = $p.ExitCode
      }
      "WINGET" {
        $exit = Install-WithWingetRetry -App $App
      }
      "BUILTIN" {
        Write-Host "  $FGGreen$Char_HeavyCheck '$AppName' is built into Windows.$Reset"
        $exit = 0
      }
      Default { throw "Unknown installer Type: $InstallerType" }
    }

    if ($null -eq $exit) { Write-ScriptText "Installer returned no exit code; treating as soft success." $FGDarkYellow; $exit = 0 }
    if ($SoftSuccessCodes -notcontains $exit) { throw "Installer returned non-success exit code: $exit" }
  }
  catch {
    Write-Host "  $FGMagenta$Char_Warn [ERROR] '$AppName' installation failed.$Reset"
    Write-ScriptText "Details: $($_.Exception.Message)" $FGMagenta
    $finalExitCode = if ($null -ne $exit) { $exit } else { -1 }
    $Summary.Add([pscustomobject]@{ AppName = $AppName; Type = $InstallerType; Exit = $finalExitCode; Present = $false; Time = Get-Date })
    $global:ScriptExitCode = 1
    return
  }
  finally { if ($tmp -and (Test-Path $tmp)) { Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue } }

  $isUserCtx = (($App.ContainsKey('RegistryScope') -and $App.RegistryScope -eq 'User') -or (($App.ContainsKey('CheckMethod') -and $App.CheckMethod -eq 'Appx') -and ($App.ContainsKey('Source') -and $App.Source -eq 'msstore'))) -and ($App.WingetScope -ne 'Machine')

  $present = $false
  if ($isUserCtx) {
    Write-ScriptText "User-context install initiated. Verification deferred." $FGDarkYellow
    $present = $true
  } else {
    $present = Wait-UntilDetected -App $App -TimeoutSec 150 -IntervalSec 5
    if ($present) { Write-Host "  $FGGreen$Char_HeavyCheck '$AppName' successfully installed.$Reset" }
    else { Write-Host "  $FGDarkYellow$Char_Warn '$AppName' not detected after timeout.$Reset" }
  }

  $Summary.Add([pscustomobject]@{ AppName = $AppName; Type = $InstallerType; Exit = $exit; Present = [bool]$present; Time = Get-Date })
}

# --- DEVICE TYPE DETERMINATION ---
$IsDesktop = $false
if ($DeviceType -eq 'Desktop') { $IsDesktop = $true }
elseif ($DeviceType -eq 'Laptop') { $IsDesktop = $false }
else {
  try {
    $chassis = (Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
    if ($chassis -and ($chassis -contains 3 -or $chassis -contains 4 -or $chassis -contains 5 -or $chassis -contains 6 -or $chassis -contains 7 -or $chassis -contains 15 -or $chassis -contains 23 -or $chassis -contains 31)) { $IsDesktop = $true }
  } catch {}
  Write-ScriptText "Auto-detected DeviceType: $(if($IsDesktop){'Desktop'}else{'Laptop'})" $FGDarkYellow
}

# Compose final app list
$RequiredApps = [System.Collections.Generic.List[Object]]::new()
$RequiredApps.AddRange($BaseApps)
if (-not $IsDesktop) {
  $RequiredApps.Add($AirMediaModule)
  Write-ScriptText "Crestron AirMedia module included for Laptop." $FGDarkYellow
}

# --- MAIN SCRIPT BODY ---

Write-Host ""
Write-ScriptText "Validating app configurations..."
$configValid = $true
foreach ($app in $RequiredApps) { if (-not (Test-AppConfiguration -App $app)) { $configValid = $false } }
if (-not $configValid) { Write-Error "Configuration validation failed."; return }
Write-Host "  $FGGreen$Char_HeavyCheck Configuration validation passed.$Reset"
Write-Stamp "Config validated"

# Separate apps
$PrerequisiteApps = $RequiredApps | Where-Object { $_.ContainsKey('IsPrerequisite') -and $_.IsPrerequisite }
$StandardApps     = $RequiredApps | Where-Object { -not ($_.ContainsKey('IsPrerequisite') -and $_.IsPrerequisite) }

# --- GUIDED PREREQUISITE CHECK ---
while ($true) {
  Write-Host ""
  Write-ScriptText "--- Starting Security Prerequisite Check ---"
  $MissingPrereqs = [System.collections.Generic.List[object]]::new()

  foreach ($app in $PrerequisiteApps) {
    if (-not (Test-AppInstalled -App $app)) { $MissingPrereqs.Add($app) }
    else { Write-LeftAligned "$FGDarkGreen$Char_BallotCheck $($app.AppName): Found$Reset" }
  }

  if ($MissingPrereqs.Count -gt 0) {
    Write-ScriptText "The following security prerequisites are missing:" $FGDarkYellow
    foreach ($app in $MissingPrereqs) {
      Write-LeftAligned "$FGDarkRed$Char_RedCross $($app.AppName)$Reset"
      if ($app.ContainsKey('ManualInstallPath')) { Write-ScriptText "   Path: $($app.ManualInstallPath)" $FGGray }
    }
    Read-Host "  After installing all missing applications, press Enter to re-check"
  }
  else {
    Write-LeftAligned "$FGGreen$Char_HeavyCheck All security prerequisites are met.$Reset"
    Write-Boundary $FGDarkGray
    break
  }
}

# --- STANDARD INSTALLATION ---
if (-not (Assert-WingetVersion -Minimum $MinWingetVersion)) { Write-Stamp "winget too old"; return }
Ensure-WingetSources

Write-Host ""
Write-ScriptText "Starting check for required applications..."
$AppsToInstall = @()
$AlreadyPresentApps = [System.Collections.Generic.List[string]]::new()
foreach ($app in $StandardApps) {
  if (Test-AppInstalled -App $app) {
    Write-LeftAligned "$FGDarkGreen$Char_BallotCheck Found: $($app.AppName)$Reset"
    $AlreadyPresentApps.Add($app.AppName)
  } else {
    Write-LeftAligned "$FGDarkRed$Char_RedCross Missing: $($app.AppName)$Reset"
    $AppsToInstall += $app
  }
}

Write-Host ""
if ($AppsToInstall.Count -gt 0) {
  $AppsToInstall = $AppsToInstall | Sort-Object InstallOrder
  Write-Boundary $FGDarkBlue
  Write-ScriptText "Missing applications detected: $($AppsToInstall.Count)" $FGDarkYellow
  Write-Host ""
  
  Write-BodyTitle "APPLICATIONS TO INSTALL"
  
  foreach ($app in $AppsToInstall) {
    Write-LeftAligned "$FGWhite  $Char_Finger $($app.AppName)$Reset"
  }

  # --- CUSTOM PROMPT FORMATTING ---
  Write-Host ""
  # Updated Prompt Format to match RULES
  $PromptStr = "${FGWhite}$Char_Keyboard  Press${FGDarkGray} ${FGYellow}$Char_Finger [Enter]${FGDarkGray} ${FGWhite}to${FGDarkGray} ${FGYellow}Install${FGWhite}|${FGDarkGray}any other to ${FGWhite}SKIP$Char_Skip${Reset}"
  Write-Centered $PromptStr

  $validInput = $false
  while (-not $validInput) {
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Enter') {
      $validInput = $true
    } else {
      Write-Host ""
      Write-ScriptText "Installation canceled by user." $FGDarkYellow
      Write-Stamp "Installation canceled by user"
      Stop-Transcript
      
      # --- [USER PREFERENCE] END OF SCRIPT PADDING ---
      1..5 | ForEach-Object { Write-Host "" }
      # -----------------------------------------------
      return
    }
  }

  Write-Boundary $FGDarkBlue
  Write-ScriptText "Installing missing applications..." $FGDarkYellow
  Write-Stamp "Starting application installation"
  foreach ($app in $AppListToInstall = $AppsToInstall) { Invoke-GenericInstall -App $app }
} else {
  Write-LeftAligned "$FGGreen$Char_HeavyCheck All required applications are already installed.$Reset"
}

# --- FINAL SUMMARY ---
Stop-Transcript | Out-Null
$logContent = [System.Collections.Generic.List[string]]::new()
$logContent.Add("========================================")
$logContent.Add(" App Installation Log")
$logContent.Add("========================================")
$logContent.Add("Date: $(Get-Date)")
$logContent.Add("Computer: $env:COMPUTERNAME")
$logContent.Add("User: $env:USERNAME")
$logContent.Add("Generated by: Keith - GPT-5 Thinking at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
$logContent.Add("")

# Wrap in arrays to avoid null .Count errors when no installs occurred
$successes = @($Summary | Where-Object { $_.Present })
$failures  = @($Summary | Where-Object { -not $_.Present })

$logContent.Add("--- Successful Installations ($($successes.Count)) ---")
if ($successes.Count -gt 0) { $successes | ForEach-Object { $logContent.Add("- $($_.AppName) (Exit Code: $($_.Exit))") } } else { $logContent.Add("None") }
$logContent.Add("")

$logContent.Add("--- Failed Installations ($($failures.Count)) ---")
if ($failures.Count -gt 0) { $failures | ForEach-Object { $logContent.Add("- $($_.AppName) (Exit Code: $($_.Exit))") } } else { $logContent.Add("None") }
$logContent.Add("")

$logContent.Add("--- Already Installed ($($AlreadyPresentApps.Count)) ---")
if ($AlreadyPresentApps.Count -gt 0) { $AlreadyPresentApps | ForEach-Object { $logContent.Add("- $_") } } else { $logContent.Add("None") }
$logContent.Add("")
$logContent.Add("========================================")
$logContent.Add("End of Report")

$logContent | Out-File -FilePath $SummaryLogPath -Encoding UTF8 -Force

Write-Boundary $FGDarkBlue
Write-ScriptText "All operations complete."
Write-ScriptText "Summary log: $SummaryLogPath" $FGGray
Write-ScriptText "Transcript:  $TranscriptLogPath" $FGGray
Write-Stamp "Summary emitted"

# --- [ADDED PER REQUEST] Wait before final verification ---
Write-Host ""
Write-ScriptText "Waiting 10 seconds for services to settle before final verification..." $FGDarkYellow
Start-Sleep -Seconds 10
# --- [END ADDITION] ---

# --- FINAL CONDITIONAL OUTPUT ---
Write-Host ""
Write-Boundary $FGDarkGray

$StillMissingApps = [System.Collections.Generic.List[string]]::new()
foreach ($app in $AppsToInstall) {
  if (-not (Test-AppInstalled -App $app)) {
    $isUserContextApp = (($app.ContainsKey('RegistryScope') -and $app.RegistryScope -eq 'User') -or
      (($app.ContainsKey('CheckMethod') -and $app.CheckMethod -eq 'Appx') -and ($app.ContainsKey('Source') -and $app.Source -eq 'msstore'))) -and
      ($app.WingetScope -ne 'Machine')
    if (-not $isUserContextApp) { $StillMissingApps.Add($app.AppName) }
  }
}

if ($StillMissingApps.Count -eq 0) {
  Write-LeftAligned "$FGGreen$Char_HeavyCheck All required applications successfully installed!$Reset"
} else {
  Write-LeftAligned "$FGRed$Char_RedCross Required applications that still need to be installed:$Reset"
  $StillMissingApps | ForEach-Object { Write-LeftAligned "$FGRed - $_$Reset" -Indent 4 }
  Write-ScriptText "See log for details: $TranscriptLogPath" $FGDarkYellow
}
Write-Boundary $FGDarkGray
Write-Stamp "Run complete"

# --- [NEW] RE-ENABLE CONTROLLED FOLDER ACCESS ---
Write-Host ""
Write-ScriptText "Attempting to re-enable 'Controlled Folder Access'..."
Write-Stamp "Re-enabling Controlled Folder Access"

try {
    # Enable Controlled Folder Access
    Set-MpPreference -EnableControlledFolderAccess Enabled -ErrorAction Stop
    
    # Verify the setting
    $newPrefs = Get-MpPreference
    if ($newPrefs.EnableControlledFolderAccess -eq 1) {
        Write-LeftAligned "$FGGreen$Char_HeavyCheck Controlled Folder Access has been re-enabled.$Reset"
        Write-Stamp "Controlled Folder Access enabled"
    } else {
        Write-LeftAligned "$FGRed$Char_RedCross Failed to re-enable Controlled Folder Access.$Reset"
        Write-ScriptText "The current state is: $($newPrefs.EnableControlledFolderAccess). This may be set by Group Policy." $FGDarkYellow
        Write-Stamp "Failed to re-enable Controlled Folder Access (State: $($newPrefs.EnableControlledFolderAccess))"
    }
} catch {
    Write-LeftAligned "$FGRed$Char_Warn [ERROR] An error occurred while trying to re-enable Controlled Folder Access:$Reset"
    Write-ScriptText $_.Exception.Message $FGRed
    Write-ScriptText "This is often because the setting is managed by Group Policy (GPO) or Intune." $FGDarkYellow
    Write-Stamp "Error re-enabling Controlled Folder Access: $($_.Exception.Message)"
}
Write-Boundary $FGDarkGray
# --- [END NEW] ---

# --- COPYRIGHT FOOTER ---
Write-Host ""
Write-Boundary $FGDarkBlue
$FooterText = "$Char_Copyright 2025, www.AIIT.support. All Rights Reserved."
Write-Centered "$FGCyan$FooterText$Reset"

# --- EXIT CODE POLICY ---
$rebootMatches = @($Summary | Where-Object { $_.Exit -eq 3010 })

if ($ScriptExitCode -ne 0) {
    # Failure already occurred and set the exit code to 1
} elseif ($rebootMatches.Count -gt 0) {
    $ScriptExitCode = 3010 # Reboot needed
}

# --- [USER PREFERENCE] END OF SCRIPT PADDING ---
1..5 | ForEach-Object { Write-Host "" }
# -----------------------------------------------
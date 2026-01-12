# .SYNOPSIS
#     WinAuto One-Liner Bootstrapper
# .DESCRIPTION
#     Downloads, installs, and launches the WinAuto suite.
#     - Downloads ZIP from GitHub
#     - Extracts to Documents
#     - Creates Desktop Shortcut
#     - Launches Suite

# --- CONFIGURATION ---
$InstallDir = "$env:USERPROFILE\Documents\WinAuto"
$ZipURL = "https://github.com/KeithOwns/WinAuto/archive/refs/heads/main.zip"

# --- SETUP ANSI COLORS ---
$Esc = [char]0x1B
$Green = "$Esc[92m"; $Red = "$Esc[91m"; $Cyan = "$Esc[96m"; $Yellow = "$Esc[93m"; $Reset = "$Esc[0m"

function Write-Step { param($T) Write-Host " $Cyan[SETUP]$Reset $T" }
function Write-Ok   { param($T) Write-Host " $Green[OK]$Reset    $T" }
function Write-Err  { param($T) Write-Host " $Red[ERR]$Reset   $T" }

# Helper to print padding before exit
function Close-Script {
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    exit
}

Clear-Host
Write-Host ""
Write-Host " $Cyan   WinAuto Installer $Reset"
Write-Host " $Cyan   ================= $Reset"
Write-Host ""

# 1. CHECK ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "Administrator privileges required."
    Start-Sleep -Seconds 2
    Close-Script
}

# 2. DOWNLOAD & INSTALL
Write-Step "Configuring installation path: $InstallDir"

# Cleanup old version (Fresh Install strategy ensures clean state without Git)
if (Test-Path $InstallDir) {
    Write-Step "Removing old version..."
    try {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Err "Failed to remove old version. Ensure WinAuto is not running."
        Close-Script
    }
}

Write-Step "Downloading repository archive..."
$ZipPath = "$env:TEMP\WinAuto_Setup.zip"
$ExtractPath = "$env:TEMP\WinAuto_Extract"

try {
    # Download the ZIP
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $ZipURL -OutFile $ZipPath -ErrorAction Stop
    Write-Ok "Download complete."

    # Extract
    Write-Step "Extracting files..."
    if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    # Move files to InstallDir
    # GitHub zips usually extract to a folder like 'WinAuto-main', so we find that child folder
    $SourceFolder = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
    
    if ($SourceFolder) {
        Move-Item -Path $SourceFolder.FullName -Destination $InstallDir -Force
        Write-Ok "Installed to $InstallDir"
    } else {
        throw "Extracted zip was empty or invalid structure."
    }

    # Cleanup Temp
    Remove-Item $ZipPath -Force
    Remove-Item $ExtractPath -Recurse -Force

} catch {
    Write-Err "Installation failed: $($_.Exception.Message)"
    # Attempt cleanup on fail
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Close-Script
}

# 3. CREATE SHORTCUT
try {
    Write-Step "Creating Desktop shortcut..."
    $ShortcutPath = "$env:USERPROFILE\Desktop\WinAuto.lnk"
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "$InstallDir\WinAuto.bat"
    $Shortcut.WorkingDirectory = "$InstallDir"
    $Shortcut.IconLocation = "shell32.dll,238" # Shield Icon
    $Shortcut.Description = "WinAuto Maintenance Suite"
    $Shortcut.Save()

    # --- SET RUN AS ADMIN ---
    # Read the shortcut file as bytes
    $bytes = [System.IO.File]::ReadAllBytes($ShortcutPath)
    # The 'Run as Administrator' flag is in byte 21 (0x15). We set bit 5 (0x20).
    $bytes[0x15] = $bytes[0x15] -bor 0x20
    # Save the modified bytes back to the file
    [System.IO.File]::WriteAllBytes($ShortcutPath, $bytes)

    Write-Ok "Shortcut created on Desktop (Run as Admin)."
} catch {
    Write-Err "Failed to create shortcut: $($_.Exception.Message)"
}

# 4. LAUNCH
Write-Host ""
Write-Ok "Installation complete!"
Write-Step "Launching WinAuto..."
Start-Sleep -Seconds 2

# Print padding before handing off control
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""

& "$InstallDir\WinAuto.bat"

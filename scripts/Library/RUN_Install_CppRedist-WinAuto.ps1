#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Installs the latest Visual C++ Redistributable (2015-2022) for x64 and x86.
.DESCRIPTION
    Downloads the official installers from Microsoft and performs a silent installation.
    Useful for ensuring system compatibility and security.
#>

# --- SHARED FUNCTIONS ---
. "$PSScriptRoot\..\Shared\Shared_UI_Functions.ps1"
. "$PSScriptRoot\..\Library\MODULE_Logging.ps1"
Init-Logging

Write-Header "INSTALL C++ REDIST"

$TempDir = "$env:TEMP\WinAuto_CppRedist"
if (-not (Test-Path $TempDir)) { New-Item -Path $TempDir -ItemType Directory -Force | Out-Null }

$Installers = @(
    @{
        Name = "Visual C++ 2015-2022 (x64)"
        Url  = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        File = "$TempDir\vc_redist.x64.exe"
        Args = "/install /quiet /norestart"
    },
    @{
        Name = "Visual C++ 2015-2022 (x86)"
        Url  = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        File = "$TempDir\vc_redist.x86.exe"
        Args = "/install /quiet /norestart"
    }
)

foreach ($app in $Installers) {
    Write-LeftAligned "$FGGray Downloading $($app.Name)...$Reset"
    
    try {
        Invoke-WebRequest -Uri $app.Url -OutFile $app.File -ErrorAction Stop
        Write-Log "Downloaded $($app.Name)" -Level INFO
        
        Write-LeftAligned "$FGGray Installing $($app.Name)...$Reset"
        $proc = Start-Process -FilePath $app.File -ArgumentList $app.Args -Wait -PassThru -NoNewWindow
        
        # 0 = Success, 3010 = Success (Reboot Required), 1638 = Newer version already installed
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-LeftAligned "$FGGreen$Char_HeavyCheck Successfully installed $($app.Name).$Reset"
            Write-Log "Installed $($app.Name) (Exit: $($proc.ExitCode))" -Level SUCCESS
        } elseif ($proc.ExitCode -eq 1638) {
            Write-LeftAligned "$FGGreen$Char_CheckMark Newer version already installed.$Reset"
            Write-Log "Newer version of $($app.Name) already present." -Level SUCCESS
        } else {
            Write-LeftAligned "$FGRed$Char_RedCross Installation failed (Exit Code: $($proc.ExitCode)).$Reset"
            Write-Log "Failed to install $($app.Name) (Exit: $($proc.ExitCode))" -Level ERROR
        }
        
    } catch {
        Write-LeftAligned "$FGRed$Char_RedCross Error: $($_.Exception.Message)$Reset"
        Write-Log "Error processing $($app.Name): $($_.Exception.Message)" -Level ERROR
    }
}

# Cleanup
try { Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue } catch {}

Write-Host ""
Write-LeftAligned "$FGCyan Done.$Reset"

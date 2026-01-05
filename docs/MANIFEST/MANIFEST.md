# WinAuto System Impact Manifest

This document details the specific technical changes that the **WinAuto** suite makes to your Windows 11 system.

## 1. Security Configuration (`MODULE_Configuration.ps1`)

**Goal:** Harden system security according to Microsoft recommended baselines.

| Feature | Change | Technical Action |
| :--- | :--- | :--- |
| **Real-Time Protection** | **Enabled** | `Set-MpPreference -DisableRealtimeMonitoring $false` |
| **PUA Protection** | **Enabled** | `Set-MpPreference -PUAProtection Enabled` |
| **Core Isolation** | **Enabled** | Registry: `HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity` -> `Enabled = 1` |
| **LSA Protection** | **Enabled** | Registry: `HKLM\SYSTEM\CurrentControlSet\Control\Lsa` -> `RunAsPPL = 1` |
| **Stack Protection** | **Enabled** | Registry: `HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel` -> `KernelSEHOPEnabled = 1` |
| **SmartScreen (System)** | **Warn** | Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer` -> `SmartScreenEnabled = "Warn"` |
| **SmartScreen (Store)** | **Enabled** | Registry: `HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost` -> `EnableWebContentEvaluation = 1` |
| **Phishing Protection** | **Enabled** | `Set-MpPreference -EnablePhishingProtection Enabled` |
| **Firewall** | **Enabled** | `Set-NetFirewallProfile -Enabled True` (Domain, Private, Public) |

---

## 2. Windows Update (`C1_WindowsUpdate_SETnSCAN.ps1`)

**Goal:** Ensure updates are delivered reliably and automatically.

| Feature | Change | Technical Action |
| :--- | :--- | :--- |
| **Microsoft Updates** | **Enabled** | Registry: `HKLM\...\WindowsUpdate\UX\Settings` -> `AllowMUUpdateService = 1` |
| **Metered Connections** | **Allowed** | Registry: `HKLM\...\WindowsUpdate\UX\Settings` -> `AllowAutoWindowsUpdateDownloadOverMeteredNetwork = 1` |
| **Restart Notifications**| **Enabled** | Registry: `HKLM\...\WindowsUpdate\UX\Settings` -> `RestartNotificationsAllowed2 = 1` |
| **ARSO (Auto Login)** | **Enabled** | Registry: `HKLM\...\Winlogon\UserARSO\{SID}` -> `OptOut = 0` (Allows finishing setup after reboot) |
| **App Restart** | **Enabled** | Registry: `HKCU\...\Winlogon` -> `RestartApps = 1` |

---

## 3. System Maintenance (`MODULE_Maintenance.ps1`)

**Goal:** Repair system files and optimize performance.

| Action | Description | Technical Command |
| :--- | :--- | :--- |
| **System Repair** | Scan & Repair OS | `sfc /scannow` (and `DISM /RestoreHealth` if needed) |
| **Disk Optimization** | TRIM/Defrag | `Optimize-Volume -DriveLetter C -ReTrim` (SSD) or `-Defrag` (HDD) |
| **Cleanup** | Clear Temp Files | Delete files in `%TEMP%` and `%WINDIR%\Temp` |
| **Runtimes** | Install C++ Redist | `RUN_Install_CppRedist-WinAuto.ps1` (Installs latest x64/x86) |
| **Updates** | App Updates | `winget upgrade --all` |
| **Updates** | Store Updates | Automates Microsoft Store UI to click "Get updates" |
| **Updates** | OS Updates | Automates Settings UI to click "Check for updates" |

---

## 4. UI Optimization (`SET_VisualEffectsPerformance-WinAuto.ps1`)

**Goal:** Improve responsiveness by reducing animations.

| Feature | Change | Technical Action |
| :--- | :--- | :--- |
| **Visual Effects** | **Performance** | Registry: `HKCU\...\Explorer\VisualEffects` -> `VisualFXSetting = 2` |
| **Animations** | **Disabled** | Registry: `HKCU\...\Explorer\Advanced` -> `TaskbarAnimations = 0` |
| **Selection Fade** | **Disabled** | Registry: `HKCU\...\Explorer\Advanced` -> `ListviewAlphaSelect = 0` |

---

## 5. Optional / Manual Tools

These actions are **ONLY** performed if you manually run the specific scripts in `scripts\Library`.

| Script | Action | Impact |
| :--- | :--- | :--- |
| **C3_WindowsDebloat** | **Privacy** | Disables Advertising ID, Telemetry, and Tailored Experiences. |
| **RUN_RemoveBloatware**| **Debloat** | Removes pre-installed apps like Netflix, TikTok, Disney+, etc. |
| **C4_Network_FIXnSECURE**| **Network** | Resets Winsock/IP, Disables NetBIOS/LLMNR, Sets DNS to Cloudflare (1.1.1.1). |
| **SET_AlignTaskbarLeft** | **UI** | Moves Taskbar icons to the left (Registry: `TaskbarAl = 0`). |
| **SET_ClassicContextMenu**| **UI** | Restores Windows 10 right-click menu (Registry: `InprocServer32`). |
| **SET_PowerPlanHigh** | **Power** | Sets Power Plan to "High Performance". |

---
© 2026, www.AIIT.support. All Rights Reserved.

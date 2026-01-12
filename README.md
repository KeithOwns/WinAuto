# 🪟 WinAuto: Windows 11 Automation Suite

> **A standardized, modular PowerShell framework for system hardening, maintenance, and configuration.**

![Platform](https://img.shields.io/badge/Platform-Windows%2011-0078D6?style=flat-square)
![Language](https://img.shields.io/badge/Language-PowerShell%205.1%2B-5391FE?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)

## ⚡ Quick Install

Run in PowerShell (Admin):
```powershell
iex (irm https://raw.githubusercontent.com/KeithOwns/WinAuto/main/setup.ps1)
```

## 📖 What is WinAuto?

WinAuto is an enterprise-grade framework designed for reliability and idempotency. It is not just a "debloat" script but a comprehensive toolkit for:
*   **Security Hardening:** Enforcing Microsoft Security Baselines (Defender, Firewall, ASR).
*   **System Maintenance:** Automating updates via COM/WMI interfaces.
*   **App Deployment:** Silent installation of runtimes and core apps.
*   **Modular Design:** 50+ atomic scripts sharing a central logic engine.

## 🌟 Key Features

*   **🛡️ Production Safe:** Automated restore points and "safety fuse" timeouts allow for unattended runs with a bailout option.
*   **🔧 Advanced Automation:** Uses COM objects for Windows Updates and UI Automation for Settings/Store apps where APIs don't exist.
*   **🎨 Unified UX:** Shared UI kernel ensures consistent logging, error handling, and high-contrast visuals across all scripts.
*   **✅ Self-Validating:** Built-in CI-style linting checks for syntax, encoding, and privilege requirements.

## 📂 Structure

*   **`scripts/Main/`**: Entry points (Master Suites).
*   **`scripts/Library/`**: 50+ standalone atomic scripts (The Toolbox).
*   **`scripts/Shared/`**: Core engine, UI logic, and resources.

## 🚀 Usage

**Interactive Menu:**
Run `.\WinAuto.bat` to access the master control interface.

**Modular Execution:**
Any script in `scripts\Library` works independently:
```powershell
.\scripts\Library\C2_WindowsSecurity_CHECKnSETnSCAN.ps1
```

**Single-File Version:**
Copy/paste the content of `WinAuto_Standalone.ps1` into an Administrator PowerShell window for instant execution without files.

---
**WinAuto Team** | © 2026 AI+IT Support
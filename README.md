# WinAuto (Core Edition)

> **Enterprise-grade Windows 11 configuration management in a single, self-contained PowerShell file.**

![Version](https://img.shields.io/badge/version-2.1.0-blue) ![Platform](https://img.shields.io/badge/platform-Windows%2011-lightgray) ![License](https://img.shields.io/badge/license-MIT-green)

WinAuto is a lightweight, high-performance automation suite designed to streamline the configuration, security hardening, and maintenance of Windows 11 systems. It consolidates best-practice security settings, application management, and system maintenance into an interactive dashboard.

## 🚀 Key Features

-   **Interactive Dashboard:** A modern, arrow-key driven CLI interface for manual and automated operations.
-   **SmartRUN Automation:** Intelligent orchestration that audits system state and only applies changes where configuration drift is detected.
-   **Security Hardening:** Automates Microsoft Defender, Memory Integrity, Kernel Stack Protection, LSA Protection, App & browser control, and Windows Firewall.
-   **Application Management:** Config-driven installer supporting WinGet, MSI, and EXE with silent deployment.
-   **Automated Maintenance:** One-touch system repair (SFC/DISM), drive optimization, temp file cleanup, and suite updates.
-   **Suite Updates:** Integrated self-updater that pulls the latest version directly from GitHub (via Git or ZIP).
-   **UI Automation:** Robust handling of system settings and Windows Security app elements that cannot be managed via registry alone.

## 🛠️ Usage

1.  **Elevate:** Open a PowerShell window as **Administrator**.
2.  **Run:** Execute the script:
    ```powershell
    .\WinAuto.ps1
    ```
3.  **Navigate:** Use the `^` and `v` arrow keys to select sections.
4.  **Execute:** Press `Space` to run the selected section or `SmartRUN`.
5.  **Info:** Press `I` to view the functional outline. From the Info page, press `Enter` to export a technical CSV map or `Esc` to return to the dashboard.

## 📁 Project Structure

-   `WinAuto.ps1`: The primary script containing the dashboard and embedded logic.
-   `scripts/AtomicScripts/Installers/`: Atomic installation scripts called by the main suite.
-   `logs/`: Local execution logs (`wa.log`).

## 🛡️ Requirements

-   **Operating System:** Windows 11 (Build 22000+)
-   **Privileges:** Administrator
-   **Execution Policy:** Set to `RemoteSigned` (handled automatically by the script).

## ⚖️ Disclaimer

1.  **Test First:** Always run in a non-production environment first.
2.  **Back up:** Critical data should be backed up before running maintenance tasks.
3.  **Responsibility:** The authors are not responsible for any system instability or data loss.

---
*Maintained by KeithOwns | Open Source MIT License*

@echo off
:: Set UTF-8 encoding for Unicode characters
chcp 65001 >nul
cls

:: --- ANSI Color Variables ---
set "Esc="
set "Reset=%Esc%[0m"
set "Bold=%Esc%[1m"
set "FGCyan=%Esc%[96m"
set "FGDarkBlue=%Esc%[34m"
set "FGGreen=%Esc%[92m"
set "FGRed=%Esc%[91m"
set "FGYellow=%Esc%[93m"
set "FGWhite=%Esc%[97m"
set "FGGray=%Esc%[37m"
set "FGDarkGray=%Esc%[90m"
set "FGDarkGreen=%Esc%[32m"
set "FGDarkRed=%Esc%[31m"
set "FGDarkMagenta=%Esc%[35m"
set "BGDarkGray=%Esc%[100m"
set "BGYellow=%Esc%[103m"
set "BGCyan=%Esc%[106m"
set "BGGreen=%Esc%[102m"
set "BGRed=%Esc%[101m"
set "BGWhite=%Esc%[107m"
set "FGBlack=%Esc%[30m"

:: --- Line Variables ---
set "HLine=━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
set "LLine=────────────────────────────────────────────────────────────"
set "OLine=‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"

:: --- Header ---
echo.
echo                   %Bold%%FGCyan%➖WinAuto➖%Reset%
echo                %Bold%%FGCyan%SCRIPT OUTPUT RULES%Reset%
echo %FGDarkBlue%%HLine%%Reset%
echo            %FGCyan%─ Script Output LEGEND ─%Reset%
echo.
echo  %FGGray%      Color    ANSI   %FGBlack%%BGWhite% About  %Reset% %FGGray%Where   Default_String%Reset%
echo %FGDarkGray%%OLine%%Reset%

:: --- Rows ---
echo  %FGCyan%       Cyan \e[96m %FGBlack%%BGCyan% Script %Reset%  Hdr/Ftr     ➖WinAuto➖%Reset%
echo  %FGDarkBlue%   DarkBlue \e[34m %FGBlack%%BGDarkBlue% Script %Reset%  Lines       ━━━━━━━━━━━━%Reset%
echo  %FGGreen%      Green \e[92m %FGBlack%%BGGreen% Script %Reset%  Output      ✅ Success!%Reset%
echo  %FGRed%        Red \e[91m %FGBlack%%BGRed% Script %Reset%  Output      ❎ Failure!%Reset%
echo  %FGYellow%     Yellow \e[93m %FGBlack%%BGYellow% Script %Reset%  Input       %FGBlack%%BGYellow%☛ [Key]%Reset%
echo  %FGWhite%      White \e[97m ➖%FGWhite%BOLD%Reset%➖ Body            ➖%Reset%
echo  %FGGray%       Gray \e[37m %FGGray%%BGDarkGray% regular%Reset%  Body            -%Reset%
echo  %FGDarkGray%   DarkGray \e[90m %FGWhite%%BGDarkGray% System %Reset%  Lines       ────────────%Reset%
echo  %FGDarkGreen%  DarkGreen \e[32m %FGWhite%%FGDarkGreen% System %Reset%  Output      ☑  ENABLED%Reset%
echo  %FGDarkRed%    DarkRed \e[31m %FGWhite%%BGDarkRed% System %Reset%  Output      %FGDarkRed%❎ DISABLED%Reset%
echo  %FGDarkMagenta%    Magenta \e[95m %FGWhite%%Esc%[105m System %Reset%  Output      ⚠️  %Esc%[105mWARNING%Reset%

:: --- Footer ---
echo %FGDarkGray%%LLine%%Reset%
echo.
echo %FGDarkBlue%%HLine%%Reset%
echo.
echo            %FGCyan%© 2026, www.AIIT.support. All Rights Reserved.%Reset%

:: --- Final Exit Spacing (5 Lines) ---
echo.
echo.
echo.
echo.
echo.
pause >nul
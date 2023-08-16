::This script runs powershell scripts to download the required binaries to run the tiny11 Windows Creation Tool
@echo off
:: Check for admin privileges
net session >nul 2>&1
if %errorlevel% == 0 (
    goto :start
) else (
    echo Requesting elevation...
    :: Create a temporary VBScript file
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\elevate.vbs"
    :: Run the VBScript to prompt for elevation
    cscript //nologo "%temp%\elevate.vbs"
    exit /b
)

:start
cd %~dp0

:: Run the getNSudo and getOscdimg powershell scripts to download the required binaries
if not exist "%~dp0bin\nsudo.exe" (
    powershell -ExecutionPolicy Bypass -File "%~dp0bin\getNSudo.ps1"
)

if not exist "%~dp0bin\oscdimg.exe" (
    powershell -ExecutionPolicy Bypass -File "%~dp0bin\getOscdimg.ps1"
)

exit
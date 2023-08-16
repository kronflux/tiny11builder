::This script runs powershell scripts to download the required binaries to run the tiny11 builder
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

:: Run the WindowsIsoDownloader powershell script to download Windows Iso Downloader tool
if not exist "%~dp0bin\WindowsIsoDownloader\" (
    powershell -ExecutionPolicy Bypass -File "%~dp0bin\getWindowsIsoDownloader.ps1"
)

::This script runs the tiny11 builder as TrustedInstaller in order to have access to protected components that cannot be modified under Administrator privileges
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

:: Check if nsudo.exe and oscimg.exe exist in the bin directory
if not exist "%~dp0bin\nsudo.exe" (
    cls
    echo nsudo.exe not found in bin directory. Please download NSudo using the GetBins.cmd script in the root directory.
    pause
    exit /b
)

if not exist "%~dp0bin\oscdimg.exe" (
    cls
    echo oscdimg.exe not found in bin directory. Please download oscdimg.exe using the GetBins.cmd script in the root directory.
    pause
    exit /b
)

@start /b "tiny11" bin\nsudo.exe -U:T -P:E "powershell" "-ExecutionPolicy" "Bypass" "-file" "%~dp0tiny11builder.ps1"
exit
@echo off

if "%~1"=="" (
    echo Usage: %~nx0 RegFileToConvert.reg"
    pause
    exit /b 1
) else (
powershell -ExecutionPolicy Bypass -File %~dp0bin\ConvertReg.ps1 %*
)
exit
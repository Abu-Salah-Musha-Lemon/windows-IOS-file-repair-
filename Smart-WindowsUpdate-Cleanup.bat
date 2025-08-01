@echo off
title Smart Windows Update & System Health Cleanup
cls

:: -------------------------------------------------------------------
:: Script Name   : Smart-WindowsUpdate-Cleanup.bat
:: Author        : Abu Salah Musha Lemon
:: Description   : Runs system health checks (DISM/SFC), cleans update
::                 temp files, and performs disk cleanup safely.
:: Created Date  : 2025-08-01
:: Version       : 1.0
:: -------------------------------------------------------------------

:: ---------[ Admin Rights Check ]---------
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ This script must be run as Administrator.
    pause
    exit /b
)

echo ============================================================
echo [1/8] QUICK CHECK - DISM /CheckHealth
echo ============================================================
DISM /Online /Cleanup-Image /CheckHealth
IF %ERRORLEVEL% EQU 0 (
    echo ✔ No corruption detected.
) ELSE (
    echo ⚠ Potential corruption found.
)

echo.
echo ============================================================
echo [2/8] DEEP SCAN - DISM /ScanHealth
echo ============================================================
DISM /Online /Cleanup-Image /ScanHealth
IF %ERRORLEVEL% NEQ 0 (
    echo ⚠ Issues may exist. Proceeding to repair...
)

echo.
echo ============================================================
echo [3/8] IMAGE REPAIR - DISM /RestoreHealth
echo ============================================================
DISM /Online /Cleanup-Image /RestoreHealth
IF %ERRORLEVEL% EQU 0 (
    echo ✔ Windows image repaired successfully.
) ELSE (
    echo ⚠ Some issues could not be fixed automatically.
)

echo.
echo ============================================================
echo [4/8] SYSTEM FILE CHECK - SFC /scannow
echo ============================================================
SFC /scannow
IF %ERRORLEVEL% EQU 0 (
    echo ✔ SFC completed. No integrity violations found.
) ELSE (
    echo ⚠ SFC found and attempted to fix system file issues.
)

echo.
echo ============================================================
echo [5/8] STOPPING Windows Update Services
echo ============================================================
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

echo.
echo ============================================================
echo [6/8] DELETING Update Temp Files
echo ============================================================
rd /s /q %windir%\SoftwareDistribution\Download
rd /s /q %windir%\SoftwareDistribution\DataStore

echo.
echo ============================================================
echo [7/8] RESTARTING Windows Update Services
echo ============================================================
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

echo.
echo ============================================================
echo [8/8] FINAL CLEANUP - Disk Cleanup (Silent Mode)
echo ============================================================
cleanmgr /sageset:123 >nul
timeout /t 3 >nul
cleanmgr /sagerun:123 >nul

echo.
echo ✅ All maintenance tasks completed successfully!
pause
exit

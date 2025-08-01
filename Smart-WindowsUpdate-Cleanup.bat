@echo off
title Smart Windows Update & System Health Cleanup
cls

:: ---------[ Header Information ]---------
echo =============================================================
echo        SMART WINDOWS UPDATE & SYSTEM HEALTH CLEANUP
echo =============================================================
echo  Script Name : Smart-WindowsUpdate-Cleanup.bat
echo  Author      : Abu Salah Musha Lemon
echo  Created     : August 1, 2025
echo  Version     : 1.0
echo  Description : This script repairs Windows image, checks system
echo                file integrity, clears Windows Update cache,
echo                and runs disk cleanup silently.
echo =============================================================
echo.

:: ---------[ Admin Rights Check ]---------
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ This script must be run as Administrator.
    pause
    exit /b
)

:: ---------[ 1. DISM - CheckHealth ]---------
echo =============================================================
echo [1/8] QUICK CHECK - DISM /CheckHealth
echo =============================================================
DISM /Online /Cleanup-Image /CheckHealth

:: ---------[ 2. DISM - ScanHealth ]---------
echo.
echo =============================================================
echo [2/8] DEEP SCAN - DISM /ScanHealth
echo =============================================================
DISM /Online /Cleanup-Image /ScanHealth

:: ---------[ 3. DISM - RestoreHealth ]---------
echo.
echo =============================================================
echo [3/8] IMAGE REPAIR - DISM /RestoreHealth
echo =============================================================
DISM /Online /Cleanup-Image /RestoreHealth

:: ---------[ 4. SFC - System File Check ]---------
echo.
echo =============================================================
echo [4/8] SYSTEM FILE CHECK - SFC /scannow
echo =============================================================
SFC /scannow

:: ---------[ 5. Stop Update Services ]---------
echo.
echo =============================================================
echo [5/8] STOPPING Windows Update Services
echo =============================================================
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

:: ---------[ 6. Delete Update Temp Files ]---------
echo.
echo =============================================================
echo [6/8] DELETING Update Temp Files
echo =============================================================
rd /s /q %windir%\SoftwareDistribution\Download
rd /s /q %windir%\SoftwareDistribution\DataStore

:: ---------[ 7. Restart Update Services ]---------
echo.
echo =============================================================
echo [7/8] RESTARTING Windows Update Services
echo =============================================================
net start wuauserv >nul 2>&1
net start bits >nul 2>&1

:: ---------[ 8. Disk Cleanup ]---------
echo.
echo =============================================================
echo [8/8] FINAL CLEANUP - Disk Cleanup (Silent)
echo =============================================================
cleanmgr /sageset:123 >nul
timeout /t 3 >nul
cleanmgr /sagerun:123 >nul

echo.
echo =============================================================
echo ✅ All tasks completed successfully. Your system is now clean.
echo =============================================================
pause
exit

@echo off
:: ============================================================================
:: FILE        : Smart-WindowsUpdate-Cleanup.bat
:: AUTHOR      : Abu Salah Musha Lemon
:: DATE        : 01 August 2025
:: VERSION     : 1.0
:: DESCRIPTION : A Windows maintenance script that performs the following:
::               - Checks Windows image health (DISM)
::               - Repairs Windows image if needed
::               - Verifies system file integrity (SFC)
::               - Stops Windows Update services
::               - Clears SoftwareDistribution temp files
::               - Restarts update services
::               - Runs Disk Cleanup in silent mode
::
:: USAGE       : Run as Administrator
:: ============================================================================
cls
title Smart Windows Update and System Health Cleanup

:: ----------------------------- Header Display ------------------------------
echo ============================================================================
echo                  SMART WINDOWS UPDATE AND SYSTEM HEALTH CLEANUP
echo ============================================================================
echo  Script Name : Smart-WindowsUpdate-Cleanup.bat
echo  Author      : Abu Salah Musha Lemon
echo  Created     : August 1, 2025
echo  Version     : 1.0
echo  Description : Repair system health, clear update temp files,
echo                and run disk cleanup automatically.
echo ============================================================================
echo.

:: --------------------------- Admin Privileges Check ------------------------
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ This script must be run as Administrator.
    pause
    exit /b
)

:: --------------------------- DISM CheckHealth ------------------------------
echo [1/8] Checking Windows image health...
DISM /Online /Cleanup-Image /CheckHealth
echo.

:: --------------------------- DISM ScanHealth -------------------------------
echo [2/8] Scanning for deeper issues in Windows image...
DISM /Online /Cleanup-Image /ScanHealth
echo.

:: --------------------------- DISM RestoreHealth ----------------------------
echo [3/8] Repairing the Windows image (if needed)...
DISM /Online /Cleanup-Image /RestoreHealth
echo.

:: --------------------------- SFC Scan --------------------------------------
echo [4/8] Verifying system file integrity...
SFC /scannow
echo.

:: --------------------------- Stop Update Services --------------------------
echo [5/8] Stopping Windows Update-related services...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
echo Services stopped.
echo.

:: --------------------------- Delete Update Cache ---------------------------
echo [6/8] Deleting SoftwareDistribution cache files...
rd /s /q %windir%\SoftwareDistribution\Download
rd /s /q %windir%\SoftwareDistribution\DataStore
echo Cache deleted.
echo.

:: --------------------------- Restart Update Services -----------------------
echo [7/8] Restarting Windows Update services...
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
echo Services restarted.
echo.

:: --------------------------- Disk Cleanup ----------------------------------
echo [8/8] Running Disk Cleanup silently...
cleanmgr /sageset:123 >nul
timeout /t 3 >nul
cleanmgr /sagerun:123 >nul
echo Disk cleanup completed.
echo.

:: --------------------------- End of Script ---------------------------------
echo ============================================================================
echo ✅ All tasks completed successfully.
echo You may now close this window or restart your PC if prompted.
echo ============================================================================
pause
exit

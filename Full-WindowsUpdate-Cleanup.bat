@echo off
:: Elevate to admin if not already
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Please run this script as Administrator.
    pause
    exit
)

echo ========================================
echo [1/8] Checking Windows Image Health...
echo ========================================
DISM /Online /Cleanup-Image /CheckHealth

echo ========================================
echo [2/8] Scanning Windows Image Health...
echo ========================================
DISM /Online /Cleanup-Image /ScanHealth

echo ========================================
echo [3/8] Restoring Windows Image Health...
echo ========================================
DISM /Online /Cleanup-Image /RestoreHealth

echo ========================================
echo [4/8] Running System File Checker...
echo ========================================
SFC /scannow

echo ========================================
echo [5/8] Stopping Windows Update Services...
echo ========================================
net stop wuauserv >nul
net stop bits >nul

echo ========================================
echo [6/8] Deleting Windows Update Temp Files...
echo ========================================
rd /s /q %windir%\SoftwareDistribution\Download
rd /s /q %windir%\SoftwareDistribution\DataStore

echo ========================================
echo [7/8] Starting Windows Update Services...
echo ========================================
net start wuauserv >nul
net start bits >nul

echo ========================================
echo [8/8] Running Disk Cleanup...
echo ========================================
cleanmgr /sageset:123 >nul
timeout /t 3 >nul
cleanmgr /sagerun:123 >nul

echo ========================================
echo ✅ All maintenance tasks completed!
pause
exit

@echo off
:: ============================================================================
:: FILE        : Smart-WindowsUpdate-Cleanup.bat
:: AUTHOR      : Abu Salah Musha Lemon
:: DATE        : 01 August 2025
:: VERSION     : 2.0
:: DESCRIPTION : A Windows maintenance script that performs the following:
::               - Checks Windows image health (DISM)
::               - Repairs Windows image if needed
::               - Verifies system file integrity (SFC)
::               - Runs DISM Component Store cleanup (frees several GB)
::               - Stops ALL relevant Windows Update services
::               - Clears SoftwareDistribution temp files safely
::               - Restarts update services
::               - Runs Disk Cleanup in fully unattended/silent mode
::               - Detects reboot requirement after SFC
::               - Logs all output to a timestamped log file
::
:: USAGE       : Run as Administrator
:: CHANGES     : v2.0 - Added error handling, logging, cryptsvc/msiserver,
::               component cleanup, unattended disk cleanup, reboot detection
:: ============================================================================

setlocal EnableDelayedExpansion
cls
title Smart Windows Update and System Health Cleanup v2.0

:: ========================= LOG FILE SETUP ==================================
set "LOG_DIR=%~dp0Logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Build a safe timestamp (avoids slashes and colons in filenames)
for /f "tokens=1-3 delims=/" %%a in ("%DATE%") do (
    set "DD=%%a"
    set "MM=%%b"
    set "YYYY=%%c"
)
for /f "tokens=1-3 delims=:." %%a in ("%TIME: =0%") do (
    set "HH=%%a"
    set "MIN=%%b"
    set "SS=%%c"
)
set "TIMESTAMP=%YYYY%-%MM%-%DD%_%HH%-%MIN%-%SS%"
set "LOGFILE=%LOG_DIR%\Cleanup_%TIMESTAMP%.log"

:: All output goes to both console and log file
call :LOG "============================================================================"
call :LOG "         SMART WINDOWS UPDATE AND SYSTEM HEALTH CLEANUP  v2.0"
call :LOG "============================================================================"
call :LOG " Script Name : Smart-WindowsUpdate-Cleanup.bat"
call :LOG " Author      : Abu Salah Musha Lemon"
call :LOG " Version     : 2.0"
call :LOG " Log File    : %LOGFILE%"
call :LOG " Started At  : %DATE% %TIME%"
call :LOG "============================================================================"
call :LOG ""

:: ========================= ADMIN CHECK =====================================
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    call :LOG "[ERROR] This script must be run as Administrator. Exiting."
    pause
    exit /b 1
)
call :LOG "[OK] Administrator privileges confirmed."
call :LOG ""

:: ========================= STEP 1: DISM CheckHealth ========================
call :LOG "[1/9] Checking Windows image health..."
DISM /Online /Cleanup-Image /CheckHealth >> "%LOGFILE%" 2>&1
call :CHECKERR %ERRORLEVEL% "DISM CheckHealth"
call :LOG ""

:: ========================= STEP 2: DISM ScanHealth =========================
call :LOG "[2/9] Scanning for deeper issues in Windows image..."
DISM /Online /Cleanup-Image /ScanHealth >> "%LOGFILE%" 2>&1
call :CHECKERR %ERRORLEVEL% "DISM ScanHealth"
call :LOG ""

:: ========================= STEP 3: DISM RestoreHealth ======================
call :LOG "[3/9] Repairing the Windows image (if needed)..."
call :LOG "      Note: Requires internet access. May take several minutes."
DISM /Online /Cleanup-Image /RestoreHealth >> "%LOGFILE%" 2>&1
set "DISM_ERR=%ERRORLEVEL%"
if %DISM_ERR% NEQ 0 (
    call :LOG "[WARNING] DISM RestoreHealth returned error code %DISM_ERR%."
    call :LOG "          Image repair may be incomplete. Check log for details."
    call :LOG "          Continuing with remaining steps..."
) else (
    call :LOG "[OK] DISM RestoreHealth completed successfully."
)
call :LOG ""

:: ========================= STEP 4: DISM Component Cleanup ==================
call :LOG "[4/9] Cleaning up Component Store (reclaims significant disk space)..."
DISM /Online /Cleanup-Image /StartComponentCleanup >> "%LOGFILE%" 2>&1
call :CHECKERR %ERRORLEVEL% "DISM Component Cleanup"
call :LOG ""

:: ========================= STEP 5: SFC Scan =================================
call :LOG "[5/9] Verifying system file integrity (SFC)..."
call :LOG "      Note: May take several minutes. Please wait."
SFC /scannow >> "%LOGFILE%" 2>&1
set "SFC_ERR=%ERRORLEVEL%"
:: SFC exit codes: 0=no violations, 1=repairs made, 2=could not perform, 3=found but couldn't fix
if %SFC_ERR% EQU 0 (
    call :LOG "[OK] SFC found no integrity violations."
) else if %SFC_ERR% EQU 1 (
    call :LOG "[OK] SFC found and repaired integrity violations. A REBOOT IS RECOMMENDED."
    set "REBOOT_NEEDED=1"
) else if %SFC_ERR% EQU 2 (
    call :LOG "[WARNING] SFC could not perform the requested operation."
) else if %SFC_ERR% EQU 3 (
    call :LOG "[WARNING] SFC found integrity violations it could NOT fix. Run DISM RestoreHealth again, then re-run SFC."
) else (
    call :LOG "[WARNING] SFC returned unexpected code: %SFC_ERR%"
)
call :LOG ""

:: ========================= STEP 6: Stop ALL Update Services ================
call :LOG "[6/9] Stopping all Windows Update-related services..."
net stop wuauserv    >> "%LOGFILE%" 2>&1
net stop bits        >> "%LOGFILE%" 2>&1
net stop cryptsvc    >> "%LOGFILE%" 2>&1
net stop msiserver   >> "%LOGFILE%" 2>&1
call :LOG "[OK] Services stopped (wuauserv, bits, cryptsvc, msiserver)."
call :LOG ""

:: ========================= STEP 7: Clear Update Cache ======================
call :LOG "[7/9] Clearing SoftwareDistribution cache..."

:: Safely delete Download folder
if exist "%windir%\SoftwareDistribution\Download" (
    rd /s /q "%windir%\SoftwareDistribution\Download" >> "%LOGFILE%" 2>&1
    call :LOG "      Deleted: SoftwareDistribution\Download"
) else (
    call :LOG "      Skipped: SoftwareDistribution\Download (not found)"
)

:: Safely delete DataStore folder
if exist "%windir%\SoftwareDistribution\DataStore" (
    rd /s /q "%windir%\SoftwareDistribution\DataStore" >> "%LOGFILE%" 2>&1
    call :LOG "      Deleted: SoftwareDistribution\DataStore"
) else (
    call :LOG "      Skipped: SoftwareDistribution\DataStore (not found)"
)

:: Recreate the Download folder so Windows doesn't have to
if not exist "%windir%\SoftwareDistribution\Download" (
    mkdir "%windir%\SoftwareDistribution\Download" >> "%LOGFILE%" 2>&1
    call :LOG "      Recreated: SoftwareDistribution\Download"
)

call :LOG "[OK] Cache cleanup complete."
call :LOG ""

:: ========================= STEP 8: Restart ALL Update Services =============
call :LOG "[8/9] Restarting Windows Update services..."
net start wuauserv    >> "%LOGFILE%" 2>&1
net start bits        >> "%LOGFILE%" 2>&1
net start cryptsvc    >> "%LOGFILE%" 2>&1
net start msiserver   >> "%LOGFILE%" 2>&1
call :LOG "[OK] Services restarted (wuauserv, bits, cryptsvc, msiserver)."
call :LOG ""

:: ========================= STEP 9: Silent Disk Cleanup =====================
call :LOG "[9/9] Configuring and running fully silent Disk Cleanup..."

:: Pre-configure all disk cleanup categories via registry (no GUI needed)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders"      /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\BranchCache"                    /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files"       /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files"           /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files"              /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files"               /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations"         /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin"                    /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Service Pack Cleanup"           /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files"                /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files" /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files"    /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files"                /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files"          /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache"                /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup"                 /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files"        /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\User file versions"             /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender"               /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Files"  /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files" /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files"      /v StateFlags0123 /t REG_DWORD /d 2 /f >> "%LOGFILE%" 2>&1

call :LOG "      Registry cleanup flags set. Running cleanmgr silently..."
cleanmgr /sagerun:123 >> "%LOGFILE%" 2>&1
call :LOG "[OK] Disk Cleanup completed."
call :LOG ""

:: ========================= SUMMARY =========================================
call :LOG "============================================================================"
call :LOG " CLEANUP SUMMARY"
call :LOG "============================================================================"
call :LOG " Finished At : %DATE% %TIME%"
call :LOG " Log saved to: %LOGFILE%"
call :LOG ""

if defined REBOOT_NEEDED (
    call :LOG " [!] REBOOT REQUIRED: SFC made repairs that require a system restart."
    call :LOG "     Please restart your PC to complete the process."
    echo.
    echo  ============================================================
    echo   ACTION REQUIRED: Please restart your PC.
    echo   SFC repaired system files that need a reboot to take effect.
    echo  ============================================================
    echo.
    choice /C YN /M "Restart now? (Y=Yes, N=No)"
    if !ERRORLEVEL! EQU 1 (
        call :LOG " User chose to restart now."
        shutdown /r /t 15 /c "Restarting to complete system file repairs."
    ) else (
        call :LOG " User chose to restart later."
    )
) else (
    call :LOG " All tasks completed. No reboot required."
    echo.
    echo  All tasks completed successfully. No reboot required.
)

call :LOG "============================================================================"
echo.
echo  Log file saved to:
echo  %LOGFILE%
echo.
pause
exit /b 0

:: ========================= HELPER SUBROUTINES ==============================

:: :LOG - Write a message to both console and log file
:LOG
set "MSG=%~1"
echo %MSG%
echo %MSG% >> "%LOGFILE%"
goto :eof

:: :CHECKERR - Check ERRORLEVEL and log pass/fail
:CHECKERR
set "ERRCODE=%~1"
set "STEPNAME=%~2"
if "%ERRCODE%" NEQ "0" (
    call :LOG "[WARNING] %STEPNAME% returned error code %ERRCODE%. Check log for details."
) else (
    call :LOG "[OK] %STEPNAME% completed successfully."
)
goto :eof

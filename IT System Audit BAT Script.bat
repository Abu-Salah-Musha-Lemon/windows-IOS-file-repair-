@echo off
:: ============================================================================
:: FILE        : System Audit Only.bat
:: AUTHOR      : Abu Salah Musha Lemon
:: DATE        : 16 February 2026
:: VERSION     : 1.0
:: DESCRIPTION : Collects full system audit report including:
::               - OS Name & Version
::               - CPU, RAM, GPU
::               - Motherboard
::               - Storage Drives
::               - Network Adapters
::               - BIOS / UEFI
::               - Monitor Information
::               - Security Information (Firewall, Defender, Secure Boot, TPM)
:: USAGE       : Run as Administrator
:: ============================================================================
cls
title Full System Audit Tool
color 0A

:: Set report path
set Report=%USERPROFILE%\Desktop\Full_System_Audit_Report.txt

echo ========================================= > "%Report%"
echo Full System Audit Report - %date% %time% >> "%Report%"
echo ========================================= >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: OS Information
:: ==============================
echo [OS Information] >> "%Report%"
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: CPU Information
:: ==============================
echo [CPU Information] >> "%Report%"
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: RAM Information
:: ==============================
echo [RAM Information] >> "%Report%"
wmic memorychip get BankLabel, Capacity, Speed, Manufacturer /format:list >> "%Report%"
for /f "tokens=2 delims==" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do set TotalRAM=%%a
set /a TotalRAMMB=%TotalRAM:~0,-6%
echo Total RAM: %TotalRAMMB% MB >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: GPU Information
:: ==============================
echo [GPU Information] >> "%Report%"
wmic path win32_VideoController get Name,AdapterRAM,DriverVersion /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: Motherboard
:: ==============================
echo [Motherboard] >> "%Report%"
wmic baseboard get Product,Manufacturer,SerialNumber /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: Storage Drives
:: ==============================
echo [Storage Drives] >> "%Report%"
wmic diskdrive get Model,Size,MediaType,Status /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: Network Adapters
:: ==============================
echo [Network Adapters] >> "%Report%"
wmic nic where "NetEnabled=true" get Name,MACAddress,Speed /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: BIOS / UEFI
:: ==============================
echo [BIOS / UEFI Information] >> "%Report%"
wmic bios get Manufacturer,SMBIOSBIOSVersion,ReleaseDate /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: Monitor Information
:: ==============================
echo [Monitor Information] >> "%Report%"
wmic desktopmonitor get Name,ScreenHeight,ScreenWidth,MonitorType /format:list >> "%Report%"
echo. >> "%Report%"

:: ==============================
:: Security Information
:: ==============================
echo [Security Information] >> "%Report%"
netsh advfirewall show allprofiles state >> "%Report%"
powershell -Command "Get-MpComputerStatus | Select AntivirusEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated | Format-List" >> "%Report%"
powershell -Command "Confirm-SecureBootUEFI" >> "%Report%"
powershell -Command "Get-Tpm | Format-List" >> "%Report%"
echo. >> "%Report%"

:: ==============================
echo ========================================= >> "%Report%"
echo System Audit Completed! >> "%Report%"
echo Report saved to Desktop as Full_System_Audit_Report.txt >> "%Report%"
echo ========================================= >> "%Report%"

echo.
echo System Audit Completed!
echo Report saved to Desktop:
echo %Report%
pause

@echo off
title System Audit
color 0A

set Report=%USERPROFILE%\Desktop\Client_System_Report.txt

echo ========================================= > "%Report%"
echo System Audit Report - %date% %time% >> "%Report%"
echo ========================================= >> "%Report%"
echo. >> "%Report%"

:: OS Info
echo [OS Information] >> "%Report%"
systeminfo | findstr /B /C:"OS Name" /C:"OS Version" >> "%Report%"
echo. >> "%Report%"

:: CPU Info
echo [CPU Information] >> "%Report%"
wmic cpu get Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed /format:list >> "%Report%"
echo. >> "%Report%"

:: RAM Info
echo [RAM Information] >> "%Report%"
wmic memorychip get BankLabel, Capacity, Speed, Manufacturer /format:list >> "%Report%"
for /f "tokens=2 delims==" %%a in ('wmic computersystem get TotalPhysicalMemory /value') do set TotalRAM=%%a
set /a TotalRAMMB=%TotalRAM:~0,-6%
echo Total RAM: %TotalRAMMB% MB >> "%Report%"
echo. >> "%Report%"

:: GPU Info
echo [GPU Information] >> "%Report%"
wmic path win32_VideoController get Name,AdapterRAM,DriverVersion /format:list >> "%Report%"
echo. >> "%Report%"

:: Motherboard
echo [Motherboard] >> "%Report%"
wmic baseboard get Product,Manufacturer,SerialNumber /format:list >> "%Report%"
echo. >> "%Report%"

:: Storage Drives
echo [Storage Drives] >> "%Report%"
wmic diskdrive get Model,Size,MediaType,Status /format:list >> "%Report%"
echo. >> "%Report%"

:: Network Adapters
echo [Network Adapters] >> "%Report%"
wmic nic where "NetEnabled=true" get Name,MACAddress,Speed /format:list >> "%Report%"
echo. >> "%Report%"

:: BIOS
echo [BIOS Information] >> "%Report%"
wmic bios get Manufacturer,SMBIOSBIOSVersion,ReleaseDate /format:list >> "%Report%"
echo. >> "%Report%"

:: Monitor
echo [Monitor Information] >> "%Report%"
wmic desktopmonitor get Name,ScreenHeight,ScreenWidth,MonitorType /format:list >> "%Report%"
echo. >> "%Report%"

:: Security Info
echo [Security Information] >> "%Report%"
:: Firewall Status
netsh advfirewall show allprofiles state >> "%Report%"
:: Defender Status
powershell -Command "Get-MpComputerStatus | Select AntivirusEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated | Format-List" >> "%Report%"
:: Secure Boot
powershell -Command "Confirm-SecureBootUEFI" >> "%Report%"
echo. >> "%Report%"

echo ========================================= >> "%Report%"
echo Audit Complete! Report saved to Desktop as Client_System_Report.txt >> "%Report%"
echo ========================================= >> "%Report%"

echo.
echo Audit completed! Report saved to Desktop:
echo %Report%
pause

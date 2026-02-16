@echo off
:: ====================================================================
:: FILE        : System_Audit.bat
:: AUTHOR      : Abu Salah Musha Lemon
:: DATE        : 16 February 2026
:: VERSION     : 2.1
:: DESCRIPTION : Full System Audit Report 
:: ====================================================================
cls
title Full System Audit Tool
color 0A

:: ------------------------------
:: Set report file
:: ------------------------------
set "Report=%USERPROFILE%\Desktop\Full_System_Audit_Report.txt"

:: ------------------------------
:: Create header in UTF-8
:: ------------------------------
powershell -NoProfile -Command ^
"$Report = '%Report%'; ^
Set-Content -LiteralPath $Report -Value ('=========================================' + [Environment]::NewLine + 'Full System Audit Report - ' + (Get-Date) + [Environment]::NewLine + '=========================================') -Encoding UTF8"

:: ==============================
:: OS Information
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[OS Information]'"
powershell -Command "Get-CimInstance Win32_OperatingSystem | Select-Object Caption, Version | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: CPU Information
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[CPU Information]'"
powershell -Command "Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: RAM Information
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[RAM Information]'"
powershell -Command "Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel, Manufacturer, Capacity, Speed | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"
powershell -Command ^
"$TotalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / (1024*1024); ^
Add-Content -LiteralPath '%Report%' -Value ('Total RAM: {0:N0} MB' -f $TotalRAM)"

:: ==============================
:: GPU Information
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[GPU Information]'"
powershell -Command "Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: Motherboard
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[Motherboard]'"
powershell -Command "Get-CimInstance Win32_BaseBoard | Select-Object Product, Manufacturer, SerialNumber | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: Storage Drives
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[Storage Drives]'"
powershell -Command "Get-CimInstance Win32_DiskDrive | Select-Object Model, MediaType, Size, Status | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: Network Adapters
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[Network Adapters]'"
powershell -Command "Get-CimInstance Win32_NetworkAdapter | Where-Object {$_.NetEnabled -eq $true} | Select-Object Name, MACAddress, Speed | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: BIOS / UEFI
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[BIOS / UEFI Information]'"
powershell -Command "Get-CimInstance Win32_BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: Monitor Information
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[Monitor Information]'"
powershell -Command "Get-CimInstance Win32_VideoController | Select-Object Name, CurrentHorizontalResolution, CurrentVerticalResolution | Format-List | Out-String | Add-Content -LiteralPath '%Report%'"

:: ==============================
:: Security Information
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '[Security Information]'"
powershell -Command "netsh advfirewall show allprofiles state | Out-String | Add-Content -LiteralPath '%Report%'"

:: Windows Defender (if installed)
powershell -Command ^
"if (Get-Command 'Get-MpComputerStatus' -ErrorAction SilentlyContinue) { ^
    Get-MpComputerStatus | Select-Object AntivirusEnabled, RealTimeProtectionEnabled, AntivirusSignatureLastUpdated | Format-List | Out-String | Add-Content -LiteralPath '%Report%' ^
} else { Add-Content -LiteralPath '%Report%' 'Windows Defender not installed or unavailable.' }"

:: Secure Boot
powershell -Command ^
"try { Confirm-SecureBootUEFI | Out-String | Add-Content -LiteralPath '%Report%' } ^
catch { Add-Content -LiteralPath '%Report%' -Value 'Secure Boot not supported on this system.' }"

:: TPM
powershell -Command ^
"if (Get-Command 'Get-Tpm' -ErrorAction SilentlyContinue) { Get-Tpm | Format-List | Out-String | Add-Content -LiteralPath '%Report%' } ^
else { Add-Content -LiteralPath '%Report%' -Value 'TPM not available.' }"

:: ==============================
:: Done
:: ==============================
powershell -Command "Add-Content -LiteralPath '%Report%' -Value '=========================================`nSystem Audit Completed!`nReport saved to Desktop as Full_System_Audit_Report.txt`n========================================='"

echo.
echo Full System Audit Completed!
echo Report saved to Desktop:
echo %Report%
pause

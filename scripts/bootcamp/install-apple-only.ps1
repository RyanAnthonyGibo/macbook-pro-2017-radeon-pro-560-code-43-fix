# install-apple-only.ps1 - Apple-only Boot Camp 6.1.6851 install for MacBookPro14,3 (A1707). RUN AS ADMIN.
# Needs C:\Setup\bootcamp61 prepared with build-apple-only-msi.ps1 (Apple files only, no AMD folder).
# Never uninstalls anything. Never touches the AMD/Radeon display driver (only reads its info before/after).
$ErrorActionPreference='Continue'
$d='C:\Setup\bootcamp61'; $a="$d\BootCamp\Drivers\Apple"; $wp="$d\`$WinPEDriver`$"
$ts=Get-Date -f yyyyMMdd-HHmmss; $L="$d\logs-$ts"; New-Item $L -ItemType Directory -Force | Out-Null
Start-Transcript "$L\install.log"
# Locale-independent admin check ('Administrators' by name fails on pt-BR Windows)
if(-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){ Write-Host 'Run as Administrator.'; Stop-Transcript; exit 1 }
if(Get-ChildItem $d -Recurse -File | ? { $_.Name -match '^(amd|ati)|radeon' }){ Write-Host 'AMD file found - aborting'; Stop-Transcript; exit 2 }
# 1) Read-only display snapshot
Get-PnpDevice -Class Display | Format-List * | Out-File "$L\display-before.txt"
Get-CimInstance Win32_VideoController | Format-List Name,DriverVersion,InfFilename,Status | Out-File "$L\display-before.txt" -Append
# 2) Backup current Apple drivers
$bk="$L\driver-backup"; New-Item $bk -ItemType Directory -Force | Out-Null
Get-CimInstance Win32_PnPSignedDriver | ? { $_.DriverProviderName -match 'Apple' -and $_.InfName -like 'oem*.inf' } | Select -Expand InfName -Unique | % { pnputil /export-driver $_ $bk }
pnputil /enum-drivers > "$L\drivers-before.txt"
# 3) Pause watchdog, stop Bootcamp.exe so files can be replaced
schtasks /change /tn A1707-TrackpadWatchdog /disable
Get-Process Bootcamp,AppleControlPanel -EA 0 | Stop-Process -Force
# 4) Boot Camp Services (Apple-only MSI copy)
$p=Start-Process msiexec.exe -ArgumentList "/i `"$a\BootCampAppleOnly.msi`" /qn /norestart /l*v `"$L\msi.log`"" -Wait -PassThru
Write-Host "msiexec exit: $($p.ExitCode)"
# 5) Apple SPI / T1 drivers
foreach($i in 'AppleSPITrackpad\AppleSPITrackpad.inf','AppleSPIDevice\AppleSPIDevice.inf','AppleSPIKeyboard\AppleSPIKeyboard.inf','AppleUSBCompositeDevice64\AppleUSBCompositeDevice.inf'){ pnputil /add-driver "$wp\$i" /install }
# 6) Fast Startup off
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' HiberbootEnabled 0 -Type DWord
# 7) After snapshot
pnputil /enum-drivers > "$L\drivers-after.txt"
Get-CimInstance Win32_VideoController | Format-List Name,DriverVersion,InfFilename,Status | Out-File "$L\display-after.txt"
Get-Service KeyAgent,MacHALDriver,AppleOSSMgr -EA 0 | ft Name,Status,StartType -a
schtasks /change /tn A1707-TrackpadWatchdog /enable
Write-Host "Done. Logs: $L  -> reboot Windows."
Stop-Transcript

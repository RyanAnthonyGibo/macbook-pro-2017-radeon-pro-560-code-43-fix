<#
 bootcamp-reapply.ps1 - Re-apply Boot Camp trackpad settings (tap to click, secondary click / right click)
 at every logon and make sure the Boot Camp tray app (Bootcamp.exe, needed by Touch Bar / ESC) is running.
 Boot Camp stores trackpad options only in HKCU\Software\Apple Inc.\Trackpad\Mode (DWORD, undocumented bits),
 which can get lost after a reboot.
 Author: Ryan Anthony Gibo - MIT License. Use at your own risk.

 1. Set your options in C:\Windows\System32\AppleControlPanel.exe -> Trackpad.
 2. Read your value:  (Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode   (e.g. 40)
 3. Run:  powershell -ExecutionPolicy Bypass -File bootcamp-reapply.ps1 -Mode 40
#>
param(
  [Parameter(Mandatory = $true)][int]$Mode,
  [int]$WheelScrollLines = 0   # optional: e.g. 1 if two-finger scroll is too fast (0 = leave unchanged)
)
$key = 'HKCU:\Software\Apple Inc.\Trackpad'
if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
Set-ItemProperty -Path $key -Name Mode -Value $Mode -Type DWord

if ($WheelScrollLines -gt 0) {
  Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WheelScrollLines -Value "$WheelScrollLines"
  Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool SystemParametersInfo(uint a, uint b, System.IntPtr c, uint d);'
  [W.U]::SystemParametersInfo(0x69, [uint32]$WheelScrollLines, [IntPtr]::Zero, 3) | Out-Null  # SPI_SETWHEELSCROLLLINES
}

$exe = Join-Path $env:WINDIR 'System32\Bootcamp.exe'
if (-not (Test-Path $exe)) { $exe = 'C:\Program Files\Boot Camp\Bootcamp.exe' }
for ($i = 1; $i -le 5; $i++) {
  Get-Process Bootcamp -ErrorAction SilentlyContinue | Stop-Process -Force
  Start-Sleep -Seconds 2
  Start-Process $exe
  Start-Sleep -Seconds 3
  if (Get-Process Bootcamp -ErrorAction SilentlyContinue) { Write-Output "Bootcamp.exe running (try $i), Mode=$Mode"; break }
}

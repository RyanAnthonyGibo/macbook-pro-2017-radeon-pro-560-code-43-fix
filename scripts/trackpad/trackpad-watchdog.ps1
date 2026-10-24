# A1707 (MacBook Pro 2017) Boot Camp trackpad watchdog - by Ryan Anthony Gibo (MIT)
# Root cause: Bootcamp.exe 6.1.6700 crashes (BEX64). Without it, the Apple SPI Trackpad
# loses two-finger scroll, two-finger right click and tap-to-click. This keeps it alive.
$log="C:\Setup\trackpad\watchdog.log"
New-Item (Split-Path $log) -ItemType Directory -Force | Out-Null
function L($m){ "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') $m" | Add-Content $log }
$reg='HKCU:\Software\Apple Inc.\Trackpad'
if(-not (Test-Path $reg)){ New-Item $reg -Force | Out-Null }
# Mode 40 (0x28) = tap-to-click + two-finger secondary click (read yours from AppleControlPanel.exe)
if((Get-ItemProperty $reg -EA 0).Mode -ne 40){ Set-ItemProperty $reg Mode 40 -Type DWord; L "Mode reset to 40" }
if((Get-ItemProperty 'HKCU:\Control Panel\Desktop').WheelScrollLines -ne '1'){ Set-ItemProperty 'HKCU:\Control Panel\Desktop' WheelScrollLines '1'; L "WheelScrollLines=1" }
$exe="C:\Program Files\Boot Camp\Bootcamp.exe"
for($i=0;$i -lt 6;$i++){
  if(Get-Process Bootcamp -EA 0){ if($i){L "Bootcamp.exe running after $i tries"}; break }
  L "Bootcamp.exe not running -> starting (try $($i+1))"
  Start-Process $exe; Start-Sleep 8
}
if(-not (Get-Process Bootcamp -EA 0)){ L "FAILED to keep Bootcamp.exe running" }

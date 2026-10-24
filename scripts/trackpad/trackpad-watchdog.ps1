# A1707 trackpad watchdog v2
# Known-good: HKCU\Software\Apple Inc.\Trackpad Mode = 43 (0x2B), captured right after the Boot Camp
# control panel "Apply" fixed scroll/right-click. (v1 forced 40 = 0x28, which dropped bits 0x03.)
# Edit $GOOD to your own value: set the Trackpad tab, click Apply, then read Mode.
# When the value is wrong we rewrite it and restart Bootcamp.exe so it is pushed to the driver (no admin).
$GOOD=43
$log="C:\Setup\trackpad\watchdog.log"
function L($m){ "$(Get-Date -f 'yyyy-MM-dd HH:mm:ss') $m" | Add-Content $log }
$reg='HKCU:\Software\Apple Inc.\Trackpad'
$exe="C:\Program Files\Boot Camp\Bootcamp.exe"
if(-not (Test-Path $reg)){ New-Item $reg -Force | Out-Null }
$cur=(Get-ItemProperty $reg -EA 0).Mode
$restart=$false
if($cur -ne $GOOD){ Set-ItemProperty $reg Mode $GOOD -Type DWord; L "Mode $cur -> $GOOD"; $restart=$true }
if($restart -and (Get-Process Bootcamp -EA 0)){ Stop-Process -Name Bootcamp -Force -EA 0; Start-Sleep 2; L "Bootcamp.exe restarted to apply" }
for($i=0;$i -lt 6;$i++){
  if(Get-Process Bootcamp -EA 0){ break }
  L "Bootcamp.exe not running -> starting (try $($i+1))"
  Start-Process explorer.exe -ArgumentList "`"$exe`""; Start-Sleep 8
}
if(-not (Get-Process Bootcamp -EA 0)){ L "FAILED to keep Bootcamp.exe running" }

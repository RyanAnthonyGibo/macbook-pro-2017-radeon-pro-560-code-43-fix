# Installs the A1707 trackpad watchdog as a per-user scheduled task (no admin needed).
# Triggers: logon, unlock, resume from sleep, Bootcamp.exe crash (Application Error 1000), every 2 min.
# Before installing: set the Boot Camp control panel Trackpad tab, click Apply, read
# (Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode and put it in $GOOD in trackpad-watchdog.ps1.
$d="C:\Setup\trackpad"; New-Item $d -ItemType Directory -Force | Out-Null
Copy-Item "$PSScriptRoot\trackpad-watchdog.ps1","$PSScriptRoot\run-hidden.vbs" $d -Force
$u="$env:USERDOMAIN\$env:USERNAME"
$q1="&lt;QueryList&gt;&lt;Query Id=`"0`" Path=`"System`"&gt;&lt;Select Path=`"System`"&gt;*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;"
$q2="&lt;QueryList&gt;&lt;Query Id=`"0`" Path=`"Application`"&gt;&lt;Select Path=`"Application`"&gt;*[System[Provider[@Name='Application Error'] and EventID=1000]] and *[EventData[Data='Bootcamp.exe']]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;"
@"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
<Triggers>
<LogonTrigger><Enabled>true</Enabled><UserId>$u</UserId><Delay>PT10S</Delay></LogonTrigger>
<SessionStateChangeTrigger><Enabled>true</Enabled><StateChange>SessionUnlock</StateChange><UserId>$u</UserId></SessionStateChangeTrigger>
<EventTrigger><Enabled>true</Enabled><Subscription>$q1</Subscription><Delay>PT5S</Delay></EventTrigger>
<EventTrigger><Enabled>true</Enabled><Subscription>$q2</Subscription><Delay>PT3S</Delay></EventTrigger>
<TimeTrigger><Enabled>true</Enabled><StartBoundary>2026-01-01T00:00:00</StartBoundary><Repetition><Interval>PT2M</Interval></Repetition></TimeTrigger>
</Triggers>
<Principals><Principal id="Author"><UserId>$u</UserId><LogonType>InteractiveToken</LogonType><RunLevel>LeastPrivilege</RunLevel></Principal></Principals>
<Settings><MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy><DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries><StopIfGoingOnBatteries>false</StopIfGoingOnBatteries><StartWhenAvailable>true</StartWhenAvailable><ExecutionTimeLimit>PT5M</ExecutionTimeLimit><Enabled>true</Enabled></Settings>
<Actions Context="Author"><Exec><Command>wscript.exe</Command><Arguments>"$d\run-hidden.vbs"</Arguments></Exec></Actions>
</Task>
"@ | Set-Content "$d\A1707-TrackpadWatchdog.xml" -Encoding Unicode
schtasks /create /tn "A1707-TrackpadWatchdog" /xml "$d\A1707-TrackpadWatchdog.xml" /f
schtasks /run /tn "A1707-TrackpadWatchdog"

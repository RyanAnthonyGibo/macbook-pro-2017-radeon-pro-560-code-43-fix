# build-apple-only-msi.ps1 - builds BootCampAppleOnly.msi from Apple's official Boot Camp 6.1 package (no admin).
# 1) Get Apple's BootCampESD.pkg for MacBookPro14,3 (catalog product 041-89072, Boot Camp Services 6.1.6851), e.g. with brigadier:
#      brigadier --model MacBookPro14,3      (or download BootCampESD.pkg from swcdn.apple.com via the Apple sucatalog)
#    Extract with 7-Zip: BootCampESD.pkg -> Payload~ -> Library/Application Support/BootCamp/WindowsSupport.dmg -> BootCamp\ and $WinPEDriver$\
# 2) Copy ONLY these into C:\Setup\bootcamp61 (keep the folder layout; never copy BootCamp\Drivers\AMD):
#      BootCamp\Drivers\Apple\{BootCamp.msi,AppleDFR64.exe,AppleSOC64.exe,AppleKeyboardInstaller64.exe}
#      $WinPEDriver$\{AppleSPITrackpad,AppleSPIDevice,AppleSPIKeyboard,AppleUSBCompositeDevice64}
# 3) Run this script. It checks Apple's signature and writes a copy of BootCamp.msi with every non-Apple driver action,
#    AppleDisplay, SetVideoKeyInfo (CA_SetGrfxVal), fsutil and AppleSoftwareUpdate removed from InstallExecuteSequence.
param($Root='C:\Setup\bootcamp61')
$a="$Root\BootCamp\Drivers\Apple"
$sig=Get-AuthenticodeSignature "$a\BootCamp.msi"
if($sig.Status -ne 'Valid' -or $sig.SignerCertificate.Subject -notmatch 'O=Apple Inc\.'){ throw "BootCamp.msi is not validly signed by Apple" }
if(Get-ChildItem $Root -Recurse -File | ? { $_.Name -match '^(amd|ati)|radeon' }){ throw 'AMD/ATI files found - remove them' }
Copy-Item "$a\BootCamp.msi" "$a\BootCampAppleOnly.msi" -Force
$keep='CA_AppleComposite','CA_AppleDFR','CA_AppleSOC','CA_AppleSPITrackpad','CA_AppleSPIDevice','CA_AppleSPIKeyboard','CA_KeyMagic','CA_KeyMagic_rb','CA_SetVolumeName','CA_IsHiDPISys','CA_Is4kSector','CA_SetBTKey','CA_SetNDISKey','CA_SetHibRebootKey','CA_SetBTPairingKey'
$wi=New-Object -ComObject WindowsInstaller.Installer
function Inv($o,$m,$args2){ $o.GetType().InvokeMember($m,'InvokeMethod',$null,$o,$args2) }
$db=Inv $wi 'OpenDatabase' @("$a\BootCampAppleOnly.msi",1)
$v=Inv $db 'OpenView' @('SELECT Action FROM InstallExecuteSequence'); Inv $v 'Execute' $null | Out-Null
$all=@(); while($r=Inv $v 'Fetch' $null){ $all+=$r.GetType().InvokeMember('StringData','GetProperty',$null,$r,1) }; Inv $v 'Close' $null | Out-Null
$del=$all | ? { ($_ -like 'CA_*' -or $_ -eq 'AppleSoftwareUpdate') -and $keep -notcontains $_ }
foreach($x in $del){ $q=Inv $db 'OpenView' @("DELETE FROM InstallExecuteSequence WHERE Action='$x'"); Inv $q 'Execute' $null | Out-Null; Inv $q 'Close' $null | Out-Null }
Inv $db 'Commit' $null | Out-Null; [Runtime.InteropServices.Marshal]::ReleaseComObject($db) | Out-Null
"Removed $($del.Count) actions: $($del -join ', ')"
"Built $a\BootCampAppleOnly.msi (unsigned copy; original stays Apple-signed)"

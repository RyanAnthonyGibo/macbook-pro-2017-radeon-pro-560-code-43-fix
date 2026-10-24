🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017 (A1707) Radeon Pro 560 / 555 Code 43 एरर का समाधान — टूटी या हटाई गई इंटरनल स्क्रीन (eDP) के साथ Windows 10/11 Boot Camp, OpenCore से VFCT VBIOS पैच

📄 **तकनीकी पेपर:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **लेखक और खोजकर्ता: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — मूल कारण 21/10/2026 को खोजा गया और समाधान बनाया गया।

क्या आपका **AMD Radeon Pro 560 या Radeon Pro 555** वाला **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** डिवाइस मैनेजर में **"Windows ने इस डिवाइस को रोक दिया है क्योंकि इसने समस्याओं की रिपोर्ट की है। (Code 43)"** दिखा रहा है? क्या **इंटरनल स्क्रीन (LCD / eDP पैनल) टूटी, डिस्कनेक्ट या हटाई गई** है और आप Mac को **बिना स्क्रीन (headless) एक्सटर्नल मॉनिटर के साथ** (USB-C, Thunderbolt 3, HDMI, DisplayPort) चलाते हैं? तब **AMD ड्राइवर (Boot Camp, Adrenalin)** फेल होता है क्योंकि **VBIOS अब भी इंटरनल eDP पैनल घोषित करता है**। यह रिपॉज़िटरी इसे ठीक करती है: **ACPI VFCT टेबल** (VBIOS की वह कॉपी जो Windows पढ़ता है) को पैच करके eDP कनेक्टर हटाती है और **OpenCore** (`ACPI > Delete + Add`) से लोड करती है। नतीजा: **4 GB VRAM, DirectX 11/12 और हार्डवेयर एक्सेलेरेशन** के साथ काम करता Radeon Pro 560।

कीवर्ड: MacBook Pro 2017 code 43 error, A1707 Radeon Pro 560 code 43 समाधान, Boot Camp टूटी स्क्रीन ग्राफिक्स कार्ड, Radeon Pro 555 code 43 Windows 10, Radeon Pro 560 काम नहीं कर रहा Windows 11, बिना स्क्रीन MacBook Pro Windows, Boot Camp headless, eDP AMD ड्राइवर, VFCT पैच, VBIOS, OpenCore Boot Camp GPU, MacBook Pro पर Warframe, Windows में Touch Bar काम नहीं कर रहा, Boot Camp ESC बटन गायब, Boot Camp ट्रैकपैड tap to click रीस्टार्ट के बाद रीसेट, Boot Camp राइट क्लिक, दो उंगलियों से स्क्रॉल बहुत तेज़।

> ⚠️ **अस्वीकरण — अपने जोखिम पर उपयोग करें।** आप बूटलोडर द्वारा लोड की जाने वाली फ़र्मवेयर टेबल बदल रहे हैं। गलत कॉन्फ़िगरेशन से Mac बूट नहीं हो सकता। एक रिकवरी USB और `config.plist` का बैकअप रखें। कोई वारंटी नहीं ([LICENSE](LICENSE))। Apple या AMD से संबद्ध नहीं।

## त्वरित समाधान (TL;DR)
1. Windows बूट करें (Microsoft Basic Display Adapter काम करता है) और सामान्य Boot Camp / AMD ड्राइवर इंस्टॉल करें (Code 43 दिखेगा — यह अपेक्षित है)।
2. VFCT डंप करें: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`।
3. `python scripts/vfct-parse.py vfct.dat` → कनेक्टर `3114` (eDP) और पाथ `0002` (LCD1) की पुष्टि करें।
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`, फिर `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 कनेक्टर, चेकसम OK)।
5. `VFCT-noeDP.aml` को `EFI\OC\ACPI\` में कॉपी करें, `config.plist` का बैकअप लें और [opencore/config-snippet.plist](opencore/config-snippet.plist) जोड़ें।
6. OpenCore से रीस्टार्ट करें → डिवाइस मैनेजर: **Radeon Pro 560 — "यह डिवाइस ठीक से काम कर रहा है"** ✅

## आवश्यकताएँ
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B)। Radeon Pro 555 / 2016 A1707 शायद समान, पर **सत्यापित नहीं**; ID अलग होने पर स्क्रिप्ट रुक जाती है।
- Windows 10 22H2 (19045 पर परखा गया) या Windows 11; AMD R6.4 30.0.13045.22003 / Boot Camp ड्राइवर।
- **OpenCore** (1.0.6 परखा गया): Apple फ़र्मवेयर ACPI टेबल नहीं बदल सकता।
- Python 3 और ACPICA का `acpidump.exe`।

## चरण-दर-चरण गाइड
1. इंटरनल ESP पर **OpenCore इंस्टॉल करें** और सुनिश्चित करें कि Windows उसी से बूट हो। `config.plist` बहाल करने वाला USB तैयार रखें।
2. एडमिन टर्मिनल में **VFCT डंप करें**: `acpidump.exe -n VFCT -b`।
3. **जाँचें**: `python scripts/vfct-parse.py vfct.dat`। अपेक्षित: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`।
4. **पैच करें**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`।
5. **सत्यापित करें**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`।
6. **ESP माउंट करें**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; `config.plist` का बैकअप लें।
7. **config.plist संपादित करें**: स्निपेट से `ACPI > Add` और `ACPI > Delete` एंट्री जोड़ें (`VkZDVA==` = "VFCT")।
8. OpenCore से **रीस्टार्ट करें** और डिवाइस मैनेजर व `dxdiag` जाँचें।

## अक्सर पूछे जाने वाले प्रश्न
**स्क्रीन टूटने के बाद ही Code 43 क्यों?** VBIOS एक eDP कनेक्टर घोषित करता है। ड्राइवर पैनल चालू करने की कोशिश करता है, HPD नहीं मिलता और डिस्प्ले डिटेक्शन के ~0.4 सेकंड बाद खुद को हटा लेता है → Code 43।

**क्या ड्राइवर दोबारा इंस्टॉल करना, Windows 11 या नया Adrenalin मदद करेगा?** नहीं। Apple 22.19, AMD R6.4 और Adrenalin 26.5.2 Windows 10 और 11 दोनों पर फेल हुए।

**क्या मुझे इंटीग्रेटेड Intel GPU चाहिए?** नहीं। बिना स्क्रीन वाले A1707 पर `apple_set_os.efi` **इस्तेमाल न करें**: बूट Apple लोगो पर अटक गया।

**क्या मेरा VBIOS इसमें शामिल है?** नहीं। यह AMD/Apple के कॉपीराइट में है; स्क्रिप्ट *आपका अपना* डंप पैच करती है।

**क्या यह macOS पर असर डालता है?** OpenCore सभी सिस्टम के लिए टेबल लोड करता है। macOS इस GPU के लिए VFCT का उपयोग नहीं करता, पर पैच के साथ macOS बूट अभी दोबारा सत्यापित नहीं हुआ — टेस्ट करें।

**क्या मैं गेम खेल सकता हूँ?** हाँ: बिना स्क्रीन वाले A1707 पर Warframe (DirectX 11/12) डाउनलोड होकर चलता हुआ पुष्टि हुआ।

**क्या लिड सेंसर पर चुंबक लगाने से हल होगा?** हमारे टेस्ट में नहीं (`_LID` ओवरराइड और DAL रजिस्ट्री कुंजियाँ भी काम नहीं आईं)।

**Warframe लॉन्चर: "Could not create directory C:\Program Files\Warframe"?** अपने यूज़र को Modify अनुमति दें (एडमिन के रूप में): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`।

## समस्या निवारण
- **अब भी Code 43**: जाँचें कि पैच की गई टेबल सक्रिय है (SS `106B:0179` वाली VFCT)। नहीं तो OpenCore ने उसे लोड नहीं किया (पाथ, `Enabled`, OpenCore के बिना बूट)।
- **स्क्रिप्ट में "object not found" त्रुटि**: अलग VBIOS; `vfct-parse.py` चलाएँ और आउटपुट के साथ issue खोलें।
- **Mac बूट नहीं हो रहा / सफ़ेद Apple लोगो**: रिकवरी USB से बूट करें (Option → "EFI Boot") और बैकअप बहाल करें; या macOS में `sudo diskutil mount disk0s1` चलाकर बैकअप वापस कॉपी करें।
- **एक्सटर्नल 4K मॉनिटर ~30 Hz पर**: संभवतः केबल/एडैप्टर/पोर्ट की सीमा। USB-C→DP या 60 Hz पर 1440p/1080p उपयोग करें।
- **बूट पिकर पर काली स्क्रीन**: OpenCore में `UEFI > Output > Resolution` (जैसे `1920x1080@32`) और `ForceResolution`।

## इंस्टॉल के बाद: Boot Camp पर Touch Bar और ट्रैकपैड
21/10/2026 को उसी बिना स्क्रीन वाले A1707 पर सत्यापित (Windows 10 22H2, Boot Camp 6.1)।

### Windows में Touch Bar काम नहीं कर रहा / ESC बटन गायब
- आधिकारिक Boot Camp 6.1 ड्राइवर इंस्टॉल और ठीक थे: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0।
- कारण: **`Bootcamp.exe` (Boot Camp ट्रे ऐप) चल नहीं रहा था**; यही Touch Bar (फ़ंक्शन कुंजियाँ / ESC) चलाता है।
- समाधान: `Bootcamp.exe` फिर T1 कंपोज़िट डिवाइस रीस्टार्ट करें (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`)। Touch Bar और ESC **इंटरनल स्क्रीन के बिना भी** लौट आए।

### ट्रैकपैड tap to click / सेकेंडरी क्लिक रीस्टार्ट के बाद खो जाते हैं
- Boot Camp ये विकल्प केवल `HKCU\Software\Apple Inc.\Trackpad\Mode` में रखता है (DWORD, अप्रलेखित बिट्स)।
- इन्हें `C:\Windows\System32\AppleControlPanel.exe` → Trackpad में सेट करें और मान पढ़ें: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (हमारा: `40`)।
- हर लॉगऑन पर [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) से दोबारा लागू करें (`Mode` लिखता है, `Bootcamp.exe` को 5 प्रयासों तक रीस्टार्ट करता है), 10 सेकंड देरी और 3 पुनःप्रयासों वाले शेड्यूल्ड टास्क से। उदाहरण (स्क्रिप्ट को `C:\Tools\` में कॉपी करें, एडमिन के रूप में, `<user>` बदलें):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
फिर Task Scheduler → Settings: "If the task fails, restart every 1 minute", "Attempt to restart up to 3 times" (या `Register-ScheduledTask` के साथ `New-ScheduledTaskSettingsSet -RestartCount 3`)।

### दो उंगलियों से स्क्रॉल बहुत तेज़
`HKCU\Control Panel\Desktop\WheelScrollLines` को `3` से `1` करें, `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)` से तुरंत लागू। स्क्रिप्ट यह `-WheelScrollLines 1` से करती है।

## रिपॉज़िटरी की सामग्री
| पाथ | क्या है |
|---|---|
| `scripts/vfct-patch.py` | eDP कनेक्टर/एनकोडर और LCD1 पाथ हटाता है, LCD1 फ़्लैग साफ़ करता है, SSID 106B:0179 सेट करता है, चेकसम ठीक करता है |
| `scripts/vfct-parse.py` | VFCT और ATOM ऑब्जेक्ट टेबल पार्स करता है, चेकसम जाँचता है |
| `scripts/bootcamp-reapply.ps1` | लॉगऑन पर ट्रैकपैड Mode लागू करता है और Bootcamp.exe (Touch Bar) रीस्टार्ट करता है |
| `opencore/config-snippet.plist` | OpenCore `ACPI > Delete + Add` एंट्री |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | पूरा तकनीकी पेपर (अंग्रेज़ी / पुर्तगाली) |

## श्रेय
**Ryan Anthony Gibo**: लेखक, मूल कारण और समाधान के खोजकर्ता, हार्डवेयर टेस्टिंग। ACPICA, OpenCore (Acidanthera) और OpenCore Legacy Patcher का धन्यवाद। मदद मिली? ⭐ दें और [CITATION.cff](CITATION.cff) से उद्धृत करें।

लाइसेंस: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click-stops-working-again-definitive-fix) and `scripts/trackpad/install.ps1`. By Ryan Anthony Gibo.

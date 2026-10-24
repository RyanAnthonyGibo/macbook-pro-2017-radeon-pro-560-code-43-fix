🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# حل خطأ الرمز 43 في Radeon Pro 560 / 555 على MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp مع شاشة داخلية مكسورة أو منزوعة (eDP) عبر تعديل VBIOS في جدول VFCT باستخدام OpenCore

📄 **الورقة التقنية:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **المؤلف والمكتشف: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — تم العثور على السبب الجذري وإنشاء الحل في 21/10/2026.

هل يُظهر جهاز **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** المزوّد بـ **AMD Radeon Pro 560 أو Radeon Pro 555** في إدارة الأجهزة الرسالة **"أوقف Windows هذا الجهاز لأنه أبلغ عن مشاكل. (الرمز 43)"**؟ هل **الشاشة الداخلية (LCD / لوحة eDP) مكسورة أو مفصولة أو منزوعة** وتستخدم الماك **بدون شاشة (headless) مع شاشة خارجية** (USB-C أو Thunderbolt 3 أو HDMI أو DisplayPort)؟ يفشل **تعريف AMD (Boot Camp، Adrenalin)** لأن **الـ VBIOS ما زال يعلن عن لوحة eDP الداخلية**. هذا المستودع يحل المشكلة: يعدّل **جدول ACPI VFCT** (نسخة الـ VBIOS التي يقرأها Windows) لإزالة منفذ eDP ثم يحقنه عبر **OpenCore** (`ACPI > Delete + Add`). النتيجة: Radeon Pro 560 تعمل مع **4 جيجابايت VRAM و DirectX 11/12 وتسريع العتاد**.

كلمات مفتاحية: ماك بوك برو 2017 خطأ الرمز 43، A1707 Radeon Pro 560 كود 43، بوت كامب شاشة مكسورة كرت الشاشة، Radeon Pro 555 الرمز 43 ويندوز 10، Radeon Pro 560 لا تعمل ويندوز 11، ماك بوك برو بدون شاشة ويندوز، Boot Camp headless، eDP تعريف AMD، تعديل VFCT، VBIOS، OpenCore Boot Camp، Warframe على ماك بوك برو، Touch Bar لا يعمل في ويندوز، زر ESC مفقود بوت كامب، لوحة اللمس بوت كامب النقر باللمس يُعاد ضبطه بعد إعادة التشغيل، النقر الأيمن بوت كامب، التمرير بإصبعين سريع جدًا.

> ⚠️ **إخلاء مسؤولية — الاستخدام على مسؤوليتك الخاصة.** أنت تعدّل جداول برامج ثابتة يحمّلها محمّل الإقلاع. قد يمنع إعداد خاطئ الماك من الإقلاع. احتفظ بذاكرة USB للاسترداد ونسخة احتياطية من `config.plist`. بدون ضمان ([LICENSE](LICENSE)). غير تابع لـ Apple أو AMD.

## الحل السريع (TL;DR)
1. شغّل Windows (محوّل العرض الأساسي من Microsoft يعمل) وثبّت تعريف Boot Camp / AMD العادي (سيظهر الرمز 43 — هذا متوقع).
2. استخرج VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → تأكد من وجود المنفذ `3114` (eDP) والمسار `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` ثم `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 منافذ، المجاميع الاختبارية سليمة).
5. انسخ `VFCT-noeDP.aml` إلى `EFI\OC\ACPI\` وخذ نسخة احتياطية من `config.plist` وطبّق [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. أعد التشغيل عبر OpenCore → إدارة الأجهزة: **Radeon Pro 560 — "هذا الجهاز يعمل بشكل صحيح"** ✅

## المتطلبات
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 إصدار 2016 غالبًا مشابه لكن **غير مُتحقق منه**؛ يتوقف السكربت إذا اختلفت المعرّفات.
- Windows 10 22H2 (اختُبر على 19045) أو Windows 11؛ تعريف AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (اختُبر 1.0.6): البرنامج الثابت من Apple لا يستطيع استبدال جداول ACPI.
- Python 3 و `acpidump.exe` من ACPICA.

## دليل خطوة بخطوة
1. **ثبّت OpenCore** على قسم ESP الداخلي وتأكد أن Windows يقلع من خلاله. احتفظ بذاكرة USB تستطيع استعادة `config.plist`.
2. **استخرج VFCT** من طرفية بصلاحيات المسؤول: `acpidump.exe -n VFCT -b`.
3. **افحص**: `python scripts/vfct-parse.py vfct.dat`. المتوقع: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **طبّق التعديل**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **تحقّق**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **اربط قسم ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`؛ وخذ نسخة احتياطية من `config.plist`.
7. **عدّل config.plist**: أضف مدخلات `ACPI > Add` و `ACPI > Delete` من المقتطف (`VkZDVA==` = "VFCT").
8. **أعد التشغيل** عبر OpenCore وتحقق من إدارة الأجهزة و `dxdiag`.

## الأسئلة الشائعة
**لماذا ظهر الرمز 43 فقط بعد كسر الشاشة؟** يعلن الـ VBIOS عن منفذ eDP. يحاول التعريف تشغيل اللوحة، فلا يتلقى إشارة HPD ويزيل نفسه بعد ~0.4 ثانية من اكتشاف الشاشات → الرمز 43.

**هل تفيد إعادة تثبيت التعريفات أو Windows 11 أو Adrenalin أحدث؟** لا. فشلت Apple 22.19 و AMD R6.4 و Adrenalin 26.5.2 على Windows 10 و 11.

**هل أحتاج كرت Intel المدمج؟** لا. **لا** تستخدم `apple_set_os.efi` على A1707 بدون شاشة: توقف الإقلاع عند شعار Apple.

**هل الـ VBIOS الخاص بي مضمّن؟** لا. إنه محمي بحقوق نشر AMD/Apple؛ السكربت يعدّل *نسختك أنت*.

**هل يؤثر ذلك على macOS؟** يحقن OpenCore الجداول لكل الأنظمة. لا يستخدم macOS جدول VFCT لهذا الكرت، لكن إقلاع macOS مع التعديل لم يُتحقق منه مجددًا بعد — اختبره.

**هل يمكنني اللعب؟** نعم: تم التأكيد مع Warframe (DirectX 11/12) الذي يُنزَّل ويعمل على A1707 بدون شاشة.

**هل يحل المغناطيس على حساس الغطاء المشكلة؟** ليس في اختباراتنا (ولا تجاوز `_LID` ولا مفاتيح DAL في السجل).

**مشغّل Warframe: "Could not create directory C:\Program Files\Warframe"؟** امنح مستخدمك صلاحية التعديل (كمسؤول): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## استكشاف الأخطاء
- **ما زال الرمز 43**: تأكد أن الجدول المعدّل نشط (VFCT مع SS `106B:0179`). وإلا فإن OpenCore لم يحمّله (المسار، `Enabled`، الإقلاع بدون OpenCore).
- **خطأ "object not found" في السكربت**: VBIOS مختلف؛ شغّل `vfct-parse.py` وافتح issue مع المخرجات.
- **الماك لا يقلع / شعار Apple أبيض**: أقلع من ذاكرة الاسترداد (Option → "EFI Boot") واستعد النسخة الاحتياطية؛ أو من macOS نفّذ `sudo diskutil mount disk0s1` وانسخ النسخة الاحتياطية.
- **شاشة 4K خارجية على ~30 هرتز**: غالبًا حدّ الكابل/المحوّل/المنفذ. استخدم USB-C→DP أو 1440p/1080p على 60 هرتز.
- **شاشة سوداء في قائمة الإقلاع**: في OpenCore اضبط `UEFI > Output > Resolution` (مثل `1920x1080@32`) و `ForceResolution`.

## بعد التثبيت: Touch Bar ولوحة اللمس في Boot Camp
تم التحقق في 21/10/2026 على نفس جهاز A1707 بدون شاشة (Windows 10 22H2، Boot Camp 6.1).

### Touch Bar لا يعمل في Windows / زر ESC مفقود
- كانت تعريفات Boot Camp 6.1 الرسمية مثبتة وسليمة: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- السبب: **`Bootcamp.exe` (تطبيق Boot Camp في شريط النظام) لم يكن يعمل**؛ وهو الذي يشغّل الـ Touch Bar (مفاتيح الوظائف / ESC).
- الحل: أعد تشغيل `Bootcamp.exe` ثم الجهاز المركّب T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). عاد Touch Bar و ESC **حتى بدون الشاشة الداخلية**.

### النقر باللمس / النقر الثانوي في لوحة اللمس يضيعان بعد إعادة التشغيل
- يحفظ Boot Camp هذه الخيارات فقط في `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD، بتات غير موثقة).
- اضبطها في `C:\Windows\System32\AppleControlPanel.exe` → Trackpad ثم اقرأ القيمة: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (قيمتنا: `40`).
- أعد تطبيقها عند كل تسجيل دخول باستخدام [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (يكتب `Mode` ويعيد تشغيل `Bootcamp.exe` حتى 5 محاولات) من مهمة مجدولة بتأخير 10 ثوانٍ و 3 إعادات. مثال (انسخ السكربت إلى `C:\Tools\`، كمسؤول، واستبدل `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
ثم في جدولة المهام → الإعدادات: "إذا فشلت المهمة، أعد التشغيل كل دقيقة"، "حاول حتى 3 مرات" (أو `Register-ScheduledTask` مع `New-ScheduledTaskSettingsSet -RestartCount 3`).

### التمرير بإصبعين سريع جدًا
غيّر `HKCU\Control Panel\Desktop\WheelScrollLines` من `3` إلى `1`، ويُطبَّق فورًا عبر `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. السكربت يفعل ذلك مع `-WheelScrollLines 1`.

## محتويات المستودع
| المسار | الوظيفة |
|---|---|
| `scripts/vfct-patch.py` | يزيل منفذ/مُرمّز eDP ومسار LCD1، ويمسح علامة LCD1، ويضبط SSID 106B:0179، ويصحح المجاميع الاختبارية |
| `scripts/vfct-parse.py` | يحلل VFCT وجدول كائنات ATOM ويتحقق من المجاميع الاختبارية |
| `scripts/bootcamp-reapply.ps1` | يعيد تطبيق Mode للوحة اللمس ويعيد تشغيل Bootcamp.exe (Touch Bar) عند تسجيل الدخول |
| `opencore/config-snippet.plist` | مدخلات OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | الورقة التقنية الكاملة (الإنجليزية / البرتغالية) |

## الشكر والتقدير
**Ryan Anthony Gibo**: المؤلف ومكتشف السبب والحل واختبارات العتاد. شكرًا لمشاريع ACPICA و OpenCore (Acidanthera) و OpenCore Legacy Patcher. هل أفادك؟ امنح ⭐ واستشهد عبر [CITATION.cff](CITATION.cff).

الترخيص: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click-stops-working-again-definitive-fix) and `scripts/trackpad/install.ps1`. By Ryan Anthony Gibo.

🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# วิธีแก้ Code 43 ของ Radeon Pro 560 / 555 บน MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp ที่จอในเสียหรือถอดออก (eDP) ด้วยการแพตช์ VBIOS ในตาราง VFCT ผ่าน OpenCore

📄 **บทความเชิงเทคนิค:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **ผู้เขียนและผู้ค้นพบ: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — พบสาเหตุและสร้างวิธีแก้เมื่อ 21/10/2026

**MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** ที่ใช้ **AMD Radeon Pro 560 หรือ Radeon Pro 555** ของคุณขึ้นข้อความ **"Windows ได้หยุดอุปกรณ์นี้เนื่องจากอุปกรณ์รายงานปัญหา (Code 43)"** ใน Device Manager ใช่ไหม? **จอในตัว (LCD / แผง eDP) แตก หลุด หรือถูกถอดออก** และคุณใช้ Mac **แบบไม่มีจอ (headless) ต่อจอภายนอก** (USB-C, Thunderbolt 3, HDMI, DisplayPort) ใช่ไหม? **ไดรเวอร์ AMD (Boot Camp, Adrenalin)** จะล้มเหลวเพราะ **VBIOS ยังประกาศว่ามีแผง eDP ภายใน** รีโปนี้แก้ปัญหานั้น: แพตช์ **ตาราง ACPI VFCT** (สำเนา VBIOS ที่ Windows อ่าน) เพื่อลบคอนเนกเตอร์ eDP แล้วโหลดผ่าน **OpenCore** (`ACPI > Delete + Add`) ผลลัพธ์: Radeon Pro 560 ทำงานได้พร้อม **VRAM 4 GB, DirectX 11/12 และการเร่งด้วยฮาร์ดแวร์**

คีย์เวิร์ด: MacBook Pro 2017 code 43, A1707 Radeon Pro 560 code 43 วิธีแก้, Boot Camp จอแตก การ์ดจอ, Radeon Pro 555 code 43 Windows 10, Radeon Pro 560 ใช้ไม่ได้ Windows 11, MacBook Pro ไม่มีจอ Windows, Boot Camp headless, eDP ไดรเวอร์ AMD, แพตช์ VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe บน MacBook Pro, Touch Bar ไม่ทำงานบน Windows, ปุ่ม ESC หาย Boot Camp, แทร็กแพด Boot Camp แตะเพื่อคลิกรีเซ็ตหลังรีสตาร์ท, คลิกขวา Boot Camp, เลื่อนสองนิ้วเร็วเกินไป

> ⚠️ **คำเตือน — ใช้งานโดยยอมรับความเสี่ยงเอง** คุณกำลังแก้ไขตารางเฟิร์มแวร์ที่บูตโหลดเดอร์โหลด การตั้งค่าผิดอาจทำให้ Mac บูตไม่ขึ้น เตรียม USB กู้คืนและสำรอง `config.plist` ไว้ ไม่มีการรับประกัน ([LICENSE](LICENSE)) ไม่เกี่ยวข้องกับ Apple หรือ AMD

## วิธีแก้ด่วน (TL;DR)
1. บูต Windows (Microsoft Basic Display Adapter ใช้ได้) แล้วติดตั้งไดรเวอร์ Boot Camp / AMD ตามปกติ (จะขึ้น Code 43 — เป็นเรื่องปกติ)
2. ดัมป์ VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`
3. `python scripts/vfct-parse.py vfct.dat` → ยืนยันว่ามีคอนเนกเตอร์ `3114` (eDP) และพาธ `0002` (LCD1)
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` แล้วตามด้วย `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 คอนเนกเตอร์, checksum ถูกต้อง)
5. คัดลอก `VFCT-noeDP.aml` ไปที่ `EFI\OC\ACPI\` สำรอง `config.plist` และเพิ่ม [opencore/config-snippet.plist](opencore/config-snippet.plist)
6. รีสตาร์ทผ่าน OpenCore → Device Manager: **Radeon Pro 560 — "อุปกรณ์นี้ทำงานเป็นปกติ"** ✅

## ข้อกำหนด
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B) — Radeon Pro 555 / A1707 ปี 2016 น่าจะคล้ายกันแต่ **ยังไม่ได้ยืนยัน** สคริปต์จะหยุดหาก ID ไม่ตรง
- Windows 10 22H2 (ทดสอบ 19045) หรือ Windows 11; ไดรเวอร์ AMD R6.4 30.0.13045.22003 / Boot Camp
- **OpenCore** (ทดสอบ 1.0.6): เฟิร์มแวร์ของ Apple ไม่สามารถแทนที่ตาราง ACPI ได้
- Python 3 และ `acpidump.exe` จาก ACPICA

## คู่มือทีละขั้นตอน
1. **ติดตั้ง OpenCore** บน ESP ภายในและตรวจว่า Windows บูตผ่าน OpenCore เตรียม USB ที่กู้คืน `config.plist` ได้
2. **ดัมป์ VFCT** ในเทอร์มินัลแบบผู้ดูแลระบบ: `acpidump.exe -n VFCT -b`
3. **ตรวจสอบ**: `python scripts/vfct-parse.py vfct.dat` ที่คาดไว้: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`
4. **แพตช์**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`
5. **ยืนยันผล**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`
6. **เมานต์ ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; สำรอง `config.plist`
7. **แก้ไข config.plist**: เพิ่มรายการ `ACPI > Add` และ `ACPI > Delete` จาก snippet (`VkZDVA==` = "VFCT")
8. **รีสตาร์ท** ผ่าน OpenCore แล้วตรวจ Device Manager และ `dxdiag`

## คำถามที่พบบ่อย
**ทำไม Code 43 เกิดหลังจอเสียเท่านั้น?** VBIOS ประกาศคอนเนกเตอร์ eDP ไดรเวอร์พยายามเปิดแผงจอ แต่ไม่ได้รับสัญญาณ HPD จึงถอดตัวเองออกประมาณ 0.4 วินาทีหลังตรวจหาจอ → Code 43

**ติดตั้งไดรเวอร์ใหม่ ใช้ Windows 11 หรือ Adrenalin รุ่นใหม่ช่วยไหม?** ไม่ช่วย Apple 22.19, AMD R6.4 และ Adrenalin 26.5.2 ล้มเหลวทั้งบน Windows 10 และ 11

**ต้องใช้ GPU Intel ในตัวไหม?** ไม่ต้อง **ห้าม** ใช้ `apple_set_os.efi` กับ A1707 ที่ไม่มีจอ: การบูตค้างที่โลโก้ Apple

**มี VBIOS ของฉันในรีโปไหม?** ไม่มี เป็นลิขสิทธิ์ของ AMD/Apple สคริปต์จะแพตช์ดัมป์ *ของคุณเอง*

**กระทบ macOS ไหม?** OpenCore โหลดตารางให้ทุกระบบ macOS ไม่ใช้ VFCT กับ GPU นี้ แต่ยังไม่ได้ยืนยันซ้ำว่า macOS บูตได้พร้อมแพตช์ — โปรดทดสอบ

**เล่นเกมได้ไหม?** ได้: ยืนยันแล้วกับ Warframe (DirectX 11/12) ที่ดาวน์โหลดและรันบน A1707 ที่ไม่มีจอ

**วางแม่เหล็กที่เซนเซอร์ฝาช่วยไหม?** ไม่ช่วยในการทดสอบของเรา (การ override `_LID` และคีย์รีจิสทรี DAL ก็ไม่ช่วย)

**ตัวเปิด Warframe ขึ้น "Could not create directory C:\Program Files\Warframe"?** ให้สิทธิ์ Modify กับผู้ใช้ของคุณ (ในฐานะผู้ดูแลระบบ): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`

## การแก้ไขปัญหา
- **ยังขึ้น Code 43**: ตรวจว่าตารางที่แพตช์แล้วทำงานอยู่ (VFCT มี SS `106B:0179`) ถ้าไม่ใช่ แสดงว่า OpenCore ไม่ได้โหลด (พาธ, `Enabled`, บูตโดยไม่ผ่าน OpenCore)
- **สคริปต์แจ้ง "object not found"**: VBIOS ต่างรุ่น รัน `vfct-parse.py` แล้วเปิด issue พร้อมผลลัพธ์
- **Mac บูตไม่ขึ้น / โลโก้ Apple สีขาว**: บูตจาก USB กู้คืน (Option → "EFI Boot") แล้วกู้คืนไฟล์สำรอง หรือใน macOS ใช้ `sudo diskutil mount disk0s1` แล้วคัดลอกไฟล์สำรองกลับ
- **จอ 4K ภายนอกได้แค่ ~30 Hz**: น่าจะเป็นข้อจำกัดของสาย/อะแดปเตอร์/พอร์ต ใช้ USB-C→DP หรือ 1440p/1080p ที่ 60 Hz
- **จอดำที่หน้าเลือกบูต**: ใน OpenCore ตั้ง `UEFI > Output > Resolution` (เช่น `1920x1080@32`) และ `ForceResolution`

## หลังติดตั้ง: Touch Bar และแทร็กแพดบน Boot Camp
ยืนยันเมื่อ 21/10/2026 บน A1707 ไม่มีจอเครื่องเดิม (Windows 10 22H2, Boot Camp 6.1)

### Touch Bar ไม่ทำงานบน Windows / ปุ่ม ESC หาย
- ไดรเวอร์ Boot Camp 6.1 อย่างเป็นทางการติดตั้งอยู่และปกติ: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0
- สาเหตุ: **`Bootcamp.exe` (แอป Boot Camp ในถาดระบบ) ไม่ได้ทำงาน** ซึ่งเป็นตัวควบคุม Touch Bar (ปุ่มฟังก์ชัน / ESC)
- วิธีแก้: รีสตาร์ท `Bootcamp.exe` แล้วรีสตาร์ทอุปกรณ์คอมโพสิต T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`) Touch Bar และ ESC กลับมา **แม้ไม่มีจอใน**

### แตะเพื่อคลิก / คลิกรองของแทร็กแพดหายหลังรีสตาร์ท
- Boot Camp เก็บตัวเลือกเหล่านี้ไว้ที่ `HKCU\Software\Apple Inc.\Trackpad\Mode` เท่านั้น (DWORD, บิตที่ไม่มีเอกสาร)
- ตั้งค่าใน `C:\Windows\System32\AppleControlPanel.exe` → Trackpad แล้วอ่านค่า: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (ของเรา: `40`)
- นำค่ากลับมาใช้ทุกครั้งที่ล็อกออนด้วย [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (เขียน `Mode` และรีสตาร์ท `Bootcamp.exe` สูงสุด 5 ครั้ง) ผ่าน Scheduled Task ที่หน่วง 10 วินาทีและลองใหม่ 3 ครั้ง ตัวอย่าง (คัดลอกสคริปต์ไปที่ `C:\Tools\` รันแบบผู้ดูแลระบบ และแทน `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
จากนั้นใน Task Scheduler → Settings: "If the task fails, restart every 1 minute", "Attempt to restart up to 3 times" (หรือใช้ `Register-ScheduledTask` กับ `New-ScheduledTaskSettingsSet -RestartCount 3`)

### เลื่อนสองนิ้วเร็วเกินไป
เปลี่ยน `HKCU\Control Panel\Desktop\WheelScrollLines` จาก `3` เป็น `1` มีผลทันทีด้วย `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)` สคริปต์ทำได้ด้วย `-WheelScrollLines 1`

## เนื้อหาในรีโป
| พาธ | คืออะไร |
|---|---|
| `scripts/vfct-patch.py` | ลบคอนเนกเตอร์/เอนโค้ดเดอร์ eDP และพาธ LCD1 ล้างแฟล็ก LCD1 ตั้ง SSID 106B:0179 และแก้ checksum |
| `scripts/vfct-parse.py` | แยกวิเคราะห์ VFCT และตารางออบเจ็กต์ ATOM ตรวจ checksum |
| `scripts/bootcamp-reapply.ps1` | นำ Mode ของแทร็กแพดกลับมาใช้และรีสตาร์ท Bootcamp.exe (Touch Bar) ตอนล็อกออน |
| `opencore/config-snippet.plist` | รายการ OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | บทความเชิงเทคนิคฉบับเต็ม (อังกฤษ / โปรตุเกส) |

## เครดิต
**Ryan Anthony Gibo**: ผู้เขียน ผู้ค้นพบสาเหตุและวิธีแก้ ทดสอบบนฮาร์ดแวร์ ขอบคุณ ACPICA, OpenCore (Acidanthera) และ OpenCore Legacy Patcher มีประโยชน์ไหม? กด ⭐ และอ้างอิงผ่าน [CITATION.cff](CITATION.cff)

สัญญาอนุญาต: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

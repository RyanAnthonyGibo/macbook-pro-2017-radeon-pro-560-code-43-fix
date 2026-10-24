🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Cách sửa lỗi Code 43 Radeon Pro 560 / 555 trên MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp khi màn hình trong bị vỡ hoặc đã tháo (eDP), vá VBIOS VFCT bằng OpenCore

📄 **Bài báo kỹ thuật:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Tác giả và người phát hiện: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — tìm ra nguyên nhân gốc và tạo bản sửa ngày 21/10/2026.

**MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** dùng **AMD Radeon Pro 560 hoặc Radeon Pro 555** của bạn báo **"Windows đã dừng thiết bị này vì nó đã báo cáo sự cố. (Mã 43)"** trong Device Manager? **Màn hình trong (LCD / tấm eDP) bị vỡ, rút cáp hoặc đã tháo** và bạn dùng Mac **không màn hình (headless) với màn hình ngoài** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? **Driver AMD (Boot Camp, Adrenalin)** lỗi vì **VBIOS vẫn khai báo tấm eDP bên trong**. Repo này khắc phục: vá **bảng ACPI VFCT** (bản sao VBIOS mà Windows đọc) để xóa cổng eDP rồi nạp qua **OpenCore** (`ACPI > Delete + Add`). Kết quả: Radeon Pro 560 hoạt động với **4 GB VRAM, DirectX 11/12 và tăng tốc phần cứng**.

Từ khóa: MacBook Pro 2017 lỗi code 43, A1707 Radeon Pro 560 lỗi mã 43, Boot Camp vỡ màn hình card đồ họa, Radeon Pro 555 code 43 Windows 10, Radeon Pro 560 không hoạt động Windows 11, MacBook Pro không màn hình Windows, Boot Camp headless, eDP driver AMD, vá VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe trên MacBook Pro, Touch Bar không hoạt động trên Windows, mất phím ESC Boot Camp, trackpad Boot Camp chạm để nhấp bị reset sau khi khởi động lại, chuột phải Boot Camp, cuộn hai ngón quá nhanh.

> ⚠️ **TUYÊN BỐ MIỄN TRỪ — TỰ CHỊU RỦI RO.** Bạn đang sửa các bảng firmware do bootloader nạp. Cấu hình sai có thể khiến Mac không khởi động được. Hãy chuẩn bị USB khôi phục và bản sao lưu `config.plist`. Không bảo hành ([LICENSE](LICENSE)). Không liên kết với Apple hay AMD.

## Sửa nhanh (TL;DR)
1. Khởi động Windows (Microsoft Basic Display Adapter vẫn chạy) và cài driver Boot Camp / AMD bình thường (sẽ báo Mã 43 — đúng như dự kiến).
2. Dump VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → xác nhận có cổng `3114` (eDP) và đường `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` rồi `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 cổng, checksum OK).
5. Chép `VFCT-noeDP.aml` vào `EFI\OC\ACPI\`, sao lưu `config.plist` và áp dụng [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Khởi động lại qua OpenCore → Device Manager: **Radeon Pro 560 — "Thiết bị này đang hoạt động bình thường"** ✅

## Yêu cầu
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 đời 2016 có lẽ tương tự nhưng **chưa xác minh**; script sẽ dừng nếu ID khác.
- Windows 10 22H2 (đã thử 19045) hoặc Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (đã thử 1.0.6): firmware của Apple không thể thay bảng ACPI.
- Python 3 và `acpidump.exe` của ACPICA.

## Hướng dẫn từng bước
1. **Cài OpenCore** lên ESP trong và đảm bảo Windows khởi động qua nó. Chuẩn bị USB có thể khôi phục `config.plist`.
2. **Dump VFCT** trong terminal quyền admin: `acpidump.exe -n VFCT -b`.
3. **Kiểm tra**: `python scripts/vfct-parse.py vfct.dat`. Kỳ vọng: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Vá**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Xác thực**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Mount ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; sao lưu `config.plist`.
7. **Sửa config.plist**: thêm mục `ACPI > Add` và `ACPI > Delete` từ snippet (`VkZDVA==` = "VFCT").
8. **Khởi động lại** qua OpenCore và kiểm tra Device Manager cùng `dxdiag`.

## Câu hỏi thường gặp
**Vì sao chỉ bị Mã 43 sau khi màn hình hỏng?** VBIOS khai báo một cổng eDP. Driver cố bật tấm màn hình, không nhận được HPD và tự gỡ ~0,4 giây sau khi dò màn hình → Mã 43.

**Cài lại driver, Windows 11 hay Adrenalin mới có giúp không?** Không. Apple 22.19, AMD R6.4 và Adrenalin 26.5.2 đều lỗi trên Windows 10 và 11.

**Có cần GPU Intel tích hợp không?** Không. **Đừng** dùng `apple_set_os.efi` trên A1707 không màn hình: máy treo ở logo Apple.

**VBIOS của tôi có kèm trong repo không?** Không. Nó thuộc bản quyền AMD/Apple; script vá bản dump *của chính bạn*.

**Có ảnh hưởng macOS không?** OpenCore nạp bảng cho mọi hệ điều hành. macOS không dùng VFCT cho GPU này, nhưng việc khởi động macOS với bản vá chưa được kiểm tra lại — hãy thử.

**Có chơi game được không?** Được: đã xác nhận với Warframe (DirectX 11/12) tải về và chạy trên A1707 không màn hình.

**Đặt nam châm ở cảm biến nắp có sửa được không?** Không trong thử nghiệm của chúng tôi (ghi đè `_LID` và các khóa DAL trong registry cũng không).

**Launcher Warframe: "Could not create directory C:\Program Files\Warframe"?** Cấp quyền Modify cho người dùng của bạn (bằng admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Khắc phục sự cố
- **Vẫn Mã 43**: kiểm tra bảng đã vá có đang hoạt động (VFCT với SS `106B:0179`). Nếu không, OpenCore chưa nạp (đường dẫn, `Enabled`, khởi động không qua OpenCore).
- **Script báo "object not found"**: VBIOS khác; chạy `vfct-parse.py` và mở issue kèm kết quả.
- **Mac không khởi động / logo Apple trắng**: khởi động USB khôi phục (Option → "EFI Boot") và khôi phục bản sao lưu; hoặc trong macOS chạy `sudo diskutil mount disk0s1` rồi chép lại bản sao lưu.
- **Màn hình 4K ngoài chỉ ~30 Hz**: có lẽ do giới hạn cáp/bộ chuyển/cổng. Dùng USB-C→DP hoặc 1440p/1080p ở 60 Hz.
- **Màn hình đen ở bộ chọn khởi động**: trong OpenCore đặt `UEFI > Output > Resolution` (vd. `1920x1080@32`) và `ForceResolution`.

## Sau khi cài: Touch Bar và trackpad trên Boot Camp
Đã xác minh ngày 21/10/2026 trên cùng chiếc A1707 không màn hình (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar không hoạt động trên Windows / mất phím ESC
- Driver Boot Camp 6.1 chính thức đã cài và bình thường: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Nguyên nhân: **`Bootcamp.exe` (ứng dụng Boot Camp ở khay hệ thống) không chạy**; chính nó điều khiển Touch Bar (phím chức năng / ESC).
- Cách sửa: khởi động lại `Bootcamp.exe`, sau đó khởi động lại thiết bị tổng hợp T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar và ESC trở lại **dù không có màn hình trong**.

### Chạm để nhấp / nhấp phụ của trackpad bị mất sau khi khởi động lại
- Boot Camp chỉ lưu các tùy chọn này trong `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, các bit không có tài liệu).
- Đặt chúng trong `C:\Windows\System32\AppleControlPanel.exe` → Trackpad rồi đọc giá trị: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (của chúng tôi: `43`).
- Áp dụng lại mỗi lần đăng nhập bằng [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (ghi `Mode`, khởi động lại `Bootcamp.exe` tối đa 5 lần) qua Scheduled Task trễ 10 giây và thử lại 3 lần. Ví dụ (chép script vào `C:\Tools\`, chạy admin, thay `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Sau đó trong Task Scheduler → Settings: "If the task fails, restart every 1 minute", "Attempt to restart up to 3 times" (hoặc `Register-ScheduledTask` với `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Cuộn hai ngón quá nhanh
Đổi `HKCU\Control Panel\Desktop\WheelScrollLines` từ `3` thành `1`, áp dụng ngay bằng `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Script làm việc này với `-WheelScrollLines 1`.

## Nội dung repo
| Đường dẫn | Chức năng |
|---|---|
| `scripts/vfct-patch.py` | Xóa cổng/encoder eDP và đường LCD1, xóa cờ LCD1, đặt SSID 106B:0179, sửa checksum |
| `scripts/vfct-parse.py` | Phân tích VFCT và bảng đối tượng ATOM, kiểm tra checksum |
| `scripts/bootcamp-reapply.ps1` | Áp dụng lại Mode của trackpad và khởi động lại Bootcamp.exe (Touch Bar) khi đăng nhập |
| `opencore/config-snippet.plist` | Mục OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Bài báo kỹ thuật đầy đủ (tiếng Anh / tiếng Bồ Đào Nha) |

## Ghi công
**Ryan Anthony Gibo**: tác giả, người tìm ra nguyên nhân và cách sửa, kiểm thử phần cứng. Cảm ơn ACPICA, OpenCore (Acidanthera) và OpenCore Legacy Patcher. Hữu ích? Hãy ⭐ và trích dẫn qua [CITATION.cff](CITATION.cff).

Giấy phép: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Solusi Error Code 43 Radeon Pro 560 / 555 di MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp dengan Layar Internal Rusak atau Dilepas (eDP), Patch VBIOS VFCT lewat OpenCore

📄 **Paper teknis:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Penulis dan penemu: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — akar masalah ditemukan dan solusi dibuat pada 21/10/2026.

Apakah **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** Anda dengan **AMD Radeon Pro 560 atau Radeon Pro 555** menampilkan **"Windows telah menghentikan perangkat ini karena melaporkan masalah. (Kode 43)"** di Device Manager? Apakah **layar internal (LCD / panel eDP) rusak, terlepas, atau dicopot** dan Anda memakai Mac **tanpa layar (headless) dengan monitor eksternal** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? **Driver AMD (Boot Camp, Adrenalin)** gagal karena **VBIOS masih mendeklarasikan panel eDP internal**. Repo ini memperbaikinya: mem-patch **tabel ACPI VFCT** (salinan VBIOS yang dibaca Windows) untuk menghapus konektor eDP lalu menyuntikkannya lewat **OpenCore** (`ACPI > Delete + Add`). Hasilnya: Radeon Pro 560 bekerja dengan **VRAM 4 GB, DirectX 11/12, dan akselerasi hardware**.

Kata kunci: MacBook Pro 2017 error code 43, A1707 Radeon Pro 560 kode 43, Boot Camp layar rusak kartu grafis, Radeon Pro 555 code 43 Windows 10, Radeon Pro 560 tidak berfungsi Windows 11, MacBook Pro tanpa layar Windows, Boot Camp headless, eDP driver AMD, patch VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe di MacBook Pro, Touch Bar tidak berfungsi di Windows, tombol ESC hilang Boot Camp, trackpad Boot Camp tap to click hilang setelah restart, klik kanan Boot Camp, scroll dua jari terlalu cepat.

> ⚠️ **PERINGATAN — RISIKO DITANGGUNG SENDIRI.** Anda mengubah tabel firmware yang dimuat bootloader. Konfigurasi yang salah bisa membuat Mac gagal boot. Siapkan USB pemulihan dan cadangan `config.plist`. Tanpa garansi ([LICENSE](LICENSE)). Tidak berafiliasi dengan Apple atau AMD.

## Solusi cepat (TL;DR)
1. Boot ke Windows (Microsoft Basic Display Adapter berfungsi) dan instal driver Boot Camp / AMD biasa (akan muncul Kode 43 — memang begitu).
2. Dump VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → pastikan ada konektor `3114` (eDP) dan path `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` lalu `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 konektor, checksum OK).
5. Salin `VFCT-noeDP.aml` ke `EFI\OC\ACPI\`, cadangkan `config.plist`, dan terapkan [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Restart lewat OpenCore → Device Manager: **Radeon Pro 560 — "Perangkat ini berfungsi dengan baik"** ✅

## Persyaratan
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 kemungkinan serupa tetapi **belum diverifikasi**; skrip berhenti jika ID berbeda.
- Windows 10 22H2 (diuji 19045) atau Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (diuji 1.0.6): firmware Apple tidak bisa mengganti tabel ACPI.
- Python 3 dan `acpidump.exe` dari ACPICA.

## Panduan langkah demi langkah
1. **Instal OpenCore** di ESP internal dan pastikan Windows boot lewat OpenCore. Siapkan USB yang bisa memulihkan `config.plist`.
2. **Dump VFCT** di terminal admin: `acpidump.exe -n VFCT -b`.
3. **Periksa**: `python scripts/vfct-parse.py vfct.dat`. Yang diharapkan: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Patch**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Validasi**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Mount ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; cadangkan `config.plist`.
7. **Edit config.plist**: tambahkan entri `ACPI > Add` dan `ACPI > Delete` dari snippet (`VkZDVA==` = "VFCT").
8. **Restart** lewat OpenCore lalu cek Device Manager dan `dxdiag`.

## Pertanyaan umum
**Kenapa Kode 43 muncul hanya setelah layar rusak?** VBIOS mengumumkan konektor eDP. Driver mencoba menyalakan panel, tidak menerima HPD, lalu melepaskan diri ~0,4 detik setelah deteksi layar → Kode 43.

**Apakah instal ulang driver, Windows 11, atau Adrenalin terbaru membantu?** Tidak. Apple 22.19, AMD R6.4, dan Adrenalin 26.5.2 gagal di Windows 10 dan 11.

**Apakah saya perlu GPU Intel terintegrasi?** Tidak. **Jangan** gunakan `apple_set_os.efi` di A1707 tanpa layar: boot macet di logo Apple.

**Apakah VBIOS saya disertakan?** Tidak. VBIOS dilindungi hak cipta AMD/Apple; skrip mem-patch dump *milik Anda sendiri*.

**Apakah ini memengaruhi macOS?** OpenCore menyuntikkan tabel untuk semua sistem. macOS tidak memakai VFCT untuk GPU ini, tetapi boot macOS dengan patch belum diverifikasi ulang — silakan uji.

**Bisa main game?** Bisa: terkonfirmasi dengan Warframe (DirectX 11/12) yang terunduh dan berjalan di A1707 tanpa layar.

**Apakah magnet di sensor lid bisa memperbaiki?** Tidak dalam pengujian kami (override `_LID` dan kunci registry DAL juga tidak).

**Launcher Warframe: "Could not create directory C:\Program Files\Warframe"?** Beri pengguna Anda izin Modify (sebagai admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Pemecahan masalah
- **Masih Kode 43**: pastikan tabel hasil patch aktif (VFCT dengan SS `106B:0179`). Jika tidak, OpenCore tidak memuatnya (path, `Enabled`, boot tanpa OpenCore).
- **Error skrip "object not found"**: VBIOS berbeda; jalankan `vfct-parse.py` dan buka issue dengan hasilnya.
- **Mac tidak bisa boot / logo Apple putih**: boot dari USB pemulihan (Option → "EFI Boot") dan pulihkan cadangan; atau dari macOS `sudo diskutil mount disk0s1` lalu salin kembali cadangannya.
- **Monitor 4K eksternal di ~30 Hz**: kemungkinan batas kabel/adaptor/port. Gunakan USB-C→DP atau 1440p/1080p 60 Hz.
- **Layar hitam di pemilih boot**: di OpenCore atur `UEFI > Output > Resolution` (mis. `1920x1080@32`) dan `ForceResolution`.

## Pasca-instalasi: Touch Bar dan trackpad di Boot Camp
Diverifikasi pada 21/10/2026 di A1707 tanpa layar yang sama (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar tidak berfungsi di Windows / tombol ESC hilang
- Driver resmi Boot Camp 6.1 sudah terpasang dan normal: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Penyebab: **`Bootcamp.exe` (aplikasi Boot Camp di system tray) tidak berjalan**; aplikasi inilah yang menjalankan Touch Bar (tombol fungsi / ESC).
- Solusi: jalankan ulang `Bootcamp.exe`, lalu restart perangkat komposit T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar dan ESC kembali **meski tanpa layar internal**.

### Tap to click / klik sekunder trackpad hilang setelah restart
- Boot Camp menyimpan opsi ini hanya di `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, bit tidak terdokumentasi).
- Atur di `C:\Windows\System32\AppleControlPanel.exe` → Trackpad lalu baca nilainya: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (milik kami: `40`).
- Terapkan ulang setiap logon dengan [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (menulis `Mode`, restart `Bootcamp.exe` hingga 5 kali) lewat Scheduled Task dengan jeda 10 detik dan 3 percobaan ulang. Contoh (salin skrip ke `C:\Tools\`, sebagai admin, ganti `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Lalu di Task Scheduler → Settings: "If the task fails, restart every 1 minute", "Attempt to restart up to 3 times" (atau `Register-ScheduledTask` dengan `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Scroll dua jari terlalu cepat
Ubah `HKCU\Control Panel\Desktop\WheelScrollLines` dari `3` ke `1`, langsung diterapkan dengan `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Skrip melakukannya dengan `-WheelScrollLines 1`.

## Isi repositori
| Path | Fungsi |
|---|---|
| `scripts/vfct-patch.py` | Menghapus konektor/encoder eDP dan path LCD1, menghapus flag LCD1, mengatur SSID 106B:0179, memperbaiki checksum |
| `scripts/vfct-parse.py` | Mem-parse VFCT dan tabel objek ATOM, memeriksa checksum |
| `scripts/bootcamp-reapply.ps1` | Menerapkan ulang Mode trackpad dan me-restart Bootcamp.exe (Touch Bar) saat logon |
| `opencore/config-snippet.plist` | Entri OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Paper teknis lengkap (Inggris / Portugis) |

## Kredit
**Ryan Anthony Gibo**: penulis, penemu akar masalah dan solusi, pengujian hardware. Terima kasih kepada ACPICA, OpenCore (Acidanthera), dan OpenCore Legacy Patcher. Bermanfaat? Beri ⭐ dan kutip lewat [CITATION.cff](CITATION.cff).

Lisensi: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

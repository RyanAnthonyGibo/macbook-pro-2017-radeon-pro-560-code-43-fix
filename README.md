🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017 (A1707) Radeon Pro 560 / 555 Code 43 Fix — Windows 10/11 Boot Camp with Broken or Removed Internal Display (eDP), via OpenCore VFCT VBIOS Patch

> ℹ️ **This is a Windows (Boot Camp) fix.** It is **not** part of, affiliated with, or from OpenCore Legacy Patcher (OCLP). OpenCore is only used (in Option B) as a boot manager to inject a patched ACPI table.

📄 [Technical paper (EN)](docs/paper-en.md) · [Artigo técnico (PT-BR)](docs/paper-pt-BR.md)

Is your **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** with an **AMD Radeon Pro 560 or Radeon Pro 555** showing **"Windows has stopped this device because it has reported problems. (Code 43)"** in Device Manager? Is the **internal display (LCD / eDP panel) broken, cracked, disconnected or removed**, and you run the Mac **headless / clamshell with an external monitor** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? Then the **AMD driver (Boot Camp, Adrenalin, Radeon Pro Software)** fails because the **VBIOS still declares the internal eDP panel**. This repo fixes it: patch the **ACPI VFCT table** (the VBIOS copy Windows reads) to remove the eDP connector, and inject it with **OpenCore** `ACPI > Delete + Add`. Result: Radeon Pro 560 works with full **4 GB VRAM, DirectX 11/12 and hardware acceleration** — no more "Microsoft Basic Display Adapter".

Keywords: MacBook Pro 2017 Code 43, A1707 Radeon Pro 560 Code 43, Boot Camp Code 43 broken screen, Radeon Pro 555 Code 43 Windows 10, Windows 11 Radeon Pro 560 not working, MacBook Pro without screen Windows GPU, headless MacBook Pro Boot Camp, eDP removed AMD driver, VFCT patch, VBIOS ATOM object table, OpenCore Boot Camp GPU, CM_PROB_FAILED_POST_START, amdkmdag.sys DeviceRemoval, Warframe on MacBook Pro, Touch Bar not working Windows, Boot Camp Touch Bar ESC missing, Boot Camp trackpad tap to click resets after reboot, Boot Camp right click / secondary click not working after restart, two-finger scroll too fast Windows Boot Camp, AppleControlPanel trackpad.

> ⚠️ **DISCLAIMER — USE AT YOUR OWN RISK.** You modify firmware tables loaded by your bootloader. A wrong config can stop the Mac from booting. Keep a recovery USB and a backup of `config.plist`. No warranty (see [LICENSE](LICENSE)). Not affiliated with Apple or AMD.

## Option A (simplest, no OpenCore patches)
Credit: [u/Osaul4ik on Reddit](https://www.reddit.com/r/bootcamp/comments/1xczxpg/headless_macbook_pro_15_2018_no_internal_display/).
1. In macOS, open Terminal and run:
   ```sh
   sudo nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs=%01%00%00%00
   ```
2. Disable the VFCT patches in OpenCore (or don't use them at all).
3. Shut down the Mac.
4. Plug in the external monitor **before** powering on.
5. Power on and boot Windows with the normal (vanilla) loader. Secure Boot can stay on.

Revert: `sudo nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs`

Reported working on a MacBook Pro 15" 2018. **2017 (Radeon Pro 560) still to be confirmed** — if Option A doesn't work for you, use Option B.

## Option B (fallback): OpenCore VFCT VBIOS patch

### TL;DR (quick fix)
1. Boot Windows (Microsoft Basic Display works), install the normal Boot Camp / AMD driver (it will show Code 43 — expected).
2. Dump VFCT: `acpidump.exe -n VFCT -b` ([ACPICA tools](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → confirm a connector `3114` (eDP) and path tag `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` then `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 connectors, checksums OK).
5. Copy `VFCT-noeDP.aml` to `EFI\OC\ACPI\`, back up `config.plist`, merge [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Reboot through OpenCore → Device Manager: **Radeon Pro 560 — "This device is working properly"** ✅

### Requirements
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3) with Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / 2016 A1707 (MacBookPro13,3) likely similar but **unverified** — the script aborts if the object IDs differ.
- Windows 10 22H2 (tested 19045) or Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (tested 1.0.6) as boot manager — the native Apple firmware cannot replace ACPI tables.
- Python 3 (Windows Store or python.org), ACPICA `acpidump.exe`.

### Step-by-step guide
1. **Install OpenCore** on the internal ESP (e.g. via OpenCore Legacy Patcher or manually) and make sure Windows boots through it. Keep a USB recovery that can restore `config.plist`.
2. **Dump the VFCT table** in an admin terminal: `acpidump.exe -n VFCT -b` (creates `vfct.dat`).
3. **Inspect**: `python vfct-parse.py vfct.dat`. Expect 5 connectors incl. `obj 3114` (eDP), 5 encoders incl. `221e`, 5 paths incl. `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Patch**: `python vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Validate**: `python vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Mount ESP**: `mountvol S: /S`; copy `VFCT-noeDP.aml` to `S:\EFI\OC\ACPI\`; `copy S:\EFI\OC\config.plist S:\EFI\OC\config.plist.bak`.
7. **Edit config.plist**: add the `ACPI > Add` and `ACPI > Delete` entries from the snippet (`TableSignature` = `VkZDVA==` = "VFCT"). Run `ocvalidate` if you can.
8. **Reboot** through OpenCore. Check Device Manager and `dxdiag`.

## FAQ
**Why Code 43 only after the screen broke?** The VBIOS advertises an eDP (internal panel) connector. The AMD display core tries to power up / link-train that panel, gets no HPD, and the driver reports device removal ~0.4 s after display detection → Windows shows Code 43.
**Does reinstalling drivers / Windows 11 / newer Adrenalin help?** No. Apple 22.19, AMD R6.4 and Adrenalin 26.5.2 (test-signed) all failed on Windows 10 and 11. It is a platform description problem, not a driver version problem.
**Do I need the internal Intel iGPU?** No. Do **not** load `apple_set_os.efi` on a headless A1707: it hung boot at the Apple logo in our tests.
**Is my VBIOS shipped here?** No. VBIOS/VFCT binaries are AMD/Apple copyrighted; the script patches *your own* dump.
**Does it affect macOS?** OpenCore injects ACPI tables for every OS. macOS does not use VFCT for this GPU, but re-verification of macOS with the patch is still pending — test it.
**Can I play games?** Yes — the fix was motivated by running Warframe (DirectX 11/12) on a screenless A1707.
**Warframe launcher: "Could not create directory C:\Program Files\Warframe"?** Grant your user Modify on the folder (admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.
**Would a magnet on the lid sensor fix it?** Not in our tests (ACPI `_LID` override and DAL registry keys also failed).

## Troubleshooting
- **Still Code 43**: check the patched table is active — VFCT in `HKLM\HARDWARE\ACPI` / `GetSystemFirmwareTable` should show SS `106B:0179`. If not, OpenCore is not loading it (path, `Enabled`, booting without OpenCore).
- **Script assertion "object not found"**: different VBIOS; run `vfct-parse.py` and adapt IDs carefully (open an issue with the parse output).
- **Mac does not boot / white Apple logo**: boot the recovery USB (Option → "EFI Boot") and restore `config.plist.bak`; or from macOS `sudo diskutil mount disk0s1` and copy the backup back.
- **External 4K monitor at ~30 Hz**: likely cable/adapter/port limit (HDMI 1.4 adapters). Use a USB-C→DP cable or 1440p/1080p @ 60 Hz.
- **Black screen at the boot picker**: set OpenCore `UEFI > Output > Resolution` (e.g. `1920x1080@32`) and `ForceResolution`.

## Post-install: Touch Bar & trackpad on Boot Camp
Verified on 2026-10-21 on the same headless A1707 (Windows 10 22H2, Boot Camp 6.1). Radeon fix confirmed with Warframe downloading and running on the AMD driver.

### Touch Bar not working in Windows / ESC key missing
- Official Boot Camp 6.1 drivers were installed and healthy: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1 chip), SPI keyboard/trackpad 6.1.6700.0.
- Cause: **`Bootcamp.exe` (Boot Camp tray app) was not running**. It drives the Touch Bar (function keys / ESC).
- Fix: restart `Bootcamp.exe`, then restart the T1 composite device (`pnputil /restart-device "<instance id of USB\VID_05AC&PID_8600...>"`). Touch Bar and ESC came back **even with the internal panel removed**.

### Boot Camp trackpad tap to click / right click (secondary click) resets after reboot
- Boot Camp keeps these options only in `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, undocumented bit field).
- Set them in `C:\Windows\System32\AppleControlPanel.exe` → Trackpad, then read the value: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (ours: `40`).
- Re-apply at every logon with [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (writes `Mode`, restarts `Bootcamp.exe` up to 5 tries) from a Scheduled Task with a 10 s delay and 3 retries. Example (copy the script to `C:\Tools\`, run as admin, replace `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Then in Task Scheduler → task → Settings: "If the task fails, restart every 1 minute", "Attempt to restart up to 3 times" (schtasks can't set retries from the command line; or use `Register-ScheduledTask` with `New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)`).

### Two-finger scroll too fast
`HKCU\Control Panel\Desktop\WheelScrollLines` from `3` to `1`, applied live with `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69, 1, NULL, SPIF_UPDATEINIFILE|SPIF_SENDCHANGE)`. The script does it with `-WheelScrollLines 1`.

## Repository contents
| Path | What |
|---|---|
| `scripts/vfct-patch.py` | Removes eDP connector/encoder/LCD1 path, clears LCD1 support flag, sets SSID 106B:0179, fixes checksums |
| `scripts/vfct-parse.py` | Parses VFCT + ATOM object table, verifies checksums |
| `scripts/bootcamp-reapply.ps1` | Re-applies Boot Camp trackpad Mode + restarts Bootcamp.exe (Touch Bar) at logon |
| `opencore/config-snippet.plist` | OpenCore `ACPI > Delete + Add` entries |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Full technical paper |

## Credits
By [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo). Option A by u/Osaul4ik. Thanks to ACPICA and OpenCore (Acidanthera).

License: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

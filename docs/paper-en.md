# Resolving AMD Radeon Pro 560 "Code 43" on a Headless MacBook Pro 15" 2017 (A1707) under Windows: Removing the Internal eDP Path from the ACPI VFCT VBIOS Image

**Author: Ryan Anthony Gibo** ([@RyanAnthonyGibo](https://github.com/RyanAnthonyGibo)) · October 2026 · MIT License · 🇧🇷 [Versão em português](paper-pt-BR.md) · [← README](../README.md)

> Disclaimer: research notes from one machine. Use at your own risk. VBIOS binaries are not distributed.

## Abstract
On a MacBook Pro 15" 2017 (MacBookPro14,3, A1707) whose internal eDP panel was physically removed, the discrete AMD Radeon Pro 560 (Polaris 11 "Baffin", 1002:67EF, SUBSYS 0179106B) fails in Windows 10 22H2 and Windows 11 with Device Manager Code 43 (`CM_PROB_FAILED_POST_START`), independent of driver generation and boot path, while it works in macOS. An ETW DxgKrnl trace shows the AMD kernel-mode driver starting successfully and then requesting device removal ≈0.4–0.5 s after `DdiDisplayDetectControl`. We show that the cause is the ATOM BIOS object table inside the ACPI **VFCT** table, which still declares the internal LCD1/eDP display path. Removing the eDP connector, its encoder and the LCD1 display path, clearing `ATOM_DEVICE_LCD1_SUPPORT`, setting the image subsystem ID to 106B:0179, and fixing both checksums — then injecting the table via OpenCore `ACPI > Delete + Add` — restores a fully working GPU (Status OK, 4 GB VRAM, AMD driver 30.0.13045.22003).

## 1. Hardware and software
| Item | Value |
|---|---|
| Machine | MacBook Pro 15" 2017, A1707, MacBookPro14,3 |
| GPU | AMD Radeon Pro 560 4 GB GDDR5, PCI 1002:67EF SUBSYS_0179106B, ACPI `\_SB.PCI0.PEG0.GFX0` |
| VBIOS | 113-C9801AU-A02 (BaffinM / "Falcon" J80A) |
| Internal panel | Removed after physical damage (Boot Camp worked 100 % before) |
| External display | LG 4K via USB-C/HDMI |
| OS | Windows 10 22H2 (19045) with Boot Camp 6.1 drivers; Windows 11 Insider 26300 also tested |
| Boot | OpenCore 1.0.6 (OCLP build) and native Apple boot picker |
| Drivers tested | Apple Boot Camp 22.19; AMD R6.4 30.0.13045.22003 (`u0418524.inf`, `ati2mtag_Polaris11`); Adrenalin 26.5.2 31.0.21925.1001 (test-signed INF) |

Without the AMD driver Windows uses the Microsoft Basic Display Adapter (GOP framebuffer, single mode, no acceleration), so DirectX 11/12 games (e.g. Warframe) cannot run.

## 2. Symptom
Device Manager: *"Windows has stopped this device because it has reported problems. (Code 43)"*, problem `CM_PROB_FAILED_POST_START`, identical on every driver, OS build and boot path. In macOS on the same hardware the GPU works (Metal), proving the silicon and memory are healthy.

## 3. Diagnosis
### 3.1 ETW trace of the driver start
```
logman create trace dxg -p Microsoft-Windows-DxgKrnl 0xFFFFFFFF 5 -o dxg.etl -ets
pnputil /restart-device "<GPU instance id>"
logman stop dxg -ets
tracerpt dxg.etl -o dxg.xml -of XML
```
Timeline: `DdiStartDevice` SUCCESS (6 VidPN sources, 19 child devices) → memory segments (~4 GB VRAM) and contexts created → `DdiDisplayDetectControl` OK → **≈0.4–0.5 s later `FlushScheduler` + `DeviceRemoval`** → `DdiStopDeviceAndReleasePostDisplayOwnership`.

Conclusion: resources, PnP and the kernel are fine; the miniport itself aborts during display bring-up. Strings in `amdkmdag.sys` (`dce110_edp_wait_for_hpd_ready`, `edp_poweron`, `DalAllowEdpHotplugDetection`, `GetOpenLidState`) pointed to eDP initialization.

### 3.2 ACPI findings (ACPICA acpidump/iasl)
- **VFCT** present with a valid VBIOS image but image-header SSVID:SSID = `0000:0000`. No `ATRM`, `_ROM` or `ATPX`.
- SSDT "APPLE PEG0GFX0" defines `GFX0` with `Device(LCD)` `_ADR 0x110`, `_DOD {0x110}`, ATIF methods and a GMUX mailbox.
- DSDT `LID0._LID` reads the EC hall-sensor state; with the panel (and its lid magnet) gone the lid always reads *open*.

**Hypothesis:** the driver is told an internal eDP panel exists (VBIOS connector table + lid open), tries to power/link-train it, never receives HPD, and fails the whole adapter.

## 4. Experiments that failed (and why)
| # | Change | Result | Interpretation |
|---|---|---|---|
| 1 | Class-key registry: `PP_EnableLoadFalconSmcFirmware=0`, `PP_Falcon_QuickTransition_Enable=0`, `PP_Apple_Bootcamp_Enable=0`, `KMD_BootCampPlatform=0` | 43 | Not Apple power-play / SMC firmware path |
| 2 | `EnableUlps=0`, `PP_GPUPowerDownEnabled=0` | 43 | Not power gating |
| 3 | Restore original keys | 43 | Baseline |
| 4 | OpenCore GOP resolution 1920x1080 + `ForceResolution` | no effect | Pre-OS framebuffer irrelevant |
| 5 | SSDT override: `GFX0` without `Device(LCD)`/`_DOD` | 43 | ACPI is **not** the source of the eDP connector |
| 6 | ACPI `_LID` forced closed (rename `_LID`→`XLID`, new SSDT returning 0 on non-Darwin) | 43 | Driver doesn't take lid state (only) from ACPI |
| 7 | DAL registry keys from driver strings (`DalSkipDMUPanelPowerSequence`, `DalAllowEdpHotplugDetection`, `DalFeatureForceLidOpen`) | 43 | No registry escape hatch |
| 8 | OpenCore `apple_set_os.efi` (expose Intel iGPU) | **boot hang at white Apple logo** | Dangerous on headless A1707 — do not repeat |
| 9 | Current Adrenalin 26.5.2 with `ExcludeID` for 0179106B removed, self-signed catalog, test-signing | 43 | Independent of driver generation |
| — | Physical magnets over both hall lid sensors | 43 (inconclusive) | Placement not verified |
| — | Windows 11 vs Windows 10; OpenCore vs native boot | 43 | Platform, not OS |

Conclusion after 9 experiments: the eDP must come from the **VBIOS** itself, which the Windows driver reads from the ACPI VFCT table on Apple systems (there's no PCI option ROM exposed to the OS).

## 5. VFCT and ATOM BIOS structure
### 5.1 VFCT (AMD "VBIOS Fetch Content Table")
| Offset | Field |
|---|---|
| 0 | Standard 36-byte ACPI header (signature `VFCT`, length, revision, **checksum @9**, OEM ID @10, OEM Table ID @16) |
| 36 | TableUUID (16 B) |
| 52 | `VBIOSImageOffset` (u32) — 76 here |
| 56 | `Lib1ImageOffset` (u32) |
| 76 | `VFCT_IMAGE_HEADER` (28 B): PCIBus, PCIDevice, PCIFunction (u32 each), VendorID, DeviceID, **SSVID @+16, SSID @+18**, Revision (u32), ImageLength (u32) |
| 104 | ROM image (`55 AA`, size byte @+2 in 512-byte units, **ROM checksum byte @+0x21**) |

### 5.2 ATOM BIOS
`ROM[0x48]` → `ATOM_ROM_HEADER`; `+0x20` → Master Data Table; data table index **22** → **Object Header** (format rev 1, content rev 3). Object Header fields at `+4`: `usDeviceSupport`, connector table, router table, encoder table, protection table, display-path table offsets. Connector/encoder tables: `u8 count, u8 reserved[3]`, then 8-byte entries (`usObjectID, usSrcDstTableOffset, usRecordOffset, usReserved`). Display-path table: `u8 count, u8 version, u16 reserved`, then variable-size `ATOM_DISPLAY_OBJECT_PATH` (`usDeviceTag, usSize, usConnObjectId, usGPUObjectId, usGraphicObjIds[]`).

### 5.3 Original object table (VBIOS 113-C9801AU-A02)
`usDeviceSupport = 0x068A`
| Path tag | Connector | Encoder |
|---|---|---|
| **0x0002 (LCD1)** | **0x3114 (eDP)** | **0x221E** |
| 0x0008 | 0x3113 (DP) | 0x211E |
| 0x0080 | 0x3213 (DP) | 0x2220 |
| 0x0200 | 0x3313 (DP) | 0x2120 |
| 0x0400 | 0x3413 (DP) | 0x2121 |

The four DP paths are the Thunderbolt 3 / USB-C display outputs; the eDP path is the removed internal Retina panel.

## 6. The patch (`scripts/vfct-patch.py`)
1. Locate ROM (`VBIOSImageOffset + 28`), ROM header, Master Data Table, Object Header.
2. Remove connector object `0x3114` and encoder object `0x221E` (shift remaining entries left, decrement count, zero the freed tail; record offsets stay valid because the record area is untouched).
3. Remove the display path with `usDeviceTag 0x0002` (shift, decrement count, zero tail).
4. `usDeviceSupport 0x068A → 0x0688` (clear `ATOM_DEVICE_LCD1_SUPPORT`, bit 1).
5. VFCT image header SSVID:SSID `0000:0000 → 106B:0179` (matches the PCI subsystem, as the driver expects).
6. Recompute the ROM checksum (byte `0x21`, so the sum over `ROM[0..size)` ≡ 0 mod 256), set OEM Table ID, recompute ACPI checksum (byte 9).

The script asserts each object exists exactly once and aborts otherwise. In our case 66 bytes changed; file size unchanged (62,084 B).

## 7. Validation
`vfct-parse.py` on the output: 4 connectors / 4 encoders / 4 paths, devsupport `0688`, SS `106b:0179`, ACPI checksum OK, ROM checksum 0. After boot, `GetSystemFirmwareTable('ACPI','VFCT')` returned the patched table (SS 106B:0179), proving OpenCore injection works.

**Result:** Radeon Pro 560 — Status OK, `CM_PROB_NONE`, AMD R6.4 30.0.13045.22003, 4 GB VRAM, external LG at 3840x2160, hardware acceleration; test-signing disabled (not required by the fix).

## 8. OpenCore configuration
Place `VFCT-noeDP.aml` in `EFI/OC/ACPI/` and add:
```xml
<key>Add</key><array><dict>
  <key>Comment</key><string>VFCT with eDP connector removed</string>
  <key>Enabled</key><true/>
  <key>Path</key><string>VFCT-noeDP.aml</string>
</dict></array>
<key>Delete</key><array><dict>
  <key>All</key><false/>
  <key>Enabled</key><true/>
  <key>OemTableId</key><data></data>
  <key>TableLength</key><integer>0</integer>
  <key>TableSignature</key><data>VkZDVA==</data> <!-- "VFCT" -->
</dict></array>
```
No `Drivers`, `Booter` or `NVRAM` changes. Full snippet: [`opencore/config-snippet.plist`](../opencore/config-snippet.plist).

## 9. Risks, recovery and limitations
- **Risk:** a broken config.plist or bad table can prevent booting. Always back up `config.plist` first; keep a USB stick whose startup script mounts the internal ESP and restores the backup (boot via Option → "EFI Boot"). From macOS: `sudo diskutil mount disk0s1` and copy the backup back. From Windows: `mountvol S: /S`.
- **Never** add `apple_set_os.efi` on a headless A1707 (boot hang).
- **macOS:** OpenCore applies ACPI changes to every OS. macOS doesn't use VFCT for this GPU, but macOS boot with the patch has **not yet been re-verified**.
- **Only works when booting through OpenCore** — the native Apple picker loads the original VFCT (Code 43 returns).
- **Internal display:** obviously unsupported after the patch; reinstalling a panel requires removing the patch.
- **External 4K at 29 Hz** observed on an LG over USB-C/HDMI; most likely a cable/adapter/port (HDMI 1.4) limit, not the patch. Use DisplayPort or lower resolution for 60 Hz.
- Tested on one machine/VBIOS (113-C9801AU-A02). Radeon Pro 555/450/455 or other VBIOS revisions may use different object IDs.
- Firmware binaries are AMD/Apple copyrighted and not distributed; only the transformation is published.

## 10. Conclusion
Code 43 on a screenless A1707 is not a driver bug but a platform-description mismatch: the VBIOS promises an eDP panel that no longer exists, and the AMD display core fails the adapter when it can't bring it up. Editing the VBIOS copy in the VFCT table — not ACPI devices, registry keys, or drivers — fixes it in software, reversibly.

## Appendix A — Post-install: Touch Bar & trackpad on Boot Camp
Verified on 2026-10-21 on the same headless A1707 (Windows 10 22H2, Boot Camp 6.1). Radeon fix confirmed with Warframe downloading and running on the AMD driver.

### Touch Bar not working in Windows / ESC key missing
- Official Boot Camp 6.1 drivers were installed and healthy: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1 chip), SPI keyboard/trackpad 6.1.6700.0.
- Cause: **`Bootcamp.exe` (Boot Camp tray app) was not running**. It drives the Touch Bar (function keys / ESC).
- Fix: restart `Bootcamp.exe`, then restart the T1 composite device (`pnputil /restart-device "<instance id of USB\VID_05AC&PID_8600...>"`). Touch Bar and ESC came back **even with the internal panel removed**.

### Boot Camp trackpad tap to click / right click (secondary click) resets after reboot
- Boot Camp keeps these options only in `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, undocumented bit field).
- Set them in `C:\Windows\System32\AppleControlPanel.exe` → Trackpad, then read the value: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (ours: `40`).
- Re-apply at every logon with [`scripts/bootcamp-reapply.ps1`](../scripts/bootcamp-reapply.ps1) (writes `Mode`, restarts `Bootcamp.exe` up to 5 tries) from a Scheduled Task with a 10 s delay and 3 retries. Example (copy the script to `C:\Tools\`, run as admin, replace `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Then in Task Scheduler → task → Settings: "If the task fails, restart every 1 minute", "Attempt to restart up to 3 times" (schtasks can't set retries from the command line; or use `Register-ScheduledTask` with `New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)`).

### Two-finger scroll too fast
`HKCU\Control Panel\Desktop\WheelScrollLines` from `3` to `1`, applied live with `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69, 1, NULL, SPIF_UPDATEINIFILE|SPIF_SENDCHANGE)`. The script does it with `-WheelScrollLines 1`.

## Credits & citation
Research, discovery and testing: **Ryan Anthony Gibo**. Tools: ACPICA, OpenCore (Acidanthera), OpenCore Legacy Patcher. Cite via [`CITATION.cff`](../CITATION.cff).

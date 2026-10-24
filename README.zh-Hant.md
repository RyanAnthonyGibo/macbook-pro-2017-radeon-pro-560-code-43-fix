🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017（A1707）Radeon Pro 560 / 555 代碼 43 錯誤修正 — 內建螢幕（eDP）損壞或拆除的 Windows 10/11 Boot Camp，透過 OpenCore 修補 VFCT VBIOS

📄 **技術論文:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **作者與發現者：[Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — 於 2026 年 10 月 21 日找出根本原因並完成修正。

你的 **MacBook Pro 15 吋 2017（A1707, MacBookPro14,3）** 搭載 **AMD Radeon Pro 560 或 Radeon Pro 555**，在裝置管理員中顯示 **「Windows 已停止這個裝置，因為它回報了問題。(代碼 43)」** 嗎？**內建螢幕（LCD / eDP 面板）破裂、斷線或已拆除**，而你把 Mac **當作無螢幕（headless）主機接外接顯示器**（USB-C、Thunderbolt 3、HDMI、DisplayPort）使用？由於 **VBIOS 仍宣告內建 eDP 面板**，**AMD 驅動程式（Boot Camp、Adrenalin）** 會失敗。本儲存庫的解法：修補 **ACPI VFCT 表**（Windows 讀取的 VBIOS 副本），移除 eDP 接頭，再透過 **OpenCore**（`ACPI > Delete + Add`）注入。結果：Radeon Pro 560 正常運作，**4 GB VRAM、DirectX 11/12 與硬體加速** 全部可用。

關鍵字：MacBook Pro 2017 代碼43 錯誤、A1707 Radeon Pro 560 代碼43、Boot Camp 螢幕破裂 顯示卡、Radeon Pro 555 代碼43 Windows 10、Radeon Pro 560 無法使用 Windows 11、無螢幕 MacBook Pro 裝 Windows、Boot Camp headless、eDP AMD 驅動程式、VFCT 修補、VBIOS、OpenCore Boot Camp 顯示卡、MacBook Pro 玩 Warframe、Windows 觸控列 Touch Bar 不能用、Boot Camp 沒有 ESC 鍵、Boot Camp 觸控式軌跡板 點一下來點按 重開機後失效、Boot Camp 右鍵、雙指捲動太快。

> ⚠️ **免責聲明 — 風險自負。** 你將修改由開機載入程式載入的韌體表。錯誤的設定可能導致 Mac 無法開機。請準備好救援 USB 與 `config.plist` 備份。不提供任何保證（[LICENSE](LICENSE)）。與 Apple 或 AMD 無關。

## 快速修正（TL;DR）
1. 啟動 Windows（Microsoft 基本顯示介面卡可用），安裝一般的 Boot Camp / AMD 驅動程式（會顯示代碼 43，屬正常）。
2. 傾印 VFCT：`acpidump.exe -n VFCT -b`（[ACPICA](https://github.com/acpica/acpica/releases)）→ `vfct.dat`。
3. `python scripts/vfct-parse.py vfct.dat` → 確認有接頭 `3114`（eDP）與路徑 `0002`（LCD1）。
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`，接著 `python scripts/vfct-parse.py VFCT-noeDP.aml`（4 個接頭，檢查碼 OK）。
5. 將 `VFCT-noeDP.aml` 複製到 `EFI\OC\ACPI\`，備份 `config.plist`，並套用 [opencore/config-snippet.plist](opencore/config-snippet.plist)。
6. 透過 OpenCore 重新開機 → 裝置管理員：**Radeon Pro 560 —「這個裝置運作正常」** ✅

## 需求
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B)。Radeon Pro 555 / 2016 款 A1707 可能類似，但 **未驗證**；ID 不同時腳本會中止。
- Windows 10 22H2（已於 19045 測試）或 Windows 11；驅動程式 AMD R6.4 30.0.13045.22003 / Boot Camp。
- **OpenCore**（已測試 1.0.6）：Apple 韌體本身無法替換 ACPI 表。
- Python 3 與 ACPICA 的 `acpidump.exe`。

## 逐步教學
1. 在內建 ESP 上 **安裝 OpenCore**，確認 Windows 經由 OpenCore 開機。準備一支能還原 `config.plist` 的 USB。
2. 在系統管理員終端機中 **傾印 VFCT**：`acpidump.exe -n VFCT -b`。
3. **檢查**：`python scripts/vfct-parse.py vfct.dat`。預期：`obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`。
4. **修補**：`python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`。
5. **驗證**：`python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`。
6. **掛載 ESP**：`mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`；備份 `config.plist`。
7. **編輯 config.plist**：加入片段中的 `ACPI > Add` 與 `ACPI > Delete` 項目（`VkZDVA==` =「VFCT」）。
8. 透過 OpenCore **重新開機**，檢查裝置管理員與 `dxdiag`。

## 常見問題
**為什麼螢幕壞了之後才出現代碼 43？** VBIOS 宣告了一個 eDP 接頭。驅動程式嘗試點亮面板，收不到 HPD，在偵測顯示器約 0.4 秒後自行移除裝置 → 代碼 43。

**重灌驅動程式、改用 Windows 11 或新版 Adrenalin 有用嗎？** 沒用。Apple 22.19、AMD R6.4 與 Adrenalin 26.5.2 在 Windows 10 與 11 上都失敗。

**需要 Intel 內顯嗎？** 不需要。請 **不要** 在無螢幕 A1707 上使用 `apple_set_os.efi`：開機卡在 Apple 標誌。

**儲存庫有包含我的 VBIOS 嗎？** 沒有。它受 AMD/Apple 著作權保護；腳本修補的是 *你自己* 傾印的檔案。

**會影響 macOS 嗎？** OpenCore 會為所有系統注入這些表。macOS 不使用這張顯示卡的 VFCT，但修補後的 macOS 開機尚未重新驗證 — 請自行測試。

**可以玩遊戲嗎？** 可以：已在無螢幕 A1707 上確認 Warframe（DirectX 11/12）下載並執行。

**在上蓋感測器放磁鐵能解決嗎？** 在我們的測試中不行（`_LID` 覆寫與 DAL 登錄機碼也無效）。

**Warframe 啟動器：「Could not create directory C:\Program Files\Warframe」？** 以系統管理員身分給你的使用者「修改」權限：`icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`。

## 疑難排解
- **仍是代碼 43**：確認已修補的表正在生效（SS 為 `106B:0179` 的 VFCT）。否則 OpenCore 沒有載入（路徑、`Enabled`、未經 OpenCore 開機）。
- **腳本錯誤「object not found」**：VBIOS 不同；執行 `vfct-parse.py` 並附上輸出提交 issue。
- **Mac 無法開機 / 白色 Apple 標誌**：從救援 USB 開機（Option →「EFI Boot」）並還原備份；或在 macOS 執行 `sudo diskutil mount disk0s1` 後複製回備份。
- **外接 4K 顯示器只有約 30 Hz**：多半是線材/轉接頭/連接埠限制。改用 USB-C→DP，或 60 Hz 的 1440p/1080p。
- **開機選單黑畫面**：在 OpenCore 設定 `UEFI > Output > Resolution`（例如 `1920x1080@32`）與 `ForceResolution`。

## 安裝後：Boot Camp 的觸控列（Touch Bar）與軌跡板
2026 年 10 月 21 日在同一台無螢幕 A1707（Windows 10 22H2，Boot Camp 6.1）上驗證。

### Windows 觸控列不能用 / 沒有 ESC 鍵
- 官方 Boot Camp 6.1 驅動程式已安裝且正常：**Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0。
- 原因：**`Bootcamp.exe`（Boot Camp 系統匣程式）沒有執行**；觸控列（功能鍵 / ESC）正是由它驅動。
- 解法：重新啟動 `Bootcamp.exe`，再重新啟動 T1 複合裝置（`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`）。**即使沒有內建螢幕**，觸控列與 ESC 也恢復了。

### 軌跡板「點一下來點按」/「輔助點按」重開機後消失
- Boot Camp 只把這些選項存在 `HKCU\Software\Apple Inc.\Trackpad\Mode`（DWORD，未公開的位元）。
- 在 `C:\Windows\System32\AppleControlPanel.exe` → Trackpad 中設定，然後讀取數值：`(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode`（我們的是 `43`）。
- 每次登入時用 [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) 重新套用（寫入 `Mode`，最多 5 次重新啟動 `Bootcamp.exe`），透過延遲 10 秒、重試 3 次的排程工作執行。範例（把腳本複製到 `C:\Tools\`，以系統管理員執行，替換 `<user>`）：
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
接著在工作排程器 → 設定：「如果工作失敗，每隔 1 分鐘重新啟動」「最多嘗試重新啟動 3 次」（或使用 `Register-ScheduledTask` 搭配 `New-ScheduledTaskSettingsSet -RestartCount 3`）。

### 雙指捲動太快
將 `HKCU\Control Panel\Desktop\WheelScrollLines` 從 `3` 改為 `1`，透過 `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)` 立即生效。腳本可用 `-WheelScrollLines 1` 完成。

## 儲存庫內容
| 路徑 | 說明 |
|---|---|
| `scripts/vfct-patch.py` | 移除 eDP 接頭/編碼器與 LCD1 路徑，清除 LCD1 旗標，設定 SSID 106B:0179，修正檢查碼 |
| `scripts/vfct-parse.py` | 解析 VFCT 與 ATOM 物件表，驗證檢查碼 |
| `scripts/bootcamp-reapply.ps1` | 登入時重新套用軌跡板 Mode 並重新啟動 Bootcamp.exe（觸控列） |
| `opencore/config-snippet.plist` | OpenCore `ACPI > Delete + Add` 項目 |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | 完整技術論文（英文 / 葡萄牙文） |

## 致謝
**Ryan Anthony Gibo**：作者，根本原因與修正方法的發現者，實機測試。感謝 ACPICA、OpenCore（Acidanthera）與 OpenCore Legacy Patcher。覺得有幫助請按 ⭐，並透過 [CITATION.cff](CITATION.cff) 引用。

授權條款: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

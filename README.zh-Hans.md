🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017（A1707）Radeon Pro 560 / 555 代码 43 错误修复 — 内置屏幕（eDP）损坏或拆除的 Windows 10/11 Boot Camp，通过 OpenCore 修补 VFCT VBIOS

📄 **技术论文:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **作者与发现者：[Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — 于 2026 年 10 月 21 日找到根本原因并完成修复。

你的 **MacBook Pro 15 英寸 2017（A1707, MacBookPro14,3）** 搭载 **AMD Radeon Pro 560 或 Radeon Pro 555**，在设备管理器中显示 **“Windows 已停止此设备，因为它报告了问题。(代码 43)”** 吗？**内置屏幕（LCD / eDP 面板）碎了、断开或已拆除**，并且你把 Mac **当作无屏（headless）主机接外接显示器**（USB-C、Thunderbolt 3、HDMI、DisplayPort）使用？由于 **VBIOS 仍然声明内置 eDP 面板**，**AMD 驱动（Boot Camp、Adrenalin）** 会失败。本仓库的解决方法：修补 **ACPI VFCT 表**（Windows 读取的 VBIOS 副本），删除 eDP 接口，再通过 **OpenCore**（`ACPI > Delete + Add`）注入。结果：Radeon Pro 560 正常工作，**4 GB 显存、DirectX 11/12 与硬件加速** 全部可用。

关键词：MacBook Pro 2017 代码43 错误、A1707 Radeon Pro 560 代码43、Boot Camp 屏幕碎了 显卡、Radeon Pro 555 代码43 Windows 10、Radeon Pro 560 无法使用 Windows 11、无屏 MacBook Pro 装 Windows、Boot Camp headless、eDP AMD 驱动、VFCT 补丁、VBIOS、OpenCore Boot Camp 显卡、MacBook Pro 玩 Warframe、Windows 下 Touch Bar 不工作、Boot Camp 没有 ESC 键、Boot Camp 触控板 轻点来点按 重启后失效、Boot Camp 右键、双指滚动太快。

> ⚠️ **免责声明 — 风险自负。** 你将修改由引导程序加载的固件表。错误的配置可能导致 Mac 无法启动。请准备好恢复 U 盘和 `config.plist` 的备份。不提供任何担保（[LICENSE](LICENSE)）。与 Apple 或 AMD 无关。

## 快速修复（TL;DR）
1. 启动 Windows（Microsoft 基本显示适配器可用），安装常规的 Boot Camp / AMD 驱动（会显示代码 43，属正常现象）。
2. 导出 VFCT：`acpidump.exe -n VFCT -b`（[ACPICA](https://github.com/acpica/acpica/releases)）→ `vfct.dat`。
3. `python scripts/vfct-parse.py vfct.dat` → 确认存在接口 `3114`（eDP）和路径 `0002`（LCD1）。
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`，然后 `python scripts/vfct-parse.py VFCT-noeDP.aml`（4 个接口，校验和 OK）。
5. 将 `VFCT-noeDP.aml` 复制到 `EFI\OC\ACPI\`，备份 `config.plist`，并合并 [opencore/config-snippet.plist](opencore/config-snippet.plist)。
6. 通过 OpenCore 重启 → 设备管理器：**Radeon Pro 560 —“这个设备运转正常”** ✅

## 要求
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B)。Radeon Pro 555 / 2016 款 A1707 可能类似，但 **未验证**；ID 不同时脚本会中止。
- Windows 10 22H2（已在 19045 测试）或 Windows 11；驱动 AMD R6.4 30.0.13045.22003 / Boot Camp。
- **OpenCore**（已测试 1.0.6）：Apple 固件本身无法替换 ACPI 表。
- Python 3 和 ACPICA 的 `acpidump.exe`。

## 分步指南
1. 在内置 ESP 上 **安装 OpenCore**，确认 Windows 通过 OpenCore 启动。准备一个能恢复 `config.plist` 的 U 盘。
2. 在管理员终端中 **导出 VFCT**：`acpidump.exe -n VFCT -b`。
3. **检查**：`python scripts/vfct-parse.py vfct.dat`。预期：`obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`。
4. **打补丁**：`python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`。
5. **验证**：`python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`。
6. **挂载 ESP**：`mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`；备份 `config.plist`。
7. **编辑 config.plist**：添加片段中的 `ACPI > Add` 和 `ACPI > Delete` 条目（`VkZDVA==` =“VFCT”）。
8. 通过 OpenCore **重启**，检查设备管理器和 `dxdiag`。

## 常见问题
**为什么屏幕坏了之后才出现代码 43？** VBIOS 声明了一个 eDP 接口。驱动尝试点亮面板，收不到 HPD，在检测显示器约 0.4 秒后自行移除设备 → 代码 43。

**重装驱动、换 Windows 11 或新版 Adrenalin 有用吗？** 没用。Apple 22.19、AMD R6.4 和 Adrenalin 26.5.2 在 Windows 10 和 11 上都失败了。

**需要 Intel 核显吗？** 不需要。不要在无屏 A1707 上使用 `apple_set_os.efi`：启动卡在 Apple 标志。

**仓库里包含我的 VBIOS 吗？** 不包含。它受 AMD/Apple 版权保护；脚本修补的是 *你自己* 导出的文件。

**会影响 macOS 吗？** OpenCore 会为所有系统注入这些表。macOS 不使用这块显卡的 VFCT，但打补丁后的 macOS 启动尚未重新验证 — 请自行测试。

**能玩游戏吗？** 可以：已在无屏 A1707 上确认 Warframe（DirectX 11/12）下载并运行。

**在合盖传感器上放磁铁能解决吗？** 在我们的测试中不能（`_LID` 覆盖和 DAL 注册表键也无效）。

**Warframe 启动器：“Could not create directory C:\Program Files\Warframe”？** 以管理员身份给你的用户授予“修改”权限：`icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`。

## 故障排除
- **仍然是代码 43**：确认已修补的表处于生效状态（SS 为 `106B:0179` 的 VFCT）。否则 OpenCore 没有加载它（路径、`Enabled`、未经 OpenCore 启动）。
- **脚本报错 “object not found”**：VBIOS 不同；运行 `vfct-parse.py` 并附上输出提交 issue。
- **Mac 无法启动 / 白色 Apple 标志**：从恢复 U 盘启动（Option →“EFI Boot”）并恢复备份；或在 macOS 中执行 `sudo diskutil mount disk0s1` 后复制回备份。
- **外接 4K 显示器只有约 30 Hz**：多半是线缆/转接头/接口限制。改用 USB-C→DP，或 60 Hz 的 1440p/1080p。
- **启动选择界面黑屏**：在 OpenCore 中设置 `UEFI > Output > Resolution`（如 `1920x1080@32`）和 `ForceResolution`。

## 安装后：Boot Camp 下的 Touch Bar 与触控板
2026 年 10 月 21 日在同一台无屏 A1707（Windows 10 22H2，Boot Camp 6.1）上验证。

### Windows 下 Touch Bar 不工作 / 没有 ESC 键
- 官方 Boot Camp 6.1 驱动已安装且正常：**Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0。
- 原因：**`Bootcamp.exe`（Boot Camp 托盘程序）没有运行**；Touch Bar（功能键 / ESC）正是由它驱动。
- 解决：重新启动 `Bootcamp.exe`，再重启 T1 复合设备（`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`）。**即使没有内置屏幕**，Touch Bar 和 ESC 也恢复了。

### 触控板“轻点来点按”/“辅助点按”重启后丢失
- Boot Camp 只把这些选项保存在 `HKCU\Software\Apple Inc.\Trackpad\Mode`（DWORD，未公开的位）。
- 在 `C:\Windows\System32\AppleControlPanel.exe` → Trackpad 中设置，然后读取数值：`(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode`（我们的是 `43`）。
- 每次登录时用 [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) 重新应用（写入 `Mode`，最多重试 5 次重启 `Bootcamp.exe`），通过延迟 10 秒、重试 3 次的计划任务运行。示例（把脚本复制到 `C:\Tools\`，以管理员运行，替换 `<user>`）：
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
然后在任务计划程序 → 设置：“如果任务失败，每隔 1 分钟重新启动”“最多尝试重新启动 3 次”（或使用 `Register-ScheduledTask` 配合 `New-ScheduledTaskSettingsSet -RestartCount 3`）。

### 双指滚动太快
把 `HKCU\Control Panel\Desktop\WheelScrollLines` 从 `3` 改为 `1`，通过 `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)` 立即生效。脚本可用 `-WheelScrollLines 1` 完成。

## 仓库内容
| 路径 | 说明 |
|---|---|
| `scripts/vfct-patch.py` | 删除 eDP 接口/编码器和 LCD1 路径，清除 LCD1 标志，设置 SSID 106B:0179，修正校验和 |
| `scripts/vfct-parse.py` | 解析 VFCT 与 ATOM 对象表，校验校验和 |
| `scripts/bootcamp-reapply.ps1` | 登录时重新应用触控板 Mode 并重启 Bootcamp.exe（Touch Bar） |
| `opencore/config-snippet.plist` | OpenCore `ACPI > Delete + Add` 条目 |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | 完整技术论文（英文 / 葡萄牙文） |

## 致谢
**Ryan Anthony Gibo**：作者，根本原因与修复方法的发现者，实机测试。感谢 ACPICA、OpenCore（Acidanthera）和 OpenCore Legacy Patcher。有帮助的话请点 ⭐，并通过 [CITATION.cff](CITATION.cff) 引用。

许可证: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

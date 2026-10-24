🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017（A1707）Radeon Pro 560 / 555 コード 43 の解決方法 — 内蔵ディスプレイ（eDP）が故障・取り外し済みの Windows 10/11 Boot Camp、OpenCore による VFCT VBIOS パッチ

📄 **技術論文:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **作者・発見者：[Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — 2026年10月21日に根本原因を特定し、修正を作成。

**AMD Radeon Pro 560 または Radeon Pro 555** 搭載の **MacBook Pro 15インチ 2017（A1707, MacBookPro14,3）** で、デバイス マネージャーに **「問題が報告されたため、このデバイスは Windows によって停止されました。(コード 43)」** と表示されていませんか？ **内蔵ディスプレイ（LCD / eDP パネル）が割れた・外れた・取り外した** 状態で、Mac を **画面なし（ヘッドレス）で外部モニター**（USB-C、Thunderbolt 3、HDMI、DisplayPort）につないで使っていませんか？ **VBIOS が内蔵 eDP パネルを宣言したまま** なので **AMD ドライバー（Boot Camp、Adrenalin）** が失敗します。このリポジトリは、Windows が読む VBIOS のコピーである **ACPI VFCT テーブル** をパッチして eDP コネクタを削除し、**OpenCore**（`ACPI > Delete + Add`）で注入することで解決します。結果：**VRAM 4 GB、DirectX 11/12、ハードウェアアクセラレーション** で Radeon Pro 560 が動作します。

キーワード：MacBook Pro 2017 コード43 エラー、A1707 Radeon Pro 560 コード43、Boot Camp 画面割れ グラフィック 認識しない、Radeon Pro 555 コード43 Windows 10、Radeon Pro 560 動かない Windows 11、MacBook Pro 画面なし Windows、Boot Camp ヘッドレス、eDP AMD ドライバー、VFCT パッチ、VBIOS、OpenCore Boot Camp GPU、MacBook Pro で Warframe、Windows で Touch Bar が動かない、Boot Camp ESC キーがない、Boot Camp トラックパッド タップでクリック 再起動でリセット、Boot Camp 右クリック、2本指スクロールが速すぎる。

> ⚠️ **免責事項 — 自己責任でご利用ください。** ブートローダーが読み込むファームウェアテーブルを変更します。設定を誤ると Mac が起動しなくなる可能性があります。リカバリ用 USB と `config.plist` のバックアップを用意してください。無保証です（[LICENSE](LICENSE)）。Apple および AMD とは無関係です。

## クイック修正（TL;DR）
1. Windows を起動し（Microsoft 基本ディスプレイ アダプターは動作します）、通常の Boot Camp / AMD ドライバーをインストールします（コード 43 になりますが想定どおりです）。
2. VFCT をダンプ：`acpidump.exe -n VFCT -b`（[ACPICA](https://github.com/acpica/acpica/releases)）→ `vfct.dat`。
3. `python scripts/vfct-parse.py vfct.dat` → コネクタ `3114`（eDP）とパス `0002`（LCD1）を確認。
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` の後に `python scripts/vfct-parse.py VFCT-noeDP.aml`（コネクタ 4 個、チェックサム OK）。
5. `VFCT-noeDP.aml` を `EFI\OC\ACPI\` にコピーし、`config.plist` をバックアップして [opencore/config-snippet.plist](opencore/config-snippet.plist) を反映。
6. OpenCore 経由で再起動 → デバイス マネージャー：**Radeon Pro 560 —「このデバイスは正常に動作しています」** ✅

## 必要なもの
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B)。Radeon Pro 555 / 2016年モデルの A1707 も同様と思われますが **未検証** です。ID が異なるとスクリプトは中止します。
- Windows 10 22H2（19045 で検証）または Windows 11。ドライバーは AMD R6.4 30.0.13045.22003 / Boot Camp。
- **OpenCore**（1.0.6 で検証）：Apple のファームウェアだけでは ACPI テーブルを置き換えられません。
- Python 3 と ACPICA の `acpidump.exe`。

## 手順
1. 内蔵 ESP に **OpenCore をインストール** し、Windows が OpenCore 経由で起動することを確認。`config.plist` を復元できる USB を用意。
2. 管理者ターミナルで **VFCT をダンプ**：`acpidump.exe -n VFCT -b`。
3. **確認**：`python scripts/vfct-parse.py vfct.dat`。期待値：`obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`。
4. **パッチ**：`python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`。
5. **検証**：`python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`。
6. **ESP をマウント**：`mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`。`config.plist` をバックアップ。
7. **config.plist を編集**：スニペットの `ACPI > Add` と `ACPI > Delete` を追加（`VkZDVA==` =「VFCT」）。
8. OpenCore 経由で **再起動** し、デバイス マネージャーと `dxdiag` を確認。

## よくある質問
**なぜ画面が壊れてからコード 43 になったのですか？** VBIOS が eDP コネクタを宣言しています。ドライバーはパネルの電源を入れようとしますが HPD が来ず、ディスプレイ検出の約 0.4 秒後に自らデバイスを削除します → コード 43。

**ドライバー再インストール、Windows 11、新しい Adrenalin で直りますか？** いいえ。Apple 22.19、AMD R6.4、Adrenalin 26.5.2 はいずれも Windows 10/11 で失敗しました。

**内蔵 Intel GPU は必要ですか？** 不要です。画面のない A1707 で `apple_set_os.efi` を **使わないでください**。Apple ロゴで起動が止まりました。

**自分の VBIOS は含まれていますか？** いいえ。AMD/Apple の著作物なので、スクリプトで *ご自身の* ダンプをパッチします。

**macOS に影響はありますか？** OpenCore はすべての OS にテーブルを注入します。macOS はこの GPU で VFCT を使いませんが、パッチ適用後の macOS 起動はまだ再確認していません。テストしてください。

**ゲームはできますか？** はい。画面のない A1707 で Warframe（DirectX 11/12）のダウンロードと動作を確認済みです。

**蓋センサーに磁石を置けば直りますか？** 私たちのテストでは直りませんでした（`_LID` の上書きや DAL レジストリキーも効果なし）。

**Warframe ランチャー：「Could not create directory C:\Program Files\Warframe」？** ユーザーに「変更」権限を付与します（管理者で）：`icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`。

## トラブルシューティング
- **まだコード 43**：パッチ済みテーブルが有効か確認（SS が `106B:0179` の VFCT）。そうでなければ OpenCore が読み込んでいません（パス、`Enabled`、OpenCore を経由しない起動）。
- **スクリプトの「object not found」エラー**：VBIOS が異なります。`vfct-parse.py` を実行し、出力を添えて issue を作成してください。
- **Mac が起動しない / 白い Apple ロゴ**：リカバリ USB で起動（Option →「EFI Boot」）してバックアップを復元。または macOS で `sudo diskutil mount disk0s1` を実行しバックアップを書き戻します。
- **外部 4K モニターが約 30 Hz**：ケーブル・アダプター・ポートの制限と思われます。USB-C→DP か 1440p/1080p 60 Hz を使用。
- **起動ピッカーで画面が真っ黒**：OpenCore の `UEFI > Output > Resolution`（例：`1920x1080@32`）と `ForceResolution` を設定。

## インストール後：Boot Camp の Touch Bar とトラックパッド
2026年10月21日、同じ画面なし A1707（Windows 10 22H2、Boot Camp 6.1）で確認。

### Windows で Touch Bar が動かない / ESC キーがない
- 公式の Boot Camp 6.1 ドライバーはインストール済みで正常でした：**Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0。
- 原因：**`Bootcamp.exe`（Boot Camp のタスクトレイアプリ）が起動していなかった**。Touch Bar（ファンクションキー / ESC）を制御しているのはこのアプリです。
- 対処：`Bootcamp.exe` を再起動し、次に T1 複合デバイスを再起動（`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`）。**内蔵ディスプレイがなくても** Touch Bar と ESC が復活しました。

### トラックパッドの「タップでクリック」/「副ボタンのクリック」が再起動で消える
- Boot Camp はこの設定を `HKCU\Software\Apple Inc.\Trackpad\Mode`（DWORD、非公開のビット）にしか保存しません。
- `C:\Windows\System32\AppleControlPanel.exe` → Trackpad で設定し、値を読み取ります：`(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode`（私たちの値：`40`）。
- ログオンのたびに [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1)（`Mode` を書き込み、`Bootcamp.exe` を最大 5 回再起動）で再適用します。遅延 10 秒・再試行 3 回のタスクスケジューラーを使用。例（スクリプトを `C:\Tools\` にコピー、管理者で実行、`<user>` を置換）：
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
その後タスクスケジューラー → 設定：「タスクが失敗した場合 1 分ごとに再起動」「最大 3 回再起動を試みる」（または `Register-ScheduledTask` と `New-ScheduledTaskSettingsSet -RestartCount 3`）。

### 2本指スクロールが速すぎる
`HKCU\Control Panel\Desktop\WheelScrollLines` を `3` から `1` に変更し、`SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)` で即時反映。スクリプトでは `-WheelScrollLines 1` で実行できます。

## リポジトリの内容
| パス | 内容 |
|---|---|
| `scripts/vfct-patch.py` | eDP コネクタ/エンコーダと LCD1 パスを削除、LCD1 フラグをクリア、SSID を 106B:0179 に設定、チェックサムを修正 |
| `scripts/vfct-parse.py` | VFCT と ATOM オブジェクトテーブルを解析し、チェックサムを検証 |
| `scripts/bootcamp-reapply.ps1` | ログオン時にトラックパッド Mode を再適用し Bootcamp.exe（Touch Bar）を再起動 |
| `opencore/config-snippet.plist` | OpenCore の `ACPI > Delete + Add` エントリ |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | 技術論文全文（英語 / ポルトガル語） |

## クレジット
**Ryan Anthony Gibo**：作者、根本原因と修正の発見者、実機テスト。ACPICA、OpenCore（Acidanthera）、OpenCore Legacy Patcher に感謝します。役に立ったら ⭐ を付け、[CITATION.cff](CITATION.cff) で引用してください。

ライセンス: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click-stops-working-again-definitive-fix) and `scripts/trackpad/install.ps1`. By Ryan Anthony Gibo.

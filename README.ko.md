🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017 (A1707) Radeon Pro 560 / 555 코드 43 오류 해결 — 내장 디스플레이(eDP)가 깨지거나 제거된 Windows 10/11 Boot Camp, OpenCore로 VFCT VBIOS 패치

📄 **기술 논문:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **작성자 및 발견자: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — 2026년 10월 21일 근본 원인을 찾고 해결책을 만들었습니다.

**AMD Radeon Pro 560 또는 Radeon Pro 555**가 탑재된 **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)**의 장치 관리자에 **"이 장치에 문제가 있다고 보고되어 Windows에서 이 장치를 중지했습니다. (코드 43)"**가 표시되나요? **내장 디스플레이(LCD / eDP 패널)가 깨졌거나 분리·제거된** 상태에서 Mac을 **화면 없이(headless) 외장 모니터와** (USB-C, Thunderbolt 3, HDMI, DisplayPort) 사용하나요? **VBIOS가 여전히 내장 eDP 패널을 선언**하기 때문에 **AMD 드라이버(Boot Camp, Adrenalin)**가 실패합니다. 이 저장소는 Windows가 읽는 VBIOS 사본인 **ACPI VFCT 테이블**을 패치해 eDP 커넥터를 제거하고 **OpenCore**(`ACPI > Delete + Add`)로 주입해 해결합니다. 결과: **4 GB VRAM, DirectX 11/12, 하드웨어 가속**으로 Radeon Pro 560이 정상 작동합니다.

키워드: 맥북 프로 2017 코드 43 오류, A1707 Radeon Pro 560 코드 43, 부트캠프 액정 파손 그래픽카드, Radeon Pro 555 코드 43 윈도우 10, Radeon Pro 560 작동 안 함 윈도우 11, 화면 없는 맥북 프로 윈도우, Boot Camp headless, eDP AMD 드라이버, VFCT 패치, VBIOS, OpenCore 부트캠프 GPU, 맥북 프로 워프레임 Warframe, 윈도우 터치바 안 됨, 부트캠프 ESC 키 없음, 부트캠프 트랙패드 탭하여 클릭 재부팅 후 초기화, 부트캠프 우클릭, 두 손가락 스크롤 너무 빠름.

> ⚠️ **면책 조항 — 사용에 따른 위험은 본인 책임입니다.** 부트로더가 불러오는 펌웨어 테이블을 수정합니다. 잘못된 설정은 Mac 부팅을 막을 수 있습니다. 복구용 USB와 `config.plist` 백업을 준비하세요. 보증 없음([LICENSE](LICENSE)). Apple 및 AMD와 무관합니다.

## 빠른 해결 (TL;DR)
1. Windows로 부팅하고(Microsoft 기본 디스플레이 어댑터는 작동) 일반 Boot Camp / AMD 드라이버를 설치합니다(코드 43이 나오는 것이 정상).
2. VFCT 덤프: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → 커넥터 `3114`(eDP)와 경로 `0002`(LCD1) 확인.
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` 후 `python scripts/vfct-parse.py VFCT-noeDP.aml` (커넥터 4개, 체크섬 OK).
5. `VFCT-noeDP.aml`을 `EFI\OC\ACPI\`에 복사하고 `config.plist`를 백업한 뒤 [opencore/config-snippet.plist](opencore/config-snippet.plist) 적용.
6. OpenCore로 재부팅 → 장치 관리자: **Radeon Pro 560 — "이 장치가 올바르게 작동하고 있습니다"** ✅

## 요구 사항
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / 2016년형 A1707도 비슷할 것으로 보이나 **검증되지 않음**; ID가 다르면 스크립트가 중단됩니다.
- Windows 10 22H2(19045에서 테스트) 또는 Windows 11; 드라이버 AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore**(1.0.6 테스트): Apple 펌웨어만으로는 ACPI 테이블을 교체할 수 없습니다.
- Python 3와 ACPICA `acpidump.exe`.

## 단계별 가이드
1. 내장 ESP에 **OpenCore를 설치**하고 Windows가 OpenCore로 부팅되는지 확인합니다. `config.plist`를 복원할 수 있는 USB를 준비하세요.
2. 관리자 터미널에서 **VFCT 덤프**: `acpidump.exe -n VFCT -b`.
3. **확인**: `python scripts/vfct-parse.py vfct.dat`. 예상 결과: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **패치**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **검증**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **ESP 마운트**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; `config.plist` 백업.
7. **config.plist 편집**: 스니펫의 `ACPI > Add`와 `ACPI > Delete` 항목 추가(`VkZDVA==` = "VFCT").
8. OpenCore로 **재부팅**하고 장치 관리자와 `dxdiag`를 확인합니다.

## 자주 묻는 질문
**왜 화면이 고장 난 뒤에만 코드 43이 뜨나요?** VBIOS가 eDP 커넥터를 알립니다. 드라이버가 패널을 켜려 하지만 HPD를 받지 못하고 디스플레이 감지 약 0.4초 후 스스로 장치를 제거합니다 → 코드 43.

**드라이버 재설치, Windows 11, 최신 Adrenalin이 도움이 되나요?** 아니요. Apple 22.19, AMD R6.4, Adrenalin 26.5.2 모두 Windows 10과 11에서 실패했습니다.

**내장 Intel GPU가 필요한가요?** 아니요. 화면 없는 A1707에서 `apple_set_os.efi`를 **사용하지 마세요**: Apple 로고에서 부팅이 멈췄습니다.

**제 VBIOS가 포함되어 있나요?** 아니요. AMD/Apple 저작물이므로 스크립트가 *본인의* 덤프를 패치합니다.

**macOS에 영향이 있나요?** OpenCore는 모든 OS에 테이블을 주입합니다. macOS는 이 GPU에 VFCT를 사용하지 않지만, 패치 적용 후 macOS 부팅은 아직 재확인하지 않았습니다 — 테스트하세요.

**게임을 할 수 있나요?** 네: 화면 없는 A1707에서 Warframe(DirectX 11/12) 다운로드와 실행을 확인했습니다.

**덮개 센서에 자석을 두면 해결되나요?** 저희 테스트에서는 아니었습니다(`_LID` 오버라이드와 DAL 레지스트리 키도 효과 없음).

**Warframe 런처: "Could not create directory C:\Program Files\Warframe"?** 사용자에게 수정 권한을 부여하세요(관리자 권한): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## 문제 해결
- **여전히 코드 43**: 패치된 테이블이 활성인지 확인하세요(SS `106B:0179`인 VFCT). 아니면 OpenCore가 불러오지 않은 것입니다(경로, `Enabled`, OpenCore 없이 부팅).
- **스크립트 "object not found" 오류**: 다른 VBIOS입니다; `vfct-parse.py`를 실행하고 출력과 함께 issue를 올려 주세요.
- **Mac이 부팅되지 않음 / 흰색 Apple 로고**: 복구 USB로 부팅(Option → "EFI Boot")해 백업을 복원하거나, macOS에서 `sudo diskutil mount disk0s1` 후 백업을 다시 복사합니다.
- **외장 4K 모니터가 ~30 Hz**: 케이블/어댑터/포트 한계일 가능성이 큽니다. USB-C→DP 또는 60 Hz 1440p/1080p를 사용하세요.
- **부팅 선택 화면이 검은색**: OpenCore에서 `UEFI > Output > Resolution`(예: `1920x1080@32`)과 `ForceResolution` 설정.

## 설치 후: Boot Camp의 터치바와 트랙패드
2026년 10월 21일 같은 화면 없는 A1707(Windows 10 22H2, Boot Camp 6.1)에서 확인.

### Windows에서 터치바가 작동하지 않음 / ESC 키 없음
- 공식 Boot Camp 6.1 드라이버는 설치되어 정상이었습니다: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- 원인: **`Bootcamp.exe`(Boot Camp 트레이 앱)가 실행되지 않았습니다**; 이 앱이 터치바(기능 키 / ESC)를 구동합니다.
- 해결: `Bootcamp.exe`를 다시 실행한 다음 T1 복합 장치를 재시작합니다(`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). **내장 디스플레이 없이도** 터치바와 ESC가 돌아왔습니다.

### 트랙패드 탭하여 클릭 / 보조 클릭이 재부팅 후 사라짐
- Boot Camp는 이 옵션을 `HKCU\Software\Apple Inc.\Trackpad\Mode`(DWORD, 비공개 비트)에만 저장합니다.
- `C:\Windows\System32\AppleControlPanel.exe` → Trackpad에서 설정한 뒤 값을 읽습니다: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (저희 값: `40`).
- 로그온할 때마다 [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1)로 다시 적용합니다(`Mode` 기록, `Bootcamp.exe` 최대 5회 재시작). 10초 지연과 3회 재시도의 예약 작업을 사용합니다. 예시(스크립트를 `C:\Tools\`에 복사, 관리자 권한, `<user>` 교체):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
그다음 작업 스케줄러 → 설정: "작업이 실패하면 1분마다 다시 시작", "최대 3회 다시 시작 시도"(또는 `Register-ScheduledTask`와 `New-ScheduledTaskSettingsSet -RestartCount 3`).

### 두 손가락 스크롤이 너무 빠름
`HKCU\Control Panel\Desktop\WheelScrollLines`을 `3`에서 `1`로 바꾸고 `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`로 즉시 적용합니다. 스크립트는 `-WheelScrollLines 1`로 처리합니다.

## 저장소 구성
| 경로 | 설명 |
|---|---|
| `scripts/vfct-patch.py` | eDP 커넥터/인코더와 LCD1 경로 제거, LCD1 플래그 해제, SSID 106B:0179 설정, 체크섬 수정 |
| `scripts/vfct-parse.py` | VFCT와 ATOM 객체 테이블을 분석하고 체크섬 검증 |
| `scripts/bootcamp-reapply.ps1` | 로그온 시 트랙패드 Mode를 다시 적용하고 Bootcamp.exe(터치바) 재시작 |
| `opencore/config-snippet.plist` | OpenCore `ACPI > Delete + Add` 항목 |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | 전체 기술 논문(영어 / 포르투갈어) |

## 크레딧
**Ryan Anthony Gibo**: 작성자, 근본 원인과 해결책 발견, 실기기 테스트. ACPICA, OpenCore(Acidanthera), OpenCore Legacy Patcher에 감사드립니다. 도움이 되었다면 ⭐를 누르고 [CITATION.cff](CITATION.cff)로 인용해 주세요.

라이선스: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

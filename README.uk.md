🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Виправлення помилки «Код 43» Radeon Pro 560 / 555 на MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp з розбитим або знятим вбудованим екраном (eDP), патч VBIOS VFCT через OpenCore

📄 **Технічна стаття:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Автор і першовідкривач: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — причину знайдено, а виправлення створено 21.10.2026.

Ваш **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** з **AMD Radeon Pro 560 або Radeon Pro 555** показує в Диспетчері пристроїв **«Windows зупинила цей пристрій, оскільки він повідомив про проблеми. (Код 43)»**? **Вбудований екран (LCD / панель eDP) розбитий, відключений або знятий**, а Mac працює **без екрана (headless) із зовнішнім монітором** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? **Драйвер AMD (Boot Camp, Adrenalin)** падає, бо **VBIOS досі оголошує вбудовану панель eDP**. Цей репозиторій це виправляє: патчить **ACPI-таблицю VFCT** (копію VBIOS, яку читає Windows), видаляє роз'єм eDP і підвантажує її через **OpenCore** (`ACPI > Delete + Add`). Результат: Radeon Pro 560 працює з **4 ГБ VRAM, DirectX 11/12 і апаратним прискоренням**.

Ключові слова: MacBook Pro 2017 помилка код 43, A1707 Radeon Pro 560 код 43, Boot Camp розбитий екран відеокарта, Radeon Pro 555 код 43 Windows 10, Radeon Pro 560 не працює Windows 11, MacBook Pro без екрана Windows, Boot Camp headless, eDP драйвер AMD, патч VFCT, VBIOS, OpenCore Boot Camp відеокарта, Warframe на MacBook Pro, Touch Bar не працює у Windows, немає клавіші ESC Boot Camp, трекпад Boot Camp дотик для натискання скидається після перезавантаження, правий клік Boot Camp, прокрутка двома пальцями занадто швидка.

> ⚠️ **ВІДМОВА ВІД ВІДПОВІДАЛЬНОСТІ — НА ВЛАСНИЙ РИЗИК.** Ви змінюєте таблиці прошивки, які завантажує завантажувач. Неправильна конфігурація може завадити запуску Mac. Майте USB для відновлення та копію `config.plist`. Без гарантій ([LICENSE](LICENSE)). Не пов'язано з Apple чи AMD.

## Швидке рішення (TL;DR)
1. Завантажте Windows (базовий відеоадаптер Microsoft працює) і встановіть звичайний драйвер Boot Camp / AMD (буде Код 43 — так і має бути).
2. Зніміть дамп VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → переконайтеся, що є роз'єм `3114` (eDP) і шлях `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`, потім `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 роз'єми, контрольні суми OK).
5. Скопіюйте `VFCT-noeDP.aml` в `EFI\OC\ACPI\`, зробіть копію `config.plist` і додайте [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Перезавантажтеся через OpenCore → Диспетчер пристроїв: **Radeon Pro 560 — «Пристрій працює належним чином»** ✅

## Вимоги
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 року, ймовірно, так само, але **не перевірено**; скрипт зупиняється, якщо ID відрізняються.
- Windows 10 22H2 (перевірено 19045) або Windows 11; драйвер AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (перевірено 1.0.6): прошивка Apple не може підміняти ACPI-таблиці.
- Python 3 і `acpidump.exe` з ACPICA.

## Покрокова інструкція
1. **Встановіть OpenCore** на внутрішній ESP і переконайтеся, що Windows завантажується через нього. Майте USB, що відновить `config.plist`.
2. **Зніміть дамп VFCT** у терміналі адміністратора: `acpidump.exe -n VFCT -b`.
3. **Перевірте**: `python scripts/vfct-parse.py vfct.dat`. Очікується: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Пропатчте**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Перевірте результат**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Підключіть ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; зробіть копію `config.plist`.
7. **Відредагуйте config.plist**: додайте записи `ACPI > Add` і `ACPI > Delete` зі сніпета (`VkZDVA==` = «VFCT»).
8. **Перезавантажтеся** через OpenCore і перевірте Диспетчер пристроїв та `dxdiag`.

## Часті запитання
**Чому Код 43 з'явився лише після поломки екрана?** VBIOS оголошує роз'єм eDP. Драйвер намагається увімкнути панель, не отримує HPD і відключається через ~0,4 с після виявлення дисплеїв → Код 43.

**Чи допоможе перевстановлення драйверів, Windows 11 або новіший Adrenalin?** Ні. Apple 22.19, AMD R6.4 і Adrenalin 26.5.2 не запрацювали ні у Windows 10, ні в 11.

**Чи потрібна вбудована графіка Intel?** Ні. **Не** використовуйте `apple_set_os.efi` на A1707 без екрана: завантаження зависло на логотипі Apple.

**Чи є мій VBIOS у репозиторії?** Ні. Він захищений авторським правом AMD/Apple; скрипт патчить *ваш власний* дамп.

**Чи впливає це на macOS?** OpenCore підвантажує таблиці для всіх систем. macOS не використовує VFCT для цієї відеокарти, але завантаження macOS з патчем ще не перевірено повторно — перевірте.

**Чи можна грати?** Так: підтверджено з Warframe (DirectX 11/12), який завантажується і працює на A1707 без екрана.

**Чи допоможе магніт біля датчика кришки?** У наших тестах ні (як і підміна `_LID` та ключі DAL у реєстрі).

**Лаунчер Warframe: «Could not create directory C:\Program Files\Warframe»?** Надайте своєму користувачу право «Змінення» (від адміністратора): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Усунення несправностей
- **Досі Код 43**: перевірте, чи активна пропатчена таблиця (VFCT з SS `106B:0179`). Якщо ні — OpenCore її не завантажив (шлях, `Enabled`, завантаження без OpenCore).
- **Помилка скрипта «object not found»**: інший VBIOS; запустіть `vfct-parse.py` і створіть issue з виводом.
- **Mac не завантажується / білий логотип Apple**: завантажтеся з USB відновлення (Option → «EFI Boot») і поверніть копію; або в macOS `sudo diskutil mount disk0s1` і скопіюйте копію назад.
- **Зовнішній 4K-монітор на ~30 Гц**: імовірно обмеження кабелю/адаптера/порту. Використовуйте USB-C→DP або 1440p/1080p при 60 Гц.
- **Чорний екран у меню вибору завантаження**: в OpenCore `UEFI > Output > Resolution` (наприклад, `1920x1080@32`) і `ForceResolution`.

## Після встановлення: Touch Bar і трекпад у Boot Camp
Перевірено 21.10.2026 на тому ж A1707 без екрана (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar не працює у Windows / немає клавіші ESC
- Офіційні драйвери Boot Camp 6.1 були встановлені та справні: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Причина: **`Bootcamp.exe` (застосунок Boot Camp у треї) не був запущений**; саме він керує Touch Bar (функціональні клавіші / ESC).
- Рішення: перезапустіть `Bootcamp.exe`, потім складений пристрій T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar і ESC повернулися **навіть без вбудованого екрана**.

### Дотик для натискання / вторинний клік трекпада скидаються після перезавантаження
- Boot Camp зберігає ці налаштування лише в `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, недокументовані біти).
- Налаштуйте їх у `C:\Windows\System32\AppleControlPanel.exe` → Trackpad і прочитайте значення: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (у нас: `40`).
- Застосовуйте його під час кожного входу за допомогою [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (записує `Mode`, перезапускає `Bootcamp.exe` до 5 спроб) із завдання Планувальника із затримкою 10 с і 3 повторами. Приклад (скопіюйте скрипт у `C:\Tools\`, від адміністратора, замініть `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Потім у Планувальнику завдань → Параметри: «У разі збою перезапускати кожну 1 хвилину», «Не більше 3 спроб» (або `Register-ScheduledTask` з `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Прокрутка двома пальцями занадто швидка
`HKCU\Control Panel\Desktop\WheelScrollLines` з `3` на `1`, застосовується одразу через `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Скрипт робить це з `-WheelScrollLines 1`.

## Вміст репозиторію
| Шлях | Призначення |
|---|---|
| `scripts/vfct-patch.py` | Видаляє роз'єм/енкодер eDP і шлях LCD1, знімає прапорець LCD1, ставить SSID 106B:0179, виправляє контрольні суми |
| `scripts/vfct-parse.py` | Розбирає VFCT і таблицю об'єктів ATOM, перевіряє контрольні суми |
| `scripts/bootcamp-reapply.ps1` | Відновлює Mode трекпада і перезапускає Bootcamp.exe (Touch Bar) під час входу |
| `opencore/config-snippet.plist` | Записи OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Повна технічна стаття (англійська / португальська) |

## Подяки
**Ryan Anthony Gibo**: автор, знайшов причину й виправлення, тести на залізі. Дякуємо ACPICA, OpenCore (Acidanthera) і OpenCore Legacy Patcher. Допомогло? Поставте ⭐ і цитуйте через [CITATION.cff](CITATION.cff).

Ліцензія: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

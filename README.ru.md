🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Исправление ошибки «Код 43» Radeon Pro 560 / 555 на MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp с разбитым или снятым встроенным экраном (eDP), патч VBIOS VFCT через OpenCore

📄 **Техническая статья:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Автор и первооткрыватель: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — причина найдена и исправление создано 21.10.2026.

Ваш **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** с **AMD Radeon Pro 560 или Radeon Pro 555** показывает в Диспетчере устройств **«Система Windows остановила это устройство, так как оно сообщило о возникновении неполадок. (Код 43)»**? **Встроенный экран (LCD / панель eDP) разбит, отключён или снят**, а Mac работает **без экрана (headless) с внешним монитором** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? **Драйвер AMD (Boot Camp, Adrenalin)** падает, потому что **VBIOS по-прежнему объявляет встроенную панель eDP**. Этот репозиторий решает проблему: патчит **ACPI-таблицу VFCT** (копию VBIOS, которую читает Windows), удаляет разъём eDP и подгружает её через **OpenCore** (`ACPI > Delete + Add`). Итог: Radeon Pro 560 работает с **4 ГБ VRAM, DirectX 11/12 и аппаратным ускорением**.

Ключевые слова: MacBook Pro 2017 ошибка код 43, A1707 Radeon Pro 560 код 43, Boot Camp разбит экран видеокарта не работает, Radeon Pro 555 код 43 Windows 10, Radeon Pro 560 не работает Windows 11, MacBook Pro без экрана Windows, Boot Camp headless, eDP драйвер AMD, патч VFCT, VBIOS, OpenCore Boot Camp видеокарта, Warframe на MacBook Pro, Touch Bar не работает в Windows, нет клавиши ESC Boot Camp, трекпад Boot Camp касание для нажатия сбрасывается после перезагрузки, правый клик Boot Camp, прокрутка двумя пальцами слишком быстрая.

> ⚠️ **ОТКАЗ ОТ ОТВЕТСТВЕННОСТИ — НА ВАШ СТРАХ И РИСК.** Вы изменяете таблицы прошивки, которые загружает загрузчик. Неверная конфигурация может помешать загрузке Mac. Держите под рукой USB для восстановления и копию `config.plist`. Без гарантий ([LICENSE](LICENSE)). Не связано с Apple или AMD.

## Быстрое решение (TL;DR)
1. Загрузите Windows (базовый видеоадаптер Microsoft работает) и установите обычный драйвер Boot Camp / AMD (будет Код 43 — так и должно быть).
2. Снимите дамп VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → убедитесь, что есть разъём `3114` (eDP) и путь `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`, затем `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 разъёма, контрольные суммы OK).
5. Скопируйте `VFCT-noeDP.aml` в `EFI\OC\ACPI\`, сделайте копию `config.plist` и добавьте [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Перезагрузитесь через OpenCore → Диспетчер устройств: **Radeon Pro 560 — «Устройство работает нормально»** ✅

## Требования
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 года, вероятно, аналогично, но **не проверено**; скрипт прерывается, если ID отличаются.
- Windows 10 22H2 (проверено 19045) или Windows 11; драйвер AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (проверено 1.0.6): прошивка Apple не умеет подменять ACPI-таблицы.
- Python 3 и `acpidump.exe` из ACPICA.

## Пошаговая инструкция
1. **Установите OpenCore** на внутренний раздел ESP и убедитесь, что Windows загружается через него. Подготовьте USB, который восстановит `config.plist`.
2. **Снимите дамп VFCT** в терминале администратора: `acpidump.exe -n VFCT -b`.
3. **Проверьте**: `python scripts/vfct-parse.py vfct.dat`. Ожидается: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Пропатчите**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Проверьте результат**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Подключите ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; сделайте копию `config.plist`.
7. **Отредактируйте config.plist**: добавьте записи `ACPI > Add` и `ACPI > Delete` из сниппета (`VkZDVA==` = «VFCT»).
8. **Перезагрузитесь** через OpenCore и проверьте Диспетчер устройств и `dxdiag`.

## Частые вопросы
**Почему Код 43 появился только после поломки экрана?** VBIOS объявляет разъём eDP. Драйвер пытается включить панель, не получает HPD и отключается через ~0,4 с после обнаружения дисплеев → Код 43.

**Поможет ли переустановка драйверов, Windows 11 или новый Adrenalin?** Нет. Apple 22.19, AMD R6.4 и Adrenalin 26.5.2 не заработали ни в Windows 10, ни в 11.

**Нужна ли встроенная графика Intel?** Нет. **Не** используйте `apple_set_os.efi` на A1707 без экрана: загрузка зависла на логотипе Apple.

**Входит ли мой VBIOS в репозиторий?** Нет. Он защищён авторским правом AMD/Apple; скрипт патчит *ваш собственный* дамп.

**Влияет ли это на macOS?** OpenCore подгружает таблицы для всех систем. macOS не использует VFCT для этой видеокарты, но загрузка macOS с патчем ещё не перепроверена — проверьте.

**Можно ли играть?** Да: проверено на Warframe (DirectX 11/12), который скачивается и работает на A1707 без экрана.

**Поможет ли магнит у датчика крышки?** В наших тестах нет (как и подмена `_LID` и ключи DAL в реестре).

**Лаунчер Warframe: «Could not create directory C:\Program Files\Warframe»?** Дайте своему пользователю право «Изменение» (от администратора): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Устранение неполадок
- **Всё ещё Код 43**: проверьте, активна ли пропатченная таблица (VFCT с SS `106B:0179`). Если нет — OpenCore её не загрузил (путь, `Enabled`, загрузка без OpenCore).
- **Ошибка скрипта «object not found»**: другой VBIOS; запустите `vfct-parse.py` и создайте issue с выводом.
- **Mac не загружается / белый логотип Apple**: загрузитесь с USB восстановления (Option → «EFI Boot») и верните копию; или в macOS `sudo diskutil mount disk0s1` и скопируйте копию обратно.
- **Внешний 4K-монитор на ~30 Гц**: скорее всего ограничение кабеля/адаптера/порта. Используйте USB-C→DP или 1440p/1080p при 60 Гц.
- **Чёрный экран в меню выбора загрузки**: в OpenCore `UEFI > Output > Resolution` (например, `1920x1080@32`) и `ForceResolution`.

## После установки: Touch Bar и трекпад в Boot Camp
Проверено 21.10.2026 на том же A1707 без экрана (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar не работает в Windows / нет клавиши ESC
- Официальные драйверы Boot Camp 6.1 были установлены и исправны: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Причина: **`Bootcamp.exe` (приложение Boot Camp в трее) не было запущено**; именно оно управляет Touch Bar (функциональные клавиши / ESC).
- Решение: перезапустите `Bootcamp.exe`, затем составное устройство T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar и ESC вернулись **даже без встроенного экрана**.

### Касание для нажатия / вторичный клик трекпада сбрасываются после перезагрузки
- Boot Camp хранит эти настройки только в `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, недокументированные биты).
- Настройте их в `C:\Windows\System32\AppleControlPanel.exe` → Trackpad и прочитайте значение: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (у нас: `43`).
- Применяйте его при каждом входе с помощью [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (записывает `Mode`, перезапускает `Bootcamp.exe` до 5 попыток) из задачи Планировщика с задержкой 10 с и 3 повторами. Пример (скопируйте скрипт в `C:\Tools\`, от администратора, замените `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Затем в Планировщике заданий → Параметры: «При сбое перезапускать каждую 1 минуту», «Не более 3 попыток» (или `Register-ScheduledTask` с `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Прокрутка двумя пальцами слишком быстрая
`HKCU\Control Panel\Desktop\WheelScrollLines` с `3` на `1`, применяется сразу через `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Скрипт делает это с `-WheelScrollLines 1`.

## Содержимое репозитория
| Путь | Назначение |
|---|---|
| `scripts/vfct-patch.py` | Удаляет разъём/энкодер eDP и путь LCD1, снимает флаг LCD1, ставит SSID 106B:0179, исправляет контрольные суммы |
| `scripts/vfct-parse.py` | Разбирает VFCT и таблицу объектов ATOM, проверяет контрольные суммы |
| `scripts/bootcamp-reapply.ps1` | Восстанавливает Mode трекпада и перезапускает Bootcamp.exe (Touch Bar) при входе |
| `opencore/config-snippet.plist` | Записи OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Полная техническая статья (английский / португальский) |

## Благодарности
**Ryan Anthony Gibo**: автор, нашёл причину и исправление, тесты на железе. Спасибо ACPICA, OpenCore (Acidanthera) и OpenCore Legacy Patcher. Помогло? Поставьте ⭐ и цитируйте через [CITATION.cff](CITATION.cff).

Лицензия: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

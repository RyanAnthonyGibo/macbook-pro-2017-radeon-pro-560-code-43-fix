🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Naprawa błędu Kod 43 Radeon Pro 560 / 555 w MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp z uszkodzonym lub usuniętym wbudowanym ekranem (eDP), łatka VBIOS VFCT przez OpenCore

📄 **Artykuł techniczny:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Autor i odkrywca: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — przyczyna znaleziona, a poprawka stworzona 21.10.2026.

Twój **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** z **AMD Radeon Pro 560 lub Radeon Pro 555** pokazuje w Menedżerze urządzeń **„System Windows zatrzymał to urządzenie, ponieważ zgłosiło ono problemy. (Kod 43)”**? **Wbudowany ekran (LCD / panel eDP) jest uszkodzony, odłączony lub usunięty**, a Mac działa **bez ekranu (headless) z zewnętrznym monitorem** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? **Sterownik AMD (Boot Camp, Adrenalin)** zawodzi, bo **VBIOS wciąż deklaruje wewnętrzny panel eDP**. To repozytorium to naprawia: łata **tabelę ACPI VFCT** (kopię VBIOS czytaną przez Windows), usuwa złącze eDP i wstrzykuje ją przez **OpenCore** (`ACPI > Delete + Add`). Efekt: Radeon Pro 560 działa z **4 GB VRAM, DirectX 11/12 i akceleracją sprzętową**.

Słowa kluczowe: MacBook Pro 2017 błąd kod 43, A1707 Radeon Pro 560 kod 43, Boot Camp zbity ekran karta graficzna, Radeon Pro 555 kod 43 Windows 10, Radeon Pro 560 nie działa Windows 11, MacBook Pro bez ekranu Windows, Boot Camp headless, eDP sterownik AMD, łatka VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe na MacBook Pro, Touch Bar nie działa w Windows, brak klawisza ESC Boot Camp, gładzik Boot Camp stuknięcie jako kliknięcie resetuje się po restarcie, prawy przycisk Boot Camp, przewijanie dwoma palcami za szybkie.

> ⚠️ **ZASTRZEŻENIE — NA WŁASNE RYZYKO.** Modyfikujesz tabele firmware ładowane przez bootloader. Błędna konfiguracja może uniemożliwić start Maca. Miej pendrive ratunkowy i kopię `config.plist`. Brak gwarancji ([LICENSE](LICENSE)). Brak powiązań z Apple i AMD.

## Szybka poprawka (TL;DR)
1. Uruchom Windows (działa podstawowa karta grafiki Microsoft) i zainstaluj zwykły sterownik Boot Camp / AMD (pokaże Kod 43 — to oczekiwane).
2. Zrzuć VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → potwierdź złącze `3114` (eDP) i ścieżkę `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`, a potem `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 złącza, sumy kontrolne OK).
5. Skopiuj `VFCT-noeDP.aml` do `EFI\OC\ACPI\`, zrób kopię `config.plist` i dodaj [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Uruchom ponownie przez OpenCore → Menedżer urządzeń: **Radeon Pro 560 — „To urządzenie działa poprawnie”** ✅

## Wymagania
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 z 2016 prawdopodobnie podobnie, ale **niezweryfikowane**; skrypt przerywa, jeśli ID się różnią.
- Windows 10 22H2 (testowane 19045) lub Windows 11; sterownik AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (testowane 1.0.6): firmware Apple nie potrafi podmieniać tabel ACPI.
- Python 3 i `acpidump.exe` z ACPICA.

## Instrukcja krok po kroku
1. **Zainstaluj OpenCore** na wewnętrznej partycji ESP i sprawdź, czy Windows przez niego startuje. Miej pendrive, który przywróci `config.plist`.
2. **Zrzuć VFCT** w terminalu administratora: `acpidump.exe -n VFCT -b`.
3. **Sprawdź**: `python scripts/vfct-parse.py vfct.dat`. Oczekiwane: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Załataj**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Zweryfikuj**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Zamontuj ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; zrób kopię `config.plist`.
7. **Edytuj config.plist**: dodaj wpisy `ACPI > Add` i `ACPI > Delete` ze snippetu (`VkZDVA==` = „VFCT”).
8. **Uruchom ponownie** przez OpenCore i sprawdź Menedżer urządzeń oraz `dxdiag`.

## FAQ
**Dlaczego Kod 43 pojawił się dopiero po uszkodzeniu ekranu?** VBIOS zgłasza złącze eDP. Sterownik próbuje włączyć panel, nie dostaje HPD i wycofuje się ~0,4 s po wykryciu ekranów → Kod 43.

**Czy pomoże reinstalacja sterowników, Windows 11 albo nowszy Adrenalin?** Nie. Apple 22.19, AMD R6.4 i Adrenalin 26.5.2 zawiodły w Windows 10 i 11.

**Czy potrzebuję zintegrowanej grafiki Intel?** Nie. **Nie** używaj `apple_set_os.efi` w A1707 bez ekranu: start zawiesił się na logo Apple.

**Czy mój VBIOS jest dołączony?** Nie. Jest chroniony prawami autorskimi AMD/Apple; skrypt łata *twój własny* zrzut.

**Czy to wpływa na macOS?** OpenCore wstrzykuje tabele dla każdego systemu. macOS nie używa VFCT dla tej karty, ale start macOS z łatką nie został jeszcze ponownie sprawdzony — przetestuj.

**Czy mogę grać?** Tak: potwierdzone z Warframe (DirectX 11/12), który pobiera się i działa na A1707 bez ekranu.

**Czy magnes przy czujniku pokrywy pomoże?** Nie w naszych testach (podobnie override `_LID` i klucze DAL w rejestrze).

**Launcher Warframe: „Could not create directory C:\Program Files\Warframe”?** Nadaj swojemu użytkownikowi uprawnienie Modyfikacja (jako admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Rozwiązywanie problemów
- **Nadal Kod 43**: sprawdź, czy załatana tabela jest aktywna (VFCT z SS `106B:0179`). Jeśli nie, OpenCore jej nie załadował (ścieżka, `Enabled`, start bez OpenCore).
- **Błąd skryptu „object not found”**: inny VBIOS; uruchom `vfct-parse.py` i zgłoś issue z wynikiem.
- **Mac nie startuje / białe logo Apple**: uruchom pendrive ratunkowy (Option → „EFI Boot”) i przywróć kopię; albo w macOS `sudo diskutil mount disk0s1` i skopiuj kopię z powrotem.
- **Zewnętrzny monitor 4K w ~30 Hz**: prawdopodobnie limit kabla/adaptera/portu. Użyj USB-C→DP albo 1440p/1080p przy 60 Hz.
- **Czarny ekran w wyborze dysku startowego**: w OpenCore `UEFI > Output > Resolution` (np. `1920x1080@32`) i `ForceResolution`.

## Po instalacji: Touch Bar i gładzik w Boot Camp
Sprawdzone 21.10.2026 na tym samym A1707 bez ekranu (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar nie działa w Windows / brak klawisza ESC
- Oficjalne sterowniki Boot Camp 6.1 były zainstalowane i sprawne: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Przyczyna: **`Bootcamp.exe` (aplikacja Boot Camp w zasobniku) nie działała**; to ona obsługuje Touch Bar (klawisze funkcyjne / ESC).
- Rozwiązanie: uruchom ponownie `Bootcamp.exe`, a potem urządzenie złożone T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar i ESC wróciły **nawet bez wbudowanego ekranu**.

### Stuknięcie jako kliknięcie / kliknięcie dodatkowe gładzika znikają po restarcie
- Boot Camp zapisuje te opcje tylko w `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, nieudokumentowane bity).
- Ustaw je w `C:\Windows\System32\AppleControlPanel.exe` → Trackpad i odczytaj wartość: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (u nas: `40`).
- Przywracaj ją przy każdym logowaniu za pomocą [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (zapisuje `Mode`, restartuje `Bootcamp.exe` do 5 prób) z zadania harmonogramu z opóźnieniem 10 s i 3 ponowieniami. Przykład (skopiuj skrypt do `C:\Tools\`, jako admin, zamień `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Następnie w Harmonogramie zadań → Ustawienia: „Jeśli zadanie się nie powiedzie, uruchom ponownie co 1 minutę”, „Próbuj do 3 razy” (lub `Register-ScheduledTask` z `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Przewijanie dwoma palcami za szybkie
`HKCU\Control Panel\Desktop\WheelScrollLines` z `3` na `1`, zastosowane od razu przez `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Skrypt robi to z `-WheelScrollLines 1`.

## Zawartość repozytorium
| Ścieżka | Opis |
|---|---|
| `scripts/vfct-patch.py` | Usuwa złącze/enkoder eDP i ścieżkę LCD1, czyści flagę LCD1, ustawia SSID 106B:0179, poprawia sumy kontrolne |
| `scripts/vfct-parse.py` | Analizuje VFCT i tabelę obiektów ATOM, sprawdza sumy kontrolne |
| `scripts/bootcamp-reapply.ps1` | Przywraca Mode gładzika i restartuje Bootcamp.exe (Touch Bar) przy logowaniu |
| `opencore/config-snippet.plist` | Wpisy OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Pełny artykuł techniczny (angielski / portugalski) |

## Podziękowania
**Ryan Anthony Gibo**: autor, odkrywca przyczyny i poprawki, testy na sprzęcie. Podziękowania dla ACPICA, OpenCore (Acidanthera) i OpenCore Legacy Patcher. Pomogło? Daj ⭐ i cytuj przez [CITATION.cff](CITATION.cff).

Licencja: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click-stops-working-again-definitive-fix) and `scripts/trackpad/install.ps1`. By Ryan Anthony Gibo.

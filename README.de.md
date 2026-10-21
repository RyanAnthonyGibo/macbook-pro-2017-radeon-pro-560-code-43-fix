🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017 (A1707) Radeon Pro 560 / 555 Code 43 Fix — Windows 10/11 Boot Camp mit kaputtem oder ausgebautem internen Display (eDP), VFCT-VBIOS-Patch per OpenCore

📄 **Technisches Paper:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Autor und Entdecker: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — Ursache gefunden und Fix erstellt am 21.10.2026.

Zeigt dein **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** mit **AMD Radeon Pro 560 oder Radeon Pro 555** im Geräte-Manager **„Das Gerät wurde von Windows angehalten, da Probleme festgestellt wurden. (Code 43)“**? Ist das **interne Display (LCD / eDP-Panel) kaputt, abgesteckt oder ausgebaut** und nutzt du den Mac **ohne Bildschirm (headless) mit externem Monitor** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? Dann scheitert der **AMD-Treiber (Boot Camp, Adrenalin)**, weil das **VBIOS weiterhin das interne eDP-Panel meldet**. Dieses Repo behebt das: Es patcht die **ACPI-Tabelle VFCT** (die VBIOS-Kopie, die Windows liest), entfernt den eDP-Anschluss und lädt sie per **OpenCore** (`ACPI > Delete + Add`). Ergebnis: Radeon Pro 560 läuft mit **4 GB VRAM, DirectX 11/12 und Hardwarebeschleunigung**.

Suchbegriffe: MacBook Pro 2017 Fehler Code 43, A1707 Radeon Pro 560 Code 43, Boot Camp Display kaputt Grafikkarte, Radeon Pro 555 Code 43 Windows 10, Radeon Pro 560 funktioniert nicht Windows 11, MacBook Pro ohne Display Windows, Boot Camp headless, eDP AMD Treiber, VFCT Patch, VBIOS, OpenCore Boot Camp GPU, Warframe auf MacBook Pro, Touch Bar funktioniert nicht unter Windows, ESC-Taste fehlt Boot Camp, Boot Camp Trackpad Tippen zum Klicken nach Neustart weg, Rechtsklick Boot Camp, Zwei-Finger-Scrollen zu schnell.

> ⚠️ **HAFTUNGSAUSSCHLUSS — NUTZUNG AUF EIGENE GEFAHR.** Du veränderst Firmware-Tabellen, die der Bootloader lädt. Eine falsche Konfiguration kann den Start verhindern. Halte einen Rettungs-USB-Stick und ein Backup der `config.plist` bereit. Keine Gewährleistung ([LICENSE](LICENSE)). Nicht mit Apple oder AMD verbunden.

## Schnelle Lösung (TL;DR)
1. Windows starten (Microsoft-Basisanzeigeadapter funktioniert) und den normalen Boot-Camp-/AMD-Treiber installieren (er zeigt Code 43 — erwartet).
2. VFCT auslesen: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → Anschluss `3114` (eDP) und Pfad `0002` (LCD1) prüfen.
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`, danach `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 Anschlüsse, Prüfsummen OK).
5. `VFCT-noeDP.aml` nach `EFI\OC\ACPI\` kopieren, `config.plist` sichern und [opencore/config-snippet.plist](opencore/config-snippet.plist) übernehmen.
6. Über OpenCore neu starten → Geräte-Manager: **Radeon Pro 560 — „Das Gerät funktioniert einwandfrei“** ✅

## Voraussetzungen
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 von 2016 vermutlich ähnlich, aber **nicht geprüft**; das Skript bricht ab, wenn die IDs abweichen.
- Windows 10 22H2 (getestet 19045) oder Windows 11; Treiber AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (getestet 1.0.6): Apples Firmware kann keine ACPI-Tabellen ersetzen.
- Python 3 und `acpidump.exe` aus ACPICA.

## Schritt-für-Schritt-Anleitung
1. **OpenCore** auf der internen ESP installieren und prüfen, dass Windows darüber startet. Einen USB-Stick bereithalten, der `config.plist` wiederherstellen kann.
2. **VFCT auslesen** in einer Admin-Konsole: `acpidump.exe -n VFCT -b`.
3. **Prüfen**: `python scripts/vfct-parse.py vfct.dat`. Erwartet: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Patchen**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Validieren**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **ESP einhängen**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; `config.plist` sichern.
7. **config.plist bearbeiten**: die Einträge `ACPI > Add` und `ACPI > Delete` aus dem Snippet hinzufügen (`VkZDVA==` = „VFCT“).
8. Über OpenCore **neu starten**, Geräte-Manager und `dxdiag` prüfen.

## FAQ
**Warum Code 43 erst, nachdem das Display kaputt war?** Das VBIOS meldet einen eDP-Anschluss. Der Treiber versucht das Panel einzuschalten, bekommt kein HPD und meldet sich ~0,4 s nach der Displayerkennung ab → Code 43.

**Helfen Treiber-Neuinstallation, Windows 11 oder ein neueres Adrenalin?** Nein. Apple 22.19, AMD R6.4 und Adrenalin 26.5.2 scheiterten unter Windows 10 und 11.

**Brauche ich die integrierte Intel-GPU?** Nein. **Kein** `apple_set_os.efi` auf einem A1707 ohne Display: Der Start blieb am Apple-Logo hängen.

**Wird mein VBIOS mitgeliefert?** Nein. Es ist urheberrechtlich von AMD/Apple geschützt; das Skript patcht *deinen eigenen* Dump.

**Betrifft das macOS?** OpenCore lädt die Tabellen für alle Systeme. macOS nutzt die VFCT für diese GPU nicht, aber der macOS-Start mit dem Patch wurde noch nicht erneut geprüft — teste es.

**Kann ich spielen?** Ja: bestätigt mit Warframe (DirectX 11/12), das auf einem A1707 ohne Display lädt und läuft.

**Hilft ein Magnet am Deckelsensor?** In unseren Tests nicht (auch kein `_LID`-Override und keine DAL-Registry-Schlüssel).

**Warframe-Launcher: „Could not create directory C:\Program Files\Warframe“?** Gib deinem Benutzer das Recht „Ändern“ (als Admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Fehlerbehebung
- **Weiterhin Code 43**: Prüfen, ob die gepatchte Tabelle aktiv ist (VFCT mit SS `106B:0179`). Falls nicht, hat OpenCore sie nicht geladen (Pfad, `Enabled`, Start ohne OpenCore).
- **Skriptfehler „object not found“**: anderes VBIOS; `vfct-parse.py` ausführen und ein Issue mit der Ausgabe öffnen.
- **Mac startet nicht / weißes Apple-Logo**: Rettungs-USB starten (Option → „EFI Boot“) und Backup wiederherstellen; oder unter macOS `sudo diskutil mount disk0s1` und das Backup zurückkopieren.
- **Externer 4K-Monitor mit ~30 Hz**: vermutlich Kabel-/Adapter-/Port-Limit. USB-C→DP nutzen oder 1440p/1080p mit 60 Hz.
- **Schwarzer Bildschirm in der Bootauswahl**: in OpenCore `UEFI > Output > Resolution` (z. B. `1920x1080@32`) und `ForceResolution`.

## Nach der Installation: Touch Bar und Trackpad unter Boot Camp
Geprüft am 21.10.2026 auf demselben A1707 ohne Display (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar funktioniert nicht unter Windows / ESC-Taste fehlt
- Die offiziellen Boot-Camp-6.1-Treiber waren installiert und in Ordnung: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Ursache: **`Bootcamp.exe` (die Boot-Camp-App im Infobereich) lief nicht**; sie steuert die Touch Bar (Funktionstasten / ESC).
- Lösung: `Bootcamp.exe` neu starten, danach das T1-Verbundgerät (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar und ESC waren wieder da — **auch ohne internes Display**.

### Trackpad „Tippen zum Klicken“ / Sekundärklick nach Neustart zurückgesetzt
- Boot Camp speichert diese Optionen nur in `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, undokumentierte Bits).
- In `C:\Windows\System32\AppleControlPanel.exe` → Trackpad einstellen und den Wert auslesen: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (bei uns: `40`).
- Bei jeder Anmeldung mit [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) neu setzen (schreibt `Mode`, startet `Bootcamp.exe` bis zu 5-mal neu) über eine geplante Aufgabe mit 10 s Verzögerung und 3 Wiederholungen. Beispiel (Skript nach `C:\Tools\` kopieren, als Admin, `<user>` ersetzen):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Danach in der Aufgabenplanung → Einstellungen: „Bei Fehler alle 1 Minute neu starten“, „Bis zu 3 Neustartversuche“ (oder `Register-ScheduledTask` mit `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Zwei-Finger-Scrollen zu schnell
`HKCU\Control Panel\Desktop\WheelScrollLines` von `3` auf `1`, sofort übernommen mit `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Das Skript macht das mit `-WheelScrollLines 1`.

## Inhalt des Repos
| Pfad | Zweck |
|---|---|
| `scripts/vfct-patch.py` | Entfernt eDP-Anschluss/Encoder und LCD1-Pfad, löscht LCD1-Flag, setzt SSID 106B:0179, korrigiert Prüfsummen |
| `scripts/vfct-parse.py` | Liest VFCT und ATOM-Objekttabelle, prüft Prüfsummen |
| `scripts/bootcamp-reapply.ps1` | Setzt Trackpad-Mode und startet Bootcamp.exe (Touch Bar) bei der Anmeldung neu |
| `opencore/config-snippet.plist` | OpenCore-Einträge `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Vollständiges technisches Paper (Englisch / Portugiesisch) |

## Credits
**Ryan Anthony Gibo**: Autor, Entdecker der Ursache und des Fixes, Hardwaretests. Dank an ACPICA, OpenCore (Acidanthera) und OpenCore Legacy Patcher. Hat's geholfen? Gib einen ⭐ und zitiere über [CITATION.cff](CITATION.cff).

Lizenz: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

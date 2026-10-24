🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Oplossing Code 43 Radeon Pro 560 / 555 op MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp met kapot of verwijderd intern scherm (eDP), VFCT VBIOS-patch via OpenCore

📄 **Technisch paper:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Auteur en ontdekker: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — oorzaak gevonden en oplossing gemaakt op 21-10-2026.

Toont je **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** met **AMD Radeon Pro 560 of Radeon Pro 555** in Apparaatbeheer **"Dit apparaat is door Windows gestopt omdat er problemen zijn gemeld. (Code 43)"**? Is het **interne scherm (LCD / eDP-paneel) kapot, losgekoppeld of verwijderd** en gebruik je de Mac **zonder scherm (headless) met een externe monitor** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? Dan faalt de **AMD-driver (Boot Camp, Adrenalin)** omdat de **VBIOS nog steeds het interne eDP-paneel meldt**. Deze repo lost dat op: hij patcht de **ACPI-tabel VFCT** (de VBIOS-kopie die Windows leest), verwijdert de eDP-connector en laadt die via **OpenCore** (`ACPI > Delete + Add`). Resultaat: Radeon Pro 560 werkt met **4 GB VRAM, DirectX 11/12 en hardwareversnelling**.

Zoekwoorden: MacBook Pro 2017 foutcode 43, A1707 Radeon Pro 560 code 43, Boot Camp kapot scherm videokaart, Radeon Pro 555 code 43 Windows 10, Radeon Pro 560 werkt niet Windows 11, MacBook Pro zonder scherm Windows, Boot Camp headless, eDP AMD driver, VFCT patch, VBIOS, OpenCore Boot Camp GPU, Warframe op MacBook Pro, Touch Bar werkt niet in Windows, ESC-toets ontbreekt Boot Camp, Boot Camp trackpad tikken om te klikken reset na herstart, rechtsklik Boot Camp, scrollen met twee vingers te snel.

> ⚠️ **DISCLAIMER — GEBRUIK OP EIGEN RISICO.** Je wijzigt firmwaretabellen die de bootloader laadt. Een foute configuratie kan het opstarten verhinderen. Houd een herstel-USB en een back-up van `config.plist` bij de hand. Geen garantie ([LICENSE](LICENSE)). Niet gelieerd aan Apple of AMD.

## Snelle oplossing (TL;DR)
1. Start Windows (de Microsoft-basisweergaveadapter werkt) en installeer de normale Boot Camp-/AMD-driver (die geeft Code 43 — verwacht).
2. Lees de VFCT uit: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → controleer connector `3114` (eDP) en pad `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` en daarna `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 connectors, checksums OK).
5. Kopieer `VFCT-noeDP.aml` naar `EFI\OC\ACPI\`, maak een back-up van `config.plist` en voeg [opencore/config-snippet.plist](opencore/config-snippet.plist) toe.
6. Herstart via OpenCore → Apparaatbeheer: **Radeon Pro 560 — "Dit apparaat werkt correct"** ✅

## Vereisten
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 uit 2016 waarschijnlijk vergelijkbaar, maar **niet geverifieerd**; het script stopt als de ID's afwijken.
- Windows 10 22H2 (getest 19045) of Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (getest 1.0.6): de Apple-firmware kan geen ACPI-tabellen vervangen.
- Python 3 en `acpidump.exe` van ACPICA.

## Stap-voor-stap
1. **Installeer OpenCore** op de interne ESP en controleer dat Windows ermee opstart. Houd een USB klaar die `config.plist` kan herstellen.
2. **Lees de VFCT uit** in een beheerdersterminal: `acpidump.exe -n VFCT -b`.
3. **Controleer**: `python scripts/vfct-parse.py vfct.dat`. Verwacht: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Patch**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Valideer**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Koppel de ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; maak een back-up van `config.plist`.
7. **Bewerk config.plist**: voeg de items `ACPI > Add` en `ACPI > Delete` uit de snippet toe (`VkZDVA==` = "VFCT").
8. **Herstart** via OpenCore en controleer Apparaatbeheer en `dxdiag`.

## Veelgestelde vragen
**Waarom pas Code 43 nadat het scherm kapot ging?** De VBIOS meldt een eDP-connector. De driver probeert dat paneel aan te zetten, krijgt geen HPD en meldt zich ~0,4 s na de schermdetectie af → Code 43.

**Helpen drivers herinstalleren, Windows 11 of een nieuwere Adrenalin?** Nee. Apple 22.19, AMD R6.4 en Adrenalin 26.5.2 faalden op Windows 10 en 11.

**Heb ik de Intel iGPU nodig?** Nee. Gebruik **geen** `apple_set_os.efi` op een A1707 zonder scherm: het opstarten bleef hangen bij het Apple-logo.

**Zit mijn VBIOS erbij?** Nee. Die valt onder het auteursrecht van AMD/Apple; het script patcht *je eigen* dump.

**Heeft het invloed op macOS?** OpenCore laadt de tabellen voor elk systeem. macOS gebruikt de VFCT niet voor deze GPU, maar opstarten van macOS met de patch is nog niet opnieuw geverifieerd — test het.

**Kan ik gamen?** Ja: bevestigd met Warframe (DirectX 11/12) dat downloadt en draait op een A1707 zonder scherm.

**Lost een magneet op de klepsensor het op?** Niet in onze tests (ook geen `_LID`-override of DAL-registersleutels).

**Warframe-launcher: "Could not create directory C:\Program Files\Warframe"?** Geef je gebruiker het recht Wijzigen (als beheerder): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Probleemoplossing
- **Nog steeds Code 43**: controleer of de gepatchte tabel actief is (VFCT met SS `106B:0179`). Zo niet, dan heeft OpenCore hem niet geladen (pad, `Enabled`, opstarten zonder OpenCore).
- **Scriptfout "object not found"**: andere VBIOS; voer `vfct-parse.py` uit en open een issue met de uitvoer.
- **Mac start niet / wit Apple-logo**: start de herstel-USB (Option → "EFI Boot") en zet de back-up terug; of in macOS `sudo diskutil mount disk0s1` en kopieer de back-up terug.
- **Externe 4K-monitor op ~30 Hz**: waarschijnlijk limiet van kabel/adapter/poort. Gebruik USB-C→DP of 1440p/1080p op 60 Hz.
- **Zwart scherm in de opstartkiezer**: in OpenCore `UEFI > Output > Resolution` (bijv. `1920x1080@32`) en `ForceResolution`.

## Na installatie: Touch Bar en trackpad in Boot Camp
Geverifieerd op 21-10-2026 op dezelfde A1707 zonder scherm (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar werkt niet in Windows / ESC-toets ontbreekt
- De officiële Boot Camp 6.1-drivers waren geïnstalleerd en in orde: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Oorzaak: **`Bootcamp.exe` (de Boot Camp-app in het systeemvak) draaide niet**; die stuurt de Touch Bar aan (functietoetsen / ESC).
- Oplossing: herstart `Bootcamp.exe` en daarna het samengestelde T1-apparaat (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar en ESC kwamen terug, **ook zonder intern scherm**.

### Tikken om te klikken / secundaire klik van de trackpad weg na herstart
- Boot Camp bewaart deze opties alleen in `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, ongedocumenteerde bits).
- Stel ze in via `C:\Windows\System32\AppleControlPanel.exe` → Trackpad en lees de waarde: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (bij ons: `43`).
- Pas hem bij elke aanmelding opnieuw toe met [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (schrijft `Mode`, herstart `Bootcamp.exe` tot 5 pogingen) via een geplande taak met 10 s vertraging en 3 herhalingen. Voorbeeld (kopieer het script naar `C:\Tools\`, als beheerder, vervang `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Daarna in Taakplanner → Instellingen: "Als de taak mislukt, elke 1 minuut opnieuw starten", "Maximaal 3 keer opnieuw proberen" (of `Register-ScheduledTask` met `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Scrollen met twee vingers te snel
`HKCU\Control Panel\Desktop\WheelScrollLines` van `3` naar `1`, direct toegepast met `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Het script doet dit met `-WheelScrollLines 1`.

## Inhoud van de repo
| Pad | Wat |
|---|---|
| `scripts/vfct-patch.py` | Verwijdert eDP-connector/encoder en LCD1-pad, wist de LCD1-vlag, zet SSID 106B:0179, herstelt checksums |
| `scripts/vfct-parse.py` | Leest de VFCT en de ATOM-objecttabel, controleert checksums |
| `scripts/bootcamp-reapply.ps1` | Past trackpad-Mode opnieuw toe en herstart Bootcamp.exe (Touch Bar) bij aanmelden |
| `opencore/config-snippet.plist` | OpenCore-items `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Volledig technisch paper (Engels / Portugees) |

## Credits
**Ryan Anthony Gibo**: auteur, ontdekker van de oorzaak en de oplossing, hardwaretests. Dank aan ACPICA, OpenCore (Acidanthera) en OpenCore Legacy Patcher. Geholpen? Geef een ⭐ en citeer via [CITATION.cff](CITATION.cff).

Licentie: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

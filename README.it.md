🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Soluzione errore Codice 43 Radeon Pro 560 / 555 su MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp con schermo interno rotto o rimosso (eDP), patch VBIOS VFCT con OpenCore

📄 **Articolo tecnico:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Autore e scopritore: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — causa trovata e soluzione creata il 21/10/2026.

Il tuo **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** con **AMD Radeon Pro 560 o Radeon Pro 555** mostra **"Windows ha arrestato il dispositivo perché ha rilevato dei problemi. (Codice 43)"** in Gestione dispositivi? Lo **schermo interno (LCD / pannello eDP) è rotto, scollegato o rimosso** e usi il Mac **senza schermo (headless) con un monitor esterno** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? Il **driver AMD (Boot Camp, Adrenalin)** fallisce perché la **VBIOS dichiara ancora il pannello eDP interno**. Questo repository lo risolve: modifica la **tabella ACPI VFCT** (la copia della VBIOS letta da Windows) togliendo il connettore eDP e la inietta con **OpenCore** (`ACPI > Delete + Add`). Risultato: Radeon Pro 560 funzionante con **4 GB di VRAM, DirectX 11/12 e accelerazione hardware**.

Parole chiave: MacBook Pro 2017 errore codice 43, A1707 Radeon Pro 560 codice 43, Boot Camp schermo rotto scheda video, Radeon Pro 555 codice 43 Windows 10, Radeon Pro 560 non funziona Windows 11, MacBook Pro senza schermo Windows, Boot Camp headless, eDP driver AMD, patch VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe su MacBook Pro, Touch Bar non funziona su Windows, tasto ESC mancante Boot Camp, trackpad Boot Camp tocco per clic si resetta, clic destro Boot Camp, scorrimento a due dita troppo veloce.

> ⚠️ **AVVISO — USALO A TUO RISCHIO.** Modifichi tabelle firmware caricate dal bootloader. Una configurazione errata può impedire l'avvio del Mac. Tieni una chiavetta USB di ripristino e un backup di `config.plist`. Nessuna garanzia ([LICENSE](LICENSE)). Non affiliato ad Apple o AMD.

## Soluzione rapida (TL;DR)
1. Avvia Windows (la scheda video di base Microsoft funziona) e installa il normale driver Boot Camp / AMD (darà Codice 43, è previsto).
2. Estrai la VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → verifica il connettore `3114` (eDP) e il percorso `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` e poi `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 connettori, checksum OK).
5. Copia `VFCT-noeDP.aml` in `EFI\OC\ACPI\`, fai il backup di `config.plist` e applica [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Riavvia tramite OpenCore → Gestione dispositivi: **Radeon Pro 560 — "Il dispositivo funziona correttamente"** ✅

## Requisiti
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 probabilmente simile ma **non verificato**; lo script si interrompe se gli ID sono diversi.
- Windows 10 22H2 (testato 19045) o Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (testato 1.0.6): il firmware Apple non può sostituire tabelle ACPI.
- Python 3 e `acpidump.exe` di ACPICA.

## Guida passo passo
1. **Installa OpenCore** sulla ESP interna e verifica che Windows si avvii tramite esso. Tieni una chiavetta che possa ripristinare `config.plist`.
2. **Estrai la VFCT** in un terminale amministratore: `acpidump.exe -n VFCT -b`.
3. **Controlla**: `python scripts/vfct-parse.py vfct.dat`. Atteso: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Applica la patch**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Verifica**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Monta la ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; fai il backup di `config.plist`.
7. **Modifica config.plist**: aggiungi le voci `ACPI > Add` e `ACPI > Delete` dello snippet (`VkZDVA==` = "VFCT").
8. **Riavvia** tramite OpenCore e controlla Gestione dispositivi e `dxdiag`.

## Domande frequenti
**Perché Codice 43 solo dopo la rottura dello schermo?** La VBIOS annuncia un connettore eDP. Il driver prova ad accendere il pannello, non riceve HPD e si rimuove ~0,4 s dopo il rilevamento degli schermi → Codice 43.

**Reinstallare i driver, Windows 11 o un Adrenalin più recente aiuta?** No. Apple 22.19, AMD R6.4 e Adrenalin 26.5.2 hanno fallito su Windows 10 e 11.

**Serve la GPU Intel integrata?** No. **Non** usare `apple_set_os.efi` su un A1707 senza schermo: l'avvio si è bloccato sul logo Apple.

**La mia VBIOS è inclusa?** No. È protetta da copyright AMD/Apple; lo script modifica il *tuo* dump.

**Influisce su macOS?** OpenCore inietta le tabelle per tutti i sistemi. macOS non usa la VFCT per questa GPU, ma l'avvio di macOS con la patch non è ancora stato riverificato: provalo.

**Posso giocare?** Sì: confermato con Warframe (DirectX 11/12) scaricato e avviato su un A1707 senza schermo.

**Un magnete sul sensore del coperchio risolve?** Non nei nostri test (nemmeno l'override di `_LID` o le chiavi DAL del registro).

**Launcher di Warframe: "Could not create directory C:\Program Files\Warframe"?** Dai al tuo utente il permesso Modifica (da admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Risoluzione dei problemi
- **Ancora Codice 43**: verifica che la tabella modificata sia attiva (VFCT con SS `106B:0179`). Altrimenti OpenCore non l'ha caricata (percorso, `Enabled`, avvio senza OpenCore).
- **Errore "object not found" dello script**: VBIOS diversa; esegui `vfct-parse.py` e apri una issue con l'output.
- **Il Mac non si avvia / logo Apple bianco**: avvia la chiavetta di ripristino (Option → "EFI Boot") e ripristina il backup; oppure da macOS `sudo diskutil mount disk0s1` e ricopia il backup.
- **Monitor 4K esterno a ~30 Hz**: probabile limite di cavo/adattatore/porta. Usa USB-C→DP o 1440p/1080p a 60 Hz.
- **Schermo nero nel selettore di avvio**: in OpenCore `UEFI > Output > Resolution` (es. `1920x1080@32`) e `ForceResolution`.

## Post-installazione: Touch Bar e trackpad su Boot Camp
Verificato il 21/10/2026 sullo stesso A1707 senza schermo (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar non funziona su Windows / tasto ESC mancante
- I driver ufficiali Boot Camp 6.1 erano installati e funzionanti: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Causa: **`Bootcamp.exe` (l'app Boot Camp nell'area di notifica) non era in esecuzione**; è lei a gestire la Touch Bar (tasti funzione / ESC).
- Soluzione: riavvia `Bootcamp.exe` e poi il dispositivo composito T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar ed ESC sono tornati **anche senza schermo interno**.

### Tocco per clic / clic secondario del trackpad persi dopo il riavvio
- Boot Camp salva queste opzioni solo in `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, bit non documentati).
- Impostale in `C:\Windows\System32\AppleControlPanel.exe` → Trackpad e leggi il valore: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (il nostro: `40`).
- Riapplicalo a ogni accesso con [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (scrive `Mode`, riavvia `Bootcamp.exe` fino a 5 tentativi) tramite un'attività pianificata con ritardo di 10 s e 3 nuovi tentativi. Esempio (copia lo script in `C:\Tools\`, da admin, sostituisci `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Poi in Utilità di pianificazione → Impostazioni: "Se l'attività non riesce, riavvia ogni 1 minuto", "Tenta il riavvio fino a 3 volte" (o `Register-ScheduledTask` con `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Scorrimento a due dita troppo veloce
`HKCU\Control Panel\Desktop\WheelScrollLines` da `3` a `1`, applicato subito con `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Lo script lo fa con `-WheelScrollLines 1`.

## Contenuto del repository
| Percorso | Cosa fa |
|---|---|
| `scripts/vfct-patch.py` | Rimuove connettore/encoder eDP e percorso LCD1, cancella il flag LCD1, imposta SSID 106B:0179, corregge i checksum |
| `scripts/vfct-parse.py` | Analizza la VFCT e la tabella oggetti ATOM, verifica i checksum |
| `scripts/bootcamp-reapply.ps1` | Riapplica il Mode del trackpad e riavvia Bootcamp.exe (Touch Bar) all'accesso |
| `opencore/config-snippet.plist` | Voci OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Articolo tecnico completo (inglese / portoghese) |

## Crediti
**Ryan Anthony Gibo**: autore, scopritore della causa e della soluzione, test sull'hardware. Grazie ad ACPICA, OpenCore (Acidanthera) e OpenCore Legacy Patcher. Ti è stato utile? Lascia una ⭐ e cita con [CITATION.cff](CITATION.cff).

Licenza: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

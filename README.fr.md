🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Correctif erreur Code 43 Radeon Pro 560 / 555 sur MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp avec écran interne cassé ou retiré (eDP), patch VBIOS VFCT via OpenCore

📄 **Article technique:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Auteur et découvreur : [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — cause trouvée et correctif créé le 21/10/2026.

Votre **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** avec **AMD Radeon Pro 560 ou Radeon Pro 555** affiche **« Windows a arrêté ce périphérique car il présente des problèmes. (Code 43) »** dans le Gestionnaire de périphériques ? L'**écran interne (LCD / dalle eDP) est cassé, débranché ou retiré** et vous utilisez le Mac **sans écran (headless) avec un moniteur externe** (USB-C, Thunderbolt 3, HDMI, DisplayPort) ? Le **pilote AMD (Boot Camp, Adrenalin)** échoue car la **VBIOS déclare toujours la dalle eDP interne**. Ce dépôt corrige cela : il patche la **table ACPI VFCT** (la copie de la VBIOS lue par Windows) pour retirer le connecteur eDP, puis l'injecte avec **OpenCore** (`ACPI > Delete + Add`). Résultat : Radeon Pro 560 fonctionnelle avec **4 Go de VRAM, DirectX 11/12 et accélération matérielle**.

Mots-clés : MacBook Pro 2017 erreur code 43, A1707 Radeon Pro 560 code 43, Boot Camp écran cassé carte graphique, Radeon Pro 555 code 43 Windows 10, Radeon Pro 560 ne fonctionne pas Windows 11, MacBook Pro sans écran Windows, Boot Camp headless, eDP pilote AMD, patch VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe sur MacBook Pro, Touch Bar ne fonctionne pas sous Windows, touche ESC absente Boot Camp, trackpad Boot Camp toucher pour cliquer réinitialisé, clic droit Boot Camp, défilement à deux doigts trop rapide.

> ⚠️ **AVERTISSEMENT — À VOS RISQUES ET PÉRILS.** Vous modifiez des tables de firmware chargées par le chargeur de démarrage. Une mauvaise configuration peut empêcher le Mac de démarrer. Gardez une clé USB de secours et une sauvegarde de `config.plist`. Aucune garantie ([LICENSE](LICENSE)). Non affilié à Apple ni à AMD.

## Correctif rapide (TL;DR)
1. Démarrez Windows (l'adaptateur d'affichage de base Microsoft fonctionne) et installez le pilote Boot Camp / AMD habituel (il affichera Code 43, c'est normal).
2. Extrayez la VFCT : `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → vérifiez le connecteur `3114` (eDP) et le chemin `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` puis `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 connecteurs, checksums OK).
5. Copiez `VFCT-noeDP.aml` dans `EFI\OC\ACPI\`, sauvegardez `config.plist` et appliquez [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Redémarrez via OpenCore → Gestionnaire de périphériques : **Radeon Pro 560 — « Ce périphérique fonctionne correctement »** ✅

## Prérequis
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 probablement similaire mais **non vérifié** ; le script s'arrête si les ID diffèrent.
- Windows 10 22H2 (testé 19045) ou Windows 11 ; pilote AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (testé 1.0.6) : le firmware Apple ne peut pas remplacer les tables ACPI.
- Python 3 et `acpidump.exe` d'ACPICA.

## Guide pas à pas
1. **Installez OpenCore** sur l'ESP interne et vérifiez que Windows démarre par lui. Gardez une clé USB capable de restaurer `config.plist`.
2. **Extrayez la VFCT** dans un terminal administrateur : `acpidump.exe -n VFCT -b`.
3. **Inspectez** : `python scripts/vfct-parse.py vfct.dat`. Attendu : `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Patchez** : `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Validez** : `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Montez l'ESP** : `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml` ; sauvegardez `config.plist`.
7. **Modifiez config.plist** : ajoutez les entrées `ACPI > Add` et `ACPI > Delete` du snippet (`VkZDVA==` = « VFCT »).
8. **Redémarrez** via OpenCore et vérifiez le Gestionnaire de périphériques et `dxdiag`.

## FAQ
**Pourquoi le Code 43 seulement après la casse de l'écran ?** La VBIOS annonce un connecteur eDP. Le pilote tente d'allumer cette dalle, ne reçoit pas de HPD et se retire ~0,4 s après la détection des écrans → Code 43.

**Réinstaller les pilotes, Windows 11 ou un Adrenalin récent aide-t-il ?** Non. Apple 22.19, AMD R6.4 et Adrenalin 26.5.2 ont échoué sous Windows 10 et 11.

**Ai-je besoin du GPU Intel intégré ?** Non. **N'utilisez pas** `apple_set_os.efi` sur un A1707 sans écran : le démarrage s'est bloqué sur le logo Apple.

**Ma VBIOS est-elle fournie ?** Non. Elle est sous copyright AMD/Apple ; le script patche *votre propre* dump.

**Est-ce que cela affecte macOS ?** OpenCore injecte les tables pour tous les systèmes. macOS n'utilise pas la VFCT pour ce GPU, mais le démarrage de macOS avec le patch n'a pas encore été revérifié : testez-le.

**Puis-je jouer ?** Oui : confirmé avec Warframe (DirectX 11/12) téléchargé et lancé sur un A1707 sans écran.

**Un aimant sur le capteur du capot règle-t-il le problème ?** Pas dans nos tests (ni l'override de `_LID`, ni les clés DAL du registre).

**Lanceur Warframe : « Could not create directory C:\Program Files\Warframe » ?** Donnez à votre utilisateur le droit Modifier (en admin) : `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Dépannage
- **Toujours Code 43** : vérifiez que la table patchée est active (VFCT avec SS `106B:0179`). Sinon, OpenCore ne l'a pas chargée (chemin, `Enabled`, démarrage sans OpenCore).
- **Erreur « object not found » du script** : VBIOS différente ; lancez `vfct-parse.py` et ouvrez une issue avec la sortie.
- **Le Mac ne démarre plus / logo Apple blanc** : démarrez la clé de secours (Option → « EFI Boot ») et restaurez la sauvegarde ; ou depuis macOS `sudo diskutil mount disk0s1` puis recopiez la sauvegarde.
- **Moniteur 4K externe à ~30 Hz** : probablement une limite du câble/adaptateur/port. Utilisez USB-C→DP ou 1440p/1080p à 60 Hz.
- **Écran noir au sélecteur de démarrage** : dans OpenCore, `UEFI > Output > Resolution` (ex. `1920x1080@32`) et `ForceResolution`.

## Après l'installation : Touch Bar et trackpad sous Boot Camp
Vérifié le 21/10/2026 sur le même A1707 sans écran (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar ne fonctionne pas sous Windows / touche ESC absente
- Les pilotes officiels Boot Camp 6.1 étaient installés et OK : **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Cause : **`Bootcamp.exe` (l'application Boot Camp de la zone de notification) ne tournait pas** ; c'est elle qui pilote la Touch Bar (touches de fonction / ESC).
- Solution : relancez `Bootcamp.exe`, puis redémarrez le périphérique composite T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). La Touch Bar et ESC sont revenues **même sans écran interne**.

### Toucher pour cliquer / clic secondaire du trackpad perdus après redémarrage
- Boot Camp stocke ces options uniquement dans `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, bits non documentés).
- Réglez-les dans `C:\Windows\System32\AppleControlPanel.exe` → Trackpad, puis lisez la valeur : `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (la nôtre : `43`).
- Réappliquez-la à chaque ouverture de session avec [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (écrit `Mode`, relance `Bootcamp.exe` jusqu'à 5 essais) via une tâche planifiée avec 10 s de délai et 3 nouvelles tentatives. Exemple (copiez le script dans `C:\Tools\`, en admin, remplacez `<user>`) :
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Puis dans le Planificateur de tâches → Paramètres : « Si la tâche échoue, redémarrer toutes les 1 minute », « Tenter de redémarrer jusqu'à 3 fois » (ou `Register-ScheduledTask` avec `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Défilement à deux doigts trop rapide
`HKCU\Control Panel\Desktop\WheelScrollLines` de `3` à `1`, appliqué immédiatement avec `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. Le script le fait avec `-WheelScrollLines 1`.

## Contenu du dépôt
| Chemin | Rôle |
|---|---|
| `scripts/vfct-patch.py` | Retire connecteur/encodeur eDP et le chemin LCD1, efface le flag LCD1, met le SSID 106B:0179, corrige les checksums |
| `scripts/vfct-parse.py` | Analyse la VFCT et la table d'objets ATOM, vérifie les checksums |
| `scripts/bootcamp-reapply.ps1` | Réapplique le Mode du trackpad et relance Bootcamp.exe (Touch Bar) à l'ouverture de session |
| `opencore/config-snippet.plist` | Entrées OpenCore `ACPI > Delete + Add` |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Article technique complet (anglais / portugais) |

## Crédits
**Ryan Anthony Gibo** : auteur, découvreur de la cause et du correctif, tests matériels. Merci à ACPICA, OpenCore (Acidanthera) et OpenCore Legacy Patcher. Utile ? Mettez une ⭐ et citez via [CITATION.cff](CITATION.cff).

Licence: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

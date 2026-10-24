🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Solución al error Código 43 de la Radeon Pro 560 / 555 en MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp con pantalla interna rota o retirada (eDP), parche VBIOS VFCT con OpenCore

📄 **Artículo técnico:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Autor y descubridor: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — causa raíz encontrada y solución creada el 21/10/2026.

¿Tu **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** con **AMD Radeon Pro 560 o Radeon Pro 555** muestra **"Windows ha detenido este dispositivo porque ha informado de problemas. (Código 43)"** en el Administrador de dispositivos? ¿La **pantalla interna (LCD / panel eDP) está rota, desconectada o retirada** y usas el Mac **sin pantalla (headless) con un monitor externo** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? El **driver AMD (Boot Camp, Adrenalin)** falla porque la **VBIOS sigue declarando el panel eDP interno**. Este repositorio lo soluciona: parchea la **tabla ACPI VFCT** (la copia de la VBIOS que lee Windows) para quitar el conector eDP y la inyecta con **OpenCore** (`ACPI > Delete + Add`). Resultado: Radeon Pro 560 funcionando con **4 GB de VRAM, DirectX 11/12 y aceleración por hardware**.

Palabras clave: MacBook Pro 2017 error código 43, A1707 Radeon Pro 560 código 43, Boot Camp pantalla rota tarjeta gráfica, Radeon Pro 555 código 43 Windows 10, Radeon Pro 560 no funciona Windows 11, MacBook Pro sin pantalla Windows, Boot Camp headless, eDP driver AMD, parche VFCT, VBIOS, OpenCore Boot Camp GPU, Warframe en MacBook Pro, Touch Bar no funciona en Windows, falta la tecla ESC Boot Camp, trackpad Boot Camp tocar para hacer clic se reinicia, clic derecho Boot Camp, desplazamiento con dos dedos muy rápido.

> ⚠️ **AVISO — ÚSALO BAJO TU PROPIO RIESGO.** Modificas tablas de firmware que carga el gestor de arranque. Una configuración errónea puede impedir que el Mac arranque. Ten un USB de recuperación y una copia de `config.plist`. Sin garantía ([LICENSE](LICENSE)). Sin relación con Apple ni AMD.

## Solución rápida (TL;DR)
1. Arranca Windows (funciona el adaptador básico de Microsoft) e instala el driver Boot Camp / AMD normal (mostrará Código 43, es lo esperado).
2. Extrae la VFCT: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → confirma el conector `3114` (eDP) y la ruta `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` y después `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 conectores, checksums OK).
5. Copia `VFCT-noeDP.aml` a `EFI\OC\ACPI\`, haz copia de `config.plist` y aplica [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Reinicia con OpenCore → Administrador de dispositivos: **Radeon Pro 560 — "Este dispositivo funciona correctamente"** ✅

## Requisitos
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 probablemente igual, pero **no verificado**; el script aborta si los IDs difieren.
- Windows 10 22H2 (probado 19045) o Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (probado 1.0.6): el firmware de Apple no puede reemplazar tablas ACPI.
- Python 3 y `acpidump.exe` de ACPICA.

## Guía paso a paso
1. **Instala OpenCore** en la ESP interna y comprueba que Windows arranca con él. Ten un USB que pueda restaurar `config.plist`.
2. **Extrae la VFCT** en una terminal de administrador: `acpidump.exe -n VFCT -b`.
3. **Inspecciona**: `python scripts/vfct-parse.py vfct.dat`. Esperado: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Parchea**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Valida**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **Monta la ESP**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; haz copia de `config.plist`.
7. **Edita config.plist**: añade las entradas `ACPI > Add` y `ACPI > Delete` del snippet (`VkZDVA==` = "VFCT").
8. **Reinicia** con OpenCore y revisa el Administrador de dispositivos y `dxdiag`.

## Preguntas frecuentes
**¿Por qué Código 43 solo después de romperse la pantalla?** La VBIOS anuncia un conector eDP. El driver intenta encender ese panel, no recibe HPD y se retira ~0,4 s después de detectar pantallas → Código 43.

**¿Sirve reinstalar drivers, Windows 11 o un Adrenalin más nuevo?** No. Apple 22.19, AMD R6.4 y Adrenalin 26.5.2 fallaron en Windows 10 y 11.

**¿Necesito la GPU Intel integrada?** No. **No** uses `apple_set_os.efi` en un A1707 sin pantalla: bloqueó el arranque en el logo de Apple.

**¿Se incluye mi VBIOS?** No. Tiene copyright de AMD/Apple; el script parchea *tu propio* volcado.

**¿Afecta a macOS?** OpenCore inyecta las tablas para todos los sistemas. macOS no usa la VFCT en esta GPU, pero el arranque de macOS con el parche aún no se ha reverificado: pruébalo.

**¿Puedo jugar?** Sí: confirmado con Warframe (DirectX 11/12) descargando y funcionando en un A1707 sin pantalla.

**¿Un imán en el sensor de la tapa lo arregla?** No en nuestras pruebas (tampoco el override de `_LID` ni las claves DAL del registro).

**Launcher de Warframe: "Could not create directory C:\Program Files\Warframe"?** Da a tu usuario permiso de Modificar (como admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Solución de problemas
- **Sigue el Código 43**: comprueba que la tabla parcheada está activa (VFCT con SS `106B:0179`). Si no, OpenCore no la cargó (ruta, `Enabled`, arranque sin OpenCore).
- **Error "object not found" en el script**: VBIOS distinta; ejecuta `vfct-parse.py` y abre un issue con la salida.
- **El Mac no arranca / logo blanco de Apple**: arranca el USB de recuperación (Option → "EFI Boot") y restaura la copia; o desde macOS `sudo diskutil mount disk0s1` y copia la copia de vuelta.
- **Monitor 4K externo a ~30 Hz**: probable límite del cable/adaptador/puerto. Usa USB-C→DP o 1440p/1080p a 60 Hz.
- **Pantalla negra en el selector de arranque**: en OpenCore, `UEFI > Output > Resolution` (p. ej. `1920x1080@32`) y `ForceResolution`.

## Post-instalación: Touch Bar y trackpad en Boot Camp
Verificado el 21/10/2026 en el mismo A1707 sin pantalla (Windows 10 22H2, Boot Camp 6.1).

### Touch Bar no funciona en Windows / falta la tecla ESC
- Los drivers oficiales de Boot Camp 6.1 estaban instalados y bien: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Causa: **`Bootcamp.exe` (la app de la bandeja de Boot Camp) no se estaba ejecutando**; es quien controla la Touch Bar (teclas de función / ESC).
- Solución: reinicia `Bootcamp.exe` y luego el dispositivo compuesto T1 (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). La Touch Bar y ESC volvieron **incluso sin la pantalla interna**.

### Tocar para hacer clic / clic derecho del trackpad se pierden al reiniciar
- Boot Camp guarda estas opciones solo en `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, bits no documentados).
- Configúralas en `C:\Windows\System32\AppleControlPanel.exe` → Trackpad y lee el valor: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (el nuestro: `43`).
- Reaplícalo en cada inicio de sesión con [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (escribe `Mode` y reinicia `Bootcamp.exe` hasta 5 intentos) desde una tarea programada con 10 s de retraso y 3 reintentos. Ejemplo (copia el script a `C:\Tools\`, ejecuta como admin, cambia `<user>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Luego en el Programador de tareas → Configuración: "Si la tarea falla, reiniciar cada 1 minuto", "Intentar reiniciar hasta 3 veces" (o `Register-ScheduledTask` con `New-ScheduledTaskSettingsSet -RestartCount 3`).

### Desplazamiento con dos dedos demasiado rápido
`HKCU\Control Panel\Desktop\WheelScrollLines` de `3` a `1`, aplicado al instante con `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)`. El script lo hace con `-WheelScrollLines 1`.

## Contenido del repositorio
| Ruta | Qué es |
|---|---|
| `scripts/vfct-patch.py` | Quita conector/encoder eDP y la ruta LCD1, borra el flag LCD1, pone SSID 106B:0179 y corrige checksums |
| `scripts/vfct-parse.py` | Analiza la VFCT y la tabla de objetos ATOM, verifica checksums |
| `scripts/bootcamp-reapply.ps1` | Reaplica el Mode del trackpad y reinicia Bootcamp.exe (Touch Bar) al iniciar sesión |
| `opencore/config-snippet.plist` | Entradas `ACPI > Delete + Add` de OpenCore |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Artículo técnico completo (inglés / portugués) |

## Créditos
**Ryan Anthony Gibo**: autor, descubridor de la causa raíz y de la solución, pruebas en hardware. Gracias a ACPICA, OpenCore (Acidanthera) y OpenCore Legacy Patcher. ¿Te ayudó? Dale una ⭐ y cita con [CITATION.cff](CITATION.cff).

Licencia: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click--touch-bar-die-after-reboot-definitive-fix-tested-2026-10-24): Apple-only Boot Camp 6.1 reinstall (`scripts/bootcamp/`), AMD driver untouched, Fast Startup off, Mode=43 watchdog. By Ryan Anthony Gibo.

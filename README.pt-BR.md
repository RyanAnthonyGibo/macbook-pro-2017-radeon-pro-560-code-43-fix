🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# Correção do Código 43 da Radeon Pro 560 / 555 no MacBook Pro 2017 (A1707) — Windows 10/11 Boot Camp com Tela Interna Quebrada ou Removida (eDP), via Patch de VBIOS VFCT no OpenCore

🇺🇸 **[Read in English](README.md)** · 📄 **[Artigo técnico (PT-BR)](docs/paper-pt-BR.md)** · 📄 **[Technical paper (EN)](docs/paper-en.md)**

> **Autor e descobridor: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — causa raiz encontrada e correção criada em 21/10/2026.

Seu **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** com **AMD Radeon Pro 560 ou Radeon Pro 555** mostra **"O Windows parou este dispositivo porque ele relatou problemas. (Código 43)"** no Gerenciador de Dispositivos? A **tela interna (LCD / painel eDP) está quebrada, trincada, desconectada ou foi removida**, e você usa o Mac **sem tela (headless) com monitor externo** (USB-C, Thunderbolt 3, HDMI, DisplayPort)? Então o **driver AMD (Boot Camp, Adrenalin)** falha porque a **VBIOS ainda declara o painel eDP interno**. Este repositório resolve: modifica a **tabela ACPI VFCT** (a cópia da VBIOS que o Windows lê) removendo o conector eDP, e injeta com o **OpenCore** (`ACPI > Delete + Add`). Resultado: Radeon Pro 560 funcionando com **4 GB de VRAM, DirectX 11/12 e aceleração** — adeus "Adaptador de Vídeo Básico da Microsoft".

Palavras-chave: MacBook Pro 2017 código 43, A1707 Radeon Pro 560 erro 43, Boot Camp tela quebrada placa de vídeo, Radeon Pro 555 código 43 Windows 10, Windows 11 Radeon Pro 560 não funciona, MacBook Pro sem tela Windows, MacBook headless Boot Camp, eDP removido driver AMD, patch VFCT, VBIOS ATOM, OpenCore Boot Camp GPU, Warframe no MacBook Pro, Touch Bar não funciona no Windows, ESC sumiu Boot Camp, toque para clicar do trackpad reseta ao reiniciar, clique direito Boot Camp não funciona, rolagem com dois dedos muito rápida, Boot Camp trackpad configuração perdida.

> ⚠️ **AVISO — USE POR SUA CONTA E RISCO.** Você altera tabelas de firmware carregadas pelo bootloader. Uma config errada pode impedir o boot. Tenha um pendrive de recuperação e backup do `config.plist`. Sem garantia ([LICENSE](LICENSE)). Sem vínculo com Apple ou AMD.

## Resumo rápido (TL;DR)
1. Entre no Windows (o vídeo básico da Microsoft funciona) e instale o driver Boot Camp / AMD normal (vai dar Código 43 — esperado).
2. Extraia a VFCT: `acpidump.exe -n VFCT -b` ([ferramentas ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → confirme o conector `3114` (eDP) e o caminho `0002` (LCD1).
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml` e depois `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 conectores, checksums OK).
5. Copie `VFCT-noeDP.aml` para `EFI\OC\ACPI\`, faça backup do `config.plist` e aplique o [opencore/config-snippet.plist](opencore/config-snippet.plist).
6. Reinicie pelo OpenCore → Gerenciador de Dispositivos: **Radeon Pro 560 — "Este dispositivo está funcionando corretamente"** ✅

## Requisitos
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3) com Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / A1707 2016 provavelmente parecido, mas **não verificado** — o script aborta se os IDs forem diferentes.
- Windows 10 22H2 (testado 19045) ou Windows 11; driver AMD R6.4 30.0.13045.22003 / Boot Camp.
- **OpenCore** (testado 1.0.6) — o firmware da Apple sozinho não substitui tabelas ACPI.
- Python 3 e `acpidump.exe` do ACPICA.

## Passo a passo
1. **Instale o OpenCore** na ESP interna e garanta que o Windows inicia por ele. Tenha um pendrive que restaure o `config.plist`.
2. **Extraia a VFCT** num terminal admin: `acpidump.exe -n VFCT -b`.
3. **Inspecione**: `python vfct-parse.py vfct.dat` → 5 conectores (com `obj 3114`), 5 encoders (com `221e`), 5 caminhos (com `tag 0002`), devsupport `068a`, `ss 0000:0000`.
4. **Aplique o patch**: `python vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Valide**: `python vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, cksum da ROM `0`.
6. **Monte a ESP**: `mountvol S: /S`; copie o `.aml` para `S:\EFI\OC\ACPI\`; faça backup do `config.plist`.
7. **Edite o config.plist** com as entradas `ACPI > Add` e `ACPI > Delete` do snippet (`VkZDVA==` = "VFCT").
8. **Reinicie** pelo OpenCore e confira o Gerenciador de Dispositivos e o `dxdiag`.

## Perguntas frequentes
**Por que o Código 43 só depois que a tela quebrou?** A VBIOS anuncia um conector eDP (tela interna). O driver tenta ligar esse painel, não recebe HPD e se remove ~0,4 s depois da detecção de telas → Código 43.
**Reinstalar driver / Windows 11 / Adrenalin novo resolve?** Não. Apple 22.19, AMD R6.4 e Adrenalin 26.5.2 (assinado em modo teste) falharam no Windows 10 e 11.
**Preciso da Intel integrada?** Não. **Não** use `apple_set_os.efi` num A1707 sem tela: travou o boot na maçã branca.
**A VBIOS vem no repositório?** Não. É protegida por direitos autorais da AMD/Apple; o script modifica o *seu próprio* dump.
**Afeta o macOS?** O OpenCore injeta as tabelas para todos os sistemas. O macOS não usa a VFCT nessa GPU, mas o boot do macOS com o patch ainda não foi reverificado — teste.
**Dá pra jogar?** Sim — a motivação foi rodar Warframe (DirectX 11/12) num A1707 sem tela.
**Launcher do Warframe: "Could not create directory C:\Program Files\Warframe"?** Dê permissão de Modificar ao seu usuário (admin): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.
**Ímã no sensor da tampa resolve?** Não nos nossos testes (override de `_LID` e chaves DAL no registro também falharam).

## Solução de problemas
- **Continua Código 43**: veja se a tabela modificada está ativa (VFCT com SS `106B:0179`). Se não, o OpenCore não carregou (caminho, `Enabled`, boot sem OpenCore).
- **Erro "object not found" no script**: VBIOS diferente; rode o `vfct-parse.py` e abra uma issue com a saída.
- **Mac não inicia / maçã branca**: use o pendrive de recuperação (Option → "EFI Boot") e restaure o backup; ou no macOS `sudo diskutil mount disk0s1` e copie o backup de volta.
- **Monitor 4K externo a ~30 Hz**: provável limite do cabo/adaptador/porta. Use cabo USB-C→DP ou 1440p/1080p a 60 Hz.
- **Tela preta no seletor de boot**: no OpenCore, `UEFI > Output > Resolution` (ex.: `1920x1080@32`) e `ForceResolution`.

## Pós-instalação: Touch Bar e trackpad no Boot Camp
Verificado em 21/10/2026 no mesmo A1707 sem tela (Windows 10 22H2, Boot Camp 6.1). Correção da Radeon confirmada com o Warframe baixando e rodando no driver AMD.

### Touch Bar não funciona no Windows / tecla ESC sumiu
- Os drivers oficiais do Boot Camp 6.1 estavam instalados e OK: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (chip T1), teclado/trackpad SPI 6.1.6700.0.
- Causa: o **`Bootcamp.exe` (app da bandeja do Boot Camp) não estava rodando**. É ele que controla a Touch Bar (teclas de função / ESC).
- Solução: reinicie o `Bootcamp.exe` e depois o dispositivo composto do T1 (`pnputil /restart-device "<instance id de USB\VID_05AC&PID_8600...>"`). Touch Bar e ESC voltaram **mesmo com a tela interna removida**.

### Toque para clicar / clique direito (clique secundário) do trackpad resetam após reiniciar
- O Boot Camp guarda essas opções só em `HKCU\Software\Apple Inc.\Trackpad\Mode` (DWORD, bits não documentados).
- Configure em `C:\Windows\System32\AppleControlPanel.exe` → Trackpad e leia o valor: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (o nosso: `40`).
- Reaplique a cada logon com o [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) (grava `Mode`, reinicia o `Bootcamp.exe` em até 5 tentativas) numa Tarefa Agendada com atraso de 10 s e 3 novas tentativas. Exemplo (copie o script para `C:\Tools\`, rode como admin, troque `<usuario>`):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<usuario>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Depois, no Agendador de Tarefas → tarefa → Configurações: "Se a tarefa falhar, reiniciar a cada 1 minuto", "Tentar reiniciar até 3 vezes" (ou use `Register-ScheduledTask` com `New-ScheduledTaskSettingsSet -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)`).

### Rolagem com dois dedos rápida demais
`HKCU\Control Panel\Desktop\WheelScrollLines` de `3` para `1`, aplicado na hora com `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69, 1, NULL, SPIF_UPDATEINIFILE|SPIF_SENDCHANGE)`. O script faz isso com `-WheelScrollLines 1`.

## Créditos
**Ryan Anthony Gibo** — autor, descobridor da causa raiz e da correção, testes no hardware. Agradecimentos aos projetos ACPICA, OpenCore (Acidanthera) e OpenCore Legacy Patcher. Ajudou? Deixe uma ⭐ e cite via [CITATION.cff](CITATION.cff).

Licença: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.
## Trackpad: rolagem / botão direito param de novo (solução definitiva)

**Causa:** o driver Apple SPI Trackpad continua OK, mas os gestos (rolar com dois dedos, clique direito com dois dedos, tocar para clicar) só funcionam enquanto o `Bootcamp.exe` está rodando. O Bootcamp.exe 6.1.6700 trava sozinho (Evento 1000 `BEX64`) e só é iniciado uma vez no logon.

**Solução:** rode `scripts/trackpad/install.ps1` (sem admin). A tarefa `A1707-TrackpadWatchdog` reinicia o Bootcamp.exe no logon, desbloqueio, volta da suspensão, logo após um crash e a cada 2 min, e reaplica Mode=40 e rolagem de 1 linha. Log em `C:\Setup\trackpad\watchdog.log`.

Credits / Créditos: Ryan Anthony Gibo.

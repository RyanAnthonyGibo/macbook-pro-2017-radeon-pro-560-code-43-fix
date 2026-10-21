# Resolvendo o "Código 43" da AMD Radeon Pro 560 num MacBook Pro 15" 2017 (A1707) sem tela no Windows: removendo o caminho eDP interno da imagem de VBIOS na tabela ACPI VFCT

**Autor: Ryan Anthony Gibo** ([@RyanAnthonyGibo](https://github.com/RyanAnthonyGibo)) · Outubro de 2026 · Licença MIT · 🇺🇸 [English version](paper-en.md) · [← README](../README.pt-BR.md)

> Aviso: notas de pesquisa de uma máquina. Use por sua conta e risco. Binários de VBIOS não são distribuídos.

## Resumo
Num MacBook Pro 15" 2017 (MacBookPro14,3, A1707) cujo painel eDP interno foi removido fisicamente, a GPU dedicada AMD Radeon Pro 560 (Polaris 11 "Baffin", 1002:67EF, SUBSYS 0179106B) falha no Windows 10 22H2 e no Windows 11 com Código 43 (`CM_PROB_FAILED_POST_START`), independentemente da versão do driver e do caminho de boot, enquanto funciona no macOS. Um trace ETW do DxgKrnl mostra o driver AMD iniciando com sucesso e pedindo a remoção do dispositivo ≈0,4–0,5 s após `DdiDisplayDetectControl`. Mostramos que a causa é a tabela de objetos ATOM BIOS dentro da tabela ACPI **VFCT**, que ainda declara o caminho de tela LCD1/eDP. Removendo o conector eDP, seu encoder e o caminho LCD1, limpando `ATOM_DEVICE_LCD1_SUPPORT`, definindo o subsystem 106B:0179 e corrigindo os dois checksums — e injetando a tabela via OpenCore `ACPI > Delete + Add` — a GPU volta a funcionar por completo (Status OK, 4 GB de VRAM, driver AMD 30.0.13045.22003).

## 1. Hardware e software
| Item | Valor |
|---|---|
| Máquina | MacBook Pro 15" 2017, A1707, MacBookPro14,3 |
| GPU | AMD Radeon Pro 560 4 GB GDDR5, PCI 1002:67EF SUBSYS_0179106B, ACPI `\_SB.PCI0.PEG0.GFX0` |
| VBIOS | 113-C9801AU-A02 (BaffinM / "Falcon" J80A) |
| Tela interna | Removida após dano físico (antes disso o Boot Camp funcionava 100%) |
| Tela externa | LG 4K via USB-C/HDMI |
| SO | Windows 10 22H2 (19045) com drivers Boot Camp 6.1; Windows 11 Insider 26300 também testado |
| Boot | OpenCore 1.0.6 (build OCLP) e seletor nativo da Apple |
| Drivers testados | Apple Boot Camp 22.19; AMD R6.4 30.0.13045.22003 (`u0418524.inf`); Adrenalin 26.5.2 31.0.21925.1001 (INF assinado em modo teste) |

Sem o driver AMD o Windows usa o Adaptador de Vídeo Básico da Microsoft (framebuffer GOP, um único modo, sem aceleração), e jogos DirectX 11/12 (ex.: Warframe) não rodam.

## 2. Sintoma
Gerenciador de Dispositivos: *"O Windows parou este dispositivo porque ele relatou problemas. (Código 43)"*, problema `CM_PROB_FAILED_POST_START`, igual em todos os drivers, builds e caminhos de boot. No macOS, no mesmo hardware, a GPU funciona (Metal) — o chip e a memória estão bons.

## 3. Diagnóstico
### 3.1 Trace ETW da inicialização do driver
```
logman create trace dxg -p Microsoft-Windows-DxgKrnl 0xFFFFFFFF 5 -o dxg.etl -ets
pnputil /restart-device "<instance id da GPU>"
logman stop dxg -ets
tracerpt dxg.etl -o dxg.xml -of XML
```
Linha do tempo: `DdiStartDevice` SUCCESS (6 fontes VidPN, 19 filhos) → segmentos de memória (~4 GB) e contextos criados → `DdiDisplayDetectControl` OK → **≈0,4–0,5 s depois `FlushScheduler` + `DeviceRemoval`** → `DdiStopDeviceAndReleasePostDisplayOwnership`.

Conclusão: recursos, PnP e kernel estão OK; o próprio driver aborta durante a ativação das telas. Strings no `amdkmdag.sys` (`dce110_edp_wait_for_hpd_ready`, `edp_poweron`, `DalAllowEdpHotplugDetection`, `GetOpenLidState`) apontaram para a inicialização do eDP.

### 3.2 ACPI (ACPICA acpidump/iasl)
- **VFCT** presente com VBIOS válida, mas SSVID:SSID do cabeçalho da imagem = `0000:0000`. Sem `ATRM`, `_ROM` ou `ATPX`.
- SSDT "APPLE PEG0GFX0" define `GFX0` com `Device(LCD)` `_ADR 0x110`, `_DOD {0x110}`, métodos ATIF e mailbox do GMUX.
- `LID0._LID` do DSDT lê o sensor hall via EC; sem o painel (e seu ímã) a tampa sempre aparece *aberta*.

**Hipótese:** o driver é informado de que existe um painel eDP (tabela de conectores da VBIOS + tampa aberta), tenta ligá-lo, nunca recebe HPD e derruba o adaptador inteiro.

## 4. Experimentos que falharam (e por quê)
| # | Mudança | Resultado | Interpretação |
|---|---|---|---|
| 1 | Registro (class key): `PP_EnableLoadFalconSmcFirmware=0`, `PP_Falcon_QuickTransition_Enable=0`, `PP_Apple_Bootcamp_Enable=0`, `KMD_BootCampPlatform=0` | 43 | Não é o caminho Apple/SMC |
| 2 | `EnableUlps=0`, `PP_GPUPowerDownEnabled=0` | 43 | Não é economia de energia |
| 3 | Restaurar chaves originais | 43 | Linha de base |
| 4 | Resolução GOP do OpenCore 1920x1080 + `ForceResolution` | sem efeito | Framebuffer pré-SO irrelevante |
| 5 | SSDT sobrescrita: `GFX0` sem `Device(LCD)`/`_DOD` | 43 | O conector eDP **não** vem do ACPI |
| 6 | `_LID` forçado fechado (rename `_LID`→`XLID` + SSDT retornando 0 fora do Darwin) | 43 | O driver não lê a tampa (só) pelo ACPI |
| 7 | Chaves DAL do driver (`DalSkipDMUPanelPowerSequence`, `DalAllowEdpHotplugDetection`, `DalFeatureForceLidOpen`) | 43 | Sem saída pelo registro |
| 8 | `apple_set_os.efi` no OpenCore (expor a Intel) | **boot travado na maçã branca** | Perigoso no A1707 sem tela — não repetir |
| 9 | Adrenalin 26.5.2 sem o `ExcludeID` 0179106B, catálogo autoassinado, test-signing | 43 | Independe da geração do driver |
| — | Ímãs sobre os dois sensores hall da tampa | 43 (inconclusivo) | Posição não verificada |
| — | Windows 11 vs 10; OpenCore vs boot nativo | 43 | Plataforma, não SO |

Após 9 experimentos: o eDP tem de vir da **própria VBIOS**, que o driver no Windows lê da tabela ACPI VFCT em Macs (não há option ROM PCI exposta ao SO).

## 5. Estrutura da VFCT e do ATOM BIOS
### 5.1 VFCT ("VBIOS Fetch Content Table" da AMD)
| Offset | Campo |
|---|---|
| 0 | Cabeçalho ACPI padrão de 36 bytes (assinatura `VFCT`, tamanho, revisão, **checksum @9**, OEM ID @10, OEM Table ID @16) |
| 36 | TableUUID (16 B) |
| 52 | `VBIOSImageOffset` (u32) — 76 aqui |
| 56 | `Lib1ImageOffset` (u32) |
| 76 | `VFCT_IMAGE_HEADER` (28 B): PCIBus, PCIDevice, PCIFunction (u32), VendorID, DeviceID, **SSVID @+16, SSID @+18**, Revision (u32), ImageLength (u32) |
| 104 | Imagem da ROM (`55 AA`, tamanho @+2 em blocos de 512, **checksum da ROM @+0x21**) |

### 5.2 ATOM BIOS
`ROM[0x48]` → `ATOM_ROM_HEADER`; `+0x20` → Master Data Table; tabela de dados índice **22** → **Object Header** (formato 1, conteúdo 3). Campos em `+4`: `usDeviceSupport` e offsets das tabelas de conectores, roteadores, encoders, proteção e caminhos de tela. Conectores/encoders: `u8 count, u8 reservado[3]` + entradas de 8 bytes (`usObjectID, usSrcDstTableOffset, usRecordOffset, usReserved`). Caminhos: `u8 count, u8 version, u16 reservado` + `ATOM_DISPLAY_OBJECT_PATH` de tamanho variável (`usDeviceTag, usSize, usConnObjectId, usGPUObjectId, usGraphicObjIds[]`).

### 5.3 Tabela de objetos original (VBIOS 113-C9801AU-A02)
`usDeviceSupport = 0x068A`
| Tag | Conector | Encoder |
|---|---|---|
| **0x0002 (LCD1)** | **0x3114 (eDP)** | **0x221E** |
| 0x0008 | 0x3113 (DP) | 0x211E |
| 0x0080 | 0x3213 (DP) | 0x2220 |
| 0x0200 | 0x3313 (DP) | 0x2120 |
| 0x0400 | 0x3413 (DP) | 0x2121 |

Os quatro DP são as saídas de vídeo Thunderbolt 3 / USB-C; o eDP é a tela Retina removida.

## 6. O patch (`scripts/vfct-patch.py`)
1. Localiza a ROM (`VBIOSImageOffset + 28`), o ROM header, a Master Data Table e o Object Header.
2. Remove o conector `0x3114` e o encoder `0x221E` (desloca as entradas, decrementa o contador, zera o fim; offsets de registros continuam válidos).
3. Remove o caminho com `usDeviceTag 0x0002`.
4. `usDeviceSupport 0x068A → 0x0688` (limpa `ATOM_DEVICE_LCD1_SUPPORT`, bit 1).
5. SSVID:SSID do cabeçalho da imagem `0000:0000 → 106B:0179` (igual ao subsystem PCI, como o driver espera).
6. Recalcula o checksum da ROM (byte `0x21`, soma de `ROM[0..size)` ≡ 0 mod 256), define o OEM Table ID e recalcula o checksum ACPI (byte 9).

O script verifica que cada objeto existe exatamente uma vez e aborta caso contrário. No nosso caso mudaram 66 bytes; tamanho inalterado (62.084 B).

## 7. Validação
`vfct-parse.py` na saída: 4 conectores / 4 encoders / 4 caminhos, devsupport `0688`, SS `106b:0179`, checksum ACPI OK, checksum da ROM 0. Após o boot, `GetSystemFirmwareTable('ACPI','VFCT')` retornou a tabela modificada (SS 106B:0179).

**Resultado:** Radeon Pro 560 — Status OK, `CM_PROB_NONE`, AMD R6.4 30.0.13045.22003, 4 GB de VRAM, LG externo em 3840x2160, aceleração por hardware; test-signing desligado (não é necessário).

## 8. Configuração do OpenCore
Coloque `VFCT-noeDP.aml` em `EFI/OC/ACPI/` e adicione:
```xml
<key>Add</key><array><dict>
  <key>Comment</key><string>VFCT with eDP connector removed</string>
  <key>Enabled</key><true/>
  <key>Path</key><string>VFCT-noeDP.aml</string>
</dict></array>
<key>Delete</key><array><dict>
  <key>All</key><false/>
  <key>Enabled</key><true/>
  <key>OemTableId</key><data></data>
  <key>TableLength</key><integer>0</integer>
  <key>TableSignature</key><data>VkZDVA==</data> <!-- "VFCT" -->
</dict></array>
```
Sem mudanças em `Drivers`, `Booter` ou `NVRAM`. Snippet completo: [`opencore/config-snippet.plist`](../opencore/config-snippet.plist).

## 9. Riscos, recuperação e limitações
- **Risco:** um config.plist ou tabela ruim pode impedir o boot. Sempre faça backup do `config.plist`; tenha um pendrive cujo script monte a ESP interna e restaure o backup (boot via Option → "EFI Boot"). No macOS: `sudo diskutil mount disk0s1` e copie o backup. No Windows: `mountvol S: /S`.
- **Nunca** adicione `apple_set_os.efi` num A1707 sem tela (trava o boot).
- **macOS:** o OpenCore aplica as mudanças ACPI a todos os SOs. O macOS não usa a VFCT nessa GPU, mas o boot do macOS com o patch **ainda não foi reverificado**.
- **Só funciona com boot pelo OpenCore** — o seletor nativo da Apple carrega a VFCT original (o Código 43 volta).
- **Tela interna:** deixa de ser suportada; ao instalar um painel novo, remova o patch.
- **4K externo a 29 Hz** num LG via USB-C/HDMI; provavelmente limite de cabo/adaptador/porta (HDMI 1.4), não do patch. Use DisplayPort ou resolução menor para 60 Hz.
- Testado numa máquina/VBIOS (113-C9801AU-A02). Radeon Pro 555/450/455 ou outras revisões podem ter IDs diferentes.
- Binários de firmware são protegidos por direitos autorais da AMD/Apple e não são distribuídos; só a transformação é publicada.

## 10. Conclusão
O Código 43 num A1707 sem tela não é bug de driver, e sim uma descrição de plataforma errada: a VBIOS promete um painel eDP que não existe mais, e o driver AMD derruba o adaptador ao não conseguir ativá-lo. Editar a cópia da VBIOS na tabela VFCT — e não dispositivos ACPI, registro ou drivers — resolve por software, de forma reversível.

## Créditos e citação
Pesquisa, descoberta e testes: **Ryan Anthony Gibo**. Ferramentas: ACPICA, OpenCore (Acidanthera), OpenCore Legacy Patcher. Cite via [`CITATION.cff`](../CITATION.cff).

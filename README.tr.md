🌐 🇺🇸 [English](README.md) · 🇧🇷 [Português](README.pt-BR.md) · 🇪🇸 [Español](README.es.md) · 🇫🇷 [Français](README.fr.md) · 🇩🇪 [Deutsch](README.de.md) · 🇮🇹 [Italiano](README.it.md) · 🇳🇱 [Nederlands](README.nl.md) · 🇵🇱 [Polski](README.pl.md) · 🇷🇺 [Русский](README.ru.md) · 🇺🇦 [Українська](README.uk.md) · 🇹🇷 [Türkçe](README.tr.md) · 🇸🇦 [العربية](README.ar.md) · 🇮🇳 [हिन्दी](README.hi.md) · 🇮🇩 [Bahasa Indonesia](README.id.md) · 🇹🇭 [ไทย](README.th.md) · 🇻🇳 [Tiếng Việt](README.vi.md) · 🇯🇵 [日本語](README.ja.md) · 🇰🇷 [한국어](README.ko.md) · 🇨🇳 [简体中文](README.zh-Hans.md) · 🇹🇼 [繁體中文](README.zh-Hant.md)

# MacBook Pro 2017 (A1707) Radeon Pro 560 / 555 Kod 43 Hatası Çözümü — Dahili Ekranı Kırık veya Sökülmüş (eDP) Windows 10/11 Boot Camp, OpenCore ile VFCT VBIOS Yaması

📄 **Teknik makale:** [English](docs/paper-en.md) · [Português](docs/paper-pt-BR.md)

> **Yazar ve keşfeden: [Ryan Anthony Gibo](https://github.com/RyanAnthonyGibo)** — kök neden 21.10.2026'da bulundu ve çözüm oluşturuldu.

**AMD Radeon Pro 560 veya Radeon Pro 555**'li **MacBook Pro 15" 2017 (A1707, MacBookPro14,3)** cihazınız Aygıt Yöneticisi'nde **"Sorun bildirdiği için Windows bu aygıtı durdurdu. (Kod 43)"** mi gösteriyor? **Dahili ekran (LCD / eDP paneli) kırık, bağlantısız veya sökülmüş** ve Mac'i **ekransız (headless) harici monitörle** (USB-C, Thunderbolt 3, HDMI, DisplayPort) mı kullanıyorsunuz? **AMD sürücüsü (Boot Camp, Adrenalin)**, **VBIOS hâlâ dahili eDP panelini bildirdiği** için çöker. Bu depo sorunu çözer: Windows'un okuduğu VBIOS kopyası olan **ACPI VFCT tablosunu** yamalayıp eDP bağlantısını kaldırır ve **OpenCore** (`ACPI > Delete + Add`) ile yükler. Sonuç: **4 GB VRAM, DirectX 11/12 ve donanım hızlandırma** ile çalışan Radeon Pro 560.

Anahtar kelimeler: MacBook Pro 2017 kod 43 hatası, A1707 Radeon Pro 560 kod 43, Boot Camp kırık ekran ekran kartı, Radeon Pro 555 kod 43 Windows 10, Radeon Pro 560 çalışmıyor Windows 11, ekransız MacBook Pro Windows, Boot Camp headless, eDP AMD sürücü, VFCT yaması, VBIOS, OpenCore Boot Camp GPU, MacBook Pro'da Warframe, Windows'ta Touch Bar çalışmıyor, Boot Camp ESC tuşu yok, Boot Camp trackpad dokunarak tıklama yeniden başlatınca sıfırlanıyor, Boot Camp sağ tık, iki parmakla kaydırma çok hızlı.

> ⚠️ **UYARI — RİSK SİZE AİTTİR.** Önyükleyicinin yüklediği donanım yazılımı tablolarını değiştiriyorsunuz. Yanlış bir yapılandırma Mac'in açılmasını engelleyebilir. Bir kurtarma USB'si ve `config.plist` yedeği bulundurun. Garanti yoktur ([LICENSE](LICENSE)). Apple veya AMD ile ilişkili değildir.

## Hızlı çözüm (TL;DR)
1. Windows'u başlatın (Microsoft Temel Görüntü Bağdaştırıcısı çalışır) ve normal Boot Camp / AMD sürücüsünü kurun (Kod 43 verecek — beklenen bu).
2. VFCT'yi dökün: `acpidump.exe -n VFCT -b` ([ACPICA](https://github.com/acpica/acpica/releases)) → `vfct.dat`.
3. `python scripts/vfct-parse.py vfct.dat` → `3114` (eDP) bağlantısını ve `0002` (LCD1) yolunu doğrulayın.
4. `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`, ardından `python scripts/vfct-parse.py VFCT-noeDP.aml` (4 bağlantı, sağlama toplamları OK).
5. `VFCT-noeDP.aml` dosyasını `EFI\OC\ACPI\` içine kopyalayın, `config.plist` yedeği alın ve [opencore/config-snippet.plist](opencore/config-snippet.plist) ekleyin.
6. OpenCore ile yeniden başlatın → Aygıt Yöneticisi: **Radeon Pro 560 — "Bu aygıt düzgün çalışıyor"** ✅

## Gereksinimler
- MacBook Pro 15" 2017 A1707 (MacBookPro14,3), Radeon Pro 560 (1002:67EF SUBSYS_0179106B). Radeon Pro 555 / 2016 A1707 muhtemelen benzer ama **doğrulanmadı**; kimlikler farklıysa betik durur.
- Windows 10 22H2 (19045'te test edildi) veya Windows 11; AMD R6.4 30.0.13045.22003 / Boot Camp sürücüsü.
- **OpenCore** (1.0.6 test edildi): Apple donanım yazılımı ACPI tablolarını değiştiremez.
- Python 3 ve ACPICA `acpidump.exe`.

## Adım adım kılavuz
1. Dahili ESP'ye **OpenCore kurun** ve Windows'un onunla açıldığından emin olun. `config.plist`'i geri yükleyebilen bir USB bulundurun.
2. Yönetici terminalinde **VFCT'yi dökün**: `acpidump.exe -n VFCT -b`.
3. **İnceleyin**: `python scripts/vfct-parse.py vfct.dat`. Beklenen: `obj 3114` (eDP), `221e`, `tag 0002`, devsupport `068a`, `ss 0000:0000`.
4. **Yamalayın**: `python scripts/vfct-patch.py vfct.dat VFCT-noeDP.aml`.
5. **Doğrulayın**: `python scripts/vfct-parse.py VFCT-noeDP.aml` → 4/4/4, devsupport `0688`, `ss 106b:0179`, `cksum ok True`, ROM cksum `0`.
6. **ESP'yi bağlayın**: `mountvol S: /S` → `S:\EFI\OC\ACPI\VFCT-noeDP.aml`; `config.plist` yedeği alın.
7. **config.plist'i düzenleyin**: snippet'teki `ACPI > Add` ve `ACPI > Delete` girdilerini ekleyin (`VkZDVA==` = "VFCT").
8. OpenCore ile **yeniden başlatın**; Aygıt Yöneticisi ve `dxdiag`'ı kontrol edin.

## SSS
**Kod 43 neden ekran kırıldıktan sonra çıktı?** VBIOS bir eDP bağlantısı bildiriyor. Sürücü paneli açmaya çalışır, HPD alamaz ve ekran algılamadan ~0,4 sn sonra kendini kaldırır → Kod 43.

**Sürücüleri yeniden kurmak, Windows 11 veya yeni Adrenalin işe yarar mı?** Hayır. Apple 22.19, AMD R6.4 ve Adrenalin 26.5.2, Windows 10 ve 11'de başarısız oldu.

**Dahili Intel GPU gerekir mi?** Hayır. Ekransız bir A1707'de `apple_set_os.efi` **kullanmayın**: açılış Apple logosunda takıldı.

**VBIOS'um depoda var mı?** Hayır. AMD/Apple telif hakkı altındadır; betik *kendi* dökümünüzü yamalar.

**macOS'u etkiler mi?** OpenCore tabloları tüm sistemlere yükler. macOS bu GPU için VFCT kullanmaz, ancak yamayla macOS açılışı henüz yeniden doğrulanmadı — test edin.

**Oyun oynayabilir miyim?** Evet: ekransız bir A1707'de inen ve çalışan Warframe (DirectX 11/12) ile doğrulandı.

**Kapak sensörüne mıknatıs koymak çözer mi?** Testlerimizde hayır (`_LID` geçersiz kılma ve DAL kayıt defteri anahtarları da işe yaramadı).

**Warframe başlatıcısı: "Could not create directory C:\Program Files\Warframe"?** Kullanıcınıza Değiştirme izni verin (yönetici olarak): `icacls "C:\Program Files\Warframe" /grant "%USERNAME%":(OI)(CI)M`.

## Sorun giderme
- **Hâlâ Kod 43**: yamalı tablonun etkin olduğunu kontrol edin (SS `106B:0179` olan VFCT). Değilse OpenCore yüklememiştir (yol, `Enabled`, OpenCore'suz açılış).
- **Betikte "object not found" hatası**: farklı VBIOS; `vfct-parse.py` çalıştırın ve çıktıyla issue açın.
- **Mac açılmıyor / beyaz Apple logosu**: kurtarma USB'sinden açın (Option → "EFI Boot") ve yedeği geri yükleyin; veya macOS'ta `sudo diskutil mount disk0s1` ile yedeği geri kopyalayın.
- **Harici 4K monitör ~30 Hz**: büyük olasılıkla kablo/adaptör/port sınırı. USB-C→DP veya 60 Hz'de 1440p/1080p kullanın.
- **Önyükleme seçicide siyah ekran**: OpenCore'da `UEFI > Output > Resolution` (ör. `1920x1080@32`) ve `ForceResolution`.

## Kurulum sonrası: Boot Camp'te Touch Bar ve trackpad
21.10.2026'da aynı ekransız A1707'de doğrulandı (Windows 10 22H2, Boot Camp 6.1).

### Windows'ta Touch Bar çalışmıyor / ESC tuşu yok
- Resmî Boot Camp 6.1 sürücüleri kurulu ve sorunsuzdu: **Apple Touch Bar** (`appledfr.inf` 6.1.6500.0), **Apple USB Composite Device 05AC:8600** (T1), SPI keyboard/trackpad 6.1.6700.0.
- Neden: **`Bootcamp.exe` (Boot Camp sistem tepsisi uygulaması) çalışmıyordu**; Touch Bar'ı (işlev tuşları / ESC) o yönetir.
- Çözüm: `Bootcamp.exe`'yi, ardından T1 bileşik aygıtını yeniden başlatın (`pnputil /restart-device "<USB\VID_05AC&PID_8600...>"`). Touch Bar ve ESC **dahili ekran olmadan bile** geri geldi.

### Trackpad dokunarak tıklama / ikincil tıklama yeniden başlatınca kayboluyor
- Boot Camp bu seçenekleri yalnızca `HKCU\Software\Apple Inc.\Trackpad\Mode` içinde saklar (DWORD, belgelenmemiş bitler).
- `C:\Windows\System32\AppleControlPanel.exe` → Trackpad'den ayarlayın ve değeri okuyun: `(Get-ItemProperty 'HKCU:\Software\Apple Inc.\Trackpad').Mode` (bizimki: `40`).
- Her oturum açılışında [`scripts/bootcamp-reapply.ps1`](scripts/bootcamp-reapply.ps1) ile yeniden uygulayın (`Mode` yazar, `Bootcamp.exe`'yi 5 denemeye kadar yeniden başlatır); 10 sn gecikmeli ve 3 yeniden denemeli bir zamanlanmış görevle. Örnek (betiği `C:\Tools\` içine kopyalayın, yönetici olarak, `<user>` değiştirin):
```powershell
schtasks /Create /TN "BootCampReapply" /RU "<user>" /IT /RL HIGHEST /SC ONLOGON /DELAY 0000:10 /F `
  /TR "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Tools\bootcamp-reapply.ps1 -Mode 40"
```
Sonra Görev Zamanlayıcı → Ayarlar: "Görev başarısız olursa her 1 dakikada yeniden başlat", "En fazla 3 kez dene" (veya `Register-ScheduledTask` ile `New-ScheduledTaskSettingsSet -RestartCount 3`).

### İki parmakla kaydırma çok hızlı
`HKCU\Control Panel\Desktop\WheelScrollLines` değerini `3`'ten `1`'e alın, `SystemParametersInfo(SPI_SETWHEELSCROLLLINES = 0x69)` ile anında uygulanır. Betik bunu `-WheelScrollLines 1` ile yapar.

## Depo içeriği
| Yol | Ne işe yarar |
|---|---|
| `scripts/vfct-patch.py` | eDP bağlantısını/kodlayıcısını ve LCD1 yolunu kaldırır, LCD1 bayrağını temizler, SSID 106B:0179 yapar, sağlama toplamlarını düzeltir |
| `scripts/vfct-parse.py` | VFCT ve ATOM nesne tablosunu çözümler, sağlama toplamlarını doğrular |
| `scripts/bootcamp-reapply.ps1` | Oturum açılışında trackpad Mode'unu uygular ve Bootcamp.exe'yi (Touch Bar) yeniden başlatır |
| `opencore/config-snippet.plist` | OpenCore `ACPI > Delete + Add` girdileri |
| `docs/paper-en.md`, `docs/paper-pt-BR.md` | Tam teknik makale (İngilizce / Portekizce) |

## Katkılar
**Ryan Anthony Gibo**: yazar, kök nedeni ve çözümü bulan, donanım testleri. ACPICA, OpenCore (Acidanthera) ve OpenCore Legacy Patcher'a teşekkürler. İşinize yaradı mı? ⭐ verin ve [CITATION.cff](CITATION.cff) ile atıf yapın.

Lisans: [MIT](LICENSE) © 2026 Ryan Anthony Gibo.

## Trackpad watchdog (Bootcamp.exe crash fix)

See [README.md](README.md#trackpad-scroll--right-click-stops-working-again-definitive-fix) and `scripts/trackpad/install.ps1`. By Ryan Anthony Gibo.

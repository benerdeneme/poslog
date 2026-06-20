# POS Panel — Otomatik Giriş + Otomatik Açılış

> **Otomatik güncelleme:** Eklenti GitHub'dan (benerdeneme/poslog) her sabah **07:55**'te kendini
> günceller. content.js değişince şubeler ertesi gün otomatik çeker — makinelere tek tek girmeye
> gerek yok. (KURULUM.bat bu görevi de kurar.)

## Ne yapıyor?
1. **Auto-login eklentisi:** Panel çıkış yapınca, tarayıcıda **kayıtlı kullanıcı adı/şifreyle** otomatik **"Giriş Yap"a basar**.
2. Her gün **08:00'da** sayfayı yeniler (çıkışı yüzeye çıkarıp otomatik giriş yapsın).
3. **Windows açılınca** Chrome otomatik açılıp paneli yükler.
4. Chrome 08:00'da kapalıysa, zamanlanmış görev onu açar.
5. Her gün **07:55'te** eklentiyi GitHub'dan günceller.

---

## ⚡ Tek komutla kurulum (en kolay)

**Başlat → cmd** (veya PowerShell) aç, şunu yapıştır + Enter:

```
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/benerdeneme/poslog/master/kur.ps1 | iex"
```

Bu otomatik: GitHub'dan indirir → **Belgeler\poslog**'a kurar → görevleri kurar → `chrome://extensions` açar.
Sonra sadece aşağıdaki **4. adımı** (eklentiyi 3 tıkla yükle) yapman yeter.

---

## Manuel kurulum — her şubede (~3 dk, bir kez)

### 1. Klasörü indir
- https://github.com/benerdeneme/poslog → yeşil **Code** → **Download ZIP** → bir yere çıkar (örn. Belgeler).

### 2. Şifre Chrome'da kayıtlı olsun
- Panele bir kez elle girerken Chrome **"Şifreyi kaydet"** deyince **Kaydet** de.

### 3. KURULUM.bat'a çift tıkla
- **Yönetici izni** penceresine **"Evet"** de.
- Başlangıç açılışı + 08:00 + 07:55 güncelleme görevleri kurulur, sonunda `chrome://extensions` açılır.

### 4. Eklentiyi yükle (3 tık)
- Açılan **chrome://extensions** sayfasında sağ üstte **"Geliştirici modu"** → **AÇ**.
- **"Paketlenmemiş öğe yükle"** → çıkardığın klasörün içindeki **`eklenti`** klasörünü seç.
- **"POS Otomatik Giriş"** listede belirir.

Hepsi bu. Artık her sabah otomatik.

---

## Test

### Otomatik giriş
1. Panelde **elle çıkış yap** (login ekranı: `https://pm01.robotpos.com/restaurant/login`).
2. **F5** → eklenti otomatik "Giriş Yap"a basıp girmeli.
3. **F12 → Console**'da `[POS-AutoLogin]` satırları görünür.

### 08:00 görevi (Chrome kapalıyken)
1. Chrome'u tamamen kapat.
2. PowerShell'de: `Start-ScheduledTask -TaskName "POS 08-00 Kontrol"` → Chrome açılmalı.

### Windows açılışı
- Bilgisayarı yeniden başlat → Chrome kendiliğinden açılıp paneli yüklemeli.

---

## Notlar
- **Önce BİR şubede test et**, sorunsuzsa diğerlerine aynısını uygula.
- Makine yeniden başlayınca kilit ekranı şifre soruyorsa: **Win+R → `netplwiz`** → "Kullanıcıların bu bilgisayarı kullanmak için..." işaretini kaldır → şifreyi gir.
- Autofill bir şubede çalışmazsa: `eklenti\content.js` içindeki `USERNAME=''`/`PASSWORD=''` satırlarına o şubenin bilgisini yaz.

## Güncelleme nasıl yayılır?
content.js GitHub'da değişince, her şube **07:55**'te otomatik çeker ve Chrome'u yeniler. Elle hiçbir şey yapmana gerek yok.

## Kaldırma
Yönetici PowerShell'de:
```powershell
Unregister-ScheduledTask -TaskName "POS 08-00 Kontrol" -Confirm:$false
Unregister-ScheduledTask -TaskName "POS Guncelle" -Confirm:$false
Remove-Item "$([Environment]::GetFolderPath('Startup'))\POS Panel.lnk"
```
Eklentiyi de chrome://extensions'dan kaldır.

## Dosyalar
| Dosya | İşi |
|---|---|
| **KURULUM.bat** | ⭐ Tek tık kurulum (yönetici) |
| eklenti/ | Chrome eklentisi (manifest.json + content.js) |
| kurulum.ps1 / 08-kontrol.ps1 / guncelle.ps1 | KURULUM.bat bunları çağırır |
| pos-autologin.user.js | (yedek) Tampermonkey kullanmak istersen |

## Sorun çözme
| Belirti | Çözüm |
|---|---|
| Eklenti listede yok | chrome://extensions → Geliştirici modu → Paketlenmemiş öğe yükle → `eklenti` klasörü |
| Giriş yapmıyor | F12 → Console `[POS-AutoLogin]` loglarına bak |
| Dolduruyor ama giremiyor | content.js'e USERNAME/PASSWORD yaz |

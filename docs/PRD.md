# PRD — Numbered Ball Shooter (Working Title)

Oct 15, 2026 · @Someone

## 1. Ürün özeti, fazlar ve karar kaydı

Bu belge, "sayılı top atış" oyununun Flutter ile yazılacak mobil sürümü için tek kaynak gerçektir. Geliştirici bir yapay zekadır ve insan müdahalesi olmayacaktır; bu yüzden her ayrıntı açık yazıldı ve belirsiz kalan her nokta bir varsayılan değerle kapatıldı. Bu belgede yazmayan bir davranış eklenmez, yazan bir davranış değiştirilmez.

### 1.1 Oyun tek paragrafta

Dikey ekranda, 7 sütunlu bir ızgarada üzerinde sayı yazan toplar durur. Oyuncu ekranın herhangi bir yerine basıp çekip bırakarak ekranın altından bir top dizisi fırlatır. Toplar duvarlardan ve sayılı toplardan seker, her temasta çarptığı sayılı topun sayısı (HP) 1 azalır, 0 olan top yok olur. Tüm toplar yere inince her şey bir satır aşağı kayar ve en üste yeni bir satır gelir. Sayılı toplardan biri en alt satırın altına (9. satıra) inerse oyun biter. Halkalar toplanınca oyuncunun top sayısı artar. Skor, eklenen satır sayısıdır (tur sayacı). Süre sınırı yoktur.

### Referans oyunlar (99 Balls ailesi)

Bu PRD, "99 Balls" türündeki HTML5 oyunların mekaniğini mobil Flutter oyununa çevirir. IDE'deki yapay zeka bu oyunların adını yalnızca bağlam için bilmelidir; tüm kurallar bu PRD'de yazılıdır ve PRD referans oyunun kendisinden önce gelir.

| Referans oyun | Yapımcı | Rol |
| --- | --- | --- |
| 99 Balls | Diamond Games | Ana referans. PRD'deki ölçüler, HP kuralı, ağırlıklar ve animasyonlar bu oyunun ekran kaydından çıkarıldı |
| 99 Balls Evo | Agame | Aynı mekaniğin başka bir sürümü; ilk ekran görüntülerinde kullanıldı, mekanik aynı |

- **Alınan:** Oynanış mekaniği (bir yerden çekip bırakarak atış, rakamlı hedefler, halkayla top artışı, satır satır inen tahta, 8. satırda oyun sonu).
- **Alınmayan:** Ad, logo, renkler, çizimler, sesler, menü düzeni ve metinler. Bunların hepsi yeni ve özgün üretilir (bölüm 7 ve 8).
- Referans oyunların kodu veya varlıkları projeye eklenmez; yapay zeka bu oyunların ekran görüntülerini taklit eden bir görünüm çizmez.

### 1.2 Fazlar

| Faz | Kapsam | Durum |
| --- | --- | --- |
| Faz 1 | Tek oyunculu oyun, ana menü, nasıl oynanır, ayarlar (dil popup dahil), feedback (EmailJS), çıkış, ses ve titreşim, yerelleştirme altyapısı | Bu PRD'nin tam kapsamı, hemen geliştirilecek |
| Faz 2 | Rekabetçi mod: Google/Apple girişi, günde 3 hak, haftalık tablo (ilk 10 gösterim, 11-20 yedek), ban filtresi, kutlama popup'ı | Bu PRD'de bölüm 11'de tanımlı, Faz 1 bittikten sonra geliştirilecek. Faz 1 kodu bunu engellemeyecek şekilde (tohumlu deterministik motor, atış kaydı) yazılır |

### 1.2.1 Kapsam dışı (hiçbir fazda yapılmayacak)

- Mağaza, skin ve yıldız para birimi (harcanabilir yıldız) yoktur. Yıldız yalnızca oyun içinde toplanan ve skora ekstra puan veren bir nesnedir (bölüm 5.11); biriktirilmez, harcanmaz, oyunlar arası taşınmaz.
- Reklam ve uygulama içi satın alma (sonra, oyun bitince eklenecek; kod bunu engellemeyecek).
- Referans oyundaki Twitter butonu.
- Kendi işletilen sunucu, Cloud Functions veya sunucu tarafı doğrulama. Yalnızca Faz 2'de Firebase Auth ve Firestore kullanılır.
- Referans oyundan gelen hiçbir görsel, ses, isim, logo veya yazı. Bunların hepsini yapay zeka özgün üretir (bölüm 2.6).

### 1.3 Karar kaydı

Karar sahibi ürün sahibidir. "Kabul" = ürün sahibi açıkça onayladı. "Varsayım" = benim önerim, ürün sahibi itiraz etmedikçe geçerlidir.

| # | Karar | Durum |
| --- | --- | --- |
| K1 | Referans: videodaki "99 Balls" mekaniği esas alınır | Kabul |
| K2 | Tema, isim, logo, renk, ses: yapay zeka özgün seçer | Kabul |
| K3 | Dil: ilk sürümde yalnızca İngilizce. Tüm metinler harici .arb dosyasında anahtarla tutulur, koda gömülmez | Kabul |
| K4 | Faz 1'de reklam ve mağaza yok | Kabul |
| K5 | Ekran ölçekleme: iPhone SE 2 ve iPhone 15 Pro Max'te aynı oranlı yerleşim (bölüm 3) | Kabul |
| K6 | Ana menü sıfırdan tasarlanır: üst yarı ortada logo, alt yarı butonlar (Play, How to Play, Feedback, Settings, Exit) | Kabul |
| K7 | Nişan: ekranın herhangi bir yerinden basıp çek-bırak, top üzerinden başlamak gerekmez; yön basma noktasına göre göreli ve çekmenin tersi yönde | Kabul (videodan doğrulandı) |
| K8 | Feedback: EmailJS, diğer uygulamalarla aynı kanal ve şablon yapısı | Kabul |
| K9 | Çıkış butonu iki platformda da uygulamayı tamamen kapatır | Kabul |
| K10 | Ayarlarda dil seçimi satıra dokununca açılan popup ile yapılır | Kabul |
| K11 | Rekabetçi mod için giriş: Google, iOS'ta ek olarak Apple. Anonim oynanabilir ama skor hiçbir koşulda veritabanına yazılmaz | Kabul |
| K12 | Sunucu yok; hile önleme cihaz içinde yapılır (bölüm 11.8) | Kabul |
| K13 | Hak: başlarken düşer, çıkış ve yeniden başlatma hakkı geri vermez, yeniden başlatma bir hak daha tüketir, 0 olunca mod açılmaz | Kabul |
| K14 | Arka plana alınca: tek oyunculuda duraklatma menüsü açılır; rekabetçide menü açılır ve yalnızca Restart ve Main Menu seçenekleri vardır | Kabul |
| K15 | Tablo haftalıktır; pazar gece 24:00'te sıfırlanır, 00:00'da yeni hafta başlar | Kabul |
| K16 | Moderasyon: Firestore'da ürün sahibinin tuttuğu banned listesi, liste çekilirken filtrelenir. Mantık diğer uygulamalardan kopyalanır | Kabul |
| V1 | Haftalık ve günlük sıfırlamalar için saat dilimi: Europe/Istanbul (UTC+3, yaz saati yok). Tüm oyuncular için aynı an, "şimdi" bilgisi cihaz saatinden değil Firestore sunucu zamanından alınır | Varsayım |
| V2 | Günlük hak sayacı (3) Firestore'daki kullanıcı belgesinde tutulur, yerelde değil. Yerel saklama yeniden kurulumla veya saat oynayarak sıfırlanabilir. Hak her gün 00:00 Europe/Istanbul'da 3'e döner | Varsayım |
| V3 | Rekabetçi modda tahta tohumu günlüktür: aynı gün herkes aynı başlangıç dizilimini ve aynı satır dizisini görür (HP'ler oyuncunun top sayısına göre değiştiği için oyunlar yine farklılaşır). Haftalık sıralama, haftanın en yüksek skoruna göredir | Varsayım |
| V4 | Rekabetçide 11-20 arası yedek liste ve ilk 10 liste ayrı sorgulanmaz: ilk 20 çekilir, banned filtrelenir, kalan ilk 10 gösterilir | Varsayım |
| V5 | Açılış: en fazla 1 sn'lik logo ekranı, sonra ana menü | Varsayım |
| V6 | Minimum nişan açısı yataydan 5°, sürükleme ölü bölgesi 10 mantıksal piksel (ayarlanabilir sabitler) | Varsayım |
| V7 | Dil popup'ı tek dil olsa bile bulunur; liste veri güdümlüdür, yeni dil eklemek = yeni .arb dosyası + listeye bir kayıt | Varsayım |
| V8 | Referans uygulamaların (FindPairs, Sudoku Pure) kodu geliştiricinin erişimindedir. Erişim yoksa bölüm 15'teki şemalardan sıfırdan yazılır | Varsayım |

## 2. Teknoloji, mimari ve proje kuralları

Oyun mantığı saf Dart'ta, Flutter'dan bağımsız bir çekirdekte yazılır; çizim ve arayüzler bu çekirdeği okur. Bu ayırım, aynı çekirdeğin birim testleriyle doğrulanmasını ve Faz 2'de atış kayıtlarının cihazda yeniden oynatılmasını mümkün kılar.

### 2.1 Teknoloji seçimi

| Alan | Seçim | Not |
| --- | --- | --- |
| Çatı | Flutter (güncel stable) + Dart 3 | Sürümler proje başlangıcında güncel ve uyumlu olanlara sabitlenir, pubspec.lock repoya girer |
| Oyun çizimi | Flame | Yalnızca oyun tuvali için. Menü ve diğer ekranlar normal Flutter widget'larıdır |
| Durum yönetimi | flutter\_riverpod | Ayarlar, dil, oyun durumu, Faz 2 oturumu |
| Yönlendirme | go\_router | Adı verilmiş rotalar (bölüm 9) |
| Kalıcı veri | shared\_preferences | Yalnızca bölüm 10'daki anahtarlar |
| Yerelleştirme | flutter\_localizations + gen-l10n (.arb) | Bölüm 2.5 ve 12 |
| Ses | flame\_audio (veya audioplayers) | Efektler düşük gecikmeli oynatılır |
| Titreşim | Flutter'ın HapticFeedback sınıfı | Üçüncü parti paket gerekmez |
| Feedback e-postası | EmailJS REST API (http paketi) | Bölüm 9.8 |
| Cihaz bilgisi | device\_info\_plus, package\_info\_plus | Feedback e-postasına eklenir |
| Ekran uyanık | wakelock\_plus | Yalnızca oyun ekranındayken açık |
| Faz 2 | firebase\_core, firebase\_auth, cloud\_firestore, google\_sign\_in, sign\_in\_with\_apple | Faz 1'de eklenmez |

### 2.2 Katmanlar ve klasör yapısı

```text
lib/
  main.dart
  app/                 # MaterialApp, router, tema uygulaması
  core/
    config/            # game_config.dart (tüm sabitler), secrets.dart (dart-define), app_info.dart
    theme/             # app_theme.dart, palette.dart, hp_colors.dart
    l10n_registry/     # supported_languages.dart
    services/          # audio_service, haptics_service, prefs_service, feedback_service
  game_core/           # SAF DART, flutter import YASAK
    engine/            # simulation.dart, collisions.dart, aim.dart, rng.dart
    model/             # board.dart, cell.dart, ball.dart, pickup.dart
    rules/             # row_generator.dart, hp_rules.dart, scoring.dart, round_state_machine.dart
    replay/            # shot_log.dart, replay_runner.dart (Faz 2 ile kullanılır)
  game_view/           # Flame: game_view.dart, painters, animasyonlar, parçacıklar
  features/
    splash/ menu/ game/ pause/ game_over/ how_to_play/ settings/ feedback/
    competitive/       # Faz 2
  l10n/                # app_en.arb (+ ileride app_xx.arb), l10n.yaml kökte
test/                  # game_core birim testleri, widget testleri
assets/                # sesler, yazı tipi, LICENSES.md
```

`game_core` içinde `package:flutter` veya `dart:ui` import edilemez. Bunu denetleyen bir test yazılır: game\_core klasöründeki tüm dosyalar taranır ve yasak import bulunursa test başarısız olur.

### 2.3 Deterministik simülasyon kuralları

- Fizik sabit zaman adımıyla ilerler (adım = 1/120 sn). Ekran kare hızından bağımsızdır; çizim adımlar arası enterpolasyon yapar. Bir karede en fazla 8 adım işlenir (fazlası atılır, yavaş cihazda oyun yavaşlar ama tutarlı kalır).
- Simülasyon içinde sin, cos, atan2 kullanılmaz; yalnızca +, -, \*, / ve sqrt. Yön, tamsayı çifti (vx, vy) olarak saklanır ve (vx, vy) / sqrt(vx² + vy²) ile birim vektöre çevrilir. Böylece aynı girdi her cihazda aynı sonucu verir.
- Tüm rastgelelik tek bir tohumlu üretecten gelir (bölüm 6.6). `Random()` veya `DateTime.now()` oyun kurallarında kullanılmaz.
- Bir atışın tam sonucu (hangi topun kaç HP kaybettiği, hangi halkaların alındığı, topun nereye indiği) yalnızca önceki tahta durumu ve atış yönünden hesaplanabilir olmalıdır.

### 2.4 Yapılandırma ve gizli değerler

- Tüm sayısal ve zamanlama sabitleri `core/config/game_config.dart` içinde adlandırılmış sabittir (bölüm 13). Kodun içinde ham sayı (magic number) kullanılmaz.
- EmailJS ve Firebase değerleri koda yazılmaz: `--dart-define` ile geçilir ve `secrets.dart` içinden okunur (`EMAILJS_SERVICE_ID`, `EMAILJS_TEMPLATE_ID`, `EMAILJS_PUBLIC_KEY`, `APP_DISPLAY_NAME`). Repoda `secrets.example.md` adıyla boş örnek bulunur.
- Uygulama adı, paket adı ve sürüm tek yerden (`app_info.dart` ve pubspec) okunur.

### 2.5 Yerelleştirme (kesin kural)

- Kullanıcıya görünen **hiçbir** metin Dart kodunda yazmaz. Her metin `lib/l10n/app_en.arb` içinde bir anahtara bağlıdır ve `AppLocalizations.of(context).anahtar` ile okunur.
- Bu kuralı denetleyen bir test yazılır: `lib/features` ve `lib/app` altında `Text('...')`, `Text("...")` gibi doğrudan metin sabiti bulunursa başarısız olur.
- Başlangıçta yalnızca `en`. Yeni dil eklemek yalnızca iki adımdır: `app_xx.arb` dosyasını eklemek ve `supported_languages.dart` listesine `{code, nativeName, flagEmoji}` kaydı girmek. Başka koda dokunulmaz.
- Varsayılan dil: cihaz dili destekleniyorsa o, değilse `en`. Kullanıcı seçimi kalıcıdır ve cihaz dilinden önceliklidir.
- Sayılar ve çoğullar ICU sözdizimiyle (`{count, plural, ...}`) yazılır. Metin birleştirme ("Score: " + n) yasaktır.
- Dil adları kendi dillerinde gösterilir (English, Türkçe, Deutsch...) ve çevrilmez, bu yüzden .arb içine konmaz; `supported_languages.dart` içinde kalır.

### 2.6 Varlık ve telif stratejisi

- Görsel varlık dosyası yoktur: toplar, halkalar, parçacıklar, logo ve tüm ikonlar kodla (CustomPainter veya vektör) çizilir. Böylece telif riski ve boyut sıfıra yakın kalır.
- Yazı tipi: açık lisanslı (OFL) bir yazı tipi pakete gömülür, çalışma anında internetten çekilmez. Lisans metni `assets/LICENSES.md` içine yazılır.
- Sesler yapay zeka tarafından sentezlenir (kodla üretilen WAV/OGG) ya da CC0 lisanslı kaynaklardan alınır; her dosyanın kaynağı `assets/LICENSES.md` içine yazılır.
- Referans oyunun adı, logosu ("9 9 BALLS" yazısı ve iki rakamın balonları), görselleri, sesleri ve renk paleti birebir kullanılmaz. Oyun kuralları ve sayısal mekanik aynı kalır.
- Uygulama adı "99 Balls" içeremez ve referans oyunun adına benzemez. Ad ve mağaza metinleri yapay zeka tarafından önerilir, ürün sahibi onaylar.

### 2.7 Platform ve performans

- Android minSdk 24 (7.0), targetSdk güncel; iOS 13+. Yalnızca dikey, dönme kilitli. Kenardan kenara (edge-to-edge) çizim, güvenli alanlara uyum (bölüm 3).
- Hedef: orta-alt seviye bir Android telefonda (ör. Samsung Galaxy A07 sınıfı) 60 FPS. Ekranda en fazla 99 top, 56 sayılı top ve en fazla 56 parçacık aynı anda çizilir. Her kare aynı nesne havuzlarını yeniden kullanır; oyun döngüsü içinde yeni nesne üretmekten kaçınılır.
- `flutter analyze` sıfır uyarı ile geçmeli, tüm testler geçmeli (bölüm 14).

## 3. Ekran ölçekleme

Tüm ekranlar 416×703 birimlik (gu = game unit) sabit bir sanal tuvalde tasarlanır ve cihaza **tek bir ölçek katsayısıyla** sığdırılır. Bu yüzden iPhone SE 2'de ve iPhone 15 Pro Max'te yerleşimin oranı aynıdır; fark yalnızca üst ve alt dolgu miktarıdır. Referans oyundaki oran 0,592 (416/703) olduğundan ızgara hesapları bu tuvale göre yapılmıştır (bölüm 4).

### 3.1 Sığdırma kuralı

```dart
// Girdi: ekran boyu (size), güvenli alan boşluğu (inset), sabitler REF_W=416, REF_H=703
final availW = size.width  - inset.left - inset.right;
final availH = size.height - inset.top  - inset.bottom;
final s = min(availW / REF_W, availH / REF_H);   // tek ölçek
final canvasW = REF_W * s;
final canvasH = REF_H * s;
final origin = Offset(inset.left + (availW - canvasW) / 2,
                      inset.top  + (availH - canvasH) / 2);
```

- Tuval, güvenli alan içinde ortalanır. Ölçek hiçbir zaman yuvarlanmaz, üst sınır yoktur (tabletlerde büyür).
- Tuval dışında kalan alan **boş bırakılmaz**: tuvalin üstündeki boşluk HUD çubuğu rengiyle, altındaki boşluk zemin çubuğu rengiyle, tabletlerde yanlardaki boşluk arka plan gradyanıyla doldurulur. Böylece çubuklar ekranın kenarına kadar uzanıyor gibi görünür ve siyah bant oluşmaz.
- Ekran boyutu veya güvenli alan değiştiğinde (ör. bölünmüş ekran) ölçek aynı kuralla yeniden hesaplanır, oyun durumu bozulmaz.
- Aynı kural oyun dışındaki tüm ekranlara (menü, ayarlar, nasıl oynanır, feedback, popup'lar) uygulanır: içerik 416×703'lük tuvale yerleştirilir, tek ölçekle büyütülüp küçülür. Kaydırılabilir içerik (ayarlar listesi, nasıl oynanır) tuval içinde kayar.
- Yazı: sistem yazı ölçek ayarı en fazla 1,15 ile sınırlanır (`textScaler` clamp). Tüm buton metinleri `FittedBox(scaleDown)` ve tek satır ile taşmaz hale getirilir.
- Minimum dokunma alanı: ölçekten sonra 44 dp. Ölçek 0,92'nin altına düşerse butonların çizim boyu aynı kalır, yalnızca dokunma alanı 44 dp'ye büyütülür.

### 3.2 Girdi eşleme

Oyun ekranında dokunma **tuvalin dışında bile** kabul edilir (tüm ekran dinlenir). Nişan için yalnızca sürükleme farkı gerekir, bu yüzden piksel farkı `ölçek s`'e bölünerek gu cinsine çevrilir. Mutlak konum eşlemesi yapılmaz.

### 3.3 Örnek cihazlar (doğrulama için)

Değerler mantıksal birim (dp/pt) cinsindendir ve testlerde bu cihaz boyutlarıyla kontrol edilir.

| Cihaz | Ekran | Üst / alt boşluk | Ölçek s | Tuval | Dolgu |
| --- | --- | --- | --- | --- | --- |
| iPhone SE 2 | 375×667 | 20 / 0 | 0,901 | 375×634 | yaklaşık 13 dikey |
| Galaxy A07 sınıfı | 384×853 | 28 / 24 | 0,923 | 384×649 | yaklaşık 152 dikey |
| iPhone 15 Pro Max | 430×932 | 59 / 34 | 1,034 | 430×727 | yaklaşık 112 dikey |
| iPad Air 11" dikey | 820×1180 | 24 / 20 | 1,616 | 672×1136 | yaklaşık 74 yan (her yan) |

iPhone SE 2 ile 15 Pro Max arasındaki ölçek farkı yalnızca cihaz genişliğinden gelir (0,901 ile 1,034); tuvalin içindeki tüm oranlar aynıdır.

## 4. Oyun alanı geometrisi

Bu bölümdeki tüm değerler 416×703 gu'luk tuvalde, sol üst köşe (0,0) olacak şekilde verilir; y aşağı doğru artar. Değerler referans oyunun ekran kaydından ölçülmüştür (±1 gu). Hepsi `game_config.dart` içinde ayarlanabilir sabittir.

### 4.1 Bölgeler

| Bölge | y aralığı (gu) | İçerik |
| --- | --- | --- |
| HUD çubuğu | 0–53 | Sol: müzik ikonu. Orta: tur sayacı (skor). Sağ: duraklat ikonu |
| Oyun alanı | 53–635 | Izgara, toplar, halkalar, parçacıklar, nişan çizgisi |
| Zemin çubuğu | 635–703 | Sol: top ikonu. Orta: eldeki top sayısı |

HUD ve zemin çubuğu oyun alanının üzerinde çizilir. Duvarlar ekranın sol kenarı (x = 0) ve sağ kenarıdır (x = 416). Tavan, HUD çubuğunun alt kenarıdır (y = 53). Zemin çizgisi zemin çubuğunun üst kenarıdır (y = 635).

### 4.2 Izgara

- 7 sütun, hücre genişliği = 416 / 7 = 59,43 gu. Sütun merkezi x = 59,43 × (c + 0,5), c = 0..6 (29,7 / 89,1 / 148,6 / 208,0 / 267,4 / 326,9 / 386,3).
- Satır aralığı (ROW\_PITCH) = 59,43 gu (kare hücre). 0. satırın merkezi y = 135,7. Satır merkezi y = 135,7 + 59,43 × r.
- Oynanabilir satırlar r = 0..7 (8 satır). 7. satırın merkezi y = 551,7.
- r = -1 satırı (merkez y = 76,3) yeni satırın doğduğu görünmez hazırlık satırıdır; HUD çubuğunun altından içeri kayar.
- r = 8 satırı (merkez y = 611,1) "oyun bitiş satırıdır": bu satıra giren herhangi bir sayılı top zemin çubuğuna değer (586–636) ve oyun biter.

### 4.3 Nesne boyutları

| Nesne | Çap / yarıçap (gu) | Çizim | Çarpışma |
| --- | --- | --- | --- |
| Sayılı top (hedef) | Çap 50, yarıçap 25 (`TARGET_RADIUS`) | Dolu daire, ortada beyaz kalın sayı | Daire. Yarıçap 25 |
| Atılan top | Dış çap 27, yarıçap 13 (`BALL_RADIUS`), çizgi kalınlığı 4,5 | Boş halka (tema rengi) | Daire. Yarıçap 13 |
| Toplanabilir halka (+1 top) | Dış çap 36, yarıçap 18 (`PICKUP_RADIUS`), çizgi 5, parlayan | Boş halka, parlama (glow) | Toplanma: top merkezi ile halka merkezi arası ≤ 18 + 13 = 31. Çarpışma yoktur, top içinden geçer |

Yıldız (bölüm 5.11) altın sarısı, yıldız biçimli ve halkadan açıkça ayırt edilir olmalıdır. Toplanabilir halka, atılan toptan görsel olarak kolay ayırt edilmelidir: daha büyük, daha parlak ve farklı renkte olmalıdır (örnek: atılan top tema ana rengi, toplanabilir halka parlak vurgu rengi).

### 4.4 Fırlatma noktası ve zemin

- Top zemin çizgisine değince durur. Dururken top merkezinin y değeri 635 - 13 = **622**'dir (`LAUNCH_Y`).
- İlk atışın fırlatma x'i tuval ortasıdır (208). Sonraki her atışın fırlatma x'i, bir önceki atışta zemine **ilk inen** topun x değeridir; x şu aralığa sıkıştırılır: \[13, 403\].
- Dizinin kalan topları zemine inince aynı y'de yatay kayarak fırlatma noktasına toplanır (bölüm 5.8).

### 4.5 HUD yerleşimi

| Öğe | Konum (merkez, gu) | Boyut | Not |
| --- | --- | --- | --- |
| Müzik ikonu | (30, 26) | 28×28, dokunma alanı min 48×48 | Müziği açıp kapatır (bölüm 8) |
| Tur sayacı | (208, 26) | Yazı yüksekliği 26, kalın | Canlı skor: tur sayacı + 3 × yıldız (bölüm 5.6 ve 5.11) |
| Duraklat ikonu | (386, 26) | 28×28, dokunma alanı min 48×48 | Rekabetçi modda gizli (bölüm 11) |
| Top ikonu | (39, 669) | Çap 24 | Dolu daire, süs değil |
| Top sayısı | (208, 669) | Yazı yüksekliği 26, kalın | Nişan/nişan: atışta kalan top sayısı (bölüm 5.6) |

### 4.5.1 Çizim sırası (alttan üste)

1. Arka plan gradyanı ve hafif hareketli ışık
2. Toplanabilir halkalar
3. Sayılı toplar
4. Yok olma animasyonundaki toplar
5. Atılan toplar
6. Nişan çizgisi
7. Parçacıklar
8. HUD ve zemin çubuğu
9. Popup'lar

## 5. Oyun mekanikleri

Bu bölüm oyunun kurallarını adım adım tanımlar. Ölçülen değerler referans oyunun videosundan alınmıştır; "UX kararı" diye işaretli yerler referanstan bilinçli olarak ayrılır.

### 5.1 Girdi ve nişan

- Girdi tüm ekranda dinlenir (bölüm 3.2). Yalnızca `ready` durumunda ve ekranda popup yokken kabul edilir. İlk parmak izlenir, ikinci ve sonraki parmaklar yok sayılır.
- **Bas** (`pointerDown`): basma noktası P0 kaydedilir. O an ekranda bir şey çizilmez.
- **Sürükle** (`pointerMove`): sürükleme vektörü d = (p − P0) / s (gu cinsinden). **Nişan vektörü a = −d** (sapan: çekmenin tersi yön). Çekme uzunluğu gücü değiştirmez, yalnızca yön önemlidir.
- **Ölü bölge:** |d| < 10 gu ise nişan yoktur (`DRAG_DEADZONE`), çizgi gösterilmez.
- **İptal bölgesi (UX kararı):** a vektörü yatay çizginin altına bakıyorsa (a.y ≥ 0) nişan geçersizdir; çizgi gösterilmez ve bırakınca atış olmaz, hak veya top harcanmaz. Oyuncu atışı iptal etmek için parmağını başlangıç noktasının üzerine çekip bırakabilir.
- **Minimum açı (UX kararı):** a vektörü yataydan 5°'den daha az yukarı bakıyorsa (`MIN_AIM_ANGLE_DEG` = 5) yön 5°'ye **sıkıştırılır** (sol ya da sağ tarafını korur). Referans oyun bu durumda atışı yok sayıyor gibi görünüyor; bizde oyuncu hep atabilir.
- **Bırak** (`pointerUp`): nişan geçerliyse atış yapılır, değilse iptal. `pointerCancel` her zaman iptaldir.
- Atış yönü tamsayı çifti olarak saklanır: `shot = (vx, vy)` = `(round(a.x * 100), round(a.y * 100))`. Simülasyon yalnızca bu çifti kullanır (bölüm 2.3).

### 5.2 Nişan çizgisi

- Yalnızca geçerli nişan sürerken görünür. Fırlatma noktasından başlar.
- Kesikli çizgi: çizgi kalınlığı 3 gu, dash 12 gu, boşluk 12,6 gu (periyot 24,6), tema vurgu rengi, opaklık 0,9; son 40 gu içinde saydamlaşarak biter.
- **Uzunluk sürüklemeyle uzar**: nişan başladığında 60 gu (`GUIDE_MIN_LENGTH`), ölü bölgeden sonraki 120 gu'luk sürüklemede (`GUIDE_RAMP_DISTANCE`) doğrusal olarak azami 490 gu'ya (`GUIDE_LENGTH`) çıkar; dokunur dokunmaz tam boy çıkmaz. Çizgi, topun gerçek yolunu önceden hesaplar: duvarlardan, tavandan ve sayılı toplardan yansır (bölüm 5.3'teki aynı çarpışma kodu kullanılır), halkaları yok sayar, zeminde biter. En çok 64 segment çizilir; uzunluk dolunca çizgi kesilir. Solma, çizginin o anki ucuna göre hesaplanır.
- Çizgi her karede en fazla bir kez yeniden hesaplanır. Kesik parçalar kayan nokta mod (%) işlemiyle değil, parça indeksiyle (k × periyot) üretilir ve segment başına en çok 100 parça çizilir; mod tabanlı yöntem cihazda sonsuz döngüye (ANR) yol açmıştır.

#### 5.2.1 İnce nişan (artımlı eşleme)

- Açıyı yalnızca parmağın anlık konumundan hesaplamak kısa sürüklemede çok hassastır: sürükleme uzunluğu L = 40 gu iken 1 gu'luk dik hareket 1,4° döndürür (L = 10 gu iken 5,7°). Kabul ölçütü: 1 gu'luk parmak hareketi her L için en fazla ≈0,48° değiştirmelidir.
- Parmak ölü bölgeden çıkınca (≥ 10 gu) ilk yön mutlaktır (ham yön). Sonraki her harekette ham açı farkı bir kazançla uygulanır: φ += Δφ × min(1, L / 120) (`AIM_MIN_RADIUS` = 120 gu). L ≥ 120 gu'da kazanç 1'dir (ham davranış).
- Ölü bölge histerezislidir: nişan 10 gu'da başlar, 6 gu'nun altına inince biter. İptal bölgesine (a.y ≥ 0) ya da ölü bölgeye dönünce nişan sıfırlanır; yeniden çıkınca yine mutlak başlar.
- φ, \[5°, 175°\] aralığına sıkıştırılır ve `aimFromDrag` ile (vx, vy) üretilir (vektör uzunluğu 100). Kılavuzun çizildiği yön ile ateşlenen yön aynı `Shot`'tır.
- Bedel: eşleme yola bağlıdır; kısa çekişte parmak başlangıca dönünce açı birebir aynı yere dönmeyebilir. Bu, ince ayar için bilinçli bir takastır.
- Bu katman yalnızca görünüm/girdi tarafındadır; `game_core` içindeki `aimFromDrag`, `Shot` ve `isValidShot` değişmez.

### 5.3 Atış, hız ve çarpışmalar

| Kural | Değer / davranış |
| --- | --- |
| Top sayısı | Atışta eldeki tüm toplar (`ballCount`) atılır |
| Fırlatma aralığı | Toplar tek tek, 17 sim adımı arayla çıkar (1/120 sn adımda 0,1417 sn; referansta ölçülen 0,135–0,148 sn). Sabit: `LAUNCH_INTERVAL_STEPS` = 17 |
| Top hızı | Sabit 585 gu/sn = adım başına 4,875 gu (`BALL_SPEED`). Yerçekimi, ivme ve sürtünme yoktur |
| Toplar arası çarpışma | Yoktur, üst üste geçerler |
| Duvar ve tavan | Yansıma: sol/sağ duvarda vx işareti değişir, tavanda (y = 53) vy işareti değişir. Top yarıçapı hesaba katılır (merkez x ≤ 13 ya da ≥ 403, merkez y ≤ 66) |
| Sayılı top | Daire-daire çarpışması. Çarpışma mesafesi `BALL_RADIUS + TARGET_RADIUS` = 38 gu. Yansıma: n = (top − hedef) / \|top − hedef\| (birim vektör), v' = v − 2(v·n)n; yansımadan sonra hız büyüklüğü kBallSpeed'e yeniden normalleştirilir (sqrt ile). Aynı adımda iki farklı top aynı hedefi vurursa her biri sırayla işlenir ve HP 2 azalır. |
| Vuruş | Her temas hedefin HP'sini tam **1** azaltır. HP 0 olan hedef anında oyun mantığından silinir (sonraki toplar içinden geçer), görsel yok olma animasyonu ayrıca oynar |
| Çifte vuruş koruması | Çarpışma yalnızca top hedeften uzaklaşmıyorsa sayılır: v·n < 0 |
| Aynı anda iki hedef | Önce en yakın olanla çarpışılır; eşitlikte (satır, sütun) sırası küçük olan. Kalan adım süresi yansımış hızla devam eder |
| Halka toplama | Top merkezi ile halka merkezi arası ≤ 31 gu (18 + 13) olduğunda toplanır. Halka içinden geçilir, top yön değiştirmez. Bir halkayı yalnızca ilk değen top toplar |
| Zemin | Top y + 13 ≥ 635 ve vy > 0 olunca iner: y = 622'ye sabitlenir, hız sıfırlanır, iniş x'i kaydedilir. Zemine ilk inen topun x'i bir sonraki atış noktasıdır |
| Tünelleme koruması | Her adımda hareket, "kesişim zamanı" (swept) ile hesaplanır: adım segmenti ile genişletilmiş daire (yarıçap 38) ve duvarlar arasındaki en erken çarpışma bulunur, ilerlenir, yansıtılır ve adımın kalan süresiyle devam edilir (adım başına en fazla 4 yineleme) |
| Takılma koruması | Bir top 20 sn'den uzun süre havada kalırsa (`FLIGHT_TIMEOUT_S`) simülasyondan çıkarılır ve o anki x'inde inmiş sayılır |

Her çarpışmada ve halka toplamada ilgili olay (ses, parçacık, titreşim) olay kuyruğuna yazılır; çizim ve ses katmanı bu kuyruğu okur, oyun mantığı onlara bağımlı değildir.

### 5.4 Tur durum makinesi

Oyun, aşağıdaki durumlardan birinde bulunur. Bir anda yalnızca biri etkindir.

| Durum | Ne olur | Çıkış koşulu |
| --- | --- | --- |
| `ready` | Oyuncu nişan alabilir. Alt sayaç `ballCount` gösterir. Fırlatma noktasında 1 top görünür | Geçerli bırakma: `firing`'e geç |
| `firing` | Toplar 17 adım arayla çıkar. Alt sayaç her çıkışta 1 azalır (N, N−1, ... 0). Girdi yok sayılır | Son top çıkınca: `flying`'e geç |
| `flying` | Toplar uçar, çarpışır, halka toplar. Alt sayaç 0'da durur. Yere inen her top, ilk inen topun x'ine hemen kayar (görsel birleşme, aşağıdaki collecting satırı) | Havada top kalmayınca: `collecting`'e geç |
| `collecting` | İnen toplar, ilk inen topun x'ine sabit hızla (`MERGE_SPEED` = 1600 gu/sn) kayıp birleşir; ilk top yerinde kalır. Kayma her top indiği anda başlar ve hepsinin inmesini beklemez. Yalnızca görseldir, çekirdek durumunu etkilemez. `collecting` süresi 0,25 sn'dir; yetişemeyen top süre bitince hedefe oturur. Toplanan halka sayısı `pendingBalls`'a işlenmiştir | Animasyon bitince: `advancing`'e geç |
| `advancing` | `ballCount += pendingBalls` (en çok 99), `pendingBalls = 0`. Yeni satır üretilir (bölüm 6), tüm nesneler 1 satır aşağı kayar (0,18 sn, `easeOutCubic`), tur sayacı +1 olur, alt sayaç yeni `ballCount`'a döner | Kayma bitince: 9. satıra inmiş sayılı top varsa `gameOver`, yoksa `ready` |
| `gameOver` | Biten satırdaki toplar 0,6 sn vurgulanır (kırmızıya yanıp söner), ardından oyun sonu ekranına geçilir (bölüm 9.5) | Yeniden başlat veya ana menü |

Duraklatma bir durum değil, bir üst katmandır: oyun donar, durum makinesi aynı yerde bekler.

#### 5.4.1 Uzun uçuşta otomatik hızlanma

- Yataya yakın tek bir topun çok uzun sürmesi (≈12 sn) tempoyu bozar. `flying` fazında geçen gerçek süre `FAST_FORWARD_AFTER` = 8 sn'yi aşarsa, kare saati karede işlenen sabit adım sayısını 1'den 4'e (`FAST_FORWARD_MAX`) 1,5 sn'de (`FAST_FORWARD_RAMP`) doğrusal artırır.
- Sayaç yalnızca `flying` fazını sayar; `firing` fazı sayılmaz (99 toplu atış ≈14 sn sürer). flying'e girişte, flying'den çıkışta ve her yeni atışta sıfırlanır; faz `flying`'den çıkınca çarpan hemen 1'e döner, `collecting` ve `advancing` hızlanmaz.
- Her adım yine 1/120 sn'lik `step()`'tir: simülasyon, replay ve `stateHash` değişmez. Karede en çok 8 × çarpan, mutlak en çok 32 adım işlenir (sonsuz döngü yok).
- Rekabetçi modda da aynıdır; yalnızca görünüm hızıdır.

### 5.5 Top sayısı ve sayaç kuralları

- Oyun 1 topla başlar (`START_BALLS` = 1). Tavan 99'dur (`MAX_BALLS`); 99'dayken toplanan halka görsel olarak toplanır ama sayıyı artırmaz.
- Toplanan her halka `pendingBalls`'u 1 artırır. Sayı **yalnızca tur bitince** `ballCount`'a eklenir. Uçuş sırasında alt sayaç değişmez (referansta 0'da kalıyor).
- Alt sayaç durumları: `ready` = `ballCount`; `firing` = `ballCount − çıkan top`; `flying` ve `collecting` = 0; `advancing` sonu = yeni `ballCount`.

### 5.6 Skor ve tur sayacı

- Tur sayacı ilk tahtada 1'dir. Her `advancing` adımı sayacı 1 artırır. HUD'daki sayı bu sayacı gösterir.
- Oyun biterse skor, oyunu bitiren satırın eklenmesinden sonraki sayacın değeridir (referansta HUD 34 iken oyun sonu 35 göstermiştir). Yani satırı eklenir eklenmez sayacın artması skora yansır.
- Skor = tur sayacı + kStarScore × toplanan yıldız sayısı (bölüm 5.11). Vurulan top sayısı ve toplanan halkalar skoru etkilemez. HUD'daki büyük sayı canlı skoru gösterir.

### 5.7 İlk tahta

- Tur 1'de 7 sütunun 2–5'i (Bölüm 6'daki ağırlıklarla) doludur, halka yoktur. Tahta, bölüm 6'daki üretici ile `ballCount = 1` kullanılarak üretilir (HP'ler 1 ve 2 olur). Yalnızca 0. satır doludur.
- Referansta ilk tahta sütun 1, 3, 4, 6'da HP 1, 2, 2, 1 şeklindedir. Bu sabit bir şey değil, üreticinin örnek çıktısı sayılır.

### 5.8 İlk çalıştırma öğretici katmanı

- Tercih `tutorialSeen` yoksa, ilk oyunun ilk `ready` durumunda gösterilir: oyun alanının ortasında `tutorialAim` metni (başlangıç: "Press anywhere, pull back and release to shoot") ve ekranın ortasında bir el ikonu ile beyaz bir nokta. El, noktayı aşağı-sola çekip bırakır; nişan çizgisi bu yöne göre yukarı-sağa uzanır. Döngü 2,4 sn, sonsuz tekrar.
- Oyuncu ilk kez ekrana basınca katman hızla solar. İlk geçerli atış yapılınca `tutorialSeen = true` yazılır. Daha sonraki oyunlarda gösterilmez. Ayrıntılı anlatım "How to Play" ekranındadır.

### 5.9 Girdi dışı olaylar

- Duraklat ikonuna basma, uygulamanın arka plana alınması ve sistem kesintileri (arama, bildirim paneli) tek oyunculu modda duraklatma katmanını açar (bölüm 9.4 ve 10).
- Simülasyon, `pointerDown` sırasında duraklatırsa nişan iptal edilir.

### 5.10 Uç durumlar

| Durum | Davranış |
| --- | --- |
| Bir atışta hiçbir hedef vurulmadı | Tur normal ilerler, yeni satır gelir |
| Aynı turda iki top aynı hedefi aynı adımda vurur | İkisi de sırayla işlenir, HP 2 azalır; HP 0'ın altına inmez, ikinci vuruş hedef silindiğinden gerçekleşmez |
| Halka 8. satıra kayar | Halka toplanmadan 8. satıra gelirse sessizce kaybolur (0,2 sn solar). Oyun bitmez |
| Ekran yönü, boyut, güvenli alan değişir | Simülasyon etkilenmez, yalnızca çizim ölçeği yenilenir |
| Oyuncu çok hızlı art arda atış yapmaya çalışır | `ready` dışında girdi yok sayılır; sıraya alınmaz |

### 5.11 Yıldız (ekstra skor nesnesi)

Yıldız, topun içinden geçerek toplanan ve yalnızca skora puan ekleyen bir nesnedir. Para birimi değildir ve oyunlar arası saklanmaz.

- **Üretim:** Bir satırın tüm adımları (bölüm 6.1) bittikten sonra, en son olarak bir kez `nextInt(100) < kStarChancePct` (varsayılan 25) çekilir. Doğruysa yıldız, karıştırılmış sütun dizisinde halkadan sonraki ilk boş sütuna (`shuffled[k + (halka ? 1 : 0)]`) konur; ek rastgele çekim yapılmaz. Bu sütun her zaman vardır (en fazla 5 top + 1 halka + 1 yıldız = 6 nesne). İlk tahtada yıldız çekimi yapılmaz. Yıldız çekimi her satırda yapılır (olasılık 0 olsa bile RNG'den bir sayı tüketir); bu yüzden bir satırın top/halka içeriği yıldızdan etkilenmez ama sonraki satırlar RNG kayışı nedeniyle değişir.
- **Toplama:** Yarıçap `kPickupRadius` (18 gu), halkayla aynı. Top yıldızın merkezine bu mesafeden yaklaşınca yıldız toplanır; top sekmez, yoluna devam eder. Aynı adımda birden fazla top değerse ilk işlenen toplar, yıldız tek kez sayılır.
- **Puan:** Her yıldız `kStarScore` (varsayılan 3) puan. Skor = tur sayacı + 3 × toplanan yıldız. Oyun biterse skor, oyunu bitiren satır eklendikten sonraki tur sayacı + toplanan yıldızların puanıdır.
- **Kayma:** Yıldız satırla birlikte aşağı kayar. Toplanmadan 8. satıra gelirse halka gibi sessizce kaybolur (0,2 sn solar); oyun bitmez ve puan eklenmez.
- **Görsel:** Altın sarısı beş köşeli yıldız, hedef yarıçapının yaklaşık %70'i boyutunda, yavaşça nabız atar (ölçek 0,95–1,05, 1,2 sn). Toplanınca 0,25 sn büyüyüp solar ve yerinde 0,6 sn yukarı süzülen "+3" yazısı çıkar.
- **Ses ve titreşim:** `sfx_star`, titreşim yok (bölüm 8.2).
- **HUD:** Büyük sayı canlı skoru gösterir; tur sayacı ayrıca gösterilmez. Bu, bölüm 4'teki HUD tablosunun "tur sayacı" öğesinin yerine geçer.
- **Yarışmalı mod:** Skor aynı formülle hesaplanır, tekrar oynatma doğrulaması yıldızları da içerir (bölüm 11.8).
- **Testler:** (1) Aynı tohumda yıldız konumları iki çalıştırmada aynıdır. (2) `kStarChancePct = 0` iken aynı RNG durumundan üretilen satırın top ve halka içeriği yıldızlı üretimle aynıdır ve yıldız yoktur. (3) Yıldız ve halka aynı hücrede olamaz. (4) Skor formülü: tur 12 ve 4 yıldız → 24. (5) Yıldız toplandıktan sonra yeniden sayılmaz.

## 6. Satır üretimi ve HP kuralları

Oyunun zorluğu bu bölümdeki kuraldan gelir. Referans oyunun 34 turunun tüm satırları incelenmiş ve aynı kural tüm satırlarda doğrulanmıştır: **bir satırdaki her topun HP'si, oyuncunun o andaki top sayısının 1, 1,5 veya 2 katıdır.** Zorluk, tur sayısıyla değil oyuncunun gücüyle (top sayısıyla) büyür.

### 6.1 Bir satırın üretilmesi

Satır, her `advancing` adımında aşağıdaki sırayla üretilir. **Rastgele sayı çekim sırası sabittir** (tekrar oynatmanın tutarlı olması için değiştirilmez):

1. `T` = o andaki `ballCount` (bu turun halkaları eklendikten sonra). İlk tahtada T = 1.
2. **Top sayısı k:** ağırlıklı seçim, `nextInt(100)` ile: 0–23 → 2 top, 24–52 → 3 top, 53–81 → 4 top, 82–99 → 5 top (ağırlıklar %24 / %29 / %29 / %18).
3. **Halka var mı:** `nextInt(100) < 56` ise satıra 1 toplanabilir halka konur, değilse konmaz (`RING_CHANCE_PERCENT` = 56). İlk tahtada halka yoktur ve bu çekim yapılmaz.
4. **Sütunlar:** 0..6 sütunları Fisher–Yates ile karıştırılır (i = 6'dan 1'e, her i için `j = nextInt(i + 1)`, dizinin i. ve j. elemanı yer değiştirir). Karışık dizinin ilk k sütunu sayılı top, sonraki sütun (halka varsa) halka olur. Aynı hücrede iki nesne olmaz.
5. **Çarpan:** her sayılı top için (sütun sırasına göre soldan sağa) `m2 = 2 + nextInt(3)` çekilir. m2 ∈ {2, 3, 4} ve çarpan m = m2 / 2 ∈ {1; 1,5; 2} eşit olasılıklıdır.
6. **HP:** `hp = hpFor(T, m2)` (bölüm 6.2).

Satır, 0. satıra konur. Daha önce mevcut tüm nesneler 1 satır aşağı kaydırılmıştır (bölüm 5.4). Yıldız üretimi için bölüm 5.11'e bak: yıldız çekimi her zaman en son yapılır ve ilk tahtada yapılmaz.

### 6.2 HP hesabı ve yuvarlama (kritik)

Referans oyun yarım değerleri **çift sayıya** yuvarlıyor (4,5→4; 10,5→10; 13,5→14; 19,5→20; 22,5→22; 25,5→26; 31,5→32). Dart'ın `.round()` fonksiyonu yarım değeri yukarı yuvarlar, bu yüzden **kullanılmaz**. HP şu tamsayı fonksiyonla hesaplanır:

```dart
/// t: oyuncunun top sayısı (>= 1). m2: 2, 3 veya 4 (çarpan = m2 / 2).
/// Sonuç = round-half-to-even(t * m2 / 2)
int hpFor(int t, int m2) {
  final n = t * m2;
  final q = n ~/ 2;
  final r = n % 2;
  if (r == 0) return q;
  return (q % 2 == 0) ? q : q + 1; // tam yarım: çifte yuvarla
}
```

Doğrulama tablosu (birim testte aynen kullanılır):

| T | m2 = 2 (×1) | m2 = 3 (×1,5) | m2 = 4 (×2) |
| --- | --- | --- | --- |
| 1 | 1 | 2 | 2 |
| 3 | 3 | 4 | 6 |
| 7 | 7 | 10 | 14 |
| 9 | 9 | 14 | 18 |
| 13 | 13 | 20 | 26 |
| 15 | 15 | 22 | 30 |
| 17 | 17 | 26 | 34 |
| 18 | 18 | 27 | 36 |
| 21 | 21 | 32 | 42 |

En yüksek HP = 2 × 99 = 198. Üç haneli sayılar topun içine sığmak için yazı boyutunu %80'e çeker (bölüm 7.1).

### 6.3 Rastgele sayı üreteci

Tüm oyun kuralları tek bir tohumlu üretecten beslenir: SplitMix64 (yalnızca 64-bit tamsayı işlemleri, native Dart).

```dart
class SplitMix64 {
  int _s;
  SplitMix64(this._s);
  int next() {
    _s += 0x9E3779B97F4A7C15;
    int z = _s;
    z = (z ^ (z >>> 30)) * 0xBF58476D1CE4E5B9;
    z = (z ^ (z >>> 27)) * 0x94D049BB133111EB;
    return z ^ (z >>> 31);
  }
  /// 0..bound-1
  int nextInt(int bound) => (next() >>> 33) % bound;
}
```

- Faz 1: tohum her oyun başında `Random.secure()` ile üretilir ve oyun durumunda saklanır.
- Faz 2: tohum günün tarihinden türetilir (bölüm 11.4).
- Aynı tohum ve aynı atış dizisi her zaman aynı tahtayı üretmelidir.

### 6.4 Doğrulama ölçütleri

- Özellik testi: herhangi bir T için üretilen her HP, {hpFor(T,2), hpFor(T,3), hpFor(T,4)} kümesindedir.
- İstatistik testi: T = 10 ile 10.000 satır üretildiğinde top sayısı dağılımı ağırlıkların ±2 puan, halka oranı %56 ±2 puan, çarpan dağılımı %33,3 ±2 puandır. Hiçbir satırda aynı hücrede iki nesne yoktur ve 7'den fazla nesne yoktur.
- Tekrarlanabilirlik testi: aynı tohumla iki kez 100 satır üretildiğinde çıktılar bire bir aynıdır.

## 7. Görsel kurallar

Mekanik referansla aynı, görünüm özgündür. Aşağıdaki kurallar hangi temada olursa olsun geçerlidir; renk ve şekil değerleri tema dosyasından gelir.

### 7.1 Sayılı top: renk ve sayı

- Topun rengi HP'ye bağlıdır ve **her vuruşta anında güncellenir**. Renk, HP durakları arasında doğrusal (sRGB) geçişle hesaplanır. Böylece oyuncu sayıyı okumadan topun ne kadar sağlam olduğunu görür.
- Sayı: beyaz, kalın, kondanse (dar) bir yazı tipi, topun tam ortasında. 1–2 hane için 24 gu, 3 hane için 19 gu (%80). Hafif gölge ile okunaklı tutulur.

#### HP renk durakları

`hp_colors.dart` içinde 11 renk durakı tanımlanır (c0…c10). Durakların sırası "kolay → zor" anlamı taşır: sıcak ve canlı renkler düşük HP, soğuk renkler orta HP, mor-pembe en yüksek HP.

| Durak | HP aralığı | Davranış | Referans ton (yalnızca sıra ve sıcaklık için) |
| --- | --- | --- | --- |
| c0 | 1–3 | Sabit | Kırmızı-pembe |
| c1 | 6 | 3 ile 6 arası doğrusal | Turuncu |
| c2 | 7–13 | 6 ile 7 arası geçiş, sonra sabit | Sarı |
| c3 | 17–24 | 13 ile 17 arası geçiş, sonra sabit | Parlak yeşil |
| c4 | 26 | 24 ile 26 arası geçiş | Turkuaz |
| c5 | 27–32 | 26 ile 27 arası geçiş, sonra sabit | Açık camgöbeği |
| c6 | 34 | 32 ile 34 arası geçiş | Gök mavisi |
| c7 | 36 | 34 ile 36 arası geçiş | Mavi |
| c8 | 44 | 36 ile 44 arası geçiş | İndigo |
| c9 | 48 | 44 ile 48 arası geçiş | Eflatun-pembe |
| c10 | 50 ve üstü | 48 ile 50 arası geçiş, 50'den sonra sabit | Magenta |

Kurallar: Referans oyunun kirmizi-bordo zemin ve turuncu zemin çubuğu düzeni **kullanılmaz**. Renkleri yapay zeka seçer; ardışık iki durak gözle ayrı seçilebilmeli, beyaz sayı her renk üzerinde en az 3:1 kontrastı sağlamalıdır. Sayı zaten bilgiyi taşıdığı için renk tek başına anlam taşımaz (renk körlüğü için yeterli).

### 7.2 Animasyonlar

Tüm süreler saniye cinsindendir ve `game_config.dart` içinde ayarlanır. Animasyonlar yalnızca görseldir; oyun mantığını geciktirmez (tek istisna: satır kayması, bölüm 5.4).

| Olay | Süre | Tanım |
| --- | --- | --- |
| Vuruş (HP azalır) | 0,10 | Hedef ölçeği 1,00 → 1,12 → 1,00. Sayı ve renk anında değişir |
| Yok olma (HP 0) | 0,70 | Sayı kaybolur, top düz renkli bir elipse dönüşür ve madeni para gibi dönerek aşağı-yana süzülüp söner (ayrıntı 7.2.1) |
| Halka toplama | 0,25 | Halka 1,0 → 1,6 ölçekle büyüyerek solar; 8 kıvılcım parçacığı (boyut 3, hız 120→0 gu/sn, ömür 0,35 sn) halka renginde saçılır |
| Top zeminde birleşme | 0,25 | `ease-in-out` ile fırlatma noktasına kayma, varınca kaybolma |
| Satır kayması | 0,18 | Tüm nesneler 59,43 gu aşağı kayar (`easeOutCubic`); yeni satır r = -1'den gelirken opaklığı 0 → 1 olur |
| Tehlike uyarısı | 1,2 döngü | 7. satırda herhangi bir sayılı top varsa zemin çubuğunun üst kenarı tehlike renginde yumuşak nefes alma ile parlar (UX kararı, kapatılabilir sabit) |
| Oyun bitimi | 0,60 + 0,35 | Biten satırdaki toplar 3 kez yanıp söner, sonra 0,35 sn'lik solma ile oyun sonu ekranına geçilir |
| Ekran geçişi | 0,20 | Solma (fade) |
| Buton basılı | 0,08 | Ölçek 1,0 → 0,96, bırakınca geri döner |

#### 7.2.1 Yok olma animasyonu ayrıntısı

Referans videodan kare kare çıkarılmıştır (0,7 sn). u = t / 0,7 (0→1):

- Ölçek Y = |cos(1,5 · π · u)| (elips ince çizgiye iner, tekrar açılır, tekrar kapanır), ölçek X = 1 + 0,1 · sin(π · u).
- Dönme = -0,6 · u radyan.
- Konum: yerçekimi `g = 600 gu/sn²` ile aşağı, yatay hız 35 gu/sn (yönü görsel rastgeleliğiyle ±). Görsel rastgelelik oyun tohumunu **tüketmez**; ayrı bir `Random` kullanılır.
- Opaklık: u < 0,5 iken 1; sonra 0'a doğrusal iner.
- Renk: ölüm anındaki top rengi, sayı yok.

### 7.3 Parçacık ve nesne havuzları

Parçacıklar 64 nesnelik bir havuzdan alınır ve bitince havuza döner. Havuz doluysa yeni parçacık yaratmak yerine en eskisi yeniden kullanılır. Oyun döngüsünde her karede yeni `Paint`, `Path` veya liste üretilmez; yeniden kullanılır.

### 7.4 Tema yönergesi (yapay zeka için)

- Yapay zeka beş tema konsepti seçer (bkz. 7.4.1; Orbitfall, Candy Burst, Pixel Drop, Abyss, Ink & Paper) ve gerekçesini `docs/THEME.md` içine kısa yazar.
- Teslimat: `app_theme.dart` ve `palette.dart` içinde şu alanlar: `bgGradientTop`, `bgGradientBottom`, `hudBar`, `floorBar`, `accent` (nişan çizgisi ve atılan top), `pickupGlow`, `textPrimary`, `textSecondary`, `danger`, `buttonPrimary`, `buttonSecondary`, `popupSurface`; ve `hp_colors.dart` durakları (7.1).
- Özgün logo (kodla çizilen vektör), uygulama ikonu, oyun adı. Logo ana menüde üst yarının tam ortasındadır (bölüm 9.1).
- Arka plan koyu veya orta-koyu tonlu olmalı; renkli topların öne çıkmasını sağlamalıdır. HUD ve zemin çubukları arka plandan ayrı görünmelidir.
- Atılan top (halka veya dolu orb olabilir) ile toplanabilir halka birbirinden **hızla ayırt edilebilmeli**: toplanabilir halka %33 daha büyük (yarıçap 18 ve 13) ve parlayan ayrı bir vurgu renginde olur.
- Yazı tipi: tek bir OFL yazı tipi ailesi, en fazla 2 ağırlık (Regular ve Bold). Sayılar için aynı ailenin dar (condensed) biçimi ya da tabular rakamlar kullanılır.

#### 7.4.1 Beş tema ve kilit mimarisi

- Beş tema vardır: Orbitfall (ücretsiz), Candy Burst, Pixel Drop, Abyss, Ink & Paper. Her birinin kendi renk paleti, top/hedef/halka çizimi, arka planı, parçacık efektleri ve kendi ses kimliği (müzik döngüsü + efektler) vardır.
- Temalar yalnızca görünüm ve sestir: çarpışma yarıçapları, yerleşim, kurallar, replay, skor ve `stateHash` hiçbir temada değişmez.
- Mimari: `GameTheme` (palet, çizim, efekt, ses alanları), `ThemeRegistry` (beş tema), seçilen tema `theme_id` ile kaydedilir. `ThemeAccess.isUnlocked(theme)` kilit sorusunun tek kapısıdır; v1'de `kAllThemesUnlocked = true` (test için hepsi açık). Kayıtlı tema bulunamaz ya da kilitliyse ücretsiz temaya (Orbitfall) dönülür.
- Sonraki sürümlerde üyelik: Orbitfall ücretsiz, diğer dördü kilitli. Yerel bir bayrak güvenli değildir; gerçek üyelik mağaza faturalandırması (Google Play Billing, iOS IAP) ve doğrulama gerektirir. Tüm temalar herkese açık yayımlandıktan sonra kilitlenirse mevcut kullanıcılar için eski haklar korunur (grandfathering).
- Tüm görseller kodla (CustomPainter) üretilir; sesler `tools/audio/` altındaki Python betikleriyle sentezlenir. Tema başına ses bütçesi yaklaşık 2 MB.

## 8. Ses ve titreşim

Referans videoda ses yoktur; tüm ses varlıkları yapay zeka ile üretilir ve orijinal olmalıdır. Ses ve titreşim, Ayarlar'daki üç bağımsız anahtara bağlıdır: Müzik, Ses Efektleri, Titreşim. Varsayılan üçü de açıktır.

### 8.1 Kurallar

- Ses dosyaları `assets/audio/` altında, SFX için `.wav` (44.1 kHz, 16 bit, mono), müzik için `.ogg` (stereo, döngüsel) formatındadır.
- Her SFX en fazla 1 sn sürer ve tepe seviyesi −3 dBFS'te normalize edilir. Müzik −14 LUFS civarındadır ve SFX'lerden belirgin biçimde alçaktır (müzik oynatıcı ses seviyesi 0.35, SFX 1.0).
- Aynı SFX 50 ms içinde tekrar tetiklenirse ikincisi çalınmaz (sınırlama, `kSfxMinGapMs`). Aynı anda en fazla 8 SFX çalar; fazlası atlanır.
- Top vuruşu sesi için 3 adet varyant (perde farkı) tanımlanır ve sırayla (rastgele değil, simülasyon RNG'sinden bağımsız bir sayaçla) döndürülür. Ses seçimi oyun simülasyonunu asla etkilemez.
- Ses ve titreşim yalnızca `game_core` olaylarına tepki veren sunum katmanında çağrılır; `game_core` içinde ses kodu bulunmaz.

### 8.2 Olay tablosu

| Olay | SFX anahtarı | Titreşim | Not |
| --- | --- | --- | --- |
| Top ateşlendi | `sfx_shoot` | yok | Her top için çalar, 50 ms sınırı geçerli |
| Top duvara/tavana çarptı | `sfx_wall` | yok | Çok hafif, kısa tık |
| Top hedefe çarptı (hedef yok olmadı) | `sfx_hit_1..3` | yok | HP düştükçe perde hafifçe yükselir |
| Hedef yok oldu | `sfx_break` | hafif (`light`) | Kırılma animasyonuyla aynı karede |
| Halka (ring) alındı | `sfx_pickup` | yok | Yeni top eklenir |
| Toplar toplandı (birleşme) | `sfx_collect` | yok | Toplama aşamasının başında bir kez |
| Satır kaydı | `sfx_advance` | yok | Sayaç +1 ile birlikte |
| Yeni en iyi skor | `sfx_record` | orta (`medium`) | Oyun sonu ekranında bir kez |
| Oyun bitti | `sfx_gameover` | ağır (`heavy`) | Satır 8'e inince |
| Buton tıklaması | `sfx_click` | seçim (`selectionClick`) | Tüm menü butonları |
| İlk 10'a giriş (Faz 2) | `sfx_celebrate` | orta (`medium`) | Kutlama penceresi açılırken |
| Yıldız toplandı | sfx\_star | yok | Parlak, kısa; ardışık toplamada perde hafifçe yükselir |

Nişan alma sırasında ses ve titreşim yoktur.

### 8.3 Müzik

- Tek bir döngüsel parça, 60–90 sn uzunluğunda, sakin ve ritmik, tema yönüne uygun. Menüde ve oyunda aynı parça çalar.
- Uygulama açılışında, kullanıcı ilk dokunuştan sonra başlar (tarayıcı/platform otomatik oynatma kısıtları için güvenli yol).
- Duraklatma menüsü açıkken müzik %40 seviyeye iner; devam edince eski seviyeye döner (300 ms geçiş).
- Uygulama arka plana alınınca müzik durur, öne gelince kaldığı yerden devam eder.
- Müzik anahtarı kapatılırsa anında durur; açılırsa baştan başlar.

### 8.4 Titreşim

- `HapticFeedback` kullanılır: `lightImpact`, `mediumImpact`, `heavyImpact`, `selectionClick`.
- Titreşim anahtarı kapalıysa hiçbir çağrı yapılmaz. Platform desteklemiyorsa hata sessizce yutulur.
- Hedef kırılma titreşimi, aynı satırda art arda çok sayıda kırılma olursa saniyede en fazla 10 kez tetiklenir (`kHapticMaxPerSec`).

### 8.5 Yapay zeka ses üretimi için yönerge

- Ses stili: yumuşak, arcade, kısa, kulak yormayan; keskin ve yüksek frekanslı sesler kaçınılır.
- Hiçbir ses, bilinen bir oyun, film veya müzikten alıntı ya da benzer olmamalıdır. Üretim aracının kullanım koşulları ticari kullanıma izin vermelidir; araç ve tarih `assets/CREDITS.md` dosyasına yazılır.
- Her SFX için üretim istemi (prompt) `assets/audio/PROMPTS.md` içinde saklanır.
- Dosya adları yukarıdaki tablodaki anahtarlarla birebir aynıdır; kod yalnızca bu anahtarlarla çağırır.

## 9. Ekranlar ve akışlar

Uygulama `go_router` ile şu rotalara sahiptir. Tüm ekranlar dikey (portrait) kilitlidir ve arka plan rengi oyun alanıyla uyumludur.

| Rota | Ekran | Açıklama |
| --- | --- | --- |
| `/` | Splash | Logo, en fazla 1 sn, ardından `/menu` |
| `/menu` | Ana menü | Beş buton |
| `/game` | Oyun | Faz 1 tek kişilik oyun |
| `/howto` | Nasıl oynanır | 4 sayfalık anlatım |
| `/feedback` | Geri bildirim | EmailJS ile gönderim |
| `/settings` | Ayarlar | Ses, dil, sürüm, gizlilik |
| `/competitive` | Yarışmalı mod (Faz 2) | Bölüm 11 |

### 9.1 Splash

- Tam ekran arka plan rengi, ortada logo. Süre: kaynaklar yüklenene kadar, en az 0.4 sn, en fazla 1 sn.
- Yüklenenler: `SharedPreferences`, yerelleştirme, ses ön yüklemesi (SFX hafızaya alınır).

### 9.2 Ana menü

- Ekran dikey olarak ikiye bölünür. Üst yarıda logo tam ortalanmış (yatay ve dikey) durur. Alt yarıda beş buton alt alta, yatayda ortalanmış dizilir.
- Butonlar sırasıyla: Oyna, Nasıl Oynanır, Geri Bildirim, Ayarlar, Çıkış.
- Buton boyutu: genişlik ekran genişliğinin %70'i (en fazla 320 dp), yükseklik 52 dp, aralık 14 dp, köşe yarıçapı 14 dp. "Oyna" butonu birincil renkte ve biraz daha büyük (yükseklik 60 dp), diğerleri ikincil renkte.
- Butona basınca 0.08 sn içinde %95 ölçeğe iner, bırakınca geri döner (`sfx_click` + `selectionClick`).
- En iyi skor, logonun altında küçük bir metin olarak gösterilir ("En iyi: N"). Skor 0 ise gösterilmez.
- Faz 2'de "Oyna" butonunun altına altıncı bir buton gelir: "Yarışma" (Bölüm 11).
- Ekranda mağaza veya reklam öğesi yoktur.

### 9.3 Oyun ekranı (HUD)

HUD yerleşimi Bölüm 4'te tanımlıdır. Sağ üstte duraklatma ikonu (36×36 dp dokunma alanı 48×48 dp) bulunur. Faz 2 yarışmalı modda bu ikon yoktur.

### 9.4 Duraklatma menüsü

- Oyun üzerinde yarı saydam (%60 siyah) bir katman ve ortada kart açılır. Simülasyon durur, fizik ilerlemez.
- Kart içeriği: başlık "Duraklatıldı", üç buton: Devam Et, Yeniden Başlat, Ana Menü.
- Yeniden Başlat: onay sormaz, mevcut oyunu atar ve yeni tohumla başlar. Ana Menü: mevcut oyun kaydedilmez; en iyi skor korunur.
- Uygulama arka plana alınınca (tek kişilik) bu menü otomatik açılır; geri dönüldüğünde oyun menü açık ve duraklatılmış halde bulunur.
- Android geri tuşu: oyun sırasında duraklatma menüsünü açar; menü açıkken menüyü kapatır (devam). Ana menüde geri tuşu hiçbir şey yapmaz.

### 9.5 Oyun sonu ekranı

- Satır 8'e inince, 0.4 sn "sallanma" animasyonundan sonra katman ve kart açılır.
- Kart içeriği: "Oyun Bitti", skor (büyük), en iyi skor, yeni rekor ise "Yeni Rekor!" etiketi ve `sfx_record`. Butonlar: Tekrar Oyna, Ana Menü.
- Skor sayacı 0'dan skora 0.6 sn içinde sayarak çıkar (ease-out).

### 9.6 Nasıl oynanır

- 4 sayfa, yatay kaydırmalı (`PageView`), altta 4 nokta göstergesi, sağ üstte kapat. Son sayfada "Anladım" butonu menüye döner.
- Sayfalar: (1) Çek ve bırak: ekranın herhangi bir yerine bas, geriye çek, bırak. (2) Rakamlar: her blokta rakam kadar vuruş gerekir. (3) Halkalar: halkadan geçen top sayını artırır. (4) Amaç: blokların alt sıraya inmesine izin verme; mümkün olduğunca uzun dayan.
- Her sayfa bir çizim (yapay zeka ile üretilmiş vektör/PNG) ve en fazla iki cümle metin içerir. Metinler yerelleştirme anahtarıdır (Bölüm 12).
- İlk oyun açılışında (Bölüm 5.8) kısa oyun içi öğretici zaten gösterilir; bu ekran tekrar erişim içindir.

### 9.7 Ayarlar

| Satır | Tür | Davranış |
| --- | --- | --- |
| Müzik | Anahtar | Açık/kapalı, anında etkili |
| Ses efektleri | Anahtar | Açık/kapalı |
| Titreşim | Anahtar | Açık/kapalı |
| Dil | Satır | Dokununca açılan pencere (popup) dil listesini gösterir; seçim anında uygulanır ve kaydedilir |
| Sürüm | Metin | `package_info_plus` ile `v1.0.0 (build)` |
| Gizlilik politikası | Bağlantı | Harici tarayıcıda açılır; adres `--dart-define` ile gelmez, `app_config.dart` sabitidir ve ayarlanabilir tablosundadır |

- Faz 2'de bu ekrana "Hesap" satırı eklenir: Google ile giriş, iOS'ta ek olarak Apple ile giriş, çıkış yap.
- Dil penceresi: ortada kart, her dil bir satır (yerel adı, ör. "English", "Türkçe"), seçili olanda onay işareti. Dil listesi `supported_languages` kayıt defterinden gelir; yeni dil eklemek yalnızca `.arb` dosyası ve bu listeye bir satır eklemektir. İlk sürümde yalnızca İngilizce vardır; liste tek öğeli de olsa pencere çalışır.
- İlk açılışta dil, cihaz dili desteklenenler arasındaysa o, değilse İngilizce olur.

### 9.8 Geri bildirim

Referans uygulamalar FindPairs ve Sudoku Pure ile aynı düzen ve aynı EmailJS kanalı kullanılır (bölüm 15.2). Gönderim doğrudan EmailJS REST API'sine yapılır, kendi sunucu yoktur.

- Alanlar: Kategori seçici (Hata / Fikir / Diğer; değerler `BUG`, `IDEA`, `OTHER`), çok satırlı mesaj kutusu (en fazla 500 karakter, canlı sayaç "0/500"), isteğe bağlı e-posta alanı (geçerlilik kontrolü yapılır), Gönder butonu.
- Gönder butonu mesaj boşsa pasiftir. Gönderirken buton yerine dönen gösterge çıkar, çift gönderim engellenir.
- İstek: `POST https://api.emailjs.com/api/v1.0/email/send`, gövde JSON: `service_id`, `template_id`, `user_id` (public key) ve `template_params`.
- `template_params` alanları: `app_name`, `category`, `subject` ("\<AppName> Feedback: \<Category>"), `message`, `user_email` (boşsa "-"), `app_version`, `platform`, `os_version`, `device_model`, `locale`, `timestamp` (ISO 8601 UTC).
- Cihaz bilgisi `device_info_plus` ve `package_info_plus` ile toplanır; hiçbir kişisel tanımlayıcı (reklam kimliği vb.) gönderilmez.
- Başarılı (HTTP 200): "Teşekkürler!" iletisi ve menüye dönüş. Hata: kutu içeriği korunur, "Gönderilemedi, tekrar dene" iletisi gösterilir. Zaman aşımı 15 sn.
- Gizli anahtarlar yalnızca `--dart-define` ile gelir (Bölüm 2); kodda sabit yazılmaz. Anahtarlar boşsa Gönder butonu pasif olur ve ekranda hata değil sessiz bir uyarı gösterilir.
- Aynı cihazdan art arda gönderim sınırı: 30 sn.
- Örnek e-posta şablonları (iki uygulamadan) geliştiriciye referans olarak verilir (Bölüm 15).

### 9.9 Çıkış

- Android: `SystemNavigator.pop()`. iOS: `exit(0)`. Her iki durumda uygulama tamamen kapanır ve yeniden açılışta sıfırdan başlar.
- Çıkışta onay penceresi yoktur.

### 9.10 Geçişler

Ekran geçişi 0.2 sn yumuşak solma (fade). Pencereler (popup) 0.18 sn ölçek+solma ile açılır. Hiçbir geçiş simülasyonu etkilemez.

## 10. Yaşam döngüsü ve kalıcı veri

Faz 1'de yalnızca cihazdaki `shared_preferences` kullanılır. Devam eden oyun diske kaydedilmez; uygulama kapanırsa oyun kaybolur, en iyi skor korunur.

### 10.1 Yerel anahtarlar

| Anahtar | Tip | Varsayılan | Açıklama |
| --- | --- | --- | --- |
| `best_score` | int | 0 | Tek kişilik en iyi skor |
| `music_on` | bool | true | Müzik anahtarı |
| `sfx_on` | bool | true | Ses efektleri anahtarı |
| `haptics_on` | bool | true | Titreşim anahtarı |
| `locale` | String | cihaz dili veya `en` | Seçili dil kodu |
| `tutorial_seen` | bool | false | Oyun içi öğretici gösterildi mi |
| `games_played` | int | 0 | İstatistik için, isteğe bağlı |
| `last_feedback_ms` | int | 0 | Geri bildirim sınırı için |

Tüm okuma/yazma işlemleri tek bir `PrefsRepository` sınıfı üzerinden yapılır; hatalar yutulur ve varsayılana dönülür.

### 10.2 Yaşam döngüsü kuralları

| Durum | Tek kişilik | Yarışmalı (Faz 2) |
| --- | --- | --- |
| Arka plana alındı (`paused`/`inactive`) | Simülasyon durur, duraklatma menüsü açılır | Simülasyon durur, yalnızca iki seçenekli menü açılır: Yeniden Başlat, Ana Menü |
| Öne geldi (`resumed`) | Menü açık, oyun duraklatılmış; Devam Et ile sürer | Aynı menü açık kalır, Devam Et yoktur |
| Uygulama sonlandırıldı | Oyun kaybolur | Hak düşmüştür, geri gelmez |
| İnternet koptu | Etkisiz | Oyun sürer, skor gönderimi yeniden denenir (Bölüm 11) |

- Ekran uyumasını önlemek için oyun ekranında `wakelock_plus` etkindir; oyundan çıkınca kapatılır.
- Arka plana geçince müzik durur, öne gelince sürer (Bölüm 8.3).
- Zaman sayacı olarak simülasyon kare sayısı kullanılır; arka planda geçen gerçek süre oyuna eklenmez. İlk karede `dt` en fazla 1/30 sn ile sınırlanır.

### 10.3 Veri sıfırlama

Uygulama içinde "verileri sıfırla" seçeneği yoktur. En iyi skor yalnızca uygulama silinince gider.

## 11. Faz 2: Yarışmalı mod

Faz 2, Faz 1 kabul testlerinden geçtikten sonra başlar. Oyun çekirdeği (`game_core`) değişmez; yarışmalı mod yalnızca tohum kaynağını, duraklatma kurallarını ve skor gönderimini ekler. Kendi sunucumuz ve Cloud Functions yoktur; yalnızca Firebase Auth ve Firestore kullanılır. Referans uygulamalardaki (FindPairs ve Sudoku Pure, Bölüm 15.2) giriş, sıralama ve yasaklı listesi yapısı kopyalanır; bu bölümdeki şema onlarla çelişirse referans uygulamaların şeması geçerlidir. Skor, Bölüm 5.6'daki formülle hesaplanır.

### 11.1 Giriş (kimlik doğrulama)

- Anonim oynama serbesttir (tek kişilik mod). Yarışmalı moda girmek için giriş gerekir. Anonim modda skor hiçbir koşulda veritabanına yazılmaz.
- Yöntemler: Google (Android ve iOS), Apple (yalnızca iOS).
- Girişten alınanlar: `uid`, görünen ad, Google ise profil fotoğrafı URL'si. Apple'dan fotoğraf alınamaz; bu durumda baş harfli avatar çizilir. Ad boşsa "Player" + `uid`'nin ilk 4 karakteri kullanılır.
- Çıkış yap ve hesap silme Ayarlar > Hesap'tadır (Apple kuralı gereği hesap silme bulunur).

### 11.2 Yarışma ana ekranı (`/competitive`)

- Üstte kalan hak göstergesi (3 nokta, dolu/boş), "Bugün kalan: N/3" ve yeni güne kalan süre sayacı.
- Ortada "Başla" butonu (hak 0 ise pasif, yerine sayaç), altında "Sıralama" butonu ve kendi haftalık en iyi skorun.
- İnternet yoksa "İnternet gerekli" uyarısı gösterilir, Başla pasif olur.

### 11.3 Haklar (günlük 3 deneme)

- Hak, oyun başlarken düşer: Başla'ya basınca Firestore işleminde (transaction) sayaç +1 yapılır, başarısız olursa oyun başlamaz. Oyun sırasında çıkış, uygulamadan atılma veya yeniden başlatma hakkı geri vermez. Menüden Yeniden Başlat yeni bir hak harcar; hak 0 ise Yeniden Başlat pasiftir.
- Gün sınırı Europe/Istanbul saatiyle 00:00'dır. "Bugün" cihaz saatine değil Firestore sunucu saatine göre belirlenir: istemci `FieldValue.serverTimestamp()` yazar ve geri okur; okunamazsa oyun başlamaz.
- Belge: `users/{uid}/attempts/{dayIndex}` alanları: `used` (int, 0–3), `updatedAt` (sunucu zamanı).

```dart
// Europe/Istanbul sabit UTC+3 (yaz saati yok)
int dayIndex(int serverUtcMs) => (serverUtcMs + 10800000) ~/ 86400000;
// 1970-01-01 Perşembe; hafta Pazartesi başlar
int weekIndex(int dayIdx) => (dayIdx + 3) ~/ 7;
```

### 11.4 Günlük tohum

- Aynı gün tüm oyuncular aynı tohumla oynar: `seed = SplitMix64(dayIndex ^ kSeedSalt).next()`. `kSeedSalt` sabit bir 64 bit sayıdır (Bölüm 13) ve sürümler arasında değişmez.
- Bu tohum Bölüm 6'daki satır üretimini besleyen tek RNG'nin başlangıcıdır. Aynı oyuncunun aynı gündeki 3 denemesi aynı tahtayı görür.
- Tek kişilik modda tohum her oyunda cihazdan rastgele alınır.

### 11.5 Yarışmalı modda duraklatma

- Duraklatma ikonu yoktur. Android geri tuşu oyun sırasında hiçbir şey yapmaz.
- Uygulama arka plana alınırsa simülasyon durur ve geri dönüşte iki seçenekli menü açılır: Yeniden Başlat (yeni hak harcar) ve Ana Menü. Devam Et yoktur. Ana Menü'ye çıkış oyunu bitmiş sayar; o ana kadarki skor gönderilmez (zaten kayıp).
- Yeniden Başlat'ta oyun hemen yeni hak düşerek başlar; hak yoksa yalnızca Ana Menü kalır.

### 11.6 Haftalık sıralama

- Hafta Pazartesi 00:00'da başlar, Pazar 24:00'te biter (Europe/Istanbul). Sıralama anahtarı `weekIndex`'tir.
- Oyuncunun haftalık skoru, o haftadaki en yüksek skorudur (tek kayıt/oyuncu).
- İlk 20 skor yazılır, ilk 10 listelenir, 11–20 yedektir (banlanan/silinen için). Liste en yeni sürüm olan 20 kayıttan, yasaklılar çıkarıldıktan sonra ilk 10'u gösterir.
- Belge: `leaderboards/{weekIndex}/entries/{uid}` alanları: `uid`, `name`, `photoUrl` (boş olabilir), `score`, `dayIndex`, `replay` (Bölüm 11.8), `createdAt` (sunucu zamanı).
- Skor gönderimi: oyun bitince istemci o haftanın ilk 20'sini okur; skoru 20. sıradan yüksekse (veya 20'den az kayıt varsa) ve oyuncunun kendi kaydından yüksekse yazar. Kendi kaydı 20'den düşük sıraya düşerse silinmez; sonraki okumada listeden dışarıda kalır.
- Gönderim başarısız olursa skor `pending_score` anahtarında saklanır, uygulama açılışında ve internet gelince yeniden denenir. Hafta bitmişse atılır.
- Liste ekranı: sıra, avatar, ad, skor; kendi satırın vurgulu. İlk 10'da değilsen altta kendi sıran gösterilir.

### 11.7 Yasaklı listesi ve kutlama

- Uygunsuz ad/foto için ben `config/banned` belgesindeki `uids` dizisine oyuncu kimliği eklerim. İstemci listeyi çekerken bu kimlikleri filtreler (kopyalanacak yapı referans uygulamalardan alınır).
- Skor ilk 10'a girdiyse oyun sonunda kutlama penceresi açılır: konfeti animasyonu (Bölüm 7 parçacık havuzu), "Tebrikler! N. sıradasın" metni, `sfx_celebrate` ve orta titreşim. İlk 10 dışında ama ilk 20 içindeyse yalnızca "Sıralamaya girdin" bilgisi gösterilir.

### 11.8 Yerel hile önleme

Sunucu tarafı doğrulama yoktur; amaç sıradan hileyi zorlaştırmaktır.

- Oyun boyunca her atış `(adım_no, vx, vy)` üçlüsü olarak kaydedilir. Oyun bitince aynı tohum ve girdilerle `game_core` başsız (headless) yeniden oynatılır; sonuç skoru, oyunun bildirdiği skora eşit değilse skor gönderilmez.
- `replay`, girdi listesinin değişken uzunluklu tam sayı kodlaması + base64'üdür; en fazla 20 KB. Firestore'a skorla birlikte yazılır, böylece şüphede ben tekrar oynatarak doğrulayabilirim.
- Makullük sınırları: skor ≤ `kMaxPlausibleScore`; atış sayısı ≥ 1; her atış aralığı ≥ 17 adım; zaman damgaları sunucu zamanından önce olamaz.
- Firestore güvenlik kuralları: yalnızca giriş yapmış kullanıcı kendi `uid` belgesini yazar; `attempts.used` yalnızca +1 artar ve 3'ü geçemez; `score` tamsayı ve 0–`kMaxPlausibleScore` arasındadır; mevcut skordan düşük yazım reddedilir; `weekIndex` ve `dayIndex` sunucu saatiyle uyuşmalıdır; `config/banned` istemciden yazılamaz.
- İsteğe bağlı: Firebase App Check (Play Integrity / DeviceCheck) açılır; bu ayar Bölüm 13'te kapalı/açık seçeneğidir.
- Bilinen sınır: kararlı kötü niyetli biri istemciyi değiştirip kurallara uyan sahte kayıt üretebilir. Bu, sunucusuz tercih edildiği için kabul edilmiş bir risktir (varsayım V5).

### 11.9 Hata durumları

| Durum | Davranış |
| --- | --- |
| Giriş iptal | Yarışma ekranına dönülür, mesaj yok |
| Giriş hatası | "Giriş yapılamadı" uyarısı, yeniden dene |
| Hak işlemi başarısız | Oyun başlamaz, "Bağlantı hatası" |
| Hak bitti | Başla pasif, yeni güne kalan süre görünür |
| Liste çekilemedi | Önbellekteki son liste + "Yenile" butonu |
| Hafta değişti oyun sırasında | Skor, oyun başladığı haftaya yazılır |

## 12. Yerelleştirme anahtar listesi

Tüm kullanıcıya görünen metinler `lib/l10n/app_en.arb` içinde anahtar olarak tutulur; kodda sabit metin yoktur. Anahtarlar `lowerCamelCase`, değerler İngilizcedir (ilk sürüm tek dil). Yeni dil = yeni `app_xx.arb` + `supported_languages` kaydına bir satır. `{n}` gibi yer tutucular ARB `placeholders` ile tanımlanır. Çoğul gerektiren metinler ICU `plural` söz dizimini kullanır.

| Anahtar | İngilizce değer | Kullanıldığı yer |
| --- | --- | --- |
| `appName` | (AI belirler, `APP_DISPLAY_NAME` ile aynı) | Başlık, geri bildirim konusu |
| `menuPlay` | Play | Ana menü |
| `menuHowToPlay` | How to Play | Ana menü |
| `menuFeedback` | Feedback | Ana menü |
| `menuSettings` | Settings | Ana menü |
| `menuExit` | Exit | Ana menü |
| `menuCompetitive` | Competitive | Ana menü (Faz 2) |
| `bestScoreLabel` | Best: {n} | Ana menü |
| `pauseTitle` | Paused | Duraklatma |
| `pauseResume` | Resume | Duraklatma |
| `pauseRestart` | Restart | Duraklatma, oyun sonu, yarışma |
| `pauseMainMenu` | Main Menu | Duraklatma, oyun sonu |
| `gameOverTitle` | Game Over | Oyun sonu |
| `scoreLabel` | Score | Oyun sonu |
| `newRecord` | New Record! | Oyun sonu |
| `playAgain` | Play Again | Oyun sonu |
| `tutorialAim` | Press anywhere, pull back and release to shoot | Oyun içi öğretici |
| `howtoPage1Title` / `howtoPage1Body` | Pull and release / Press anywhere on the screen, pull back and let go to shoot. | Nasıl oynanır |
| `howtoPage2Title` / `howtoPage2Body` | Numbers | Nasıl oynanır |
| `howtoPage3Title` / `howtoPage3Body` | Rings | Nasıl oynanır |
| `howtoPage4Title` / `howtoPage4Body` | Goal | Nasıl oynanır |
| `howtoGotIt` | Got it | Nasıl oynanır |
| `settingsTitle` | Settings | Ayarlar |
| `settingsMusic` | Music | Ayarlar |
| `settingsSfx` | Sound effects | Ayarlar |
| `settingsHaptics` | Vibration | Ayarlar |
| `settingsLanguage` | Language | Ayarlar |
| `settingsVersion` | Version | Ayarlar |
| `settingsPrivacy` | Privacy Policy | Ayarlar |
| `settingsAccount` | Account | Ayarlar (Faz 2) |
| `feedbackTitle` | Feedback | Geri bildirim |
| `feedbackCategoryBug` | Bug | Geri bildirim |
| `feedbackCategoryIdea` | Idea | Geri bildirim |
| `feedbackCategoryOther` | Other | Geri bildirim |
| `feedbackMessageHint` | Tell us what you think… | Geri bildirim |
| `feedbackEmailHint` | Email (optional) | Geri bildirim |
| `feedbackSend` | Send | Geri bildirim |
| `feedbackThanks` | Thank you! | Geri bildirim |
| `feedbackError` | Could not send. Please try again. | Geri bildirim |
| `feedbackInvalidEmail` | Enter a valid email | Geri bildirim |
| `commonClose` | Close | Genel |
| `commonCancel` | Cancel | Genel |
| `commonOk` | OK | Genel |
| `commonRetry` | Retry | Genel |
| `signInGoogle` | Continue with Google | Giriş (Faz 2) |
| `signInApple` | Continue with Apple | Giriş (Faz 2) |
| `signOut` | Sign out | Ayarlar (Faz 2) |
| `deleteAccount` | Delete account | Ayarlar (Faz 2) |
| `signInFailed` | Sign-in failed | Giriş (Faz 2) |
| `competitiveAttemptsLeft` | Attempts left today: {n}/3 | Yarışma |
| `competitiveNextReset` | New attempts in {time} | Yarışma |
| `competitiveStart` | Start | Yarışma |
| `competitiveLeaderboard` | Leaderboard | Yarışma |
| `competitiveNeedInternet` | Internet connection required | Yarışma |
| `competitiveConnectionError` | Connection error | Yarışma |
| `competitiveRestartCost` | Restarting uses another attempt | Yarışma menüsü |
| `leaderboardTitle` | Weekly Leaderboard | Sıralama |
| `leaderboardYourRank` | Your rank: {n} | Sıralama |
| `leaderboardRefresh` | Refresh | Sıralama |
| `celebrateTitle` | Congratulations! | Kutlama |
| `celebrateBody` | You are number {n} this week! | Kutlama |
| `rankedBody` | You made it onto the leaderboard | Kutlama |
| starBonusPopup | +{n} | Yıldız toplama yazısı |

Kurallar: (1) Kodda `Text('…')` ile sabit metin kullanılması test ile yakalanır (Bölüm 14). (2) Her `.arb` anahtar kümesi `app_en.arb` ile birebir aynı olmalıdır; eksik anahtar derlemeyi bozar. (3) Tarih/süre biçimleri `intl` paketiyle yerel biçimlendirilir. (4) Yeni bir özellik metin ekliyorsa anahtar bu tabloya da eklenir.

## 13. Ayarlanabilir sabitler tablosu

Tüm sayısal değerler `lib/config/constants.dart` ve `game_core/lib/src/constants.dart` içinde tek yerde, aşağıdaki adlarla tanımlanır. Kodun başka bir yerinde sabit sayı (magic number) bulunmaz. "Simülasyon" olarak işaretlenenler değiştirilirse tüm doğrulama tabloları (Bölüm 6, 14) yeniden üretilmelidir.

| Sabit | Değer | Grup | Açıklama |
| --- | --- | --- | --- |
| `kVirtualW` / `kVirtualH` | 416 / 703 gu | Geometri | Sanal tuval |
| `kCols` | 7 | Simülasyon | Sütun sayısı |
| `kPitch` | 59.43 gu | Simülasyon | Hücre aralığı |
| `kRow0CenterY` | 135.7 gu | Simülasyon | 0. satır merkezi |
| `kPlayableRows` | 8 (0–7) | Simülasyon | 8. satır oyun sonu |
| `kCeilingY` | 53 gu | Simülasyon | Tavan |
| `kFloorY` | 635 gu | Simülasyon | Zemin |
| `kLaunchY` | 622 gu | Simülasyon | Fırlatma yüksekliği |
| `kBallRadius` | 13 gu | Simülasyon | Top yarıçapı |
| `kTargetRadius` | 25 gu | Simülasyon | Hedef yarıçapı |
| `kPickupRadius` | 18 gu | Simülasyon | Halka yarıçapı |
| `kBallSpeed` | 585 gu/sn | Simülasyon | Top hızı |
| `kStepsPerSec` | 120 | Simülasyon | Sabit adım |
| `kLaunchIntervalSteps` | 17 | Simülasyon | Atışlar arası |
| `kMaxBalls` | 99 | Simülasyon | Top üst sınırı |
| `kFlightTimeoutSec` | 20 | Simülasyon | Uçuş zaman aşımı |
| `kCollectSec` | 0.25 | Sunum | Toplama süresi |
| `kAdvanceSec` | 0.18 | Sunum | Satır kayma süresi |
| `kAimDeadZone` | 10 gu | Girdi | Ölü bölge |
| `kMinAimAngleDeg` | 5° | Girdi | En küçük açı |
| `kGuideLength` | 490 gu | Sunum | Kılavuz çizgisi uzunluğu |
| `kGuideDash` / `kGuideGap` / `kGuideStroke` | 12 / 12.6 / 3 | Sunum | Çizgi stili |
| `kBallCountWeights` | 24/29/29/18 (2,3,4,5) | Simülasyon | Satır nesne sayısı ağırlıkları |
| `kRingChancePct` | 56 | Simülasyon | Halka olasılığı |
| `kMultipliersM2` | {2,3,4} | Simülasyon | Çarpan (×1, ×1.5, ×2) |
| `kParticlePool` | 64 | Sunum | Parçacık havuzu |
| `kSfxMinGapMs` | 50 | Ses | Aynı SFX aralığı |
| `kSfxMaxConcurrent` | 8 | Ses | Eş zamanlı SFX |
| `kMusicVolume` | 0.35 | Ses | Müzik seviyesi |
| `kMusicPausedFactor` | 0.4 | Ses | Duraklatmada oran |
| `kHapticMaxPerSec` | 10 | Titreşim | Kırılma titreşimi sınırı |
| `kSplashMinMs` / `kSplashMaxMs` | 400 / 1000 | UI | Açılış ekranı |
| `kFeedbackMaxChars` | 500 | UI | Geri bildirim uzunluğu |
| `kFeedbackCooldownSec` | 30 | UI | Gönderim aralığı |
| `kFeedbackTimeoutSec` | 15 | UI | Ağ zaman aşımı |
| `kPrivacyUrl` | (geliştirici girer) | UI | Gizlilik bağlantısı |
| `kDailyAttempts` | 3 | Faz 2 | Günlük hak |
| `kLeaderboardWrite` / `kLeaderboardShown` | 20 / 10 | Faz 2 | Yazılan / gösterilen |
| `kSeedSalt` | (AI 64 bit rastgele üretir, bir kez) | Faz 2 | Günlük tohum tuzu |
| `kMaxPlausibleScore` | 2000 | Faz 2 | Skor üst sınırı |
| `kReplayMaxBytes` | 20480 | Faz 2 | Tekrar kaydı sınırı |
| `kTzOffsetMs` | 10800000 | Faz 2 | Europe/Istanbul UTC+3 |
| `kAppCheckEnabled` | false | Faz 2 | App Check anahtarı |
| kStarChancePct | 25 | Simülasyon | Satırda yıldız olasılığı (%) |
| kStarScore | 3 | Simülasyon | Yıldız başına skor puanı |

## 14. Test, kabul ölçütleri ve kilometre taşları

Her kilometre taşı sonunda `flutter analyze` sıfır uyarı, `flutter test` hepsi geçti ve uygulama bir cihazda/emulatörde açılıp oynanmış olmalıdır. Bir kilometre taşı kabul ölçütleri sağlanmadan bir sonrakine geçilmez.

### 14.1 Otomatik testler

| Test | Ne doğrular | Geçme koşulu |
| --- | --- | --- |
| `no_flutter_in_core_test` | `game_core` içinde `package:flutter`, `dart:ui`, `dart:math` trig, `DateTime.now`, `Random` yok | Kaynak taraması boş döner |
| `splitmix64_test` | Seed 0 ve 1234567 için ilk 10 çıktı (referans C uygulaması; seed 0 ilk çıktı 0xE220A8397B1DCDAF) | Bölüm 6'daki tablo ile birebir |
| `hp_for_test` | `hpFor` tüm (t, m2) kombinasyonları | Bölüm 6 doğrulama tablosu |
| `row_generation_test` | Sabit tohumla ilk 30 satır | Altın kayıt (golden) dosyasıyla aynı |
| `determinism_test` | Aynı tohum + aynı girdi iki kez | Her adımda durum karması aynı |
| `replay_test` | Kaydedilen atışlar yeniden oynatılır | Skor eşit; bozuk girdi reddedilir |
| `collision_test` | Duvar, tavan, hedef, halka, köşe, üst üste hedefler | Bölüm 5 çarpışma tablosundaki her satır |
| `state_machine_test` | Durum geçişleri ve oyun sonu koşulu | 8. satıra inince `gameOver` |
| `aim_test` | Başlangıç noktasına göre göreli, ölü bölge, iptal, 5° alt sınır | Bölüm 5.1 |
| `scaling_test` | iPhone SE, iPhone 15 Pro Max, iPad, 20:9 telefon | Ölçek ve harita Bölüm 3 tablosuyla eşleşir |
| `l10n_test` | Tüm `.arb` dosyalarının anahtar kümesi, kodda sabit metin yok | Fark yok |
| `prefs_test` | Varsayılanlar ve bozuk veri | Hata fırlatmaz |
| `feedback_test` | EmailJS isteği (sahte HTTP istemcisi ile) | Alanlar ve başlık doğru |
| `rules_test` (Faz 2) | Firestore kuralları (emulatör) | Haklar +1, skor azalmaz, başkasının belgesi yazılamaz |

### 14.2 Elle kabul listesi (Faz 1)

- [ ] Uygulama ilk açılışta splash ve ana menüye gelir; beş buton görünür ve çalışır.
- [ ] Ekranın herhangi bir yerine basıp geri çekince kılavuz çizgisi çıkar; yukarı bırakınca toplar fırlar, aşağı bırakınca atış iptal olur.
- [ ] İlk tahta, tutorial ve ilk atış Bölüm 5.7–5.8'deki gibi.
- [ ] Satır kaymış, halka alınınca top sayısı artmış, toplar toplandıktan sonra tur sayacı +1 olmuş.
- [ ] Satır 8'e inince oyun biter, skor ve en iyi skor doğru gösterilir, yeniden açınca en iyi skor korunur.
- [ ] Uygulama arka plana alınıp dönülünce duraklatma menüsü açıktır.
- [ ] Müzik, ses ve titreşim anahtarları anında etkilidir ve yeniden açışta korunur.
- [ ] Dil penceresi açılır, seçim uygulanır.
- [ ] Geri bildirim gerçek EmailJS üzerinden ulaşır; konu ve alanlar Bölüm 9.8'deki gibi.
- [ ] Çıkış iki platformda da uygulamayı kapatır.
- [ ] Küçük (iPhone SE) ve büyük (15 Pro Max) ekranda yerleşim aynı oranda görünür.
- [ ] 10 dakika sürekli oyunda kare hızı 60 fps'in altına düşmez, bellek artışı gözlenmez.

### 14.3 Elle kabul listesi (Faz 2)

- [ ] Google ile giriş iki platformda, Apple ile giriş iOS'ta çalışır; anonimken skor yazılmaz.
- [ ] Başla'ya basınca hak 3'ten 2'ye iner; çıkış ve yeniden başlatma hakkı geri vermez.
- [ ] 00:00'da (Europe/Istanbul) haklar yenilenir; cihaz saati değişse de etkilenmez.
- [ ] Aynı gün aynı tohum, aynı tahta.
- [ ] Haftalık sıralama Pazartesi 00:00'da sıfırlanır; 20 yazılır, 10 gösterilir.
- [ ] Banlanan uid listeden çıkar ve 11. sıradaki yerine girer.
- [ ] İlk 10'a giren oyuncuya kutlama penceresi açılır.
- [ ] Yarışmada duraklatma ikonu yoktur; arka plana alınınca yalnızca Yeniden Başlat ve Ana Menü vardır.
- [ ] Hileli skor (elle değiştirilmiş) gönderilmez veya kurallarca reddedilir.

### 14.4 Kilometre taşları

1. **M1 — Çekirdek:** `game_core` (RNG, `hpFor`, satır üretimi, çarpışma, durum makinesi) + tüm birim testleri. Arayüz yok.
2. **M2 — Oynanabilir prototip:** Flame tuvali, ölçekleme, nesne çizimi, girdi ve kılavuz, geçici renkli şekiller.
3. **M3 — Görsel ve ses cilası:** AI ile üretilen tema, animasyonlar, parçacıklar, SFX ve müzik.
4. **M4 — Uygulama kabuğu:** Splash, ana menü, nasıl oynanır, ayarlar, dil penceresi, duraklatma/oyun sonu, kalıcı veri.
5. **M5 — Geri bildirim ve çıkış:** EmailJS, cihaz bilgisi, çıkış, yaşam döngüsü kuralları.
6. **M6 — Faz 1 yayın adayı:** Performans, kabul listesi, ikon ve mağaza görselleri, gizlilik metni.
7. **M7 — Faz 2 altyapısı:** Firebase, giriş, haklar, günlük tohum.
8. **M8 — Faz 2 sıralama:** Haftalık liste, yasaklı filtre, kutlama, yerel hile önleme, güvenlik kuralları testleri.
9. **M9 — Faz 2 yayın adayı:** Kabul listesi, mağaza güncellemesi.

## 15. Açık noktalar ve referans dosyalar

### 15.1 Açık noktalar

| # | Konu | Durum |
| --- | --- | --- |
| A1 | Yıldız toplanabilir nesnesi (yalnızca ekstra skor): öneri %25 ihtimal, +3 puan, skor = tur + 3 × yıldız | Onaylandı (15 Ekim 2026); Bölüm 1, 5.11, 6, 8, 12, 13 güncellendi. Bölüm 6'daki HP doğrulama tablosu değişmez (hpFor RNG kullanmaz). Yıldız çekimi her satırın sonuna eklendi, ilk tahtada çekim yapılmaz |
| A2 | Oyun adı, logo ve tema | Yapay zeka Bölüm 7'deki yönergeyle seçer; ad, mevcut mobil oyunların adıyla çakışmamalı |
| A3 | Gizlilik politikası adresi | Geliştirici/sahip sağlar (`kPrivacyUrl`) |
| A4 | Uygulama paket kimliği (bundle id) ve Firebase projesi | Sahip oluşturur, kimlikler `--dart-define`/yapılandırma ile verilir |
| A5 | Varsayımlar V1–V8 (Bölüm 1) | Kullanıcı itiraz etmedikçe geçerlidir |

### 15.2 Geliştiriciye verilecek referans dosyalar

Aşağıdakiler PRD'nin parçası sayılır ve geliştirme başlarken proje klasörüne konur:

**IDE'deki yapay zeka için (altyapı örnekleri, oyun mekaniği örneği değil):** Aşağıdaki iki proje, bu PRD'nin istediği altyapının çalışan örnekleridir. İlgili özelliği yazmadan önce ilgili projede şu dosyaları ara ve oku; adını bilmediğin dosyayı proje içinde ara (ör. `emailjs`, `feedback`, `leaderboard`, `banned`, `sign_in`, `language`).

| Referans uygulama | Buradan alınacak | PRD'de karşılığı |
| --- | --- | --- |
| FindPairs | EmailJS geri bildirim ekranı ve istek gövdesi, dil seçim penceresi, ayarlar ekranı | Bölüm 9.7, 9.8 |
| FindPairs | Google ve Apple ile giriş akışı, Firebase Auth kurulumu | Bölüm 11.1 |
| Sudoku Pure | EmailJS şablon alanları, Firestore skor tablosu şeması ve sorgusu | Bölüm 9.8, 11.6 |
| Sudoku Pure | `banned` listesiyle filtreleme mantığı | Bölüm 11.7 |

Bu tablodaki dağılım, hangi özelliğin hangi projede olduğu kesin bilinmediği için bir başlangıç tahminidir. İki projede de bulunuyorsa daha sade olanı baz al; ikisinde de yoksa bu PRD'deki tanım geçerlidir.

- **FindPairs** ve **Sudoku Pure** projeleri (salt okunur): EmailJS geri bildirim ekranı ve şablonu, Google/Apple giriş akışı, Firestore sıralama şeması ve sorgusu, `banned` filtreleme, dil penceresi, ayarlar ekranı.
- İki örnek geri bildirim e-postası ve geri bildirim ile dil penceresi ekran görüntüleri (kullanıcının gönderdiği).
- Referans oyun ekran kaydı (99 Balls) ve nişan alma videosu.

Kural: Bu dosyalardaki giriş, EmailJS ve Firestore kodu kullanıcının kendi uygulamalarından olduğu için yapı olarak **kopyalanır** ve bu PRD'nin mimarisine (Riverpod, go\_router, gen-l10n) uyarlanır. Çelişki varsa Firestore şeması ve EmailJS şablon alanları için referans uygulamalar, diğer her şey için bu PRD geçerlidir.

### 15.3 Yapay zekanın çalışma düzeni

- Geliştirici yapay zeka önce Bölüm 2'deki klasör yapısını oluşturur, sonra M1'den başlayarak sırayla ilerler (Bölüm 14.4). Bir kilometre taşının testleri geçmeden sonrakine geçilmez.
- PRD'de belirsiz veya çelişkili bir nokta bulursa tahmin etmez; en küçük varsayımı yapıp `docs/ASSUMPTIONS.md` dosyasına yazar ve işe devam eder.
- Simülasyonu etkileyen hiçbir değişiklik, ilgili test ve altın kayıt dosyası güncellenmeden yapılmaz.

# ASSUMPTIONS.md

Bu dosya, PRD'de (docs/PRD.md) belirsiz kalan ya da PRD ile referans projeler
çeliştiğinde alınan kararların kaydıdır. Yapay zeka her kararı buraya yazar.

## 1. Referans projeler (yalnızca okunur, kopyalanmaz)

Konum: C:\Users\Dogan\Desktop\MobileProject\SudokuPure V2

Bu klasörde Sudoku Pure'un 3 projesi vardır: standart, premium ve iOS'a
özelleştirilmiş sürüm. PRD'nin istediği altyapı özellikleri bu projelerde
mevcuttur. Yapay zeka bu projeleri okuyup yapıyı öğrenir, kodu yeni
projenin mimarisine (Riverpod, go_router, gen-l10n) uyarlayarak yeniden yazar.

Kural: Firestore şeması ve EmailJS şablon alanları için bu projeler geçerlidir.
Diğer her konuda docs/PRD.md geçerlidir.

### Özellik -> aranacak yer (yapay zeka doldurur)

| Özellik | PRD bölümü | Referans projede dosya/klasör | Not |
| --- | --- | --- | --- |
| EmailJS geri bildirim ekranı ve istek gövdesi | 9.8 | (doldurulacak) | |
| Dil seçim penceresi (popup) | 9.7 | (doldurulacak) | |
| Ayarlar ekranı | 9.7 | (doldurulacak) | |
| Google ile giriş | 11.1 | (doldurulacak) | |
| Apple ile giriş (iOS) | 11.1 | (doldurulacak) | iOS projesine bak |
| Firestore skor tablosu şeması ve sorgusu | 11.6 | (doldurulacak) | |
| banned listesi ve filtreleme | 11.7 | (doldurulacak) | |
| Hesap silme | 11.1 | (doldurulacak) | |

Üç proje arasında fark varsa (standart / premium / iOS) iOS'a özgü olanı
yalnızca iOS kodunda kullan; ortak olanı baz al.

## 2. PRD'den gelen varsayımlar

PRD Bölüm 1'deki V1–V8 varsayımları geçerlidir. Burada tekrar edilmez.
Bir varsayım değiştirilirse buraya tarih ve gerekçe ile yazılır.

## 3. Uygulama sırasında alınan kararlar

Her karar için bir satır ekle. Karar PRD'ye aykırı olamaz; yalnızca boşluğu doldurur.

| Tarih | PRD bölümü | Belirsizlik | Alınan karar | Gerekçe |
| --- | --- | --- | --- | --- |
| 2026-10-16 | 2.2, 13 | 2.2 `lib/game_core/` klasörü diyor, 13 ayrı paket (`game_core/lib/src/constants.dart`) diyor | `lib/game_core/` klasörü kullanılır, ayrı paket yapılmaz | CLAUDE.md "Bölüm 2'deki klasör yapısına birebir uy" diyor. Saflığı `no_flutter_in_core_test` korur (game_core dışından `package:` importu da yasak) |
| 2026-10-16 | 2.4, 13 | Sabitler 2.4'te `core/config/game_config.dart`, 13'te iki ayrı dosyada | game_core sabitleri `lib/game_core/constants.dart` içinde (Geometri, Simülasyon, Girdi grupları + `kStartBalls`, `kPercentBound`, `kRowTargetCounts`). Sunum/UI/ses sabitleri M2'de `core/config/game_config.dart` içinde olacak | game_core dışarıya bağımlı olamaz |
| 2026-10-16 | 14.1 | `row_generation_test` golden'ı için T dizisi tanımlı değil | Tohum 20261015; 0. satır ilk tahta (T=1), i. satır `nextRow(i+1)`. Dosya: `test/game_core/golden/rows_seed_20261015.json`, `UPDATE_GOLDEN=1` ile yeniden üretilir | T oyuna bağlı; artan T farklı HP aralıklarını kapsar. Golden, PRD 6.1–6.3 baştan yazılan bağımsız bir Python uygulamasıyla birebir doğrulandı |
| 2026-10-16 | 6.1 | "soldan sağa" çarpan sırası | Top sütunları artan sütun numarasına sıralanır, m2 bu sırayla çekilir | Metnin doğrudan okuması |
| 2026-10-16 | 4.2, 13 | `kPitch` = 59.43 mi, 416/7 = 59.4286 mı | 59.43 (Bölüm 13'teki değer) | Adlandırılmış sabit tablosu esas alındı |
| 2026-10-16 | 6.3 | SplitMix64 web'de çalışmaz (JS'de int 64-bit değil) | Kabul edildi, hedef yalnızca Android/iOS | PRD "native Dart" diyor |
| 2026-10-16 | 2.1 | "Flame'e dokunma" talimatı ile 2.1 bağımlılık listesi | `flame` ve `flame_audio` pubspec'e eklendi, Flame kodu yazılmadı | 2.1 bağımlılıkları M1 kapsamında |
| 2026-10-16 | 2.5 | gen-l10n `generate: true` ve asset bildirimi | M1'de eklenmedi; .arb ve asset dosyalarıyla birlikte M3/M4'te eklenecek | Dosyalar olmadan anlamsız ya da derleme hatası |
| 2026-10-16 | 6.3, 5.11 | splitmix64 tablosu ve yıldız şansı 0 iken RNG tüketimi | PRD düzeltildi (14.1 ve 5.11), karar gerekmez | — |
| 2026-10-16 | 5.1 | `round(a.x * 100)`'de a birim vektör mü, ham vektör mü | a = −d, gu cinsinden ham sürükleme vektörü (çözünürlük 0,01 gu). Yuvarlama açıyı 5°'nin altına iterse vy 1'er azaltılır (`isValidShot` geçene kadar). 5°'nin sin/cos değerleri literal sabit (`kMinAimSin/Cos`), aim_test dart:math ile doğrular | PRD'nin harfiyen okuması; çekirdekte trig yasak |
| 2026-10-16 | 5.4, 7.2 | Toplama (0,25 sn) ve satır kayması (0,18 sn) çekirdekte nasıl sayılır | Adım olarak sayılır: `kCollectSteps` = 30, `kAdvanceSteps` = 22 (21,6 yukarı yuvarlandı). gameOver'daki 0,6 sn vurgu yalnızca sunuma ait | `adım_no` tek bir saate bağlı olsun; replay ve determinizm bunu gerektirir |
| 2026-10-16 | 5.3, 5.4 | İlk topun çıkış anı ve atış sırasında fırlatma x'i | İlk top, atış kabul edildikten sonraki ilk adımda çıkar. Atışın kalan topları, ilk top inmiş olsa bile aynı x'ten çıkar; yeni fırlatma x'i bir sonraki atışta geçerli olur | Referans videodaki davranış; kural tek atış içinde sabit kalır |
| 2026-10-16 | 5.3 | "En yakın hedef" ve farklı türden temasların eşitliği | En yakın = en erken temas zamanı. Eşitlik sırası: hedef (satır, sütun), sonra sol duvar, sağ duvar, tavan, zemin. Köşe ardışık yinelemelerle çözülür. Adım başına 4 yineleme dolarsa adımın kalan süresi atılır | Tünellemeye karşı güvenli seçim |
| 2026-10-16 | 5.3 | Hedef yansıma formülü PRD'de kesik ("n = (top − hedef) /") | n = (top−hedef)/\|top−hedef\|, v' = v − 2(v·n)n. Hedef yansımasından sonra hız sabit büyüklüğe yeniden ölçeklenir | Standart daire yansıması |
| 2026-10-16 | 5.3 | Zaman aşımına uğrayan top fırlatma x'ini belirler mi | Evet; inmiş sayılır ve zemine ilk inen topsa x'i [13, 403]'e sıkıştırılarak bir sonraki fırlatma noktası olur | "O anki x'inde inmiş sayılır" |
| 2026-10-16 | 5.10, 5.11 | 8. satıra inen halka/yıldızın silinme anı | advancing sonunda, gameOver kontrolüyle aynı anda silinir (`PickupExpired` olayı) | Kayma animasyonu bitince |
| 2026-10-16 | 11.8 | Replay kodlama ayrıntıları | [sürüm=1][atış sayısı][her atış: adım farkı, zigzag(vx), zigzag(vy)], LEB128 varint, base64. 20 KB sınırı base64 metnine uygulanır. Geçerli bir kayıt gameOver ile bitmelidir. ready'de beklenen boş adımlar sonucu etkilemez. Zaman damgası kontrolü Firestore'a ait (Faz 2) | Sunucusuz doğrulama yalnızca oyun sonu skorunu karşılaştırır |
| 2026-10-16 | 13 | Çekirdeğin kullandığı Sunum/Faz 2 sabitleri | `kCollectSec`, `kAdvanceSec`, `kMaxPlausibleScore`, `kReplayMaxBytes` `lib/game_core/constants.dart` içinde | game_core dışarıya bağımlı olamaz |
| 2026-10-16 | 2.3 | Durum karmasının içeriği | FNV-1a 64: adım, faz, sayaçlar, launchX, atış yönü, zamanlayıcılar, tahta hücreleri ve tüm topların durum, konum ve hızları (double'lar ham bitleriyle) | Herhangi bir bit farkı yakalanır |
| 2026-10-16 | 2.3, 10.2 | Kare başına en fazla 8 adım ve ilk kare dt sınırı | M2'de kare döngüsüyle yapılacak; çekirdek yalnızca `step()` sunar | Kare döngüsü sunum katmanıdır |
| 2026-10-16 | 2.3 | "Çizim adımlar arası enterpolasyon yapar" | Ara değer yerine ileri kestirim: havadaki top `x + vx·alpha` konumunda çizilir (duvar/tavan/zemin sınırlarına sıkıştırılarak). `alpha`, `FixedStepClock`'tan gelir | Ara değer için topların önceki konumu gerekir; bu da game_core durumunu kopyalamak ya da game_core'u değiştirmek demektir. Bir adımlık ileri kestirim en fazla 4,9 gu sapar |
| 2026-10-16 | 5.2 | Nişan çizgisi "5.3'teki aynı çarpışma kodu"nu kullanmalı | Temas zamanları game_core'un `circleToi`/`lowerBoundToi`/`upperBoundToi` fonksiyonları ve aynı öncelik sırasıyla hesaplanır. Hedef yansıma formülü `guide_path.dart`'ta tekrar yazıldı (Simulation'daki private). `guide_path_test`, yolu gerçek Simulation topuyla adım adım (1e-6) karşılaştırır. Sonsuz yansımaya karşı 64 segment sınırı (`kGuideMaxSegments`). Çizgi HP'yi dikkate almaz | game_core değiştirilmeden; sapma testle yakalanır |
| 2026-10-16 | 5.8, 12 | Öğretici metin anahtarı: 5.8 `tutorial_slide_to_shoot` ("Slide to shoot"), 12 `tutorialAim` ("Press anywhere, pull back and release to shoot") | Bölüm 12'deki `tutorialAim` kullanılır | Bölüm 12 anahtar listesinin kaynağıdır ve camelCase kuralına uyar |
| 2026-10-16 | 2.6, 5.8 | Öğretici el ikonu kodla çizilmeli | M2'de geçici olarak Material `Icons.touch_app`; M3'te kodla çizilmiş ikonla değiştirilecek. Solma süresi 0,2 sn ("hızla solar") | Kullanıcı M2 için "yalnızca metin ve basit ikon" istedi |
| 2026-10-16 | 4.5, 7.2 | M2'de HUD'un hangi öğeleri | Skor, top ikonu ve top sayısı çizildi. Müzik ve duraklat ikonları M4/M5'te (işlevleriyle birlikte). Tehlike uyarısı, kırılma animasyonu, parçacıklar ve sayı gölgesi M3'te | Kapsam: M2 = geçici şekiller |
| 2026-10-16 | 5.4, 7.2 | Oyun sonu sırası | GameOver olayından sonra bitiş satırındaki hedefler 0,6 sn içinde 3 kez tehlike rengiyle yanıp söner. Ardından karartma ve kart 0,35 sn'de solarak açılır | 5.4 ve 7.2'deki süreler; kart geçici (M4) |
| 2026-10-16 | 3 | Ölçekleme kodunun konumu | `lib/app/canvas_fit.dart` | Bölüm 3 tüm ekranlara uygulanır; tek bir ortak yer |
| 2026-10-16 | 10.1 | M2'de kalıcı veri | `PrefsRepository` yalnızca `tutorial_seen` ile başladı; kalan anahtarlar M4'te. `tutorial_seen` ilk geçerli atışta yazılır (katman ilk basışta solmuş olsa bile) | 5.8 |
| 2026-10-16 | 7.1, 7.4 | Renkler | `palette.dart` ve `hp_colors.dart` geçici değerler; durak geçiş kuralı ve beyaz rakamda ≥3:1 kontrast testle sabit. Nihai renkler M3'te | M2 = geçici şekiller |
| 2026-10-16 | 10.2 | Arka plandan dönüş | Flame motoru arka planda kendisi duraklatır; dönüşte `FixedStepClock.reset()` ile ilk kare tekrar 1/30 sn ile sınırlanır ve nişan iptal edilir. Duraklatma menüsü M4'te | Arka planda geçen süre oyuna eklenmez |
| 2026-10-16 | 2.4 | Geçici katmanların ölçüleri (yazı boyu, boşluk, kart genişliği) | `game_config.dart`'ta adlandırılmış sabit; M4'te gerçek ekranlarla gözden geçirilecek | Magic number kuralı |
| 2026-10-16 | 5.2 | Nişan çizgisi boyu (cihaz testi) | Boy sürüklemeyle uzar: `lerp(kGuideMinLength=60, kGuideLength=490, t)`, t = clamp((dragDist − 10) / `kGuideRampDistance`=120, 0, 1). Solma her zaman o anki uca göre (son 40 gu) | PRD 5.2'deki sabit 490 boy, kullanıcı isteğiyle rampaya çevrildi |
| 2026-10-16 | 5.1 | Kısa çekişte nişan sıçraması (cihaz testi) | Görünüm katmanında artımlı ince nişan (`AimController`): ölü bölgeden çıkışta yön mutlak, sonraki açı farkları min(1, L / `kAimMinRadius`=120) kazancıyla uygulanır → 1 gu hareket ≤ 0,478°. Atış `aimFromDrag(−cos φ·100, sin φ·100)` ile üretilir (`kAimShotLength`=100); çizilen ve ateşlenen (vx,vy) aynıdır. game_core'daki `AimTracker` ve `aimFromDrag` değişmedi | Mutlak eşlemede açı değişimi atan(1/L); L=60'ta 0,955°/gu ve ölçüt (≤0,5°) sağlanamaz. Bedeli: kısa çekişte eşleme yola bağlı (parmak aynı noktaya dönünce açı birebir dönmeyebilir). Düşük geçiren filtre reddedildi: gecikme ekler, oturduğunda yine 0,955°/gu |
| 2026-10-16 | 5.1 | Ölü bölge sınırında yanıp sönme | Histerezis: nişan `kAimEnterDistance`=10 gu'da başlar, `kAimExitDistance`=6 gu altında biter. İptal bölgesi ve ölü bölge nişanı sıfırlar; tekrar çıkınca yön yine mutlak | Kullanıcı isteği |
| 2026-10-16 | 5.4, 4.4 | Topların zeminde toplanması (cihaz testi) | Yalnızca görsel (`BallMergeAnimator`): ilk inen top yerinde kalır, sonra inen her top `firstLandingX`'e sabit `kMergeSpeed`=1600 gu/sn ile kayar, hedefe varınca birleşir (tek top görünür), geçmez. collecting bitince (RowAdvanced) hâlâ kayan toplar hedefe oturur. Çekirdekteki collecting (30 adım), stateHash ve replay değişmez (testle doğrulandı) | 1600 gu/sn ile en uzak mesafe (390 gu) 0,244 sn sürer, collecting'den (0,25 sn) kısa |
| 2026-10-16 | 3, 9 | Oyun ekranında metinler sarı çift alt çizgili / monospace görünüyordu (cihaz testi) | `GameScreen` kökü `Material(type: MaterialType.transparency)` ile sarıldı; tüm katmanlar `DefaultTextStyle`'ı temadan alır. Flame sayıları açık `TextStyle`'lı `TextPainter` kullandığı için etkilenmez. Widget testi (`game_screen_test`) sarmalayıcı kaldırılınca hatayı yakalıyor | Material atası olmayan `Text` Flutter'ın hata stiline düşer |
| 2026-10-16 | 2.3, 5.3 | Uzun kuyruk (yataya yakın tek top ~12 sn) tempoyu bozuyor | Yalnızca kare saatinde hızlanma (`FastForward`, `GameLoop`): faz `flying` iken geçen **gerçek** süre `kFastForwardAfter`=5 sn'yi aşınca çarpan `kFastForwardRamp`=1,5 sn'de 1 → `kFastForwardMax`=4'e doğrusal yükselir. Sayaç flying'e girişte, flying'den çıkışta ve her atışta sıfırlanır (99 toplu turda ~14 sn'lik firing sayılmaz). flying bitince çarpan hemen 1'e döner ve karenin kalan hızlı adımları atılır (collecting hızlanmaz). Birleşme animasyonu, kılavuz ve oyun sonu süreleri gerçek dt ile çalışır | Her adım yine `session.step()` (1/120 sn); simülasyon, replay ve stateHash değişmez (testle doğrulandı) |
| 2026-10-16 | 2.3 | Kare başına adım üst sınırı hızlanmayla nasıl uyumlu olur | Sınır = ceil(`kMaxStepsPerFrame` × çarpan), mutlak üst sınır `kMaxStepsPerFrameFast` = 8 × 4 = 32. Çarpan [1, 4] aralığına sıkıştırılır (NaN → 1). Fazlası, eskisi gibi atılır. İlk kare dt sınırı (1/30 sn) ölçeklemeden önce uygulanır | Sabit sayaçlı döngü, sonsuz döngü riski yok |
| 2026-10-16 | 12 | M2'de .arb içeriği | Yalnızca kullanılan anahtarlar: `tutorialAim`, `gameOverTitle`, `scoreLabel`, `playAgain`. Kalan anahtarlar ve l10n_test M4'te | Kullanılmayan anahtar eklenmedi |
| 2026-10-16 | 1.3 K3, 12 | Dil: PRD K3 "ilk sürüm yalnızca İngilizce" diyor | M3a'dan itibaren **tr + en** (ürün sahibinin talimatı). `app_tr.arb` eklendi; anahtar kümeleri testle eşit tutulur. K3'ü ürün sahibi güncelleyecek | Ürün sahibi talimatı |
| 2026-10-16 | 2.2, 7.4 | Tema dosyalarının yeri (PRD 2.2: `core/theme/`) | `lib/themes/` (GameTheme, HpRamp, ThemeRegistry, ThemeAccess, provider'lar, temalar). Eski `core/theme/palette.dart` ve `hp_colors.dart` kaldırıldı; renkler temadan gelir | Ürün sahibinin M3a talimatı |
| 2026-10-16 | 7.4.1 | Yer tutucu temalar (M3a) | candybust, pixeldrop, abyss, inkpaper: `isPlaceholder = true`, `isFree = false`. Orbitfall çizicisi + Orbitfall paletinin HSL ton/doygunluk varyantı; HP durakları, efektler ve sesler Orbitfall'ınki (ortak). Debug seçicide "yer tutucu" etiketiyle görünür. M3b–e'de gerçek temalarla değiştirilecek | Mimari şimdiden beş temayla sınanır |
| 2026-10-16 | 7.4.1, 10.1 | Tema kalıcılığı | Yeni anahtar `theme_id` (String, varsayılan yok → Orbitfall). Bilinmeyen, yanlış tipte ya da kilitli id Orbitfall'a düşer. `kAllThemesUnlocked = true`; `ThemeAccess` tek kapı. 10.1'e eklenmeli | PRD 7.4.1 |
| 2026-10-16 | 9.7 | Tema seçici | M3a'da yalnızca debug yapıda (`kDebugMode`) oyun ekranında, zemin çubuğunun sağında küçük düğme. Gerçek seçici M4'te Ayarlar'da | Ürün sahibi talimatı |
| 2026-10-16 | 8.1, 8.3 | Müzik biçimi ve uzunluğu (PRD: stereo OGG, 60–90 sn) | **Mono 22.05 kHz 16-bit WAV, ~31.3 sn kesintisiz döngü** (92 BPM, 12 ölçü). OGG ve 60–90 sn yok. Döngü başı ve sonu sıfır geçişinde, sınır farkı < tam ölçeğin %1'i (testli) | Tema başına ~2 MB bütçe: 60 sn stereo WAV ~10.6 MB; makinede OGG kodlayıcı yok. Ürün sahibi kısa WAV döngüsünü seçti. Orbitfall toplamı 1.60 MB |
| 2026-10-16 | 8.1 | Müzik ses seviyesi (PRD: ~−14 LUFS) | LUFS ölçümü yerine RMS −16 dBFS'e normalize, tepe ≤ −3 dBFS; oynatıcı seviyesi 0.35 | Betikte LUFS ölçer yok; RMS yaklaşık karşılık |
| 2026-10-16 | 8.1, 8.2 | Vuruş sesi: 8.1 "3 varyant sırayla döner", 8.2 "HP düştükçe perde yükselir" | 3 varyant (perde ×1, ×1.06, ×1.12) simülasyondan bağımsız sayaçla sırayla döner. HP'ye bağlı perde ve yıldızda ardışık perde artışı yapılmadı | 8.1 daha kesin; ses seçimi simülasyonu etkilememeli |
| 2026-10-16 | 8.1, 5.4.1 | Ses sınırları ve hızlanma | `kSfxMinGapMs` (50) ve `kSfxMaxConcurrent` (8) **duvar saatiyle** ölçülür, simülasyon adımıyla değil; eş zamanlılık her sesin dosya süresiyle sayılır. Müzik hızlanmadan etkilenmez. Hızlanmada karede yeni kıvılcım ≤ `kMaxSparksPerFrame` (24), yeni animasyon ≤ `kMaxAnimsPerFrame` (12). 32 adımlı karede ≤ 8 ses ve havuz sınırları testle doğrulandı | Ürün sahibi talimatı |
| 2026-10-16 | 7.3 | Havuzlar (PRD 7.3: 64; 2.7'de "en fazla 56 parçacık") | Ayrı havuzlar: kıvılcım `kParticlePool` = 64 (yalnızca kıvılcım), yok olma `kBreakAnimPool` = 56 (= 7 × 8 hedef), pop 16, "+3" yazısı 8. Hepsi sabit kapasiteli struct-of-arrays; doluyken en eski yuva yeniden kullanılır (taşma ve tahsis yok) | 2.7'deki 56'nın tahtadaki en fazla hedef sayısı olduğu varsayıldı |
| 2026-10-16 | 7.2, 5.11 | Belirtilmeyen efekt ölçüleri | Şok halkası 0.45 sn, ×2.2; "+3" yazısı 0.6 sn'de 30 gu yükselir, 20 gu yazı; satır ilerleme süpürmesi 0.3 sn; skor nabzı 0.2 sn ×1.15; vuruşta 3, kırılmada 8, yıldızda 6 kıvılcım, oyun sonunda hedef başına 2. Görsel rastgelelik ayrı Random (tohum 0x0B1026), oyun tohumuna dokunmaz | PRD yalnızca halka kıvılcımı ve ana süreleri veriyor |
| 2026-10-16 | 7.2 | Tehlike uyarısı | 7. satırda hedef varken zemin çubuğunun üst kenarı 1.2 sn döngüyle tehlike renginde nefes alır (6 gu şerit) | PRD 7.2 |
| 2026-10-16 | 9.1 | Native splash | Ürün sahibinin tüm oyunlarında ortak marka: SudokuPure v2.0.0'ın `flutter_native_splash` yapılandırması birebir uyarlandı (renk `#000000`, logo `assets/brand/splash-logo-circular.png`, Android 12 dahil). Yapılandırma talimatta yapıştırılmamıştı; `C:\Users\Dogan\Desktop\MobileProject\SudokuPure V2` altındaki üç projenin pubspec'inden (üçü aynı) okundu. Sudoku yapılandırmasına ek olarak `web: false` (web desteklenmiyor). `NewSplashLogo.jpeg` yedek, kullanılmıyor (gerçek boyutu 2048×2048) | Ürün sahibi talimatı |
| 2026-10-16 | 7.4 | Uygulama ikonu | Kaynak: ürün sahibinin tasarımı `assets/brand/app-icon-master.png` (1024, tam kare; uzantısı .png ama içeriği JPEG). `tools/icon/make_icon.py` (Pillow) üretir. Android: adaptive ön plan = master %78 ölçekli, ortada, 24 px yumuşak kenar, köşeler şeffaf (`adaptive_icon_foreground_inset: 0`); arka plan = master üst/alt kenar renklerinden (#081027 → #1E2458) dikey degrade PNG; eski cihazlar için master tam kare. iOS: master, RGB (alfa yok), köşe yuvarlama yok, `remove_alpha_ios`. Mağaza: `assets/store/play_icon_512.png` (32-bit), `appstore_icon_1024.png` (alfa yok), uygulamaya gömülmez. Web ikonu üretilmez | Ürün sahibinin tasarımı ve talimatı |
| 2026-10-16 | 1.1, 2.6, 7.4 | Referans oyundan görsel ayrışma (kopya/ban riski) | Tüm temalarda: (1) HUD/zemin çubukları dolu renk değil; yarı saydam nötre yakın koyu yüzey (Orbitfall `#8C0B0A18` / `#990B0A18`), ince açık kenar (`#66E6E1FF`), ortada tema vurgusu (Orbitfall nane `#5CF2A0`); referanstaki mavi (`#3F5AA6`) ve dolu çubuktan uzak. Yer tutucularda HUD yüzeyi ve kenarı ton kaydırmasından muaf. (2) Düşük HP (1–2) kırmızı/pembe değil, turuncu/amber (Orbitfall c0 `#D4570F`, c1 `#B86E00`). (3) Arka planda tek yönlü mavi spot ışığı yok; dikey degrade + yıldız tozu. `reference_distinction_test` denetler | Ürün sahibi talimatı |
| 2026-10-16 | 9.2, 9.4, 9.5 | M4 menü/oynat düğmeleri (not) | Orbitfall'da ve diğer temalarda **krem hap şeklinde düğme ve mavi yuvarlak düğme kullanılmayacak** (referans oyunun görünüşü). Düğmeler tema paletinden, farklı biçimde tasarlanacak | Ürün sahibi talimatı; M4'te uygulanacak |
| 2026-10-16 | 2.7 | Web | PRD'ye göre web desteklenmiyor: `flutter_native_splash` `web: false`, `flutter_launcher_icons` `web: generate: false`. Daha önce üretilen web splash dosyaları geri alındı | Ürün sahibi talimatı |
| 2026-10-16 | 2.6 | "Görsel varlık dosyası yok" kuralı ve ikon/splash PNG'leri | Oyun içinde görsel dosyası yok (her şey Canvas). İkon ve splash PNG'leri yalnızca platform üreticilerinin kaynağıdır, `flutter.assets`'e eklenmez | Platformlar ikon/splash için raster dosya ister |
| 2026-10-16 | 7.4 | OFL yazı tipi | M3a kapsamında değil; sistem yazı tipi sürüyor | M3a talimatında yok |
| 2026-10-16 | 8.3 | Duraklatmada müziğin %40'a inmesi | M3a'da yok (duraklatma menüsü M4'te). Arka planda duraklama ve öne gelince sürme var | Duraklatma menüsü henüz yok |

## 4. Kullanıcıya sorulacaklar

Cevabı beklenen sorular (yapay zeka işe devam eder, cevap gelince karar tablosunu günceller):

- [ ] Uygulama adı ve logo yönü
- [ ] Paket kimliği (bundle id) ve Firebase projesi
- [ ] Gizlilik politikası adresi (kPrivacyUrl)
- [ ] 9.7 gizlilik bağlantısını "harici tarayıcıda açmak" için `url_launcher` gerekir ama 2.1 tablosunda yok. M4'te eklensin mi?
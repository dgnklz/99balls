# Çalışma Kaydı (PROGRESS)

## Düzen
- Tek doğru kaynak PRD (Claude Docs projesi a501ae90-704e-4d32-9fb6-6bfdbd3da5bf, kopyası docs/PRD.md). Karar ve varsayımlar: docs/ASSUMPTIONS.md. Tema notları: docs/THEME.md.
- Akış: tek prompt -> IDE'de plan modunda plan -> inceleme/onay -> uygulama -> cihazda test -> commit/push (commit'i kullanıcı atar).
- lib/game_core saf Dart ve deterministik; temalar yalnızca görünüm ve ses. Sabitler game_config.dart'ta, metinler .arb'da. Gizli anahtar commit edilmez.

## Bitenler
- M1: game_core (sabit adım 1/120 sn, SplitMix64, tam sayı nişan).
- M2: Flame prototipi; cihaz düzeltmeleri (nişan çizgisi rampası, ince nişan, top birleşme animasyonu, uzun uçuşta otomatik hızlanma: 8 sn sonra x4).
- M3a: 5 temalı mimari (Orbitfall tam; Candy Burst, Pixel Drop, Abyss, Ink & Paper yer tutucu), ses altyapısı (mono 22.05 kHz WAV, ~32 sn müzik döngüsü), marka splash'ı, ikon (assets/brand/app-icon-master.png'den üretilir), referans oyundan görsel ayrışma.
- M3a düzeltme turları: zemin neonu atış noktasını izler, "+3" yazısı okunur, ses marjı (SFX 0.8), tam ekran (immersive sticky), dönüşte hızlı gizleme, kenar koruma şeridi.
- M3b Candy Burst: tam tema ve kendi sesleri; ortak çizim `BaseThemeRenderer`'a taşındı.
- Boost butonu: otomatik hızlanma yerine oyuncu kontrollü "»" butonu (uçuş 8 sn'yi aşınca, 4×, yalnızca kare saati).
- M3c Pixel Drop: tam tema (piksel silüet hedef, özgün 3×5 rakam), çiptün sesler.
- M3p performans: karede bulanıklık yok, parıltılar pişmiş resim, Pixel Drop tek atlasla toplu çizim; J8'de gerçekçi tahta üç temada ≤ 33 ms. Ölçüm aracı tools/bench/.
- Geliştirici aracı: debug/profile yapıda "Yüksek HP tahtası" (tema seçici penceresinde).

## Sıradaki
- M3d: Abyss (görsel, efekt, ses).
- M3e: Ink & Paper (görsel, efekt, ses).
- M4: ana menü, ayarlar (tema seçici dahil), dil penceresi, url_launcher, en iyi skor (debug oyununda yazılmaz), boost ilk kullanım ipucu.
- M5: geri bildirim (EmailJS), çıkış, yaşam döngüsü, duraklatmada müzik %40, OFL yazı tipi.
- M6: kabul listesi, mağaza hazırlığı, iOS ana ekran göstergesi/sistem hareketleri (Mac gerekir), ad ve ikon benzerlik kontrolü.
- Faz 2 (M7-M9): giriş, günde 3 hak, haftalık sıralama, replay ile yerel hile önleme. Faz 1 bitmeden başlamaz.

## Önemli kararlar
- Temalar: 5 tane, v1'de hepsi açık (kAllThemesUnlocked), sonra Orbitfall ücretsiz diğerleri üyelik. Üyelik için mağaza faturalandırması ve doğrulama gerekir.
- Ad ve mağaza metinlerinde "99 Balls" ve "Evo" geçmez. Referans oyunun HUD/renk/menü stiline benzetilmez.
- Android: durum ve gezinti çubukları gizli; kenarlardan başlayan dokunuş nişan sayılmaz.

## Açık notlar
- Repo public; gizli anahtar, google-services.json, videolar commit edilmez.
- Kayıt defterinin sonuna her tur için tarih + 2-3 satır ekle.

## Kayıt
- 2026-10-16 · M3b Candy Burst: tam tema (erik moru zemin + kayan şerit/serpinti deseni, parlak vurgulu spiralli şeker hedefler, sedefli top, sakız halkası, konfeti/serpinti efektleri) ve kendi sesleri (118 BPM marimba döngüsü + 13 SFX, 1.67 MB). Kimlik `candyburst` olarak düzeltildi.
- Ortak çizim `BaseThemeRenderer`'a taşındı; Orbitfall çizim golden'ı (64 çağrı) birebir aynı. analyze temiz, 333 test yeşil; game_core değişmedi.
- Cihazda bakılacak: c2 limon-yeşil ve parlak vurgu ile rakam okunurluğu (öncelikli), FPS, döngü eki, tema geçişi.
- 2026-10-16 · Boost butonu: otomatik hızlanma kalktı; uçuş 8 sn'yi aşınca sağ altta "»" butonu belirir (tek nabız), basınca rampayla 4×, tekrar basınca 1×; uçuş bitince kaybolur ve sıfırlanır. Yalnızca kare saati (skor/stateHash/replay aynı, testli). Basış nişana düşmez (solarken de yutulur).
- Not: boost ilk kullanım ipucu (ne işe yaradığını anlatan metin) M4/M5'te.
- 2026-10-16 · M3c Pixel Drop: tam tema. Koyu kahve-zeytin zemin + tarama çizgisi + hücre adımlı düşen bloklar; 2 gu ızgarada piksel hedef (silüet çarpışma dairesinin içinde, 48 gu), açık kenar halkası, özgün 3×5 piksel rakam (1–2 hane %50, 3 hane %40 yükseklik); piksel top/halka/yıldız, kare kıvılcım. Kendi sesleri: bant sınırlı darbe + üçgen çiptün, 124 BPM D minör (dorian/aeolian), 1.59 MB.
- analyze temiz, 393 test yeşil; game_core değişmedi; Orbitfall/Candy ses dosyaları bayt bayt aynı.
- Profil ölçümü (Galaxy J8): M3c'deki 83/228/236 ms notunun yerini M3p sonuçları aldı (aşağıda).
- Cihazda bakılacak: 3 haneli HP okunuyor mu, c10 (mürdüm) hedef zeminden ayrışıyor mu, müzik döngü eki ve tını (keskin değil mi), Pixel Drop FPS (yeniden ölçüm).
- 2026-10-16 · M3p performans (J8, Impeller, raster ort): rakam gölgesi bulanıksız; halka/HUD parıltısı pişmiş resimden (Pixel'de piksel hale/şerit); Pixel Drop'ta hedef/top/kıvılcım/bloklar tek drawRawAtlas (cihaz pikseline oturur). Gerçekçi tahta: Orbitfall 99 → 15 ms, Candy 86 → 26 ms, Pixel 35 → 9 ms; en kötü: 222 → 22, 133 → 34, 45 → 10 ms. Hedef (gerçekçi ≤ 33, en kötü ≤ 50) üçünde de tuttu.
- Orbitfall/Candy toplu çizimi ertelendi (hedefin altında). Skia belirgin hızlı ama yalnızca raporlandı (Impeller kapatma Flutter'da kullanımdan kalkıyor). Orbitfall golden'ı güncellendi (yalnız parıltı çağrıları). Ölçüm aracı: tools/bench/ (README). game_core değişmedi.
- 2026-10-16 · Yüksek HP debug tahtası: tema seçici (artık debug + profile, `kDebugToolsEnabled`) penceresinin altında "Yüksek HP tahtası". Sabit tahta: her HP durağının sınırları, 99 ve 100/111/148/188/198, 2 halka, 1 yıldız; 99 top, tur 175 (`GameSession.forTest`, game_core değişmedi).
- Debug oyunu kalıcı veriye yazmaz (`BallGame.isDebugGame`; tutorial_seen korunur). M4'te best_score/games_played yazımı bu koşula uyacak. Release'te seçici widget ağacında yok (testli).
- Cihazda bakılacak: her temada 3 haneli rakamlar ve c10 (50+), ardışık duraklar (24/26/27, 32/34/36, 44/46/48/50), HUD'da 3 haneli sayaç, profilde 99 topla FPS.

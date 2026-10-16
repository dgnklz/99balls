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

## Sıradaki
- M3b-e: Candy Burst, Pixel Drop, Abyss, Ink & Paper (görsel, efekt, ses).
- M4: ana menü, ayarlar (tema seçici dahil), dil penceresi, url_launcher, geri bildirim (EmailJS).
- M5: yaşam döngüsü, duraklatmada müzik %40, OFL yazı tipi.
- M6: performans, mağaza hazırlığı, iOS ana ekran göstergesi/sistem hareketleri (Mac gerekir), ad ve ikon benzerlik kontrolü.
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

# Temalar (PRD 7.4, 7.4.1)

Beş tema vardır; temalar yalnızca görünüm ve sestir. Çarpışma yarıçapları, yerleşim,
kurallar, replay, skor ve `stateHash` hiçbir temada değişmez (testle doğrulanır).

| Tema | Durum | Konsept |
|---|---|---|
| Orbitfall | **Tam**, ücretsiz | Derin uzay ve yörüngeler |
| Candy Burst | **Tam** (M3b) | Şeker/tatlı dünyası |
| Pixel Drop | **Tam** (M3c) | Kodla çizilen piksel dünyası |
| Abyss | Yer tutucu | M3d'de |
| Ink & Paper | Yer tutucu | M3e'de |

Yer tutucular (Abyss, Ink & Paper) kayıtlı ve seçilebilir, ama henüz Orbitfall çizicisini, paletinin ton/doygunluk
varyantını ve Orbitfall seslerini kullanır (`lib/themes/placeholder/`).

## Orbitfall — gerekçe

- **Neden uzay:** Sabit hızla seken, düz çizgilerle hareket eden toplar yerçekimsiz bir
  ortamı çağrıştırır; "top yörüngeye fırlatılır" metaforu nişan çizgisiyle uyumludur.
- **Arka plan:** Derin lacivert degrade (#0B1026 → #1A1F4D) ve iki katmanlı yavaşça kayan
  yıldız tozu. Koyu zemin renkli hedefleri öne çıkarır (7.4); hareket hafiftir, oyunu
  dikkat dağıtmadan canlı tutar.
- **Atılan top:** Neredeyse beyaz camgöbeği halka. **Toplanabilir halka:** nane yeşili,
  parlayan ve %38 daha büyük — atılan toptan hızla ayırt edilir (7.4).
- **Yıldız:** Altın sarısı, nabız atan beş köşeli yıldız (5.11).
- **HP durakları:** Sıcak (turuncu, amber, zeytin-altın) → soğuk (yeşil, turkuaz, mavi) →
  indigo, eflatun, magenta. Düşük HP bilinçli olarak kırmızı/pembe değil. Beyaz rakamla her
  HP'de en az 3:1 kontrast (testli).
- **HUD ve zemin çubukları:** Dolu renk çubuk değil; yarı saydam, nötre yakın koyu yüzey
  (#0B0A18, %55–60 opak), oyun alanına bakan ince açık kenar çizgisi ve ortasında nane rengi
  vurgu.
- **Efektler:** Vuruşta hedef nabzı ve camgöbeği kıvılcım; kırılmada madeni para dönüşü
  ve "yıldız tozu"; halka/yıldızda büyüyüp solma; satır ilerlemede zemin kenarında ışık
  süpürmesi; oyun sonunda kırmızı şok halkaları; 7. satırda tehlike nefesi.
- **Ses:** Yumuşak sinüs tabanlı "plink", arpej ve pad'ler; sakin 92 BPM uzay ambiyansı.

## Candy Burst — gerekçe

- **Neden şeker:** Renkli, numaralı toplar zaten şekerlemeyi çağrıştırır; kırılma "şeker
  çıtırtısı", toplanan halka "sakız baloncuğu" olur. Orbitfall'ın sakin uzayına karşı neşeli,
  oyuncu bir ikinci kimlik.
- **Arka plan:** Derin erik/böğürtlen moru degrade (#2A1040 → #4B1F6F). Üstünde iki yavaş kayan
  desen katmanı: çok soluk 45° şeker şeritleri ve beş pastel renkte küçük serpinti çubukları
  (bir kez kaydedilmiş Picture; karede yalnızca kaydırma). Lacivert uzaydan ve referansın
  siyah + mavi spot zemininden ayrışır.
- **Hedefler:** Yuvarlak şekerler: sol üstte parlak vurgu, dış bantta ince spiral, beyaz rakam.
  HP: mandalina → kayısı → limon-yeşil → elma → nane → turkuaz → gök → yaban mersini → üzüm →
  erik-leylak → gül-pembe. Düşük HP turuncu; beyazla her HP'de en az 3:1 (testli).
- **Top:** Dolu, sedefli beyaz (ince leylak kenar, parlak nokta). **Halka:** nane sakız halkası,
  içinde ince şeftali çizgi; içi boş ve %38 büyük, toptan hızla ayırt edilir. **Yıldız:** altın,
  beyaz şeker kenarlı.
- **HUD:** Yarı saydam koyu erik yüzey, ince açık pembemsi kenar, gül-şeftali vurgu.
- **Efektler:** Vuruşta konfeti renginde serpinti, kırılmada şeker rengi + konfeti dönüşümlü
  serpinti ve parlak vurgulu dönen şeker parçası; halka/yıldızda kendi renginde serpinti.
  Havuz ve kare bütçeleri Orbitfall ile aynı.
- **Ses:** Marimba/ksilofon, pizzicato bas, baloncuk pop ve şeker çıtırtısı; 118 BPM majör
  pentatonik neşeli döngü.

## Pixel Drop — gerekçe

- **Neden piksel:** Izgaraya dizilmiş numaralı toplar ve basamak basamak inen satırlar
  zaten eski bir ekranın hücrelerini çağrıştırır. Orbitfall'ın yumuşak uzayına ve Candy
  Burst'ün parlak şekerine karşı keskin kenarlı, sade, "ekran pikseli" kimliği. Tüm şekiller
  kodla, 2 gu'luk tek bir ızgaraya oturtularak çizilir; görsel dosyası yoktur.
- **Arka plan:** Koyu kahve-zeytin degrade (#17140D → #2A2616). Mavi değil, tek ton yeşil
  değil: dört tonlu yeşil el konsolu paletini çağrıştırmaz (zemin tonu 30–60°, testli).
  Petrol-teal elendi, çünkü orta HP durakları (deniz, petrol) ile karışıyordu. Üstünde sabit,
  çok soluk yatay tarama çizgileri ve hücre adımlarıyla yavaşça düşen seyrek piksel blokları
  ("drop"; amber, camgöbeği, orkide, krem). İkisi de bir kez kaydedilmiş Picture.
- **Hedefler:** Piksel silüet; yalnızca tamamı çarpışma dairesinin içinde kalan hücreler
  (24 hücre = 48 gu, eksenlerde 1 gu içeride, alanın %89.6'sı). Dolgu HP rengi; 1 hücrelik
  açık kenar halkası (HP rengi + %35 beyaz; zeminden her HP'de ≥ 3:1, testli); halkanın hemen
  içinde üst-sol parlak yay. Rakamlar özgün 3×5 piksel glif, hedef merkezine hizalı:
  1–2 hanede 5 gu piksel (yükseklik çapın %50'si), 3 hanede 4 gu piksel (%40). Rakamlar her
  HP'de (1–198) açık kenarın içinde kalır.
- **HP durakları:** mandalina → amber → hardal → çimen → deniz → petrol → gök → çivit → mor →
  orkide → mürdüm. Kenar yumuşatmasız rakam için Candy Burst'ten koyu ve doygun: beyazla her
  durakta ≥ 4.5:1 (en düşük c0 4.79). Düşük HP turuncu (24°).
- **Top ve halka:** Top sıcak beyaz piksel orb + tek parlak hücre. Halka camgöbeği, içi boş,
  2 hücre kalın, %38 büyük; parıltısı 0.5 sn'lik iki kare arasında adımlı yanıp söner.
  **Yıldız:** altın piksel yıldız; parlak karede gövdesinde tek beyaz hücre.
- **HUD:** Yarı saydam koyu kahve yüzey (#120F09, %55/%60), ince krem kenar, amber vurgu.
  Boost butonu açıkken amber dolgu üstünde koyu "»" (11:1).
- **Efektler:** Kıvılcımlar ızgaraya oturan kare pikseller (hareket hücre hücre görünür);
  vuruş ve kırılmada blok renkleriyle konfeti. Sayılar ve havuz bütçesi Candy Burst ile aynı.
- **Ses:** Yumuşatılmış çiptün: bant sınırlı darbe (%25 ve %50) ve üçgen dalga, filtreli
  gürültü ritim. 124 BPM, D minör (dorian/aeolian karışımı), Dm7–G7–B♭maj7–Am7 × 4. Melodi
  bu proje için yazıldı, senkoplu ve geniş aralıklı; bilinen çiptün temalarına (Korobeiniki/
  Tetris dahil) benzememesi gözetildi: Korobeiniki'nin noktalı 2/4 ritmi, A minör inen dizisi
  ve cümle yapısı kullanılmadı. Kesin değerlendirme kulakla (cihazda) yapılmalı.

## Referans oyundan ayrışma

Referans oyunun görünüşü: siyaha yakın zemin + mavi spot ışığı, kırmızı/pembe dolu hedefler,
mavi dolu üst/alt çubuklar, krem hap şeklinde oynat düğmesi. Tüm temalar bunlardan ayrışır:
yönlü spot ışığı yok (yalnızca dikey degrade + yıldız tozu), düşük HP turuncu/amber, çubuklar
yarı saydam koyu yüzey; M4'teki menü düğmeleri krem hap ya da mavi yuvarlak olmayacak. Oyun içi boost butonu da bu
kurala uyar: kapalıyken yarı saydam koyu yüzey + ince açık kenar + vurgu renginde "»", açıkken
tema vurgusu dolgu (hiçbir temada mavi değil).
`test/themes/reference_distinction_test.dart` bu kuralları her tema için denetler;
`test/themes/boost_contrast_test.dart` boost butonunun her temada okunur (≥ 3:1) ve maviden
uzak olduğunu denetler.

# Temalar (PRD 7.4, 7.4.1)

Beş tema vardır; temalar yalnızca görünüm ve sestir. Çarpışma yarıçapları, yerleşim,
kurallar, replay, skor ve `stateHash` hiçbir temada değişmez (testle doğrulanır).

| Tema | Durum | Konsept |
|---|---|---|
| Orbitfall | **Tam**, ücretsiz | Derin uzay ve yörüngeler |
| Candy Burst | **Tam** (M3b) | Şeker/tatlı dünyası |
| Pixel Drop | **Tam** (M3c) | Kodla çizilen piksel dünyası |
| Abyss | **Tam** (M3d) | Okyanus dibi, biyolüminesans |
| Ink & Paper | **Tam** (M3e) | Sumi-e: kâğıt üstünde fırça ve mürekkep (tek açık zeminli tema) |

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

## Abyss — gerekçe

- **Neden okyanus dibi:** Yavaşça inen satırlar derine batan bir dünyayı, sekip duran toplar
  karanlıkta yanıp sönen ışık noktalarını çağrıştırır. Sakin, derin ve gizemli bir kimlik:
  Orbitfall'ın uzayına benzemesin diye ışık yalnızca canlılardan gelir (hale, parlak kenar);
  yıldız ya da yönlü ışık yoktur.
- **Arka plan:** Siyaha yakın petrol-deniz yeşili degrade (#031512 → #0A2A2A, ton 170–180°).
  Lacivert/indigo değil (Orbitfall ~230°), kahve-zeytin değil (Pixel 30–60°); ton bandı testli.
  Üstünde yavaşça **yükselen** halka kabarcıklar (bir kez kaydedilmiş Picture) ve çok yavaş
  **inen** plankton tozu ("deniz karı"; gerçekte çöker, zıt akış derinlik hissi verir). Hüzme,
  spot ya da yönlü ışık yok.
- **Hedefler:** Denizanası: üstte kubbe, düz yanlar, 4 dalgalı etek ve 3 kısa S kıvrımlı dokunaç.
  Gövde HP renginde; iç kenar ve dokunaçlar HP rengi + %45 beyaz (biyolüminesan kenar);
  kubbede parlak vurgu; HP renginde yumuşak hale. Silüetin tamamı çarpışma dairesinin içinde
  (testli); hale (≤ 28 gu) çarpışma alanını sezdirir, komşu hücreye değmez. Rakamlar ortak
  beyaz, bulanıksız gölgeli; 1–2 ve 3 hane kutuları gövdenin dolu kısmında (testli).
  Alternatif "parlak kabarcık" (daire) Orbitfall/Candy dairelerine fazla benzediği için elendi.
- **HP durakları:** bakır-turuncu (fener balığı ışığı) → amber → yosun-sarı → deniz marulu →
  deniz yeşili → lagün → gök → derin mavi → çivit-mor → mor → magenta. Zemin tonu (170–180°)
  bilerek boş bırakıldı: c3 sarıya (90°), c5 maviye (202°) kayık; her HP'de açık kenar zeminden
  ≥ 5.4:1. Beyaz rakamla her durakta ≥ 3.57:1; düşük HP turuncu (21.5°). Aynı indeksteki
  Orbitfall/Candy/Pixel durağına RGB ≥ 31.
- **Top ve halka:** Top soluk aqua-beyaz çekirdek + pişmiş yumuşak hale. Halka fosforlu limon
  (#C8FF6E), içi boş, %38 büyük, içinde ince "jöle zarı" çizgisi, 1.6 sn'lik opaklık nabzı;
  diğer temaların halkalarından, toptan, yıldızdan ve HP duraklarından RGB ≥ 97 uzak.
  **Yıldız:** yuvarlak kollu mercan-altın deniz yıldızı, ortasında açık nokta.
- **HUD:** Yarı saydam koyu petrol yüzey (#021210, %55/%60), ince açık kenar, biyolüminesan aqua
  vurgu (#5FF5E0; zemine 11:1, referans maviye uzak).
- **Efektler:** Kıvılcımlar kabarcık (halka + parlak nokta). Konfeti: aqua, fosforlu limon,
  lavanta, inci. Sayılar Candy/Pixel ile aynı (4/10/8/8/2).
- **Performans:** Hale, gövde, kenar+dokunaç, vurgu, top ve kabarcık tek bir pürüzsüz beyaz maske
  atlasında (`lib/themes/shared/sprite_atlas.dart`); her grup tek `drawRawAtlas` (56 hedef = 1
  çağrı + rakamlar). Bulanıklık yalnızca atlas üretiminde.
- **Ses:** Su altı: alçak, yavaş filtre süpürmeli pad; perdesi kayan su damlası; sonar ping;
  kabarcık kümeleri. 75 BPM, F♯ minör (dorian renkli), F♯m9–Dmaj7–Bm9–C♯m7–Amaj7. Seyrek, geniş
  aralıklı özgün damla melodisi; yarım ton ostinato ya da bilinen su altı/köpekbalığı temalarına
  benzerlik yok. Telefon hoparlörü için 200 Hz altı tek başına yok (müzikte %5.5); SFX'lerin
  ana enerjisi 300 Hz–3 kHz. Kesin değerlendirme kulakla (cihazda) yapılmalı.

## Ink & Paper — gerekçe

- **Neden mürekkep ve kâğıt:** Diğer dört tema koyu; Ink & Paper bilerek **açık** zeminli tek temadır
  (sumi-e, el yapımı kâğıt). Sayılı toplar kâğıda düşmüş pigment lekeleri, atılan top bir mürekkep damlası,
  toplanan halka bir hanko mührüdür. Sakin, el yapımı, sessiz ("ma") bir kimlik. PRD 7.4'ün "koyu zemin"
  maddesine bilinçli istisnadır (ASSUMPTIONS).
- **Arka plan:** Sıcak krem ham kâğıt degradesi (#F1E8D6 → #E4D6BC) + bir kez pişirilmiş ince gren ve kâğıt
  lifleri (tek resim); üstünde çok yavaş kayan, çok soluk mürekkep-yıkama lekeleri. Mavi spot ya da yönlü
  ışık yok; referansın siyah + mavi zeminine hiç benzemez.
- **Hedefler:** Mürekkep-yıkama pigment disk: kenarı hafif düzensiz fırça diski (3 varyant, sütuna göre),
  içinde koyu, incelen, açıklıklı **enso** fırça kenarı (HP + %45 sumi), kuru fırça dokusu ve HP renginde
  kâğıda yayılma (nijimi). Silüet çarpışma dairesinin içinde (R ≤ 22.7 < 25, testli); gövde rakam
  bölgesinde tam opak, doku yalnızca koyulaştırır.
- **HP durakları:** aşı-kehribar → kuchiba hardal → yosun → çam iğnesi → tokusa → seiheki → hanada →
  ai (çivit) → kikyō → murasaki → koyu gül kurusu. Açık zeminde okunsun diye koyu, doygun pigmentler:
  beyaz rakam her HP'de ≥ 4.89:1, pigment kâğıda ≥ 3.41:1, enso kenarı ≥ 6.2:1. Düşük HP turuncu-kehribar
  (33.6°), kırmızı/pembe değil.
- **Top ve halka:** Top koyu sumi damlası (#1E1B18) + hafif parlak nokta (kâğıda 12–14:1). Halka hanko
  vermilyonu (#D23A20) fırça halka: içi boş, %38 büyük, uçları üst üste binen kalın-ince fırça izi, kâğıtta
  pigment yayılması gibi hafif parıltı; toptan (koyu dolu damla) ve hedeflerden (dolu disk) hemen ayrılır.
  **Yıldız:** altın yaprak beş köşeli, açık altın lekecikli, ince sumi kenarlı (altın tek başına kâğıtta
  zayıf, kenar 12:1).
- **HUD:** Açık zeminde de referans ayrışma kuralı: yarı saydam koyu sumi yüzey (#1E1A16, %70; krem
  üstünde bileşik ≈ #5E5850, beyaz HUD rakamı 7:1), ince krem kenar, altın yaprak vurgu (#E2B65C). Zemin
  çubuğundaki top simgesi kâğıt diski üstünde sumi damla. Boost açıkken altın dolgu üstünde koyu "»" (9:1);
  öğretici yazı ve el koyu mürekkep (10.7:1).
- **Efektler:** Vuruşta mürekkep damlacıkları (sumi, ai, bengara, kincha), kırılmada mürekkep sıçraması +
  dönen pigment diski; halka/yıldızda kendi renginde damlalar ve büyüyüp solan fırça izi (mürekkep dalgası);
  damlalar hız yönünde uzamış. Satır ilerlemede kâğıt kenarında kuru fırça darbesi süpürmesi.
- **Tehlike ve oyun sonu:** Kırmızı yerine **koyu mürekkep**: 7. satırda zemin kenarından yukarı mürekkep
  sızar (nefes alır), oyun sonunda son satır sumiye boyanır ve sumi şok halkaları yayılır. Gerekçe: kâğıtta
  en güçlü sinyal koyuluktur (sumi kâğıda 10.7:1, kırmızı 3.4–3.9:1) ve bu temada kırmızı halkanın (ödül)
  rengidir; tehlike de kırmızı olsa karışırdı.
- **Sistem çubukları:** Simgeler köşenin gerçek rengine göre seçilir: telefonlarda köşe sumi çubuk → açık
  simge; yan letterbox'lı geniş ekranlarda köşe krem → koyu simge.
- **Performans:** Kâğıt tek resim (≤ 2 px/gu), lekeler düşük çözünürlüklü ayrı atlasta, hedef/top/halka/
  yıldız/damla ortak beyaz maske atlasında; her grup tek `drawRawAtlas`. Bulanıklık yalnızca pişirmede;
  `BlendMode.multiply` yok (Impeller'da pahalı).
- **Ses:** Sumi-e atölyesi: koto (oshide süslemeli), sho benzeri kamış kümesi, nefesli shakuhachi, mokugyo
  ve hyoshigi; fırçanın kâğıtta "fiş"i, mürekkep lekesinin "şlap"ı, tek orin vuruşu (yıldız). 84 BPM,
  11 ölçü (31.4 sn), D in-sen (D–E♭–G–A–C), A + A′ + sessizliğe açılan koda. Abyss'in perde kaydırmalı
  damla + yankısı ve F♯ minörü kullanılmadı. Müzikte 200 Hz altı yok; SFX'lerin ana bandı 294 Hz–2.8 kHz.
  Kesin değerlendirme kulakla (cihazda) yapılmalı.

## Referans oyundan ayrışma

Referans oyunun görünüşü: siyaha yakın zemin + mavi spot ışığı, kırmızı/pembe dolu hedefler,
mavi dolu üst/alt çubuklar, krem hap şeklinde oynat düğmesi. Tüm temalar bunlardan ayrışır:
yönlü spot ışığı yok (yalnızca dikey degrade + yıldız tozu), düşük HP turuncu/amber, çubuklar
yarı saydam koyu yüzey; M4'teki menü düğmeleri krem hap ya da mavi yuvarlak olmayacak. Oyun içi boost butonu da bu
kurala uyar: kapalıyken yarı saydam koyu yüzey + ince açık kenar + vurgu renginde "»", açıkken
tema vurgusu dolgu (hiçbir temada mavi değil); açıkken "»" rengi `onAccent`'tir (koyu temalarda zemin
rengi, Ink & Paper'da sumi).
`test/themes/reference_distinction_test.dart` bu kuralları her tema için denetler;
`test/themes/boost_contrast_test.dart` boost butonunun her temada okunur (≥ 3:1; kapalı hal zeminin
üstündeki yarı saydam daireye göre) ve maviden uzak olduğunu denetler.

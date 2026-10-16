# Temalar (PRD 7.4, 7.4.1)

Beş tema vardır; temalar yalnızca görünüm ve sestir. Çarpışma yarıçapları, yerleşim,
kurallar, replay, skor ve `stateHash` hiçbir temada değişmez (testle doğrulanır).

| Tema | Durum | Konsept |
|---|---|---|
| Orbitfall | **Tam**, ücretsiz | Derin uzay ve yörüngeler |
| Candy Burst | **Tam** (M3b) | Şeker/tatlı dünyası |
| Pixel Drop | Yer tutucu | M3c'de |
| Abyss | Yer tutucu | M3d'de |
| Ink & Paper | Yer tutucu | M3e'de |

Yer tutucular kayıtlı ve seçilebilir, ama henüz Orbitfall çizicisini, paletinin ton/doygunluk
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

## Referans oyundan ayrışma

Referans oyunun görünüşü: siyaha yakın zemin + mavi spot ışığı, kırmızı/pembe dolu hedefler,
mavi dolu üst/alt çubuklar, krem hap şeklinde oynat düğmesi. Tüm temalar bunlardan ayrışır:
yönlü spot ışığı yok (yalnızca dikey degrade + yıldız tozu), düşük HP turuncu/amber, çubuklar
yarı saydam koyu yüzey; M4'teki menü düğmeleri krem hap ya da mavi yuvarlak olmayacak.
`test/themes/reference_distinction_test.dart` bu kuralları her tema için denetler.
- **Efektler:** Vuruşta hedef nabzı ve camgöbeği kıvılcım; kırılmada madeni para dönüşü
  ve "yıldız tozu"; halka/yıldızda büyüyüp solma; satır ilerlemede zemin kenarında ışık
  süpürmesi; oyun sonunda kırmızı şok halkaları; 7. satırda tehlike nefesi.
- **Ses:** Yumuşak sinüs tabanlı "plink", arpej ve pad'ler; sakin 92 BPM uzay ambiyansı.

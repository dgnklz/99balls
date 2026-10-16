# Temalar (PRD 7.4, 7.4.1)

Beş tema vardır; temalar yalnızca görünüm ve sestir. Çarpışma yarıçapları, yerleşim,
kurallar, replay, skor ve `stateHash` hiçbir temada değişmez (testle doğrulanır).

| Tema | Durum (M3a) | Konsept |
|---|---|---|
| Orbitfall | **Tam**, ücretsiz | Derin uzay ve yörüngeler |
| Candy Burst | Yer tutucu | M3b'de |
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

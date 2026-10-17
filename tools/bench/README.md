# Tema çizim yükü ölçümü

`theme_bench.dart`, tema çizicilerini oyunla aynı çağrılarla tam ekranda çizer ve her kare için
`FrameTiming`'den UI (build) ve raster sürelerini toplar. Uygulamaya gömülmez (`lib/` dışında).

## Çalıştırma

Gerçek cihazda, profil modunda (debug ölçümü anlamsızdır):

```sh
flutter run --profile -d <cihaz> -t tools/bench/theme_bench.dart
# Skia ile karşılaştırma (yalnızca ölçüm bayrağı; uygulamada ayar yok):
flutter run --profile -d <cihaz> -t tools/bench/theme_bench.dart --no-enable-impeller
# Yalnızca bir tema (id: orbitfall, candyburst, pixeldrop, abyss, inkpaper):
flutter run --profile -d <cihaz> -t tools/bench/theme_bench.dart --dart-define=BENCH_THEME=inkpaper
```

- Varsayılan (BENCH_THEME verilmezse) beş temanın hepsi ölçülür: ~4,8 dk (41 aşama × 7 sn).
  Tek tema ~1 dk sürer (9 aşama). Ekran zaman aşımı koşudan uzun olmalı.
- Ekran açık ve kilitsiz olmalı; kapalı ekranda kare çizilmez.
- Sonuçlar konsolda ve logcat'te `BENCH` satırlarıdır; sonda `BENCH DONE`. Ardından `q` ile çık.
- İlk çalıştırma sonrası tekrar ölçüm yapın; kesin sonuç olarak tekrarı kullanın. Kurulumdan sonraki ilk
  çalıştırmada telefon ısınırken (GPU/saat) değerler şişebilir: J8'de Ink & Paper'ın ilk çalıştırmasında
  boş kare (`-`) 16.48 ms, tekrarında 2.74 ms çıktı. Boş kare düzeneğin payıdır; belirgin yüksekse
  ölçümü tekrarlayın.

## Aşamalar

Her tema için:

| Kod | Ne çizilir |
|---|---|
| `W` | En kötü tahta: 56 hedef (HP 1–198, bazıları vuruş nabzında), 6 halka, 2 yıldız, 99 top, 64 kıvılcım, HUD, zemin |
| `R` | Gerçekçi tahta: 28 hedef, 4 halka, 1 yıldız, 99 top, 64 kıvılcım, HUD, zemin |
| `b` `t` `o` `r` `k` `h` | En kötü tahtadan tek parça: zemin, hedefler, toplar, halka + yıldız, kıvılcımlar, HUD |

İlk aşama (`<ilk tema>/-`) boş karedir: düzeneğin kendi payı. Bileşen sürelerinden bu çıkarılınca
o bileşenin net maliyeti kalır.

Her aşama 2 sn ısınma + 5 sn ölçümdür; satırda ortalama, p95, p99, en büyük değer ve 16 ms'yi aşan
kare sayısı yazar.

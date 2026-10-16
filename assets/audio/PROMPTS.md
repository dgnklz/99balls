# Ses sentez tarifleri (PRD 8.5)

Sesler bir yapay zeka ses modeliyle değil, `tools/audio/` altındaki Python betikleriyle
**kodla sentezlenir**. Bu dosya her sesin tarifini tutar (PRD'deki "üretim istemi"nin
karşılığı). Tüm sesler yumuşak, kısa, arcade tarzıdır; ana enerji ~2.5 kHz altındadır.

## Orbitfall (`tools/audio/orbitfall.py`, tohum 0x0B1026)

| Dosya | Süre | Tarif |
|---|---|---|
| `sfx_shoot` | 60 ms | Sinüs, 900 → 620 Hz üstel süpürme, τ = 20 ms sönüm ("pew") |
| `sfx_wall` | 40 ms | 1100 Hz sinüs tık (τ 6 ms) + 2.5 kHz alçak geçirenli gürültü |
| `sfx_hit_1..3` | 90 ms | 660 Hz × {1, 1.06, 1.12} sinüs + 2. harmonik (0.35), τ 30 ms; sırayla döner |
| `sfx_break` | 300 ms | Alçak geçirenli gürültü patlaması + 1200 → 380 Hz düşen sinüs + 1568 Hz çan |
| `sfx_pickup` | 250 ms | C6–E6–G6 yükselen arpej, 50 ms aralık, yumuşak sinüs |
| `sfx_star` | 300 ms | 1568/2093/1175 Hz sinüs katmanı, 18 Hz parıltı titreşimi, τ 100 ms |
| `sfx_collect` | 180 ms | Filtrelenmiş gürültü "whoosh" + 300 → 520 Hz yükselen sinüs |
| `sfx_advance` | 250 ms | 220 → 170 Hz alçak "thum" + oktav, τ 80 ms |
| `sfx_gameover` | 900 ms | A4–F4–C4–A3 inen arpej (minör his), τ 250 ms |
| `sfx_record` | 800 ms | C5–E5–G5–C6 yükselen arpej, τ 220 ms |
| `sfx_click` | 40 ms | 1500 Hz sinüs, τ 6 ms |
| `music_loop` | ~31.3 sn | 92 BPM, 12 ölçü, Am9–Fmaj7–Cmaj7–G6 × 3: detune pad, üçgen bas (1. ve 3. vuruş), sekizlik sinüs arpej, çok hafif shaker; dairesel kuyruk, sıfır geçişinde başlar/biter, RMS −16 dBFS |

## Candy Burst (`tools/audio/candyburst.py`, tohum 0xCA4D1E)

Neşeli, oyuncu şeker dünyası: marimba/ksilofon tınıları, pizzicato bas, baloncuk ve şeker çıtırtısı.

| Dosya | Süre | Tarif |
|---|---|---|
| `sfx_shoot` | 70 ms | 700 → 980 Hz yükselen "bloop" + 2. harmonik, τ 25 ms |
| `sfx_wall` | 35 ms | 1.8 kHz tahta tık (τ 4 ms) + 4 kHz alçak geçirenli gürültü |
| `sfx_hit_1..3` | 100 ms | Marimba "tok": C5 × {1, 9/8, 5/4} (pentatonik), ×3.9 kısmi ses + tahta tıkırtısı, τ 35 ms; sırayla döner |
| `sfx_break` | 350 ms | 14 tohumlu yüksek geçirenli mikro çıtırtı tanesi (şeker kırılması) + 300 → 900 Hz pop + hafif 1760 Hz parıltı |
| `sfx_pickup` | 200 ms | Baloncuk pop: 400 → 1400 Hz hızlı süpürme + 60 ms sonra küçük ikinci baloncuk (600 → 1800 Hz) |
| `sfx_star` | 450 ms | Çan: E6 × {1, 2.76, 5.4} kısmi sesler + üç kısa yüksek parıltı ("şimşek") |
| `sfx_collect` | 180 ms | Yüksek geçirenli şekerli "şık" + 500 → 800 Hz yükselen ton |
| `sfx_advance` | 280 ms | Hızlı pentatonik marimba glissandosu C5–D5–E5–G5–A5 (40 ms aralık) |
| `sfx_gameover` | 900 ms | Nazik düşen marimba melodisi G5–E5–D5–C5–A4; son nota %6 aşağı süzülür |
| `sfx_record` | 800 ms | Kısa fanfar C5–E5–G5, ardından C5–E5–G5–C6 marimba akoru |
| `sfx_click` | 30 ms | 2.2 kHz sinüs, τ 4 ms |
| `music_loop` | ~32.5 sn | 118 BPM, 16 ölçü, C–Am–F–G × 4, C majör pentatonik: marimba sekizlik melodi (A–B–A–B cümleleri), 2. ve 4. vuruşta yumuşak marimba akoru, B cümlesinde ksilofon süsü, 1. ve 3. vuruşta pizzicato bas (kök ve beşli), ara sekizliklerde seyrek tohumlu çıtırtı; dairesel kuyruk, sıfır geçişinde başlar/biter, RMS −16 dBFS |

## Pixel Drop (`tools/audio/pixeldrop.py`, tohum 0x91DE1D)

Yumuşatılmış çiptün: bant sınırlı darbe (pulse, harmonikler ≤ 3–5 kHz, katlanma yok) ve üçgen dalga,
filtreli gürültü. Keskinliği alçak geçiren filtre ve yumuşak zarflar alır (PRD 8.5).

| Dosya | Süre | Tarif |
|---|---|---|
| `sfx_shoot` | 60 ms | %25 darbe, 520 → 860 Hz yükselen "pew", τ 22 ms |
| `sfx_wall` | 35 ms | 1.1 kHz üçgen tık (τ 5 ms) + 3 kHz alçak geçirenli gürültü |
| `sfx_hit_1..3` | 80 ms | %50 kare "blip": D5 × {1, 9/8, 6/5}, τ 25 ms, 4 kHz alçak geçiren; sırayla döner |
| `sfx_break` | 320 ms | 5 örnek tutmalı ("8-bit") gürültü kırılması (3.5 kHz alçak geçiren, τ 60 ms) + %25 darbe 900 → 180 Hz düşüş |
| `sfx_pickup` | 210 ms | %25 darbe D5–F5–A5 yükselen arpej, 60 ms aralık |
| `sfx_star` | 360 ms | %12.5 darbe A5 → D6 oktav-dörtlü sıçrama + A6 üçgen parıltı (τ 60 ms) |
| `sfx_collect` | 180 ms | Üçgen 300 → 620 Hz yükselen ton + bant geçirenli gürültü "şşş" |
| `sfx_advance` | 240 ms | Üçgen bas G3 → D3 iki adım "thum" |
| `sfx_gameover` | 900 ms | %25 darbe D5–C5–A4–F4 inen dizi (aeolian), ardından D4 üçgen %8 aşağı süzülür |
| `sfx_record` | 800 ms | %25 darbe D5–F5–A5 fanfar, ardından D5–F5–A5–D6 kare akor (3.5 kHz alçak geçiren) |
| `sfx_click` | 30 ms | 1 kHz kare blip, τ 5 ms |
| `music_loop` | ~31.0 sn | 124 BPM, 16 ölçü, D minör (dorian/aeolian karışımı), Dm7–G7–B♭maj7–Am7 × 4: %25 darbe senkoplu özgün melodi (A–B–A–B cümleleri), %50 kare akor arpeji (sekizlik, oktav üstte, çok alçak), üçgen bas (kök–oktav–beşli sekizlik desen), 1–3'te üçgen kick, 2–4'te yumuşak trampet, ara sekizliklerde hafif hat; dairesel kuyruk, 5 kHz alçak geçiren, sıfır geçişinde başlar/biter. RMS −18.8 dBFS (tepe sınırı −3 dBFS'te kaldı) |

## Abyss (`tools/audio/abyss.py`, tohum 0xAB1550)

Su altı ve biyolüminesans: alçak, yavaş filtre süpürmeli pad; perdesi kayan "su damlası" (ilk 25 ms'de
0.7f → f); sonar ping; kabarcık (yükselen sinüs süpürmesi). Telefon hoparlörü kuralı: 200 Hz altı tek
başına yok; bas ve derin tonlarda 2. harmonik temelden güçlü. Her şey 4 kHz alçak geçirenden geçer.
Baskın enerji bandı = enerjinin %80'inin bulunduğu aralık.

| Dosya | Süre | Tarif | Baskın bant |
|---|---|---|---|
| `sfx_shoot` | 70 ms | Sinüs 520 → 900 Hz yükselen "blup" + 2. harmonik, τ 25 ms | 590–760 Hz |
| `sfx_wall` | 40 ms | 700 Hz üçgen tık (τ 6 ms) + 2 kHz alçak geçirenli gürültü | 680–730 Hz |
| `sfx_hit_1..3` | 110 ms | Su damlası C♯5 × {1, 9/8, 6/5}, τ 35 ms; sırayla döner | 545–565 / 610–635 / 655–675 Hz |
| `sfx_break` | 380 ms | 6 kabarcık (420–680 Hz → ×2.1, 30 ms aralık) + 320 → 160 Hz üçgen darbe (2. harmonikli) + 600 Hz–2.5 kHz köpük gürültüsü | 445–825 Hz |
| `sfx_pickup` | 420 ms | Sonar ping D6 (≈1175 Hz) + beşli, τ 60 ms, 120 ms yankı × 2 | 1170–1180 Hz |
| `sfx_star` | 420 ms | Cam çan arpeji C♯6–E6–G♯6 (kısmi ×2.76), 70 ms aralık | 1320–1665 Hz |
| `sfx_collect` | 200 ms | Üçgen 350 → 700 Hz + 400 Hz–2 kHz "şşş" | 425–540 Hz |
| `sfx_advance` | 280 ms | Harmonikli glissando 440 → 300 Hz | 345–795 Hz |
| `sfx_gameover` | 950 ms | Harmonikli inen tonlar E5–C♯5–A4–F♯4, son nota %10 süzülür; filtre 3 kHz → 600 Hz kapanır | 360–880 Hz |
| `sfx_record` | 850 ms | Çan arpeji C♯5–E5–G♯5–C♯6 + C♯m akor kabarması | 415–1110 Hz |
| `sfx_click` | 30 ms | Küçük kabarcık 900 → 1500 Hz | 1000–1200 Hz |
| `music_loop` | 32.0 sn | 75 BPM, 10 ölçü, F♯ minör (dorian renkli), F♯m9–Dmaj7–Bm9–C♯m7–Amaj7 (her biri 2 ölçü): ayrık sinüs + üçgen pad (filtre 900 ↔ 2200 Hz, 2 ölçüde bir nefes), bir oktav yukarıda harmonikli bas (147–277 Hz, 1. ve 3. vuruş), 1. vuruşta boğuk "lub-dub" kalp atışı (260 → 150 Hz, 2. harmonik baskın + tıkırtı), seyrek pentatonik damla melodisi + noktalı sekizlik yankı, seyrek kabarcık tıkırtıları; dairesel kuyruk, 4 kHz alçak geçiren, sıfır geçişinde başlar/biter. 200 Hz altı %5.5, 300 Hz–3 kHz %60; RMS −16.7 dBFS (tepe −3 dBFS sınırında) | 220–555 Hz |

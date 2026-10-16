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

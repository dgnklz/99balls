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

# Varlık kaynakları ve lisanslar

## Sesler

| Tema | Araç | Tarih | Lisans |
|---|---|---|---|
| Orbitfall | `tools/audio/` Python betikleri (numpy 2.3.3 + standart `wave`), kodla sentez | 2026-10-16 | Projeye ait özgün içerik; dış kaynak yok |
| Candy Burst | `tools/audio/candyburst.py` (numpy 2.3.3 + standart `wave`), kodla sentez | 2026-10-16 | Projeye ait özgün içerik; dış kaynak yok |
| Pixel Drop | `tools/audio/pixeldrop.py` (numpy 2.3.3 + standart `wave`), kodla sentez | 2026-10-16 | Projeye ait özgün içerik; dış kaynak yok |
| Abyss | `tools/audio/abyss.py` (numpy 2.3.3 + standart `wave`), kodla sentez | 2026-10-16 | Projeye ait özgün içerik; dış kaynak yok |
| Ink & Paper | `tools/audio/inkpaper.py` (numpy 2.3.3 + standart `wave`), kodla sentez | 2026-10-17 | Projeye ait özgün içerik; dış kaynak yok |

Tarifler: `assets/audio/PROMPTS.md`.

## Görseller

- Oyun içi tüm görseller kodla çizilir (CustomPainter/Canvas); görsel dosyası yoktur (PRD 2.6).
  Pixel Drop'un 3×5 rakam glifleri de kodda tanımlı bit maskeleridir (yazı tipi dosyası değil).
  Abyss'in denizanası, deniz yıldızı ve kabarcıkları kodda tanımlı Path'lerdir; atlas resmi
  çalışma anında üretilir. Ink & Paper'ın kâğıt dokusu, fırça diskleri, enso kenarı, fırça halka ve
  mürekkep damlaları da sabit tohumla kodda üretilir (taranmış kâğıt ya da fırça görseli yok).
- Uygulama ikonu: ürün sahibinin tasarımı `assets/brand/app-icon-master.png`; platform ve
  mağaza boyutları `tools/icon/make_icon.py` (Pillow 12.2.0) ile üretilir.
- Splash logosu: `assets/brand/` — ürün sahibinin marka kimliği.
- Öğretici el ikonu: Material Icons `touch_app` (Apache 2.0, Flutter ile gelir; geçici).

# Ses üretimi (tools/audio)

Tüm oyun sesleri bu betiklerle **sentezlenir**; dış kaynaklı ses yoktur (PRD 7.4.1, 8.5).
Çıktılar `assets/audio/<themeId>/` altına yazılır ve git'e girer.

## Kurulum (bir kez)

```sh
python -m venv tools/.venv
tools/.venv/Scripts/pip install -r tools/requirements.txt   # Windows
# macOS/Linux: tools/.venv/bin/pip install -r tools/requirements.txt
```

`tools/.venv/` git'e girmez (.gitignore).

## Üretim

Proje kökünden:

```sh
tools/.venv/Scripts/python tools/audio/build_all.py
```

Betik her dosyanın süresini, boyutunu ve SHA-256 özetinin ilk 12 karakterini yazdırır; tema
toplamı 2 MB bütçeyi aşarsa hata verir.

## Deterministiklik

Rastgelelik yalnızca sabit tohumlu `numpy.random.default_rng` ile yapılır. Aynı
numpy sürümüyle iki çalıştırma birebir aynı dosyaları üretir (özetleri karşılaştırın).

## Biçim

| Tür | Biçim | Not |
|---|---|---|
| SFX | WAV, 44.1 kHz, 16-bit, mono | ≤ 1 sn, tepe −3 dBFS (PRD 8.1) |
| Müzik | WAV, 22.05 kHz, 16-bit, mono | ~32 sn kesintisiz döngü (bütçe kararı, ASSUMPTIONS.md) |

Müzik döngüsü kuyruğu başa sarılarak (dairesel) karıştırılır, sonra başı ve sonu
sıfır geçişine denk gelecek şekilde döndürülür: son örnekten ilk örneğe geçiş
süreklidir ve ikisi de ~0'dır (`test/assets/audio_assets_test.dart` denetler).

## Telefon hoparlörü (M3d'den itibaren)

Telefon hoparlörü 200 Hz altını neredeyse hiç vermez. Bas, kalp atışı ve derin tonlar tek başına
alçak frekans olmamalı: temelin üstünde güçlü harmonikler (200 Hz üstü) bulunur. SFX'lerin ana
enerjisi 300 Hz–3 kHz arasındadır; her şey 4 kHz alçak geçirenden geçer. Baskın bantlar
`assets/audio/PROMPTS.md` tablosundadır (FFT ile ölçüldü: enerjinin %80'inin bulunduğu aralık).

Ölçüm (M3e'den itibaren) `bands.py` ile yapılır (salt okuma, dosya yazmaz):

```sh
tools/.venv/Scripts/python tools/audio/bands.py assets/audio/inkpaper
```

Her WAV için baskın bandı (birikimli enerjinin %10 ve %90 noktaları), 200 Hz altı payı ve
300 Hz–3 kHz payını Markdown satırı olarak yazar. Windows konsolunda Türkçe karakterler için
`PYTHONIOENCODING=utf-8` gerekebilir.

## Diğer temaların bayt bayt aynılığı

`build_all.py` tüm temaları yeniden yazar. Yeni tema eklerken önce mevcut dosyaların özetini alın,
üretimden sonra karşılaştırın:

```sh
sha256sum assets/audio/{orbitfall,candyburst,pixeldrop,abyss}/*.wav > /tmp/before.sha256
tools/.venv/Scripts/python tools/audio/build_all.py
sha256sum -c /tmp/before.sha256        # hepsi OK
git status --porcelain assets/audio    # yalnızca yeni klasör
```

## Dosyalar

- `synth.py`: ortak DSP (osilatör, zarf, filtre, normalize, döngü, WAV yazma)
- `orbitfall.py`: Orbitfall ses kimliği (müzik + 13 SFX)
- `candyburst.py`: Candy Burst ses kimliği (müzik + 13 SFX)
- `pixeldrop.py`: Pixel Drop ses kimliği (müzik + 13 SFX)
- `abyss.py`: Abyss ses kimliği (müzik + 13 SFX)
- `inkpaper.py`: Ink & Paper ses kimliği (müzik + 13 SFX)
- `build_all.py`: tüm temaları üretir
- `bands.py`: baskın enerji bandı ölçümü (salt okuma)

Yeni tema: `<tema>.py` yazın (aynı `THEME_ID`, `render_sfx()`, `music_loop()`
arayüzü; temaya özgü yardımcılar o dosyada kalır, `synth.py` değişmez), `build_all.py`'deki
`THEMES` listesine ekleyin, pubspec'e `assets/audio/<tema>/` ekleyin, temanın `ThemeSounds`
süre tablosunu güncelleyin, diğer temaların bayt bayt aynılığını doğrulayın ve `bands.py` ile
bantları ölçün. Sentez tarifleri `assets/audio/PROMPTS.md` dosyasına yazılır.

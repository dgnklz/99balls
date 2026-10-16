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

## Dosyalar

- `synth.py`: ortak DSP (osilatör, zarf, filtre, normalize, döngü, WAV yazma)
- `orbitfall.py`: Orbitfall ses kimliği (müzik + 13 SFX)
- `candyburst.py`: Candy Burst ses kimliği (müzik + 13 SFX)
- `build_all.py`: tüm temaları üretir

Yeni tema (M3c–e): `<tema>.py` yazın (aynı `THEME_ID`, `render_sfx()`, `music_loop()`
arayüzü), `build_all.py`'deki `THEMES` listesine ekleyin, pubspec'e
`assets/audio/<tema>/` ekleyin ve temanın `ThemeSounds` süre tablosunu güncelleyin.
Sentez tarifleri `assets/audio/PROMPTS.md` dosyasına yazılır.

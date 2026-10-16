# Uygulama ikonu (tools/icon)

Kaynak tasarım: **`assets/brand/app-icon-master.png`** (1024×1024, koyu lacivert zeminli, tam
kare; ürün sahibinin tasarımı). Tüm platform ikonları bu tek dosyadan `make_icon.py` (Pillow)
ile üretilir. Tasarım değişirse yalnızca master dosya değiştirilir ve iki komut yeniden çalıştırılır.

> Not: master dosya `.png` uzantılıdır ama içeriği JPEG'dir; Pillow içeriğe göre açar, sonuç etkilenmez.

## Üretim

```sh
tools/.venv/Scripts/python tools/icon/make_icon.py
dart run flutter_launcher_icons
```

## Çıktılar

| Dosya | Boyut | Kullanım |
|---|---|---|
| `assets/icon/ios.png` | 1024, RGB (alfa yok) | iOS; köşe yuvarlama yok (iOS kendisi yuvarlar), `remove_alpha_ios: true` |
| `assets/icon/android_legacy.png` | 1024 | Eski Android cihazlar için tam kare ikon (master'ın kendisi) |
| `assets/icon/android_foreground.png` | 1024, şeffaf | Adaptive ön plan: master %78'e küçültülmüş, ortada, kenarları 24 px yumuşak geçişli; köşeler şeffaf |
| `assets/icon/android_background.png` | 1024 | Adaptive arka plan: master'ın üst (#081027) ve alt (#1E2458) kenar renklerinden dikey degrade |
| `assets/store/play_icon_512.png` | 512, 32-bit | Google Play mağaza ikonu — **uygulamaya gömülmez** |
| `assets/store/appstore_icon_1024.png` | 1024, alfa yok | App Store mağaza ikonu — **uygulamaya gömülmez** |

Web ikonu üretilmez (PRD: web desteklenmiyor; pubspec'te `web: generate: false`).

Splash ekranı bu ikonu kullanmaz: tüm oyunlarda ortak marka logosu
`assets/brand/splash-logo-circular.png` kullanılır (pubspec `flutter_native_splash`).

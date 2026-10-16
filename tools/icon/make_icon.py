"""Uygulama ikonu üretici: tüm platform ikonlarını tek bir master tasarımdan üretir.

Kaynak: assets/brand/app-icon-master.png (1024x1024, koyu lacivert zeminli, tam kare).

Kullanım (proje kökünden):
    tools/.venv/Scripts/python tools/icon/make_icon.py
    dart run flutter_launcher_icons

Üretilenler:
  assets/icon/ios.png                1024  master, RGB (alfa yok), köşe yuvarlama yok
  assets/icon/android_legacy.png     1024  master (eski Android için tam kare)
  assets/icon/android_foreground.png 1024  master %78'e küçültülmüş, şeffaf tuvalde
                                           ortalanmış, kenarları yumuşak geçişli
  assets/icon/android_background.png 1024  master'ın üst/alt kenar renklerinden dikey degrade
  assets/store/play_icon_512.png      512  Google Play, 32-bit PNG (uygulamaya gömülmez)
  assets/store/appstore_icon_1024.png 1024 App Store, alfa yok (uygulamaya gömülmez)
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
MASTER = ROOT / "assets" / "brand" / "app-icon-master.png"
ICON_DIR = ROOT / "assets" / "icon"
STORE_DIR = ROOT / "assets" / "store"

SIZE = 1024
PLAY_SIZE = 512

# Android adaptive ön planı: master'ın kapladığı oran ve yumuşak kenar genişliği.
FOREGROUND_SCALE = 0.78
FEATHER_PX = 24

# Degrade için kenar rengi örneklemesi: üst/alt satırdan her N pikselde bir.
EDGE_SAMPLE_STEP = 4


def _edge_color(img: Image.Image, y: int) -> tuple[int, int, int]:
    px = [img.getpixel((x, y)) for x in range(0, img.width, EDGE_SAMPLE_STEP)]
    return tuple(round(sum(p[i] for p in px) / len(px)) for i in range(3))


def _vertical_gradient(size: int, top, bottom) -> Image.Image:
    img = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(img)
    for y in range(size):
        u = y / (size - 1)
        color = tuple(round(a + (b - a) * u) for a, b in zip(top, bottom))
        draw.line([(0, y), (size, y)], fill=color)
    return img


def _feathered_mask(size: int, feather: int) -> Image.Image:
    """Kenarlarda 0'a yumuşakça inen kare maske (yalnızca kendi sınırları içinde)."""
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rectangle([feather, feather, size - 1 - feather, size - 1 - feather], fill=255)
    return mask.filter(ImageFilter.GaussianBlur(feather / 2))


def adaptive_foreground(master: Image.Image) -> Image.Image:
    inner = round(SIZE * FOREGROUND_SCALE)
    scaled = master.resize((inner, inner), Image.LANCZOS).convert("RGBA")
    scaled.putalpha(_feathered_mask(inner, FEATHER_PX))
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    offset = (SIZE - inner) // 2
    canvas.paste(scaled, (offset, offset), scaled)
    return canvas


def main() -> None:
    master = Image.open(MASTER).convert("RGB")
    if master.size != (SIZE, SIZE):
        raise SystemExit(f"master {SIZE}x{SIZE} olmalı, {master.size} geldi")
    ICON_DIR.mkdir(parents=True, exist_ok=True)
    STORE_DIR.mkdir(parents=True, exist_ok=True)

    master.save(ICON_DIR / "ios.png", optimize=True)
    master.save(ICON_DIR / "android_legacy.png", optimize=True)
    adaptive_foreground(master).save(ICON_DIR / "android_foreground.png", optimize=True)
    top, bottom = _edge_color(master, 0), _edge_color(master, SIZE - 1)
    _vertical_gradient(SIZE, top, bottom).save(ICON_DIR / "android_background.png", optimize=True)

    master.resize((PLAY_SIZE, PLAY_SIZE), Image.LANCZOS).convert("RGBA").save(
        STORE_DIR / "play_icon_512.png", optimize=True)
    master.save(STORE_DIR / "appstore_icon_1024.png", optimize=True)

    print(f"kenar renkleri: üst #{top[0]:02X}{top[1]:02X}{top[2]:02X}  alt #{bottom[0]:02X}{bottom[1]:02X}{bottom[2]:02X}")
    for p in sorted(list(ICON_DIR.glob("*.png")) + list(STORE_DIR.glob("*.png"))):
        with Image.open(p) as im:
            print(f"{p.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}  {im.mode}")


if __name__ == "__main__":
    main()

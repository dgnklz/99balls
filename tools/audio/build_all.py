"""Tüm temaların seslerini üretir: assets/audio/<themeId>/*.wav

Kullanım (proje kökünden):
    tools/.venv/Scripts/python tools/audio/build_all.py

Deterministiktir: iki çalıştırma birebir aynı dosyaları üretir.
"""

from __future__ import annotations

import hashlib
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import candyburst  # noqa: E402
import orbitfall  # noqa: E402
import pixeldrop  # noqa: E402
from synth import MUSIC_RATE, SFX_RATE, write_wav  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
BUDGET_BYTES = 2 * 1024 * 1024  # tema başına ~2 MB (PRD 7.4.1)

THEMES = [orbitfall, candyburst, pixeldrop]


def build_theme(module) -> int:
    out_dir = ROOT / "assets" / "audio" / module.THEME_ID
    total = 0
    rows = []
    for name, samples in module.render_sfx().items():
        size = write_wav(out_dir / f"{name}.wav", samples, SFX_RATE)
        rows.append((name, len(samples) / SFX_RATE, size))
        total += size
    music = module.music_loop()
    size = write_wav(out_dir / "music_loop.wav", music, MUSIC_RATE)
    rows.append(("music_loop", len(music) / MUSIC_RATE, size))
    total += size

    print(f"[{module.THEME_ID}]")
    for name, sec, size in rows:
        digest = hashlib.sha256((out_dir / f"{name}.wav").read_bytes()).hexdigest()[:12]
        print(f"  {name:<14} {sec * 1000:7.0f} ms {size / 1024:8.1f} KB  {digest}")
    print(f"  TOPLAM {total / 1024 / 1024:.2f} MB (bütçe {BUDGET_BYTES / 1024 / 1024:.0f} MB)")
    if total > BUDGET_BYTES:
        raise SystemExit(f"{module.THEME_ID}: ses bütçesi aşıldı")
    return total


if __name__ == "__main__":
    for theme in THEMES:
        build_theme(theme)

"""Ses dosyalarının baskın enerji bandını ölçer (salt okuma; dosya yazmaz).

Kullanım (proje kökünden):
    tools/.venv/Scripts/python tools/audio/bands.py assets/audio/inkpaper [başka klasör ...]

Her WAV için güç spektrumundan (tüm dosya, tek FFT):
- baskın bant: enerjinin %80'inin bulunduğu aralık (birikimli enerjinin
  %10 ve %90 noktaları),
- 200 Hz altındaki enerji payı (telefon hoparlörü çalmaz; müzikte ≤ %6),
- 300 Hz–3 kHz arasındaki enerji payı (SFX'lerin ana bandı, PRD 8.1).
Çıktı, assets/audio/PROMPTS.md tablosuna uygun Markdown satırlarıdır.
"""

from __future__ import annotations

import sys
import wave
from pathlib import Path

import numpy as np

LOW_SHARE = 0.10
HIGH_SHARE = 0.90
PHONE_FLOOR_HZ = 200
MID_LOW_HZ = 300
MID_HIGH_HZ = 3000


def read_wav(path: Path) -> tuple[np.ndarray, int]:
    with wave.open(str(path), "rb") as w:
        rate = w.getframerate()
        pcm = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2")
    return pcm.astype(np.float64) / 32767, rate


def analyze(x: np.ndarray, rate: int) -> tuple[float, float, float, float]:
    """(bant alt Hz, bant üst Hz, <200 Hz payı, 300 Hz–3 kHz payı)."""
    power = np.abs(np.fft.rfft(x)) ** 2
    freqs = np.fft.rfftfreq(len(x), 1 / rate)
    total = power.sum()
    cum = np.cumsum(power) / total
    lo = float(freqs[np.searchsorted(cum, LOW_SHARE)])
    hi = float(freqs[np.searchsorted(cum, HIGH_SHARE)])
    below = float(power[freqs < PHONE_FLOOR_HZ].sum() / total)
    mid = float(power[(freqs >= MID_LOW_HZ) & (freqs <= MID_HIGH_HZ)].sum() / total)
    return lo, hi, below, mid


def _hz(f: float) -> str:
    return f"{f / 1000:.2f} kHz" if f >= 1000 else f"{f:.0f} Hz"


def main(folders: list[str]) -> None:
    print("| Dosya | Baskın bant (%80) | < 200 Hz | 300 Hz–3 kHz |")
    print("|---|---|---|---|")
    for folder in folders:
        for path in sorted(Path(folder).glob("*.wav")):
            x, rate = read_wav(path)
            lo, hi, below, mid = analyze(x, rate)
            print(f"| `{path.stem}` | {_hz(lo)}–{_hz(hi)} | {below:.1%} | {mid:.1%} |")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(sys.argv[1:])

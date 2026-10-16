"""Ortak ses sentez yardımcıları (numpy + wave).

Tüm üretim deterministiktir: rastgelelik yalnızca sabit tohumlu
numpy.random.default_rng ile yapılır. Çıktılar 16-bit PCM mono WAV'dır.
"""

from __future__ import annotations

import wave
from pathlib import Path

import numpy as np

SFX_RATE = 44100
MUSIC_RATE = 22050

# Tepe seviyesi −3 dBFS (PRD 8.1).
PEAK_DBFS = -3.0
INT16_MAX = 32767

# Tıklamayı önlemek için SFX başı/sonu yumuşatma (sn).
EDGE_FADE_SEC = 0.002


def db_to_gain(db: float) -> float:
    return float(10 ** (db / 20))


def timeline(duration: float, rate: int) -> np.ndarray:
    return np.arange(int(round(duration * rate))) / rate


def sine(freq, t: np.ndarray) -> np.ndarray:
    """Sabit ya da zamanla değişen frekanslı sinüs (faz birikimli)."""
    freq = np.broadcast_to(np.asarray(freq, dtype=np.float64), t.shape)
    rate = 1.0 / (t[1] - t[0]) if len(t) > 1 else 1.0
    phase = 2 * np.pi * np.cumsum(freq) / rate
    return np.sin(phase)


def triangle(freq, t: np.ndarray) -> np.ndarray:
    return 2 / np.pi * np.arcsin(sine(freq, t))


def sweep(f0: float, f1: float, t: np.ndarray) -> np.ndarray:
    """Üstel frekans süpürmesi f0 → f1."""
    u = t / t[-1] if t[-1] > 0 else t
    return f0 * (f1 / f0) ** u


def exp_decay(t: np.ndarray, tau: float) -> np.ndarray:
    return np.exp(-t / tau)


def adsr(t: np.ndarray, attack: float, decay: float, sustain: float, release: float) -> np.ndarray:
    """Basit ADSR zarfı; release, sürenin sonuna yerleşir."""
    total = t[-1] if len(t) else 0.0
    env = np.ones_like(t) * sustain
    a = t < attack
    env[a] = t[a] / attack
    d = (t >= attack) & (t < attack + decay)
    env[d] = 1 - (1 - sustain) * (t[d] - attack) / decay
    r = t > total - release
    env[r] *= np.clip((total - t[r]) / release, 0, 1)
    return env


def noise(n: int, seed: int) -> np.ndarray:
    return np.random.default_rng(seed).uniform(-1, 1, n)


def lowpass(x: np.ndarray, cutoff: float, rate: int) -> np.ndarray:
    """Tek kutuplu alçak geçiren filtre (yumuşak, keskin olmayan ton için)."""
    alpha = 1 - np.exp(-2 * np.pi * cutoff / rate)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def edge_fade(x: np.ndarray, rate: int) -> np.ndarray:
    n = min(len(x) // 2, int(EDGE_FADE_SEC * rate))
    if n > 0:
        ramp = np.linspace(0, 1, n)
        x = x.copy()
        x[:n] *= ramp
        x[-n:] *= ramp[::-1]
    return x


def normalize_peak(x: np.ndarray, peak_dbfs: float = PEAK_DBFS) -> np.ndarray:
    peak = np.max(np.abs(x))
    return x if peak == 0 else x * (db_to_gain(peak_dbfs) / peak)


def write_wav(path: Path, x: np.ndarray, rate: int) -> int:
    """x ∈ [-1, 1] float → 16-bit mono WAV. Yazılan bayt sayısını döndürür."""
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = np.clip(np.round(x * INT16_MAX), -INT16_MAX, INT16_MAX).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm.tobytes())
    return path.stat().st_size


def seamless_loop(body: np.ndarray, tail: np.ndarray) -> np.ndarray:
    """Döngü uzunluğunu aşan kuyruğu başa ekler (dairesel karıştırma).

    Böylece son örnekten ilk örneğe geçiş, sesin devamı gibi süreklidir.
    """
    out = body.copy()
    n = min(len(tail), len(out))
    out[:n] += tail[:n]
    return out


def rotate_to_zero_crossing(x: np.ndarray) -> np.ndarray:
    """Dairesel olarak sürekli bir döngüyü, başı ve sonu sıfır geçişine
    denk gelecek şekilde döndürür: x[-1] < 0 ≤ x[0] ve ikisi de sıfıra en yakın.

    Döndürme dairesel sürekliliği bozmaz; başlangıç ve bitiş değeri ~0 olur.
    """
    prev = np.roll(x, 1)
    crossings = np.where((prev < 0) & (x >= 0))[0]
    if len(crossings) == 0:
        return x
    cost = np.abs(prev[crossings]) + np.abs(x[crossings])
    k = int(crossings[np.argmin(cost)])
    return np.roll(x, -k)

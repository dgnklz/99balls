"""Orbitfall ses kimliği: yumuşak, uzay/yörünge temalı arcade sesler (PRD 8.5).

Keskin ve yüksek frekanslı seslerden kaçınılır; ana enerji ~2.5 kHz altında.
Tüm rastgelelik sabit tohumludur (TOHUM).
"""

from __future__ import annotations

import numpy as np

from synth import (
    MUSIC_RATE,
    SFX_RATE,
    adsr,
    edge_fade,
    exp_decay,
    lowpass,
    noise,
    normalize_peak,
    rotate_to_zero_crossing,
    seamless_loop,
    sine,
    sweep,
    timeline,
    triangle,
)

THEME_ID = "orbitfall"
SEED = 0x0B1026

# --- Müzik: 92 BPM, 4/4, 12 ölçü (≈31.3 sn), Am9 – Fmaj7 – Cmaj7 – G6 × 3 ---
BPM = 92
BEATS_PER_BAR = 4
BARS = 12
TAIL_SEC = 2.0
MUSIC_RMS_DBFS = -16.0

# Akorlar MIDI nota numaralarıyla (kök, akor tonları).
CHORDS = [
    (45, [57, 60, 64, 67, 71]),  # Am9
    (41, [53, 57, 60, 64]),      # Fmaj7
    (48, [55, 59, 60, 64]),      # Cmaj7
    (43, [55, 59, 62, 64]),      # G6
]
ARP_PATTERN = [0, 2, 1, 3, 2, 1, 3, 2]


def midi_hz(note: float) -> float:
    return 440.0 * 2 ** ((note - 69) / 12)


def _place(buf: np.ndarray, start: int, x: np.ndarray) -> None:
    end = min(len(buf), start + len(x))
    buf[start:end] += x[: end - start]


def music_loop() -> np.ndarray:
    rate = MUSIC_RATE
    beat = 60 / BPM
    bar = beat * BEATS_PER_BAR
    n = int(round(BARS * bar * rate))
    buf = np.zeros(n + int(TAIL_SEC * rate))
    rng = np.random.default_rng(SEED)

    for b in range(BARS):
        root, tones = CHORDS[b % len(CHORDS)]
        start = int(round(b * bar * rate))

        # Pad: hafif detune edilmiş sinüsler, yavaş atak, ölçüyü aşan bırakma.
        t = timeline(bar + 1.2, rate)
        env = adsr(t, attack=0.6, decay=0.5, sustain=0.7, release=1.2)
        pad = np.zeros_like(t)
        for note in tones[:4]:
            f = midi_hz(note)
            pad += sine(f * 0.997, t) + sine(f * 1.003, t)
        _place(buf, start, 0.10 * pad * env)

        # Bas: 1. ve 3. vuruşta kök nota, üçgen + alçak geçiren.
        for beat_i in (0, 2):
            tb = timeline(beat * 1.8, rate)
            bass = triangle(midi_hz(root), tb) * exp_decay(tb, 0.7)
            _place(buf, start + int(round(beat_i * beat * rate)), 0.35 * bass)

        # Arpej: sekizlik notalar, yumuşak sinüs + 2. harmonik.
        for i, idx in enumerate(ARP_PATTERN):
            note = tones[idx % len(tones)] + 12
            ta = timeline(beat * 1.5, rate)
            f = midi_hz(note)
            tone = sine(f, ta) + 0.25 * sine(2 * f, ta)
            arp = tone * exp_decay(ta, 0.28) * adsr(ta, 0.005, 0.05, 1.0, 0.05)
            accent = 1.0 if i % 2 == 0 else 0.7
            _place(buf, start + int(round(i * beat / 2 * rate)), 0.12 * accent * arp)

        # Shaker: arka vuruşlarda çok hafif filtrelenmiş gürültü.
        for beat_i in range(BEATS_PER_BAR):
            ts = timeline(0.08, rate)
            sh = lowpass(rng.uniform(-1, 1, len(ts)), 3000, rate) * exp_decay(ts, 0.02)
            _place(buf, start + int(round((beat_i + 0.5) * beat * rate)), 0.05 * sh)

    loop = seamless_loop(buf[:n], buf[n:])
    loop = lowpass(loop, 6000, rate)
    loop = rotate_to_zero_crossing(loop)
    rms = np.sqrt(np.mean(loop**2))
    target = 10 ** (MUSIC_RMS_DBFS / 20)
    loop = loop * (target / rms)
    return normalize_peak(loop) if np.max(np.abs(loop)) > 10 ** (-3 / 20) else loop


# --- SFX (44.1 kHz) ---


def sfx_shoot() -> np.ndarray:
    t = timeline(0.06, SFX_RATE)
    return sine(sweep(900, 620, t), t) * exp_decay(t, 0.02)


def sfx_wall() -> np.ndarray:
    t = timeline(0.04, SFX_RATE)
    tick = sine(1100, t) * exp_decay(t, 0.006)
    puff = lowpass(noise(len(t), SEED + 1), 2500, SFX_RATE) * exp_decay(t, 0.008)
    return 0.7 * tick + 0.3 * puff


def _plink(ratio: float) -> np.ndarray:
    t = timeline(0.09, SFX_RATE)
    f = 660 * ratio
    return (sine(f, t) + 0.35 * sine(2 * f, t)) * exp_decay(t, 0.03)


def sfx_hit_1() -> np.ndarray:
    return _plink(1.0)


def sfx_hit_2() -> np.ndarray:
    return _plink(1.06)


def sfx_hit_3() -> np.ndarray:
    return _plink(1.12)


def sfx_break() -> np.ndarray:
    t = timeline(0.30, SFX_RATE)
    burst = lowpass(noise(len(t), SEED + 2), 2200, SFX_RATE) * exp_decay(t, 0.05)
    fall = sine(sweep(1200, 380, t), t) * exp_decay(t, 0.10)
    chime = sine(1568, t) * exp_decay(t, 0.12) * 0.3
    return 0.5 * burst + 0.6 * fall + chime


def _arpeggio(notes: list[float], step: float, length: float, tau: float) -> np.ndarray:
    t = timeline(length, SFX_RATE)
    out = np.zeros_like(t)
    for i, note in enumerate(notes):
        start = int(round(i * step * SFX_RATE))
        tn = t[: len(t) - start]
        f = midi_hz(note)
        tone = (sine(f, tn) + 0.2 * sine(2 * f, tn)) * exp_decay(tn, tau)
        out[start:] += tone
    return out


def sfx_pickup() -> np.ndarray:
    return _arpeggio([72, 76, 79], step=0.05, length=0.25, tau=0.07)


def sfx_star() -> np.ndarray:
    t = timeline(0.30, SFX_RATE)
    shimmer = 0.6 + 0.4 * sine(18, t)
    tone = sine(1568, t) + 0.6 * sine(2093, t) + 0.3 * sine(1175, t)
    return tone * shimmer * exp_decay(t, 0.10)


def sfx_collect() -> np.ndarray:
    t = timeline(0.18, SFX_RATE)
    whoosh = lowpass(noise(len(t), SEED + 3), 1800, SFX_RATE) * adsr(t, 0.04, 0.05, 0.6, 0.08)
    rise = sine(sweep(300, 520, t), t) * adsr(t, 0.03, 0.05, 0.5, 0.08)
    return 0.6 * whoosh + 0.5 * rise


def sfx_advance() -> np.ndarray:
    t = timeline(0.25, SFX_RATE)
    thum = sine(sweep(220, 170, t), t) + 0.4 * sine(sweep(440, 340, t), t)
    return thum * exp_decay(t, 0.08)


def sfx_gameover() -> np.ndarray:
    return _arpeggio([69, 65, 60, 57], step=0.18, length=0.9, tau=0.25)


def sfx_record() -> np.ndarray:
    return _arpeggio([72, 76, 79, 84], step=0.12, length=0.8, tau=0.22)


def sfx_click() -> np.ndarray:
    t = timeline(0.04, SFX_RATE)
    return sine(1500, t) * exp_decay(t, 0.006)


SFX = {
    "sfx_shoot": sfx_shoot,
    "sfx_wall": sfx_wall,
    "sfx_hit_1": sfx_hit_1,
    "sfx_hit_2": sfx_hit_2,
    "sfx_hit_3": sfx_hit_3,
    "sfx_break": sfx_break,
    "sfx_pickup": sfx_pickup,
    "sfx_star": sfx_star,
    "sfx_collect": sfx_collect,
    "sfx_advance": sfx_advance,
    "sfx_gameover": sfx_gameover,
    "sfx_record": sfx_record,
    "sfx_click": sfx_click,
}


def render_sfx() -> dict[str, np.ndarray]:
    return {name: normalize_peak(edge_fade(fn(), SFX_RATE)) for name, fn in SFX.items()}

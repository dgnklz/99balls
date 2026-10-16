"""Pixel Drop ses kimliği: yumuşatılmış çiptün (PRD 8.5).

Bant sınırlı darbe (pulse) ve üçgen dalga + filtreli gürültü; keskinliği
alçak geçiren filtre ve yumuşak zarflar alır. Orbitfall'ın sinüs/pad uzay
sesinden ve Candy Burst'ün marimba/pizzicato tınısından belirgin ayrışır.
Melodi özgündür: bilinen bir oyun ya da çiptün temasından (Korobeiniki/Tetris
dahil) alıntı veya taklit değildir. Tüm rastgelelik sabit tohumludur (SEED).
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
    pulse,
    rotate_to_zero_crossing,
    seamless_loop,
    sweep,
    timeline,
    triangle,
)

THEME_ID = "pixeldrop"
SEED = 0x91DE1D

# --- Müzik: 124 BPM, 4/4, 16 ölçü (≈31.0 sn), D minör (dorian/aeolian karışımı) ---
# Dm7–G7–B♭maj7–Am7 × 4: G7'deki B doğal dorian, B♭maj7 aeolian rengini verir.
BPM = 124
BEATS_PER_BAR = 4
BARS = 16
TAIL_SEC = 1.5
MUSIC_RMS_DBFS = -16.0
LEAD_CUTOFF = 3500
MIX_CUTOFF = 5000

# Akorlar: (bas kökü, akor tonları) MIDI.
CHORDS = [
    (38, [62, 65, 69, 72]),  # Dm7
    (43, [67, 71, 74, 77]),  # G7
    (46, [70, 74, 77, 81]),  # B♭maj7
    (45, [69, 72, 76, 79]),  # Am7
]

# Melodi sekizlikleri (None = sus). Senkoplu, geniş aralıklı özgün cümleler.
PHRASE_A = [
    [74, None, 77, None, 76, 74, None, 69],  # Dm7
    [71, None, 74, 77, None, 79, 77, None],  # G7
    [70, 74, None, 77, 81, None, 77, 74],  # B♭maj7
    [76, None, 72, None, 69, 72, 76, None],  # Am7
]
PHRASE_B = [
    [81, None, 79, 77, None, 74, 77, 79],  # Dm7
    [77, None, 74, None, 71, 74, None, 67],  # G7
    [70, None, 74, 77, None, 81, 79, 77],  # B♭maj7
    [76, None, 72, 76, 74, 72, 69, None],  # Am7
]
MELODY = PHRASE_A + PHRASE_B + PHRASE_A + PHRASE_B

# Bas deseni (sekizlik): kök, oktav ve beşli (çiptün basına özgü sıçrama).
BASS_PATTERN = [0, None, 12, None, 0, None, 12, 7]


def midi_hz(note: float) -> float:
    return 440.0 * 2 ** ((note - 69) / 12)


def _place(buf: np.ndarray, start: int, x: np.ndarray) -> None:
    end = min(len(buf), start + len(x))
    if end > start:
        buf[start:end] += x[: end - start]


def lead(freq: float, dur: float, rate: int) -> np.ndarray:
    """Ana ses: %25 darbe, yumuşak saldırı ve sönüm."""
    t = timeline(dur, rate)
    return pulse(freq, 0.25, t, max_hz=LEAD_CUTOFF) * adsr(t, 0.006, 0.08, 0.55, 0.05)


def arp(freq: float, dur: float, rate: int) -> np.ndarray:
    """Arka arpej: %50 darbe (kare), kısa ve alçak."""
    t = timeline(dur, rate)
    return pulse(freq, 0.5, t, max_hz=3000) * exp_decay(t, 0.05) * adsr(t, 0.003, 0.01, 1, 0.01)


def bass(freq: float, dur: float, rate: int) -> np.ndarray:
    """Üçgen bas."""
    t = timeline(dur, rate)
    return triangle(freq, t) * adsr(t, 0.004, 0.05, 0.7, 0.03)


def kick(rate: int) -> np.ndarray:
    t = timeline(0.12, rate)
    return triangle(sweep(140, 50, t), t) * exp_decay(t, 0.05)


def snare(seed: int, rate: int) -> np.ndarray:
    t = timeline(0.10, rate)
    return lowpass(noise(len(t), seed), 3000, rate) * exp_decay(t, 0.03)


def hat(seed: int, rate: int) -> np.ndarray:
    t = timeline(0.03, rate)
    n = noise(len(t), seed)
    return (n - lowpass(n, 4000, rate)) * exp_decay(t, 0.008)


def music_loop() -> np.ndarray:
    rate = MUSIC_RATE
    beat = 60 / BPM
    bar = beat * BEATS_PER_BAR
    eighth = beat / 2
    n = int(round(BARS * bar * rate))
    buf = np.zeros(n + int(TAIL_SEC * rate))
    rng = np.random.default_rng(SEED)

    for b in range(BARS):
        root, tones = CHORDS[b % len(CHORDS)]
        start = int(round(b * bar * rate))

        # Üçgen bas (sekizlik desen).
        for i, offset in enumerate(BASS_PATTERN):
            if offset is None:
                continue
            _place(buf, start + int(round(i * eighth * rate)),
                   0.30 * bass(midi_hz(root + offset), eighth * 0.9, rate))

        # Kare arpej: akor tonları sırayla, oktav üstte, her sekizlik.
        for i in range(8):
            note = tones[i % len(tones)] + 12
            _place(buf, start + int(round(i * eighth * rate)),
                   0.035 * arp(midi_hz(note), eighth * 0.8, rate))

        # Ana melodi (vuruş başında hafif vurgu).
        for i, note in enumerate(MELODY[b]):
            if note is None:
                continue
            accent = 1.0 if i % 2 == 0 else 0.8
            _place(buf, start + int(round(i * eighth * rate)),
                   0.16 * accent * lead(midi_hz(note), eighth * 1.6, rate))

        # Ritim: 1 ve 3'te kick, 2 ve 4'te yumuşak trampet, ara sekizliklerde hafif hat.
        for beat_i in range(BEATS_PER_BAR):
            at = start + int(round(beat_i * beat * rate))
            if beat_i % 2 == 0:
                _place(buf, at, 0.35 * kick(rate))
            else:
                _place(buf, at, 0.10 * snare(int(rng.integers(1 << 30)), rate))
            _place(buf, at + int(round(eighth * rate)),
                   0.04 * hat(int(rng.integers(1 << 30)), rate))

    loop = seamless_loop(buf[:n], buf[n:])
    loop = lowpass(loop, MIX_CUTOFF, rate)
    loop = rotate_to_zero_crossing(loop)
    rms = np.sqrt(np.mean(loop**2))
    target = 10 ** (MUSIC_RMS_DBFS / 20)
    loop = loop * (target / rms)
    return normalize_peak(loop) if np.max(np.abs(loop)) > 10 ** (-3 / 20) else loop


# --- SFX (44.1 kHz) ---


def _blip(freq, dur: float, duty: float, tau: float, cutoff: float = 4000) -> np.ndarray:
    """Kısa darbe sesi; [freq] sabit ya da süpürme dizisi olabilir."""
    t = timeline(dur, SFX_RATE)
    x = pulse(freq, duty, t, max_hz=cutoff) * exp_decay(t, tau) * adsr(t, 0.002, 0.01, 1, 0.005)
    return lowpass(x, cutoff, SFX_RATE)


def _notes(notes: list[int], step: float, length: float, duty: float, tau: float) -> np.ndarray:
    out = np.zeros(int(round(length * SFX_RATE)))
    for i, note in enumerate(notes):
        start = int(round(i * step * SFX_RATE))
        _place(out, start, _blip(midi_hz(note), length - i * step, duty, tau))
    return out


def sfx_shoot() -> np.ndarray:
    t = timeline(0.06, SFX_RATE)
    return _blip(sweep(520, 860, t), 0.06, 0.25, 0.022)


def sfx_wall() -> np.ndarray:
    t = timeline(0.035, SFX_RATE)
    tick = triangle(1100, t) * exp_decay(t, 0.005)
    grit = lowpass(noise(len(t), SEED + 1), 3000, SFX_RATE) * exp_decay(t, 0.003)
    return 0.7 * tick + 0.3 * grit


def _hit(ratio: float) -> np.ndarray:
    return _blip(midi_hz(74) * ratio, 0.08, 0.5, 0.025)


def sfx_hit_1() -> np.ndarray:
    return _hit(1.0)


def sfx_hit_2() -> np.ndarray:
    return _hit(9 / 8)


def sfx_hit_3() -> np.ndarray:
    return _hit(6 / 5)


def _sample_hold(x: np.ndarray, hold: int) -> np.ndarray:
    """Basit "8-bit" dokusu: her [hold] örnekte bir değer tutulur."""
    return np.repeat(x[::hold], hold)[: len(x)]


def sfx_break() -> np.ndarray:
    t = timeline(0.32, SFX_RATE)
    crunch = _sample_hold(noise(len(t), SEED + 2), 5)
    crunch = lowpass(crunch, 3500, SFX_RATE) * exp_decay(t, 0.06)
    drop = pulse(sweep(900, 180, t), 0.25, t, max_hz=4000) * exp_decay(t, 0.09)
    return 0.6 * crunch + 0.5 * lowpass(drop, 4000, SFX_RATE)


def sfx_pickup() -> np.ndarray:
    return _notes([74, 77, 81], step=0.06, length=0.21, duty=0.25, tau=0.04)


def sfx_star() -> np.ndarray:
    out = _notes([81, 86], step=0.07, length=0.36, duty=0.125, tau=0.10)
    t = timeline(0.36, SFX_RATE)
    return out + 0.25 * triangle(midi_hz(93), t) * exp_decay(t, 0.06)


def sfx_collect() -> np.ndarray:
    t = timeline(0.18, SFX_RATE)
    env = adsr(t, 0.03, 0.05, 0.5, 0.08)
    rise = triangle(sweep(300, 620, t), t) * env
    n = noise(len(t), SEED + 3)
    shh = lowpass(n - lowpass(n, 1500, SFX_RATE), 3500, SFX_RATE) * env
    return 0.6 * rise + 0.3 * shh


def sfx_advance() -> np.ndarray:
    out = np.zeros(int(round(0.24 * SFX_RATE)))
    for i, note in enumerate((55, 50)):  # G3 → D3
        t = timeline(0.24 - i * 0.08, SFX_RATE)
        _place(out, int(round(i * 0.08 * SFX_RATE)),
               triangle(midi_hz(note), t) * exp_decay(t, 0.06) * adsr(t, 0.003, 0.01, 1, 0.01))
    return out


def sfx_record() -> np.ndarray:
    out = _notes([74, 77, 81], step=0.09, length=0.8, duty=0.25, tau=0.06)
    start = int(round(0.27 * SFX_RATE))
    t = timeline(0.8 - 0.27, SFX_RATE)
    chord = sum(pulse(midi_hz(note), 0.5, t, max_hz=3000) for note in (74, 77, 81, 86))
    _place(out, start, 0.35 * lowpass(chord * exp_decay(t, 0.22), 3500, SFX_RATE))
    return out


def sfx_gameover() -> np.ndarray:
    out = _notes([74, 72, 69, 65], step=0.15, length=0.9, duty=0.25, tau=0.12)
    # Son nota (D4) aşağı süzülür.
    start = int(round(4 * 0.15 * SFX_RATE))
    t = timeline(0.9 - 4 * 0.15, SFX_RATE)
    f = sweep(midi_hz(62), midi_hz(62) * 0.92, t)
    _place(out, start, lowpass(triangle(f, t) * exp_decay(t, 0.12), 4000, SFX_RATE))
    return out


def sfx_click() -> np.ndarray:
    return _blip(1000, 0.03, 0.5, 0.005)


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

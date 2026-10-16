"""Candy Burst ses kimliği: neşeli, oyuncu şeker dünyası (PRD 8.5).

Marimba/ksilofon tınıları, pizzicato bas, baloncuk ve şeker çıtırtısı.
Orbitfall'ın yumuşak sinüs/pad uzay sesinden belirgin ayrışır. Tüm rastgelelik
sabit tohumludur (SEED).
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
)

THEME_ID = "candyburst"
SEED = 0xCA4D1E

# --- Müzik: 118 BPM, 4/4, 16 ölçü (≈32.5 sn), C majör pentatonik, C–Am–F–G × 4 ---
BPM = 118
BEATS_PER_BAR = 4
BARS = 16
TAIL_SEC = 1.5
MUSIC_RMS_DBFS = -16.0

# Akorlar: (bas kökü, akor tonları) MIDI.
CHORDS = [
    (48, [60, 64, 67]),  # C
    (45, [57, 60, 64]),  # Am
    (41, [57, 60, 65]),  # F
    (43, [55, 62, 67]),  # G (pentatonikte B yok: G–D–G)
]

# Melodi sekizlikleri (None = sus); yalnızca C majör pentatonik (C D E G A).
PHRASE_A = [
    [72, None, 76, 79, 76, None, 74, 72],
    [69, None, 72, 76, 74, 72, 69, None],
    [72, None, 69, 72, 74, None, 76, 74],
    [74, 76, 74, None, 67, 69, 74, None],
]
PHRASE_B = [
    [79, None, 76, 72, 76, 79, 81, None],
    [81, 79, 76, None, 72, 76, 69, None],
    [72, 74, 76, None, 79, 76, 74, 72],
    [74, None, 79, None, 74, 72, 67, None],
]
MELODY = PHRASE_A + PHRASE_B + PHRASE_A + PHRASE_B


def midi_hz(note: float) -> float:
    return 440.0 * 2 ** ((note - 69) / 12)


def _place(buf: np.ndarray, start: int, x: np.ndarray) -> None:
    end = min(len(buf), start + len(x))
    if end > start:
        buf[start:end] += x[: end - start]


def _attack(t: np.ndarray, sec: float = 0.003) -> np.ndarray:
    return np.clip(t / sec, 0, 1)


def marimba(freq: float, dur: float, rate: int, tau: float = 0.22) -> np.ndarray:
    """Marimba: temel + ×3.9 ve ×9.2 kısmi sesler (hızlı sönen tahta tınısı)."""
    t = timeline(dur, rate)
    tone = (
        sine(freq, t)
        + 0.35 * sine(3.9 * freq, t) * exp_decay(t, 0.03)
        + 0.12 * sine(9.2 * freq, t) * exp_decay(t, 0.012)
    )
    return tone * exp_decay(t, tau) * _attack(t)


def xylophone(freq: float, dur: float, rate: int) -> np.ndarray:
    """Ksilofon: parlak, kısa; ×3 kısmi ses."""
    t = timeline(dur, rate)
    tone = sine(freq, t) + 0.4 * sine(3 * freq, t) * exp_decay(t, 0.02)
    return tone * exp_decay(t, 0.08) * _attack(t, 0.001)


def pizzicato(freq: float, dur: float, rate: int) -> np.ndarray:
    """Pizzicato bas: kısa sönümlü, hafif harmonikli çekme."""
    t = timeline(dur, rate)
    tone = sine(freq, t) + 0.5 * sine(2 * freq, t) + 0.2 * sine(3 * freq, t)
    return tone * exp_decay(t, 0.12) * _attack(t, 0.002)


def crackle(n: int, seed: int, rate: int) -> np.ndarray:
    """Şeker çıtırtısı: yüksek geçirenli kısa gürültü tanesi."""
    x = noise(n, seed)
    x = x - lowpass(x, 2000, rate)
    t = np.arange(n) / rate
    return x * exp_decay(t, 0.004)


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
        phrase_b = (b // 4) % 2 == 1

        # Pizzicato bas: 1. vuruşta kök, 3. vuruşta beşli.
        for beat_i, offset in ((0, 0), (2, 7)):
            _place(buf, start + int(round(beat_i * beat * rate)),
                   0.40 * pizzicato(midi_hz(root + offset), beat * 1.5, rate))

        # Marimba akor dokunuşu: 2. ve 4. vuruşta yumuşak üçlü.
        for beat_i in (1, 3):
            chord = sum(marimba(midi_hz(note), beat, rate, tau=0.12) for note in tones)
            _place(buf, start + int(round(beat_i * beat * rate)), 0.07 * chord)

        # Melodi: marimba sekizlikler (vuruş başında hafif vurgu).
        for i, note in enumerate(MELODY[b]):
            if note is None:
                continue
            accent = 1.0 if i % 2 == 0 else 0.8
            _place(buf, start + int(round(i * eighth * rate)),
                   0.20 * accent * marimba(midi_hz(note), eighth * 3, rate))

        # Ksilofon süsü: B cümlesinde 2. ve 4. vuruşun "ve"sinde iki oktav üst.
        if phrase_b:
            for beat_i in (1, 3):
                note = tones[-1] + 24
                _place(buf, start + int(round((beat_i + 0.5) * beat * rate)),
                       0.06 * xylophone(midi_hz(note), 0.25, rate))

        # Çıtırtı vurgusu: ara sekizliklerde seyrek, tohumlu.
        for i in range(1, 8, 2):
            if rng.random() < 0.5:
                grain = crackle(int(0.015 * rate), int(rng.integers(1 << 30)), rate)
                _place(buf, start + int(round(i * eighth * rate)), 0.05 * grain)

    loop = seamless_loop(buf[:n], buf[n:])
    loop = lowpass(loop, 6000, rate)
    loop = rotate_to_zero_crossing(loop)
    rms = np.sqrt(np.mean(loop**2))
    target = 10 ** (MUSIC_RMS_DBFS / 20)
    loop = loop * (target / rms)
    return normalize_peak(loop) if np.max(np.abs(loop)) > 10 ** (-3 / 20) else loop


# --- SFX (44.1 kHz) ---


def sfx_shoot() -> np.ndarray:
    t = timeline(0.07, SFX_RATE)
    f = sweep(700, 980, t)
    return (sine(f, t) + 0.25 * sine(2 * f, t)) * exp_decay(t, 0.025) * _attack(t)


def sfx_wall() -> np.ndarray:
    t = timeline(0.035, SFX_RATE)
    tick = sine(1800, t) * exp_decay(t, 0.004)
    wood = lowpass(noise(len(t), SEED + 1), 4000, SFX_RATE) * exp_decay(t, 0.003)
    return 0.6 * tick + 0.4 * wood


def _tok(ratio: float) -> np.ndarray:
    """Marimba "tok": C5 × oran, tahta tıkırtısıyla."""
    t = timeline(0.10, SFX_RATE)
    f = midi_hz(72) * ratio
    body = (sine(f, t) + 0.3 * sine(3.9 * f, t) * exp_decay(t, 0.015)) * exp_decay(t, 0.035)
    click = lowpass(noise(len(t), SEED + 2), 3000, SFX_RATE) * exp_decay(t, 0.002)
    return (body + 0.25 * click) * _attack(t, 0.001)


def sfx_hit_1() -> np.ndarray:
    return _tok(1.0)


def sfx_hit_2() -> np.ndarray:
    return _tok(9 / 8)


def sfx_hit_3() -> np.ndarray:
    return _tok(5 / 4)


def sfx_break() -> np.ndarray:
    t = timeline(0.35, SFX_RATE)
    out = np.zeros_like(t)
    rng = np.random.default_rng(SEED + 3)
    # Şeker çıtırtısı: azalan kazançlı mikro taneler.
    for i in range(14):
        start = int(rng.uniform(0, 0.2) * SFX_RATE)
        gain = 0.9 * (1 - i / 16)
        _place(out, start, gain * crackle(int(0.006 * SFX_RATE), int(rng.integers(1 << 30)), SFX_RATE))
    # Pop: kısa yükselen süpürme.
    tp = timeline(0.06, SFX_RATE)
    pop = sine(sweep(300, 900, tp), tp) * exp_decay(tp, 0.02) * _attack(tp)
    _place(out, 0, 0.8 * pop)
    # Hafif parıltı kuyruğu.
    out += 0.15 * sine(1760, t) * exp_decay(t, 0.08)
    return out


def _bubble(f0: float, f1: float, dur: float, tau: float) -> np.ndarray:
    t = timeline(dur, SFX_RATE)
    return sine(sweep(f0, f1, t), t) * exp_decay(t, tau) * _attack(t)


def sfx_pickup() -> np.ndarray:
    out = np.zeros(int(round(0.20 * SFX_RATE)))
    _place(out, 0, _bubble(400, 1400, 0.07, 0.025))
    _place(out, int(0.06 * SFX_RATE), 0.6 * _bubble(600, 1800, 0.05, 0.02))
    return out


def sfx_star() -> np.ndarray:
    t = timeline(0.45, SFX_RATE)
    f = midi_hz(88)  # E6
    bell = (
        sine(f, t)
        + 0.5 * sine(2.76 * f, t) * exp_decay(t, 0.12)
        + 0.25 * sine(5.4 * f, t) * exp_decay(t, 0.05)
    ) * exp_decay(t, 0.18) * _attack(t, 0.001)
    out = bell.copy()
    for start, note in ((0.05, 100), (0.12, 103), (0.20, 105)):
        tt = timeline(0.12, SFX_RATE)
        _place(out, int(start * SFX_RATE), 0.25 * sine(midi_hz(note), tt) * exp_decay(tt, 0.03))
    return out


def sfx_collect() -> np.ndarray:
    t = timeline(0.18, SFX_RATE)
    n = noise(len(t), SEED + 4)
    shh = (n - lowpass(n, 2500, SFX_RATE)) * adsr(t, 0.03, 0.05, 0.5, 0.08)
    rise = sine(sweep(500, 800, t), t) * adsr(t, 0.03, 0.05, 0.5, 0.08)
    return 0.4 * shh + 0.5 * rise


def _run(notes: list[int], step: float, length: float, tau: float, last_tau: float) -> np.ndarray:
    out = np.zeros(int(round(length * SFX_RATE)))
    for i, note in enumerate(notes):
        start = int(round(i * step * SFX_RATE))
        dur = length - i * step
        _place(out, start, marimba(midi_hz(note), dur, SFX_RATE,
                                   tau=last_tau if i == len(notes) - 1 else tau))
    return out


def sfx_advance() -> np.ndarray:
    return _run([72, 74, 76, 79, 81], step=0.04, length=0.28, tau=0.05, last_tau=0.08)


def sfx_gameover() -> np.ndarray:
    out = _run([79, 76, 74, 72], step=0.16, length=0.9, tau=0.20, last_tau=0.20)
    # Son nota hafifçe aşağı süzülür ("düşen" his).
    start = int(round(4 * 0.16 * SFX_RATE))
    t = timeline(0.9 - 4 * 0.16, SFX_RATE)
    f = sweep(midi_hz(69), midi_hz(69) * 0.94, t)
    _place(out, start, (sine(f, t) + 0.3 * sine(3.9 * f, t) * exp_decay(t, 0.03))
           * exp_decay(t, 0.12) * _attack(t))
    return out


def sfx_record() -> np.ndarray:
    out = _run([72, 76, 79], step=0.10, length=0.8, tau=0.10, last_tau=0.10)
    start = int(round(0.32 * SFX_RATE))
    dur = 0.8 - 0.32
    chord = sum(marimba(midi_hz(note), dur, SFX_RATE, tau=0.25) for note in (72, 76, 79, 84))
    _place(out, start, 0.6 * chord)
    return out


def sfx_click() -> np.ndarray:
    t = timeline(0.03, SFX_RATE)
    return sine(2200, t) * exp_decay(t, 0.004)


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

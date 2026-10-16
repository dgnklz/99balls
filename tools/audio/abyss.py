"""Abyss ses kimliği: okyanus dibi, biyolüminesans (PRD 8.5).

Sıcak, alçak ve yavaş filtre süpürmeli su altı pad'i; perdesi kayan "su
damlası" pluck'ları; yumuşak sonar ping'i ve kabarcık kümeleri. Orbitfall'ın
sabit perdeli sinüs plink/pad uzay sesinden (damlalar perde kaydırmalı, pad
filtre süpürmeli), Candy Burst'ün marimbasından ve Pixel Drop'un çiptününden
belirgin ayrışır. Melodi özgündür: bilinen su altı/köpekbalığı temalarına (yarım
ton ostinato yok), oyun ya da film müziklerine benzetilmedi.

Telefon hoparlörü: 200 Hz altı duyulmaz. Bas, kalp atışı ve derin tonlar tek
başına alçak frekans değildir; üst harmonikler (200 Hz üstü) taşır. SFX'lerin
ana enerjisi 300 Hz–3 kHz arasındadır; her şey 4 kHz'de alçak geçirgenden
geçer. Tüm rastgelelik sabit tohumludur (SEED).
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

THEME_ID = "abyss"
SEED = 0xAB1550

# --- Müzik: 75 BPM, 4/4, 10 ölçü (32.0 sn), F♯ minör (dorian renkli) ---
# F♯m9 – Dmaj7 – Bm9 – C♯m7 – Amaj7, her biri 2 ölçü.
BPM = 75
BEATS_PER_BAR = 4
BARS = 10
BARS_PER_CHORD = 2
TAIL_SEC = 2.5
MUSIC_RMS_DBFS = -16.0
CUTOFF = 4000

# Pad filtresinin süpürmesi: döngüde tam sayı periyot (2 ölçüde bir nefes).
PAD_CUTOFF_LOW = 900
PAD_CUTOFF_HIGH = 2200
PAD_SWEEP_BARS = 2

# Akorlar: (bas kökü, pad tonları) MIDI.
CHORDS = [
    (42, [57, 61, 64, 68]),  # F♯m9 (A C♯ E G♯ üstünde F♯ bas)
    (38, [57, 61, 62, 66]),  # Dmaj7
    (47, [62, 66, 69, 73]),  # Bm9
    (49, [59, 64, 68, 71]),  # C♯m7
    (45, [61, 64, 68, 69]),  # Amaj7
]

# Damla melodisi (dörtlük; None = sus). Seyrek, geniş aralıklı, F♯ minör
# pentatonik ağırlıklı; yarım ton tekrarı yok.
MELODY = [
    [73, None, 76, None],  # F♯m9
    [None, 69, None, 66],
    [74, None, None, 73],  # Dmaj7
    [None, 69, 78, None],
    [76, None, 71, None],  # Bm9
    [None, 74, None, 81],
    [80, None, 76, None],  # C♯m7
    [None, 71, None, 68],
    [73, None, 76, 81],  # Amaj7
    [None, 80, None, None],
]

# Melodi yankısı: noktalı sekizlik gecikme.
ECHO_BEATS = 0.75
ECHO_FEEDBACK = 0.35
ECHO_REPEATS = 3


def midi_hz(note: float) -> float:
    return 440.0 * 2 ** ((note - 69) / 12)


def _place(buf: np.ndarray, start: int, x: np.ndarray) -> None:
    end = min(len(buf), start + len(x))
    if end > start:
        buf[start:end] += x[: end - start]


def _echo(x: np.ndarray, delay_sec: float, feedback: float, repeats: int, rate: int) -> np.ndarray:
    """Basit yankı: her tekrar [feedback] kat sönük ve 4 kHz altı."""
    d = int(round(delay_sec * rate))
    out = np.zeros(len(x) + d * repeats)
    out[: len(x)] += x
    echo = x
    for k in range(1, repeats + 1):
        echo = lowpass(echo, 2500, rate) * feedback
        out[k * d : k * d + len(x)] += echo
    return out


def _lowpass_sweep(x: np.ndarray, cutoffs: np.ndarray, rate: int) -> np.ndarray:
    """Zamanla değişen kesimli tek kutuplu alçak geçiren (filtre süpürmesi)."""
    alpha = 1 - np.exp(-2 * np.pi * cutoffs / rate)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha[i] * (v - acc)
        y[i] = acc
    return y


def _rich(freq, t: np.ndarray, partials=(1.0, 0.55, 0.32, 0.18)) -> np.ndarray:
    """Harmonikli ton: alçak temel + 2.–4. harmonik (telefon hoparlöründe
    200 Hz üstünde duyulur)."""
    return sum(a * sine(np.asarray(freq) * (k + 1), t) for k, a in enumerate(partials))


def pad(tones: list[int], dur: float, rate: int) -> np.ndarray:
    """Hafif ayrık (detune) sinüs + üçgen; yavaş saldırı ve bırakma."""
    t = timeline(dur, rate)
    x = np.zeros_like(t)
    for note in tones:
        f = midi_hz(note)
        x += sine(f * 0.997, t) + sine(f * 1.003, t) + 0.35 * triangle(f, t)
    return x * adsr(t, 0.9, 0.5, 0.8, 1.2)


# Bas ve derin tonların harmonik ağırlığı: 2. harmonik temelden güçlü,
# böylece telefon hoparlöründe (200 Hz altı yok) bas çizgisi kaybolmaz.
BASS_PARTIALS = (0.45, 1.0, 0.6, 0.3)
BASS_OCTAVE_UP = 12


def bass(freq: float, dur: float, rate: int) -> np.ndarray:
    """Yumuşak bas: zayıf temel + güçlü harmonikler, nefes gibi şişen zarf."""
    t = timeline(dur, rate)
    return _rich(freq, t, BASS_PARTIALS) * adsr(t, 0.12, 0.3, 0.7, 0.4)


def drop(freq: float, dur: float, rate: int, tau: float = 0.22) -> np.ndarray:
    """Su damlası: ilk 25 ms'de perde 0.7f → f kayar, sonra sönümlenir."""
    t = timeline(dur, rate)
    glide = np.minimum(t / 0.025, 1.0)
    f = freq * (0.7 + 0.3 * glide)
    body = sine(f, t) + 0.28 * sine(2 * f, t) + 0.08 * sine(3 * f, t)
    return body * exp_decay(t, tau) * adsr(t, 0.003, 0.01, 1, 0.02)


def heartbeat(rate: int) -> np.ndarray:
    """Boğuk "lub-dub": aşağı süzülen üçgen + baskın 2. harmonik + kısa
    tıkırtı. Temel 150 Hz'e iner ama enerjinin çoğu 300 Hz–1.2 kHz'dedir."""
    out = np.zeros(int(round(0.45 * rate)))
    for at, gain in ((0.0, 1.0), (0.22, 0.6)):
        t = timeline(0.18, rate)
        f = sweep(260, 150, t)
        thump = 0.5 * triangle(f, t) + sine(2 * f, t)
        click = lowpass(noise(len(t), SEED + int(at * 100)), 1200, rate) * exp_decay(t, 0.012)
        _place(out, int(round(at * rate)), gain * (thump * exp_decay(t, 0.06) + 0.4 * click))
    return out


def bubble(f0: float, f1: float, dur: float, rate: int) -> np.ndarray:
    """Kabarcık: yükselen sinüs süpürmesi, kısa sönüm."""
    t = timeline(dur, rate)
    return sine(sweep(f0, f1, t), t) * exp_decay(t, dur / 3) * adsr(t, 0.002, 0.005, 1, 0.005)


def music_loop() -> np.ndarray:
    rate = MUSIC_RATE
    beat = 60 / BPM
    bar = beat * BEATS_PER_BAR
    n = int(round(BARS * bar * rate))
    total = n + int(TAIL_SEC * rate)
    pads = np.zeros(total)
    buf = np.zeros(total)
    rng = np.random.default_rng(SEED)

    for b in range(BARS):
        root, tones = CHORDS[(b // BARS_PER_CHORD) % len(CHORDS)]
        start = int(round(b * bar * rate))

        # Pad: akor başında 2 ölçü (bir sonraki akorla örtüşerek).
        if b % BARS_PER_CHORD == 0:
            _place(pads, start, 0.05 * pad(tones, bar * BARS_PER_CHORD + 0.8, rate))

        # Bas: 1. ve 3. vuruşta yarımlık; kök bir oktav yukarıda (147–277 Hz),
        # 2. harmonik baskın: telefon hoparlöründe de duyulur.
        for beat_i in (0, 2):
            _place(buf, start + int(round(beat_i * beat * rate)),
                   0.16 * bass(midi_hz(root + BASS_OCTAVE_UP), beat * 1.9, rate))

        # Kalp atışı: 1. vuruşta.
        _place(buf, start, 0.22 * heartbeat(rate))

        # Damla melodisi + yankı.
        for i, note in enumerate(MELODY[b]):
            if note is None:
                continue
            x = drop(midi_hz(note), beat * 1.6, rate)
            _place(buf, start + int(round(i * beat * rate)),
                   0.17 * _echo(x, ECHO_BEATS * beat, ECHO_FEEDBACK, ECHO_REPEATS, rate))

        # Kabarcık tıkırtıları: sekizliklerde seyrek (sabit tohum).
        for i in range(BEATS_PER_BAR * 2):
            if rng.random() < 0.3:
                f0 = 500 + 300 * rng.random()
                at = start + int(round(i * beat / 2 * rate))
                _place(buf, at, 0.035 * bubble(f0, f0 * 2.2, 0.04, rate))

    t = np.arange(total) / rate
    sweep_hz = 1 / (PAD_SWEEP_BARS * bar)
    cut = PAD_CUTOFF_LOW + (PAD_CUTOFF_HIGH - PAD_CUTOFF_LOW) * (1 - np.cos(2 * np.pi * sweep_hz * t)) / 2
    buf += _lowpass_sweep(pads, cut, rate)

    loop = seamless_loop(buf[:n], buf[n:])
    loop = lowpass(loop, CUTOFF, rate)
    loop = rotate_to_zero_crossing(loop)
    rms = np.sqrt(np.mean(loop**2))
    loop = loop * (10 ** (MUSIC_RMS_DBFS / 20) / rms)
    return normalize_peak(loop) if np.max(np.abs(loop)) > 10 ** (-3 / 20) else loop


# --- SFX (44.1 kHz) ---


def _sfx(x: np.ndarray) -> np.ndarray:
    return lowpass(x, CUTOFF, SFX_RATE)


def _tail(x: np.ndarray, sec: float) -> np.ndarray:
    """Diziyi [sec] uzunluğa keser ya da sıfırla doldurur."""
    n = int(round(sec * SFX_RATE))
    out = np.zeros(n)
    out[: min(n, len(x))] = x[:n]
    return out


def sfx_shoot() -> np.ndarray:
    t = timeline(0.07, SFX_RATE)
    f = sweep(520, 900, t)
    return _sfx((sine(f, t) + 0.3 * sine(2 * f, t)) * exp_decay(t, 0.025))


def sfx_wall() -> np.ndarray:
    t = timeline(0.04, SFX_RATE)
    tick = triangle(700, t) * exp_decay(t, 0.006)
    grit = lowpass(noise(len(t), SEED + 1), 2000, SFX_RATE) * exp_decay(t, 0.004)
    return _sfx(0.7 * tick + 0.3 * grit)


def _hit(ratio: float) -> np.ndarray:
    return _sfx(drop(midi_hz(73) * ratio, 0.11, SFX_RATE, tau=0.035))


def sfx_hit_1() -> np.ndarray:
    return _hit(1.0)


def sfx_hit_2() -> np.ndarray:
    return _hit(9 / 8)


def sfx_hit_3() -> np.ndarray:
    return _hit(6 / 5)


def sfx_break() -> np.ndarray:
    """Kabarcık patlaması: art arda yükselen kabarcıklar + harmonikli darbe."""
    out = np.zeros(int(round(0.38 * SFX_RATE)))
    rng = np.random.default_rng(SEED + 2)
    for i in range(6):
        f0 = 420 + 260 * rng.random()
        dur = 0.04 + 0.03 * rng.random()
        _place(out, int(round(i * 0.03 * SFX_RATE)), 0.55 * bubble(f0, f0 * 2.1, dur, SFX_RATE))
    t = timeline(0.2, SFX_RATE)
    f = sweep(320, 160, t)
    thump = (triangle(f, t) + 0.6 * sine(2 * f, t)) * exp_decay(t, 0.05)
    n = noise(int(round(0.25 * SFX_RATE)), SEED + 3)
    fizz = lowpass(n - lowpass(n, 600, SFX_RATE), 2500, SFX_RATE) * exp_decay(timeline(0.25, SFX_RATE), 0.05)
    _place(out, 0, 0.5 * thump)
    _place(out, 0, 0.35 * fizz)
    return _sfx(out)


def sfx_pickup() -> np.ndarray:
    """Sonar ping'i + yankı."""
    t = timeline(0.18, SFX_RATE)
    f = midi_hz(86)  # D6 ≈ 1175 Hz
    ping = (sine(f, t) + 0.3 * sine(f * 1.5, t)) * exp_decay(t, 0.06) * adsr(t, 0.004, 0.01, 1, 0.02)
    return _sfx(_tail(_echo(ping, 0.12, 0.38, 2, SFX_RATE), 0.42))


def sfx_star() -> np.ndarray:
    """Cam arpeji: çan benzeri (uyumsuz kısmi) üç nota."""
    out = np.zeros(int(round(0.42 * SFX_RATE)))
    for i, note in enumerate((85, 88, 92)):
        t = timeline(0.42 - i * 0.07, SFX_RATE)
        f = midi_hz(note)
        bell = (sine(f, t) + 0.25 * sine(f * 2.76, t)) * exp_decay(t, 0.09)
        _place(out, int(round(i * 0.07 * SFX_RATE)), 0.6 * bell * adsr(t, 0.003, 0.01, 1, 0.02))
    return _sfx(out)


def sfx_collect() -> np.ndarray:
    t = timeline(0.2, SFX_RATE)
    env = adsr(t, 0.05, 0.05, 0.6, 0.09)
    rise = (triangle(sweep(350, 700, t), t)) * env
    n = noise(len(t), SEED + 4)
    swish = lowpass(n - lowpass(n, 400, SFX_RATE), 2000, SFX_RATE) * env
    return _sfx(0.6 * rise + 0.35 * swish)


def sfx_advance() -> np.ndarray:
    """Derin glissando: 440 → 300 Hz, harmonikli (ana enerji 300 Hz üstünde)."""
    t = timeline(0.28, SFX_RATE)
    f = sweep(440, 300, t)
    return _sfx(_rich(f, t) * adsr(t, 0.02, 0.05, 0.8, 0.12))


def sfx_record() -> np.ndarray:
    out = np.zeros(int(round(0.85 * SFX_RATE)))
    for i, note in enumerate((73, 76, 80, 85)):
        t = timeline(0.85 - i * 0.09, SFX_RATE)
        f = midi_hz(note)
        bell = (sine(f, t) + 0.25 * sine(f * 2.76, t)) * exp_decay(t, 0.18)
        _place(out, int(round(i * 0.09 * SFX_RATE)), 0.45 * bell * adsr(t, 0.003, 0.01, 1, 0.05))
    start = int(round(0.36 * SFX_RATE))
    t = timeline(0.85 - 0.36, SFX_RATE)
    swell = sum(sine(midi_hz(note), t) for note in (61, 64, 68, 73)) * adsr(t, 0.08, 0.1, 0.6, 0.25)
    _place(out, start, 0.12 * swell)
    return _sfx(out)


def sfx_gameover() -> np.ndarray:
    """İnen tonlar (E5 → F♯4, harmonikli; son nota ~330 Hz'e süzülür) ve
    kapanan filtre."""
    out = np.zeros(int(round(0.95 * SFX_RATE)))
    notes = (76, 73, 69, 66)
    step = 0.16
    for i, note in enumerate(notes):
        dur = 0.95 - i * step
        t = timeline(dur, SFX_RATE)
        f = midi_hz(note)
        if i == len(notes) - 1:
            f = sweep(f, f * 0.9, t)
        tone = _rich(f, t, partials=(1.0, 0.45, 0.25)) * exp_decay(t, 0.16 if i < 3 else 0.25)
        _place(out, int(round(i * step * SFX_RATE)), 0.4 * tone * adsr(t, 0.01, 0.02, 1, 0.05))
    t = np.arange(len(out)) / SFX_RATE
    cut = 3000 - 2400 * (t / t[-1])
    return _sfx(_lowpass_sweep(out, cut, SFX_RATE))


def sfx_click() -> np.ndarray:
    return _sfx(bubble(900, 1500, 0.03, SFX_RATE))


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

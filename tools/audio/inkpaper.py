"""Ink & Paper ses kimliği: sumi-e atölyesi, kâğıt ve mürekkep (PRD 8.5).

Koto koparmaları (toplamalı, oshide süslemeli), sho benzeri kamış küme pad'i,
nefesli shakuhachi, mokugyo (ahşap balık) ve hyoshigi (ahşap tokmak); fırçanın
kâğıtta "fiş"i ve mürekkep lekesinin "şlap"ı. Orbitfall'ın sinüs uzayından,
Candy Burst'ün marimbasından, Pixel Drop'un çiptününden ve Abyss'in perde
kaydırmalı su damlası + yankısından belirgin ayrışır. Gam D in-sen
(D–E♭–G–A–C); melodi özgündür, bilinen bir eserden alınmadı.

Telefon hoparlörü: 200 Hz altı duyulmaz. Bas bir oktav yukarıda ve 2. harmonik
baskın; SFX'lerin ana enerjisi 300 Hz–3 kHz arasındadır; her şey 4 kHz'de
alçak geçirgenden geçer. Tüm rastgelelik sabit tohumludur (SEED).
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
    sine,
    sweep,
    timeline,
    triangle,
)

THEME_ID = "inkpaper"
SEED = 0x1A4B50

# --- Müzik: 84 BPM, 4/4, 11 ölçü (31.43 sn), D in-sen ---
# Biçim: A (0–3) + A′ (4–7) + "ma" kodası (8–10, seyrek, shakuhachi).
BPM = 84
BEATS_PER_BAR = 4
BARS = 11
TAIL_SEC = 2.5
MUSIC_RMS_DBFS = -17.0
# Müzik tepe tavanı (yumuşak sınırlayıcı; dosya yine −3 dBFS'e normalize edilir).
MUSIC_LIMIT_DBFS = -2.0
CUTOFF = 4000

# Bölümler: (başlangıç ölçüsü, bas kökü MIDI, sho küme tonları MIDI).
# Bas kökü bir oktav yukarıda çalınır (147–196 Hz), 2. harmonik baskın.
SECTIONS = [
    (0, 50, [62, 69, 74]),  # D
    (2, 55, [67, 74, 79]),  # G
    (4, 50, [62, 69, 75]),  # D + E♭ gerilimi
    (6, 48, [60, 67, 72]),  # C
    (8, 50, [62, 69, 74]),  # D (koda)
]

# Koto melodisi: ölçü başına (vuruş, MIDI, süre vuruş, oshide?).
KOTO = [
    [(0, 74, 1.5, False), (1.5, 75, 0.5, False), (2, 79, 1.5, True)],
    [(0.5, 81, 1, False), (2, 79, 0.5, False), (2.5, 75, 0.5, False), (3, 74, 1, False)],
    [(0, 72, 1.5, False), (2, 69, 1, False), (3, 72, 0.5, False), (3.5, 74, 0.5, False)],
    [(0, 75, 2, True)],
    [(0, 74, 1, False), (1, 79, 0.5, False), (1.5, 81, 0.5, False), (2, 84, 1.5, False)],
    [(0, 81, 1, False), (1.5, 79, 0.5, False), (2, 75, 1, True)],
    [(0, 74, 0.5, False), (0.5, 72, 0.5, False), (1, 69, 1, False), (2.5, 67, 0.5, False),
     (3, 69, 1, False)],
    [(0, 74, 3, True)],
    [],
    [(3, 81, 0.5, False)],
    [(0, 62, 1, False), (2, 74, 1, False)],
]

# Shakuhachi (koda): ölçü başına (vuruş, MIDI, süre vuruş).
SHAKUHACHI = {
    8: [(0, 69, 3)],
    9: [(0, 72, 1.5), (2, 74, 2)],
}

# Vurmalı: mokugyo çift ölçülerde 2. ve 4. vuruşta; hyoshigi cümle başlarında.
MOKUGYO_BARS = (0, 2, 4, 6)
MOKUGYO_BEATS = (1, 3)
HYOSHIGI_BARS = (0, 4, 8)


def midi_hz(note: float) -> float:
    return 440.0 * 2 ** ((note - 69) / 12)


def _place(buf: np.ndarray, start: int, x: np.ndarray) -> None:
    end = min(len(buf), start + len(x))
    if end > start:
        buf[start:end] += x[: end - start]


def _lowpass_sweep(x: np.ndarray, cutoffs: np.ndarray, rate: int) -> np.ndarray:
    """Zamanla değişen kesimli tek kutuplu alçak geçiren (filtre süpürmesi)."""
    alpha = 1 - np.exp(-2 * np.pi * cutoffs / rate)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha[i] * (v - acc)
        y[i] = acc
    return y


def _band(x: np.ndarray, low: float, high: float, rate: int) -> np.ndarray:
    """Bant geçiren: iki kez alçak geçiren (üstte daha dik iniş), sonra
    [low] altının çıkarılması. Gürültü 4 kHz üstüne taşmaz."""
    top = lowpass(lowpass(x, high, rate), high, rate)
    return top - lowpass(top, low, rate)


def _soft_limit(x: np.ndarray, ceiling: float) -> np.ndarray:
    """Yumuşak tepe sınırlayıcı (tanh): küçük örnekler neredeyse değişmez,
    koparma geçişlerinin tepeleri [ceiling]'i aşmaz."""
    return ceiling * np.tanh(x / ceiling)


def _tail(x: np.ndarray, sec: float, rate: int = SFX_RATE) -> np.ndarray:
    """Diziyi [sec] uzunluğa keser ya da sıfırla doldurur."""
    n = int(round(sec * rate))
    out = np.zeros(n)
    out[: min(n, len(x))] = x[:n]
    return out


def koto(freq: float, dur: float, rate: int, tau: float = 0.35, oshide: bool = False,
         seed: int = 0, pluck_gain: float = 0.6) -> np.ndarray:
    """Koto koparması: hafif uyumsuz 6 kısmi (üstler daha hızlı söner) + kısa
    koparma gürültüsü. oshide: notanın ortasında teli bastırıp yarım ton
    yükseltip bırakma süslemesi."""
    t = timeline(dur, rate)
    bend = np.zeros_like(t)
    if oshide and dur > 0.4:
        up0, up1 = 0.35 * dur, 0.35 * dur + 0.1
        down0, down1 = 0.7 * dur, 0.7 * dur + 0.12
        bend = np.clip((t - up0) / (up1 - up0), 0, 1) - np.clip((t - down0) / (down1 - down0), 0, 1)
    f = freq * 2 ** (bend / 12)
    x = np.zeros_like(t)
    for k in range(1, 7):
        stretch = 1 + 0.0008 * k * k
        x += (1 / k**1.1) * sine(f * k * stretch, t) * exp_decay(t, tau / (1 + 0.6 * (k - 1)))
    pluck = _band(noise(len(t), SEED + 100 + seed), 800, 3000, rate) * exp_decay(t, 0.004)
    return (x + pluck_gain * pluck) * adsr(t, 0.002, 0.01, 1, min(0.04, dur / 3))


# Bas: 2. harmonik temelden güçlü (telefon hoparlöründe 200 Hz altı yok).
BASS_PARTIALS = (0.45, 1.0, 0.6, 0.35, 0.2)


def bass(freq: float, dur: float, rate: int) -> np.ndarray:
    """Alçak koto teli: harmonikli, yavaş sönen."""
    t = timeline(dur, rate)
    x = sum(a * sine(freq * (k + 1), t) for k, a in enumerate(BASS_PARTIALS))
    return x * exp_decay(t, 0.7) * adsr(t, 0.004, 0.02, 1, 0.3)


def sho(tones: list[int], dur: float, rate: int) -> np.ndarray:
    """Sho benzeri kamış kümesi: bant sınırlı kare dalgalar, yavaş kabarma."""
    t = timeline(dur, rate)
    x = np.zeros_like(t)
    for note in tones:
        f = midi_hz(note)
        x += pulse(f * 0.998, 0.5, t, max_hz=2500) + pulse(f * 1.002, 0.5, t, max_hz=2500)
    return lowpass(x, 1800, rate) * adsr(t, 1.5, 0.3, 0.85, 1.2)


def shakuhachi(freq: float, dur: float, rate: int, seed: int = 0, fall: float = 1.0) -> np.ndarray:
    """Nefesli bambu flüt: meri (yarım ton alttan girme), gecikmeli vibrato,
    filtreli nefes gürültüsü. fall < 1: son %40'ta perde aşağı süzülür."""
    t = timeline(dur, rate)
    meri = 2 ** (-np.clip(1 - t / 0.15, 0, 1) / 12)
    vibrato = 1 + 0.006 * np.clip((t - 0.25) / 0.3, 0, 1) * np.sin(2 * np.pi * 5 * t)
    drop = 1 + (fall - 1) * np.clip((t / dur - 0.6) / 0.4, 0, 1)
    f = freq * meri * vibrato * drop
    tone = sine(f, t) + 0.25 * sine(2 * f, t) + 0.08 * sine(3 * f, t)
    breath = _band(noise(len(t), SEED + 200 + seed), freq * 0.8, freq * 3, rate)
    return (tone + 0.35 * breath) * adsr(t, 0.12, 0.1, 0.85, min(0.3, dur / 3))


def mokugyo(freq: float, rate: int, tau: float = 0.03, seed: int = 0) -> np.ndarray:
    """Ahşap balık: içi boş tahta "tok" + çok kısa tıkırtı."""
    t = timeline(max(0.12, 6 * tau), rate)
    body = sine(freq, t) * exp_decay(t, tau) + 0.4 * sine(2.3 * freq, t) * exp_decay(t, tau / 2.5)
    click = lowpass(noise(len(t), SEED + 300 + seed), 3000, rate) * exp_decay(t, 0.003)
    return body + 0.5 * click


def hyoshigi(freq: float, rate: int, seed: int = 0) -> np.ndarray:
    """Ahşap tokmak: sert, kuru "tak"."""
    t = timeline(0.08, rate)
    body = sine(freq, t) * exp_decay(t, 0.012) + 0.6 * sine(2.8 * freq, t) * exp_decay(t, 0.006)
    n = noise(len(t), SEED + 400 + seed)
    click = (n - lowpass(n, 1000, rate)) * exp_decay(t, 0.004)
    return body + 0.5 * lowpass(click, 3500, rate)


def orin(freq: float, dur: float, rate: int, tau: float) -> np.ndarray:
    """Tapınak kâsesi: uyumsuz kısmiler (1, 2.71) ve 3 Hz vuruşma + vuruş tıkı."""
    t = timeline(dur, rate)
    beat = sine(freq, t) + sine(freq + 3, t)
    upper = 0.35 * (sine(freq * 2.71, t) + sine(freq * 2.71 + 4, t))
    strike = lowpass(noise(len(t), SEED + 500), 3000, rate) * exp_decay(t, 0.003)
    return (0.5 * (beat * exp_decay(t, tau) + upper * exp_decay(t, tau / 2)) + 0.3 * strike) * adsr(
        t, 0.002, 0.01, 1, min(0.05, dur / 4))


def music_loop() -> np.ndarray:
    rate = MUSIC_RATE
    beat = 60 / BPM
    bar = beat * BEATS_PER_BAR
    n = int(round(BARS * bar * rate))
    total = n + int(TAIL_SEC * rate)
    buf = np.zeros(total)

    def at(b: int, beat_pos: float) -> int:
        return int(round((b * BEATS_PER_BAR + beat_pos) * beat * rate))

    # Sho pad + bas: her bölümün başında, bölüm boyunca (bir sonrakiyle örtüşerek).
    for i, (start_bar, root, tones) in enumerate(SECTIONS):
        end_bar = SECTIONS[i + 1][0] if i + 1 < len(SECTIONS) else BARS
        length = (end_bar - start_bar) * bar
        _place(buf, at(start_bar, 0), 0.035 * sho(tones, length + 1.0, rate))
        for b in range(start_bar, end_bar):
            _place(buf, at(b, 0), 0.15 * bass(midi_hz(root + 12), bar * 0.95, rate))

    # Koto melodisi.
    for b, notes in enumerate(KOTO):
        for i, (pos, note, length, bend) in enumerate(notes):
            x = koto(midi_hz(note), length * beat + 0.6, rate, oshide=bend, seed=b * 8 + i,
                     pluck_gain=0.3)
            _place(buf, at(b, pos), 0.17 * x)

    # Shakuhachi (koda).
    for b, notes in SHAKUHACHI.items():
        for i, (pos, note, length) in enumerate(notes):
            _place(buf, at(b, pos), 0.11 * shakuhachi(midi_hz(note), length * beat, rate, seed=b * 4 + i))

    # Vurmalı.
    for b in MOKUGYO_BARS:
        for k, pos in enumerate(MOKUGYO_BEATS):
            _place(buf, at(b, pos), 0.10 * mokugyo(780 if k == 0 else 700, rate, seed=b * 2 + k))
    for b in HYOSHIGI_BARS:
        _place(buf, at(b, 0), 0.05 * hyoshigi(1150, rate, seed=b))

    loop = seamless_loop(buf[:n], buf[n:])
    loop = lowpass(loop, CUTOFF, rate)
    loop = rotate_to_zero_crossing(loop)
    rms = np.sqrt(np.mean(loop**2))
    loop = _soft_limit(loop * (10 ** (MUSIC_RMS_DBFS / 20) / rms), 10 ** (MUSIC_LIMIT_DBFS / 20))
    return normalize_peak(loop) if np.max(np.abs(loop)) > 10 ** (-3 / 20) else loop


# --- SFX (44.1 kHz) ---


def _sfx(x: np.ndarray) -> np.ndarray:
    return lowpass(x, CUTOFF, SFX_RATE)


def sfx_shoot() -> np.ndarray:
    """Fırçanın kâğıtta "fiş"i: yükselen bant gürültüsü + minik tık."""
    t = timeline(0.07, SFX_RATE)
    n = noise(len(t), SEED + 1)
    cut = sweep(1500, 2600, t)
    top = _lowpass_sweep(_lowpass_sweep(n, cut, SFX_RATE), cut, SFX_RATE)
    swish = top - lowpass(top, 1100, SFX_RATE)
    tick = sine(1200, t) * exp_decay(t, 0.004)
    return _sfx((2.2 * swish * adsr(t, 0.008, 0.01, 1, 0.02) + 0.4 * tick) * exp_decay(t, 0.025))


def sfx_wall() -> np.ndarray:
    """Kâğıda dokunuş: kuru "tok" + hışırtı."""
    t = timeline(0.04, SFX_RATE)
    tok = triangle(900, t) * exp_decay(t, 0.005)
    rustle = lowpass(noise(len(t), SEED + 2), 3000, SFX_RATE) * exp_decay(t, 0.003)
    return _sfx(0.75 * tok + 0.3 * rustle)


def _hit(note: int, seed: int) -> np.ndarray:
    return _sfx(koto(midi_hz(note), 0.1, SFX_RATE, tau=0.06, seed=seed))


def sfx_hit_1() -> np.ndarray:
    return _hit(69, 1)  # A4


def sfx_hit_2() -> np.ndarray:
    return _hit(72, 2)  # C5


def sfx_hit_3() -> np.ndarray:
    return _hit(74, 3)  # D5


def sfx_break() -> np.ndarray:
    """Mürekkep lekesi "şlap": 450–900 Hz ıslak gürültü patlaması + ahşap vuruş
    + sıçrayan damlacık tıkları + 1–2.5 kHz fırça kuyruğu."""
    dur = 0.38
    out = np.zeros(int(round(dur * SFX_RATE)))
    t = timeline(dur, SFX_RATE)
    splat = _band(noise(len(t), SEED + 3), 450, 900, SFX_RATE) * exp_decay(t, 0.05)
    _place(out, 0, 3.0 * splat)
    _place(out, 0, 0.6 * mokugyo(620, SFX_RATE, tau=0.035, seed=1))
    rng = np.random.default_rng(SEED + 4)
    for i in range(5):
        at = 0.05 + 0.15 * rng.random()
        td = timeline(0.03, SFX_RATE)
        drop = sine(1400 + 800 * rng.random(), td) * exp_decay(td, 0.004)
        _place(out, int(round(at * SFX_RATE)), 0.25 * drop)
    brush = _band(noise(len(t), SEED + 5), 1000, 2500, SFX_RATE)
    brush_env = np.clip(t / 0.04, 0, 1) * exp_decay(np.maximum(t - 0.04, 0), 0.09)
    _place(out, 0, 1.4 * brush * brush_env)
    return _sfx(out)


def sfx_pickup() -> np.ndarray:
    """Hanko "tok"u + yukarı koto süpürmesi D5–G5–A5."""
    dur = 0.36
    out = np.zeros(int(round(dur * SFX_RATE)))
    _place(out, 0, 0.6 * mokugyo(700, SFX_RATE, tau=0.015, seed=2))
    for i, note in enumerate((74, 79, 81)):
        start = 0.06 + 0.05 * i
        x = koto(midi_hz(note), dur - start, SFX_RATE, tau=0.12, seed=10 + i)
        _place(out, int(round(start * SFX_RATE)), 0.5 * x)
    return _sfx(out)


def sfx_star() -> np.ndarray:
    """Tek orin vuruşu (C6 ≈ 1047 Hz, kısmi ×2.71, 3 Hz vuruşma)."""
    return _sfx(orin(midi_hz(84), 0.42, SFX_RATE, tau=0.2))


def sfx_collect() -> np.ndarray:
    """Kâğıtta fırça süpürmesi: kabaran 800 Hz–2 kHz "şşş" + ahşap tık."""
    t = timeline(0.2, SFX_RATE)
    swish = _band(noise(len(t), SEED + 6), 800, 2000, SFX_RATE) * adsr(t, 0.06, 0.05, 0.7, 0.09)
    out = 2.0 * swish
    _place(out, 0, 0.3 * mokugyo(900, SFX_RATE, tau=0.01, seed=3))
    return _sfx(out)


def sfx_advance() -> np.ndarray:
    """Hyoshigi çift "tak-tak" (1.1 / 1.3 kHz, 90 ms arayla)."""
    out = np.zeros(int(round(0.26 * SFX_RATE)))
    _place(out, 0, hyoshigi(1100, SFX_RATE, seed=1))
    _place(out, int(round(0.09 * SFX_RATE)), 0.85 * hyoshigi(1300, SFX_RATE, seed=2))
    return _sfx(out)


def sfx_record() -> np.ndarray:
    """Koto sukui arpeji D4–G4–A4–C5–D5 + orin (D6)."""
    dur = 0.85
    out = np.zeros(int(round(dur * SFX_RATE)))
    for i, note in enumerate((62, 67, 69, 72, 74)):
        start = 0.07 * i
        x = koto(midi_hz(note), dur - start, SFX_RATE, tau=0.25, seed=20 + i)
        _place(out, int(round(start * SFX_RATE)), 0.4 * x)
    start = 0.4
    _place(out, int(round(start * SFX_RATE)), 0.5 * orin(midi_hz(86), dur - start, SFX_RATE, tau=0.3))
    return _sfx(out)


def sfx_gameover() -> np.ndarray:
    """İnen shakuhachi cümlesi D5–A4–E♭4 (meri girişli; son nota %6 aşağı
    süzülür), filtre 3 kHz → 600 Hz kapanır."""
    dur = 0.95
    out = np.zeros(int(round(dur * SFX_RATE)))
    phrase = ((0.0, 74, 0.32, 1.0), (0.3, 69, 0.32, 1.0), (0.6, 63, 0.35, 0.94))
    for i, (start, note, length, fall) in enumerate(phrase):
        x = shakuhachi(midi_hz(note), length, SFX_RATE, seed=30 + i, fall=fall)
        _place(out, int(round(start * SFX_RATE)), 0.5 * x)
    t = np.arange(len(out)) / SFX_RATE
    cut = 3000 - 2400 * (t / t[-1])
    return _sfx(_lowpass_sweep(out, cut, SFX_RATE))


def sfx_click() -> np.ndarray:
    return _sfx(_tail(mokugyo(1400, SFX_RATE, tau=0.004, seed=4), 0.03))


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

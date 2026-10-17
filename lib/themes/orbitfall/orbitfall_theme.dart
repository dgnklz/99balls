import 'dart:ui';

import '../game_theme.dart';
import '../hp_ramp.dart';
import 'orbitfall_renderer.dart';

/// Orbitfall: derin uzay, yörüngeler ve yıldız tozu (ücretsiz tema).
/// Gerekçe: docs/THEME.md.
const String kOrbitfallId = 'orbitfall';

/// Referans oyundan ayrışma (ASSUMPTIONS): çubuklar dolu mavi değil; yarı saydam,
/// nötre yakın koyu yüzey + ince açık kenar + nane vurgusu. Arka planda yönlü
/// "spot ışığı" yok, yalnızca dikey degrade ve yıldız tozu.
const ThemePalette orbitfallPalette = ThemePalette(
  bgTop: Color(0xFF0B1026),
  bgBottom: Color(0xFF1A1F4D),
  hudBar: Color(0x8C0B0A18),
  floorBar: Color(0x990B0A18),
  hudEdge: Color(0x66E6E1FF),
  hudAccent: Color(0xFF5CF2A0),
  accent: Color(0xFFDDF4FF),
  guide: Color(0xFF9EEBFF),
  pickupGlow: Color(0xFF5CF2A0),
  star: Color(0xFFFFC93C),
  bonusText: Color(0xFFFFD54A),
  spark: Color(0xFFBFF4FF),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFAEB6E0),
  danger: Color(0xFFFF4D5E),
  buttonPrimary: Color(0xFF4F6BFF),
  buttonSecondary: Color(0xFF2C3470),
  popupSurface: Color(0xFF1B2150),
  scrim: Color(0xFF000000),
  dust: Color(0xFFCFE3FF),
);

/// c0…c10: sıcak → soğuk → magenta; beyaz rakamla en az 3:1 kontrast (testli).
/// Düşük HP kırmızı/pembe değil, turuncu/amber (referans oyundan ayrışma).
const List<Color> orbitfallHpStops = [
  Color(0xFFD4570F), // c0 turuncu
  Color(0xFFB86E00), // c1 amber
  Color(0xFF8F8200), // c2 zeytin-altın
  Color(0xFF2E9A3E), // c3 parlak yeşil
  Color(0xFF12907F), // c4 turkuaz
  Color(0xFF1A86A8), // c5 açık camgöbeği
  Color(0xFF2B72D0), // c6 gök mavisi
  Color(0xFF3352D8), // c7 mavi
  Color(0xFF5440C8), // c8 indigo
  Color(0xFF9A3CC0), // c9 eflatun-pembe
  Color(0xFFC21E86), // c10 magenta
];

const ThemeEffects orbitfallEffects = ThemeEffects(
  hitSparks: 3,
  breakSparks: 8,
  ringSparks: 8,
  starSparks: 6,
  gameOverSparksPerTarget: 2,
);

/// Orbitfall ses kimliği (tools/audio/orbitfall.py ile üretilir).
const ThemeSounds orbitfallSounds = ThemeSounds(
  music: 'orbitfall/music_loop.wav',
  sfx: {
    SfxKey.shoot: ['orbitfall/sfx_shoot.wav'],
    SfxKey.wall: ['orbitfall/sfx_wall.wav'],
    SfxKey.hit: ['orbitfall/sfx_hit_1.wav', 'orbitfall/sfx_hit_2.wav', 'orbitfall/sfx_hit_3.wav'],
    SfxKey.breakTarget: ['orbitfall/sfx_break.wav'],
    SfxKey.pickup: ['orbitfall/sfx_pickup.wav'],
    SfxKey.star: ['orbitfall/sfx_star.wav'],
    SfxKey.collect: ['orbitfall/sfx_collect.wav'],
    SfxKey.advance: ['orbitfall/sfx_advance.wav'],
    SfxKey.record: ['orbitfall/sfx_record.wav'],
    SfxKey.gameOver: ['orbitfall/sfx_gameover.wav'],
    SfxKey.click: ['orbitfall/sfx_click.wav'],
  },
  durationsMs: {
    'orbitfall/sfx_shoot.wav': 60,
    'orbitfall/sfx_wall.wav': 40,
    'orbitfall/sfx_hit_1.wav': 90,
    'orbitfall/sfx_hit_2.wav': 90,
    'orbitfall/sfx_hit_3.wav': 90,
    'orbitfall/sfx_break.wav': 300,
    'orbitfall/sfx_pickup.wav': 250,
    'orbitfall/sfx_star.wav': 300,
    'orbitfall/sfx_collect.wav': 180,
    'orbitfall/sfx_advance.wav': 250,
    'orbitfall/sfx_record.wav': 800,
    'orbitfall/sfx_gameover.wav': 900,
    'orbitfall/sfx_click.wav': 40,
  },
);

final GameTheme orbitfallTheme = GameTheme(
  id: kOrbitfallId,
  isFree: true,
  displayName: (l10n) => l10n.themeOrbitfall,
  palette: orbitfallPalette,
  hpRamp: HpRamp(orbitfallHpStops),
  effects: orbitfallEffects,
  sounds: orbitfallSounds,
  createRenderer: OrbitfallRenderer.new,
);

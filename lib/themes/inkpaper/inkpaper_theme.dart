import 'dart:ui';

import '../game_theme.dart';
import '../hp_ramp.dart';
import 'inkpaper_renderer.dart';

/// Ink & Paper: sumi-e, el yapımı kâğıt üstünde fırça ve mürekkep. Tek açık
/// zeminli tema. Gerekçe: docs/THEME.md.
const String kInkPaperId = 'inkpaper';

/// Açık zeminde de referans ayrışma kuralı: çubuklar dolu mavi değil; yarı
/// saydam koyu sumi yüzey + ince açık kenar + altın yaprak vurgu. Koyu sumi
/// yüzeyin krem üstündeki bileşiği ≈ #5E5850: beyaz HUD rakamı 7:1. Öğretici
/// ve boost "»" krem zeminde okunsun diye koyu (`onBackground`, `onAccent`).
/// Tehlike rengi kırmızı değil sumi-kuro: kırmızı bu temada halkanın (ödül)
/// rengi; kâğıtta en güçlü sinyal koyuluktur.
const ThemePalette inkPaperPalette = ThemePalette(
  bgTop: Color(0xFFF1E8D6),
  bgBottom: Color(0xFFE4D6BC),
  hudBar: Color(0xB21E1A16),
  floorBar: Color(0xB21E1A16),
  hudEdge: Color(0xCCF4ECDC),
  hudAccent: Color(0xFFE2B65C),
  accent: Color(0xFF1E1B18),
  guide: Color(0xFF2E2924),
  pickupGlow: Color(0xFFD23A20),
  star: Color(0xFFD6A12E),
  bonusText: Color(0xFFD9A02A),
  spark: Color(0xFF24201D),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFC9BBA3),
  danger: Color(0xFF2A2420),
  buttonPrimary: Color(0xFFB8432A),
  buttonSecondary: Color(0xFF4A4038),
  popupSurface: Color(0xFF2A2420),
  scrim: Color(0xFF000000),
  dust: Color(0xFF6B6158),
  onBackgroundColor: Color(0xFF2A2420),
  onAccentColor: Color(0xFF1E1A16),
);

/// Mürekkep damlacığı renkleri: sumi, ai (çivit), bengara, kincha (koyu altın).
const List<Color> inkPaperConfetti = [
  Color(0xFF24201D),
  Color(0xFF2C3F86),
  Color(0xFF8B3A26),
  Color(0xFF8E6418),
];

/// c0…c10: aşı-kehribar → kuchiba hardal → yosun → çam iğnesi → tokusa → seiheki →
/// hanada → ai (çivit) → kikyō → murasaki → koyu gül kurusu. Açık zeminde
/// okunsun diye koyu ve doygun pigmentler: beyaz rakamla her HP'de ≥ 4.89:1,
/// zemine ≥ 3.41:1; düşük HP turuncu-kehribar (33.6°), kırmızı/pembe değil.
const List<Color> inkPaperHpStops = [
  Color(0xFF9E641A), // c0 aşı-kehribar
  Color(0xFF7E6E1A), // c1 kuchiba hardal
  Color(0xFF5E7024), // c2 yosun
  Color(0xFF2E6E3E), // c3 çam iğnesi
  Color(0xFF2A5E5A), // c4 tokusa
  Color(0xFF1F5C80), // c5 seiheki
  Color(0xFF34468C), // c6 hanada
  Color(0xFF2E2E6E), // c7 ai (çivit)
  Color(0xFF68367E), // c8 kikyō
  Color(0xFF7E2E66), // c9 murasaki
  Color(0xFF8E4A5C), // c10 koyu gül kurusu
];

const ThemeEffects inkPaperEffects = ThemeEffects(
  hitSparks: 4,
  breakSparks: 10,
  ringSparks: 8,
  starSparks: 8,
  gameOverSparksPerTarget: 2,
  confetti: inkPaperConfetti,
);

/// Ink & Paper ses kimliği (tools/audio/inkpaper.py ile üretilir).
const ThemeSounds inkPaperSounds = ThemeSounds(
  music: 'inkpaper/music_loop.wav',
  sfx: {
    SfxKey.shoot: ['inkpaper/sfx_shoot.wav'],
    SfxKey.wall: ['inkpaper/sfx_wall.wav'],
    SfxKey.hit: [
      'inkpaper/sfx_hit_1.wav',
      'inkpaper/sfx_hit_2.wav',
      'inkpaper/sfx_hit_3.wav',
    ],
    SfxKey.breakTarget: ['inkpaper/sfx_break.wav'],
    SfxKey.pickup: ['inkpaper/sfx_pickup.wav'],
    SfxKey.star: ['inkpaper/sfx_star.wav'],
    SfxKey.collect: ['inkpaper/sfx_collect.wav'],
    SfxKey.advance: ['inkpaper/sfx_advance.wav'],
    SfxKey.record: ['inkpaper/sfx_record.wav'],
    SfxKey.gameOver: ['inkpaper/sfx_gameover.wav'],
    SfxKey.click: ['inkpaper/sfx_click.wav'],
  },
  durationsMs: {
    'inkpaper/sfx_shoot.wav': 70,
    'inkpaper/sfx_wall.wav': 40,
    'inkpaper/sfx_hit_1.wav': 100,
    'inkpaper/sfx_hit_2.wav': 100,
    'inkpaper/sfx_hit_3.wav': 100,
    'inkpaper/sfx_break.wav': 380,
    'inkpaper/sfx_pickup.wav': 360,
    'inkpaper/sfx_star.wav': 420,
    'inkpaper/sfx_collect.wav': 200,
    'inkpaper/sfx_advance.wav': 260,
    'inkpaper/sfx_record.wav': 850,
    'inkpaper/sfx_gameover.wav': 950,
    'inkpaper/sfx_click.wav': 30,
  },
);

final GameTheme inkPaperTheme = GameTheme(
  id: kInkPaperId,
  isFree: false,
  displayName: (l10n) => l10n.themeInkPaper,
  palette: inkPaperPalette,
  hpRamp: HpRamp(inkPaperHpStops),
  effects: inkPaperEffects,
  sounds: inkPaperSounds,
  createRenderer: InkPaperRenderer.new,
);

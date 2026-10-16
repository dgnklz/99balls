import 'dart:ui';

import '../game_theme.dart';
import '../hp_ramp.dart';
import 'candyburst_renderer.dart';

/// Candy Burst: derin erik moru zemin üzerinde parlak şeker renkleri.
/// Gerekçe: docs/THEME.md.
const String kCandyBurstId = 'candyburst';

/// Referans oyundan ayrışma (ASSUMPTIONS): çubuklar dolu mavi değil; yarı saydam
/// koyu erik yüzey + ince açık kenar + gül-şeftali vurgu.
const ThemePalette candyBurstPalette = ThemePalette(
  bgTop: Color(0xFF2A1040),
  bgBottom: Color(0xFF4B1F6F),
  hudBar: Color(0x8C1A0A24),
  floorBar: Color(0x991A0A24),
  hudEdge: Color(0x66FFE6F0),
  hudAccent: Color(0xFFFFAE9E),
  accent: Color(0xFFFFF6FB),
  guide: Color(0xFFFFE3F1),
  pickupGlow: Color(0xFF7DF5C8),
  star: Color(0xFFFFC83D),
  bonusText: Color(0xFFFFD54A),
  spark: Color(0xFFFFE9F5),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFD9B8E8),
  danger: Color(0xFFFF5470),
  buttonPrimary: Color(0xFFE05A9C),
  buttonSecondary: Color(0xFF5A2A7A),
  popupSurface: Color(0xFF3A1656),
  scrim: Color(0xFF000000),
  dust: Color(0xFFFFE3F1),
);

/// Sedefli topun ince kenarı ve sakız halkasının iç çizgisi.
const Color kCandyPearlRim = Color(0xFFC9A7FF);
const Color kCandyRingInner = Color(0xFFFFC9A8);

/// Serpinti ve konfeti renkleri.
const List<Color> candyBurstConfetti = [
  Color(0xFFFF9AC1), // pembe
  Color(0xFF8EE6FF), // gök
  Color(0xFFFFE66D), // limon
  Color(0xFF9DF2B4), // nane
  Color(0xFFC9A7FF), // leylak
];

/// c0…c10 şeker tonları: mandalina → kayısı → limon-yeşil → elma → nane →
/// turkuaz → gök → yaban mersini → üzüm → erik-leylak → gül-pembe. Beyaz rakamla
/// en az 3:1 kontrast; düşük HP kırmızı/pembe değil (testli).
const List<Color> candyBurstHpStops = [
  Color(0xFFD9600F), // c0 mandalina
  Color(0xFFB0780A), // c1 şeftali-kayısı
  Color(0xFF8A9208), // c2 limon-yeşil
  Color(0xFF3A9A3C), // c3 elma yeşili
  Color(0xFF0F9178), // c4 nane
  Color(0xFF0D879C), // c5 turkuaz
  Color(0xFF2F74D2), // c6 gök mavisi
  Color(0xFF4A58DE), // c7 yaban mersini
  Color(0xFF6E44D4), // c8 üzüm
  Color(0xFFA23AC2), // c9 erik-leylak
  Color(0xFFCC2E7C), // c10 gül-pembe
];

const ThemeEffects candyBurstEffects = ThemeEffects(
  hitSparks: 4,
  breakSparks: 10,
  ringSparks: 8,
  starSparks: 8,
  gameOverSparksPerTarget: 2,
  confetti: candyBurstConfetti,
);

/// Candy Burst ses kimliği (tools/audio/candyburst.py ile üretilir).
const ThemeSounds candyBurstSounds = ThemeSounds(
  music: 'candyburst/music_loop.wav',
  sfx: {
    SfxKey.shoot: ['candyburst/sfx_shoot.wav'],
    SfxKey.wall: ['candyburst/sfx_wall.wav'],
    SfxKey.hit: [
      'candyburst/sfx_hit_1.wav',
      'candyburst/sfx_hit_2.wav',
      'candyburst/sfx_hit_3.wav',
    ],
    SfxKey.breakTarget: ['candyburst/sfx_break.wav'],
    SfxKey.pickup: ['candyburst/sfx_pickup.wav'],
    SfxKey.star: ['candyburst/sfx_star.wav'],
    SfxKey.collect: ['candyburst/sfx_collect.wav'],
    SfxKey.advance: ['candyburst/sfx_advance.wav'],
    SfxKey.record: ['candyburst/sfx_record.wav'],
    SfxKey.gameOver: ['candyburst/sfx_gameover.wav'],
    SfxKey.click: ['candyburst/sfx_click.wav'],
  },
  durationsMs: {
    'candyburst/sfx_shoot.wav': 70,
    'candyburst/sfx_wall.wav': 35,
    'candyburst/sfx_hit_1.wav': 100,
    'candyburst/sfx_hit_2.wav': 100,
    'candyburst/sfx_hit_3.wav': 100,
    'candyburst/sfx_break.wav': 350,
    'candyburst/sfx_pickup.wav': 200,
    'candyburst/sfx_star.wav': 450,
    'candyburst/sfx_collect.wav': 180,
    'candyburst/sfx_advance.wav': 280,
    'candyburst/sfx_record.wav': 800,
    'candyburst/sfx_gameover.wav': 900,
    'candyburst/sfx_click.wav': 30,
  },
);

final GameTheme candyBurstTheme = GameTheme(
  id: kCandyBurstId,
  isFree: false,
  isPlaceholder: false,
  displayName: (l10n) => l10n.themeCandyBurst,
  palette: candyBurstPalette,
  hpRamp: HpRamp(candyBurstHpStops),
  effects: candyBurstEffects,
  sounds: candyBurstSounds,
  createRenderer: CandyBurstRenderer.new,
);

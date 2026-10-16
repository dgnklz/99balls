import 'dart:ui';

import '../game_theme.dart';
import '../hp_ramp.dart';
import 'pixeldrop_renderer.dart';

/// Pixel Drop: koyu kahve-zeytin zemin üzerinde kodla çizilen piksel dünyası.
/// Gerekçe: docs/THEME.md.
const String kPixelDropId = 'pixeldrop';

/// Referans oyundan ayrışma (ASSUMPTIONS): çubuklar dolu mavi değil; yarı saydam
/// koyu kahve yüzey + ince açık krem kenar + amber vurgu. Zemin tek ton yeşil
/// değil (dört tonlu yeşil el konsolu paletini çağrıştırmaz; testli).
const ThemePalette pixelDropPalette = ThemePalette(
  bgTop: Color(0xFF17140D),
  bgBottom: Color(0xFF2A2616),
  hudBar: Color(0x8C120F09),
  floorBar: Color(0x99120F09),
  hudEdge: Color(0x66FFF0D0),
  hudAccent: Color(0xFFFFC24A),
  accent: Color(0xFFFFF3D6),
  guide: Color(0xFFFFE9B8),
  pickupGlow: Color(0xFF66E6FF),
  star: Color(0xFFFFD23F),
  bonusText: Color(0xFFFFD54A),
  spark: Color(0xFFFFF3D6),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFFCBBF9A),
  danger: Color(0xFFFF5A3C),
  buttonPrimary: Color(0xFFE0A030),
  buttonSecondary: Color(0xFF4A4128),
  popupSurface: Color(0xFF2A2416),
  scrim: Color(0xFF000000),
  dust: Color(0xFFFFF0D0),
);

/// Düşen piksel blokları ve konfeti renkleri: amber, camgöbeği, orkide, krem.
const List<Color> pixelDropConfetti = [
  Color(0xFFFFC24A),
  Color(0xFF66E6FF),
  Color(0xFFE28CFF),
  Color(0xFFFFF3D6),
];

/// c0…c10: mandalina → amber → hardal → çimen → deniz → petrol → gök → çivit →
/// mor → orkide → mürdüm. Kenar yumuşatmasız piksel rakam için Candy Burst'ten
/// koyu ve doygun: beyazla her durakta en az 4.5:1 (test en az 3:1 ister);
/// düşük HP turuncu, kırmızı/pembe değil (testli).
const List<Color> pixelDropHpStops = [
  Color(0xFFC24E00), // c0 mandalina
  Color(0xFF9A5F00), // c1 amber
  Color(0xFF6E7000), // c2 hardal
  Color(0xFF2F7A14), // c3 çimen
  Color(0xFF00754E), // c4 deniz
  Color(0xFF006E7A), // c5 petrol
  Color(0xFF2458B0), // c6 gök
  Color(0xFF4B3FC0), // c7 çivit
  Color(0xFF7A30B4), // c8 mor
  Color(0xFF9C2A8C), // c9 orkide
  Color(0xFF7A2058), // c10 mürdüm
];

const ThemeEffects pixelDropEffects = ThemeEffects(
  hitSparks: 4,
  breakSparks: 10,
  ringSparks: 8,
  starSparks: 8,
  gameOverSparksPerTarget: 2,
  confetti: pixelDropConfetti,
);

/// Pixel Drop ses kimliği (tools/audio/pixeldrop.py ile üretilir).
const ThemeSounds pixelDropSounds = ThemeSounds(
  music: 'pixeldrop/music_loop.wav',
  sfx: {
    SfxKey.shoot: ['pixeldrop/sfx_shoot.wav'],
    SfxKey.wall: ['pixeldrop/sfx_wall.wav'],
    SfxKey.hit: [
      'pixeldrop/sfx_hit_1.wav',
      'pixeldrop/sfx_hit_2.wav',
      'pixeldrop/sfx_hit_3.wav',
    ],
    SfxKey.breakTarget: ['pixeldrop/sfx_break.wav'],
    SfxKey.pickup: ['pixeldrop/sfx_pickup.wav'],
    SfxKey.star: ['pixeldrop/sfx_star.wav'],
    SfxKey.collect: ['pixeldrop/sfx_collect.wav'],
    SfxKey.advance: ['pixeldrop/sfx_advance.wav'],
    SfxKey.record: ['pixeldrop/sfx_record.wav'],
    SfxKey.gameOver: ['pixeldrop/sfx_gameover.wav'],
    SfxKey.click: ['pixeldrop/sfx_click.wav'],
  },
  durationsMs: {
    'pixeldrop/sfx_shoot.wav': 60,
    'pixeldrop/sfx_wall.wav': 35,
    'pixeldrop/sfx_hit_1.wav': 80,
    'pixeldrop/sfx_hit_2.wav': 80,
    'pixeldrop/sfx_hit_3.wav': 80,
    'pixeldrop/sfx_break.wav': 320,
    'pixeldrop/sfx_pickup.wav': 210,
    'pixeldrop/sfx_star.wav': 360,
    'pixeldrop/sfx_collect.wav': 180,
    'pixeldrop/sfx_advance.wav': 240,
    'pixeldrop/sfx_record.wav': 800,
    'pixeldrop/sfx_gameover.wav': 900,
    'pixeldrop/sfx_click.wav': 30,
  },
);

final GameTheme pixelDropTheme = GameTheme(
  id: kPixelDropId,
  isFree: false,
  isPlaceholder: false,
  displayName: (l10n) => l10n.themePixelDrop,
  palette: pixelDropPalette,
  hpRamp: HpRamp(pixelDropHpStops),
  effects: pixelDropEffects,
  sounds: pixelDropSounds,
  createRenderer: PixelDropRenderer.new,
);

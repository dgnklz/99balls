import 'dart:ui';

import '../game_theme.dart';
import '../hp_ramp.dart';
import 'abyss_renderer.dart';

/// Abyss: okyanus dibi ve biyolüminesans. Gerekçe: docs/THEME.md.
const String kAbyssId = 'abyss';

/// Referans oyundan ayrışma (ASSUMPTIONS): çubuklar dolu mavi değil; yarı saydam
/// koyu petrol yüzey + ince açık kenar + biyolüminesan aqua vurgu. Arka planda
/// yönlü ışık/spot yok; yalnızca dikey degrade, kabarcık ve plankton tozu.
const ThemePalette abyssPalette = ThemePalette(
  bgTop: Color(0xFF031512),
  bgBottom: Color(0xFF0A2A2A),
  hudBar: Color(0x8C021210),
  floorBar: Color(0x99021210),
  hudEdge: Color(0x66D8FFF4),
  hudAccent: Color(0xFF5FF5E0),
  accent: Color(0xFFD8FFF8),
  guide: Color(0xFFA8F5EA),
  pickupGlow: Color(0xFFC8FF6E),
  star: Color(0xFFFFB84A),
  bonusText: Color(0xFFFFD54A),
  spark: Color(0xFFBFFFF2),
  textPrimary: Color(0xFFFFFFFF),
  textSecondary: Color(0xFF9CC9C0),
  danger: Color(0xFFFF5A50),
  buttonPrimary: Color(0xFF1FB8A4),
  buttonSecondary: Color(0xFF12403C),
  popupSurface: Color(0xFF0C2A28),
  scrim: Color(0xFF000000),
  dust: Color(0xFFCFEFE6),
);

/// Konfeti ve kabarcık kıvılcımı renkleri: aqua, fosforlu limon, lavanta, inci.
const List<Color> abyssConfetti = [
  Color(0xFF5FF5E0),
  Color(0xFFC8FF6E),
  Color(0xFFB79CFF),
  Color(0xFFE0FFF8),
];

/// c0…c10: bakır-turuncu (fener ışığı) → amber → yosun-sarı → deniz marulu →
/// deniz yeşili → lagün → gök → derin mavi → çivit-mor → mor → magenta.
/// Zemin tonu (170–180°) bilerek boş bırakıldı: c3 sarıya (90°), c5 maviye
/// (202°) kayık; her hedefin açık kenarı zeminden ≥ 3:1 (testli). Beyazla her
/// durakta ≥ 3:1; düşük HP turuncu, kırmızı/pembe değil (testli).
const List<Color> abyssHpStops = [
  Color(0xFFBE6838), // c0 bakır-turuncu
  Color(0xFFA57328), // c1 amber
  Color(0xFF827D28), // c2 yosun-sarı
  Color(0xFF609628), // c3 deniz marulu
  Color(0xFF1E8A5A), // c4 deniz yeşili
  Color(0xFF007ABE), // c5 lagün
  Color(0xFF0A64D7), // c6 gök
  Color(0xFF2442BA), // c7 derin mavi
  Color(0xFF6446AA), // c8 çivit-mor
  Color(0xFF803496), // c9 mor
  Color(0xFFAA1EA0), // c10 magenta
];

const ThemeEffects abyssEffects = ThemeEffects(
  hitSparks: 4,
  breakSparks: 10,
  ringSparks: 8,
  starSparks: 8,
  gameOverSparksPerTarget: 2,
  confetti: abyssConfetti,
);

/// Abyss ses kimliği (tools/audio/abyss.py ile üretilir).
const ThemeSounds abyssSounds = ThemeSounds(
  music: 'abyss/music_loop.wav',
  sfx: {
    SfxKey.shoot: ['abyss/sfx_shoot.wav'],
    SfxKey.wall: ['abyss/sfx_wall.wav'],
    SfxKey.hit: [
      'abyss/sfx_hit_1.wav',
      'abyss/sfx_hit_2.wav',
      'abyss/sfx_hit_3.wav',
    ],
    SfxKey.breakTarget: ['abyss/sfx_break.wav'],
    SfxKey.pickup: ['abyss/sfx_pickup.wav'],
    SfxKey.star: ['abyss/sfx_star.wav'],
    SfxKey.collect: ['abyss/sfx_collect.wav'],
    SfxKey.advance: ['abyss/sfx_advance.wav'],
    SfxKey.record: ['abyss/sfx_record.wav'],
    SfxKey.gameOver: ['abyss/sfx_gameover.wav'],
    SfxKey.click: ['abyss/sfx_click.wav'],
  },
  durationsMs: {
    'abyss/sfx_shoot.wav': 70,
    'abyss/sfx_wall.wav': 40,
    'abyss/sfx_hit_1.wav': 110,
    'abyss/sfx_hit_2.wav': 110,
    'abyss/sfx_hit_3.wav': 110,
    'abyss/sfx_break.wav': 380,
    'abyss/sfx_pickup.wav': 420,
    'abyss/sfx_star.wav': 420,
    'abyss/sfx_collect.wav': 200,
    'abyss/sfx_advance.wav': 280,
    'abyss/sfx_record.wav': 850,
    'abyss/sfx_gameover.wav': 950,
    'abyss/sfx_click.wav': 30,
  },
);

final GameTheme abyssTheme = GameTheme(
  id: kAbyssId,
  isFree: false,
  isPlaceholder: false,
  displayName: (l10n) => l10n.themeAbyss,
  palette: abyssPalette,
  hpRamp: HpRamp(abyssHpStops),
  effects: abyssEffects,
  sounds: abyssSounds,
  createRenderer: AbyssRenderer.new,
);

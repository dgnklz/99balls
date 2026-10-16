import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../core/config/game_config.dart';
import '../l10n/app_localizations.dart';
import 'hp_ramp.dart';
import 'render_batches.dart';

/// Temaya bağlı ses olayları (PRD 8.2 anahtarları).
enum SfxKey { shoot, wall, hit, breakTarget, pickup, star, collect, advance, record, gameOver, click }

/// Tema renkleri (PRD 7.4 alanları + yıldız ve nişan çizgisi).
@immutable
class ThemePalette {
  final Color bgTop;
  final Color bgBottom;

  /// HUD ve zemin çubuğu yüzeyi (yarı saydam; dolu renk çubuk değil).
  final Color hudBar;
  final Color floorBar;

  /// Çubukların oyun alanına bakan ince kenar çizgisi.
  final Color hudEdge;

  /// Kenar çizgisinin ortasındaki tema vurgusu.
  final Color hudAccent;

  /// Atılan top.
  final Color accent;
  final Color guide;
  final Color pickupGlow;
  final Color star;

  /// Yıldız "+3" yazısı (her zeminde okunur altın).
  final Color bonusText;
  final Color spark;
  final Color textPrimary;
  final Color textSecondary;
  final Color danger;
  final Color buttonPrimary;
  final Color buttonSecondary;
  final Color popupSurface;
  final Color scrim;

  /// Arka plandaki yıldız tozu (yoksa saydam).
  final Color dust;

  const ThemePalette({
    required this.bgTop,
    required this.bgBottom,
    required this.hudBar,
    required this.floorBar,
    required this.hudEdge,
    required this.hudAccent,
    required this.accent,
    required this.guide,
    required this.pickupGlow,
    required this.star,
    required this.bonusText,
    required this.spark,
    required this.textPrimary,
    required this.textSecondary,
    required this.danger,
    required this.buttonPrimary,
    required this.buttonSecondary,
    required this.popupSurface,
    required this.scrim,
    required this.dust,
  });
}

/// Olay başına efekt ayarları (sayılar efekt havuzlarının bütçesi içinde).
@immutable
class ThemeEffects {
  final int hitSparks;
  final int breakSparks;
  final int ringSparks;
  final int starSparks;
  final int gameOverSparksPerTarget;

  /// Konfeti renkleri: doluysa vuruş kıvılcımları bunlardan seçilir, kırılma
  /// kıvılcımları HP rengiyle dönüşümlü olur. Boşsa tek renk (görsel Random'dan
  /// fazladan sayı çekilmez).
  final List<Color> confetti;

  const ThemeEffects({
    required this.hitSparks,
    required this.breakSparks,
    required this.ringSparks,
    required this.starSparks,
    required this.gameOverSparksPerTarget,
    this.confetti = const [],
  });
}

/// Ses kimliği. Yollar `assets/audio/` altına göredir (flame_audio önbelleği).
@immutable
class ThemeSounds {
  final String music;

  /// Her olay için bir ya da daha fazla dosya (vuruşta 3 varyant).
  final Map<SfxKey, List<String>> sfx;

  /// SFX süreleri (ms); eş zamanlı ses sınırı için. Testle WAV'lara eşitlenir.
  final Map<String, int> durationsMs;

  const ThemeSounds({required this.music, required this.sfx, required this.durationsMs});

  List<String> get sfxFiles => [for (final files in sfx.values) ...files];
}

/// Temanın çizim nesnesi. Durumludur (arka plan animasyonu, önbellekli
/// Paint/Path/TextPainter); tema değişince yenisi üretilir, eskisi dispose edilir.
/// Tüm koordinatlar gu'dur.
abstract class ThemeRenderer {
  final GameTheme theme;
  double _pxPerGu = kSpritePxPerGu;

  ThemeRenderer(this.theme);

  /// Cihaz pikseli / gu: önceden pişirilen sprite'ların çözünürlüğü.
  double get pxPerGu => _pxPerGu;

  /// Oyun, tuval boyutu ya da tema değişince çağırır. Değer değişirse
  /// [onPixelRatioChanged] çalışır (sprite'lar yeniden üretilir).
  void setPixelRatio(double pxPerGu) {
    if (!(pxPerGu > 0) || (pxPerGu - _pxPerGu).abs() < 1e-6) return;
    _pxPerGu = pxPerGu;
    onPixelRatioChanged();
  }

  /// Piksel oranı değişti: pişmiş sprite'lar bırakılır, ilk çizimde yenilenir.
  @protected
  void onPixelRatioChanged() {}

  /// Arka plan animasyonu (gerçek zaman).
  void update(double dt);

  void paintBackground(Canvas canvas);

  /// Sayılı top. [fill] verilirse HP rengi yerine o kullanılır (ör. tehlike).
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill});

  /// Yok olma animasyonundaki düz renkli top (sayı yok).
  void paintTargetDisc(Canvas canvas, Color color, double opacity);

  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1});

  void paintStar(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1});

  void paintBall(Canvas canvas, double x, double y);

  /// Tek kıvılcım parçacığı; (vx, vy) ilk hız yönüdür (yönlü biçimler için).
  void paintSpark(Canvas canvas, double x, double y, double vx, double vy, double size, Color color);

  /// HUD ve zemin çubuğu; [dangerGlow] ∈ [0,1], [sweep] ∈ [0,1] ya da negatif (yok).
  /// [floorAccentX]: zemin neonunun merkezi (atış noktasını izler); üstteki
  /// neon ortada sabittir.
  void paintHud(
    Canvas canvas, {
    required int score,
    required int counter,
    required double dangerGlow,
    required double sweep,
    required double scoreScale,
    required double floorAccentX,
  });

  /// "+3" gibi yüzen yazı.
  void paintFloatText(Canvas canvas, String text, double x, double y, double opacity);

  /// Toplu çizim (M3p). Varsayılanlar tek tek çağrılara düşer; bir tema tek
  /// çağrıda çizmek için (ör. drawRawAtlas) ezebilir. Görünüm aynı olmalıdır.
  void paintBalls(Canvas canvas, BallBatch balls) {
    for (var i = 0; i < balls.length; i++) {
      paintBall(canvas, balls.x[i], balls.y[i]);
    }
  }

  void paintSparks(Canvas canvas, SparkBatch sparks) {
    for (var i = 0; i < sparks.length; i++) {
      paintSpark(canvas, sparks.x[i], sparks.y[i], sparks.vx[i], sparks.vy[i], sparks.size[i],
          Color(sparks.color[i]));
    }
  }

  /// Hedefler sırayla çizilir; [TargetBatch.fill] 0 değilse dolgu odur.
  void paintTargets(Canvas canvas, TargetBatch targets) {
    for (var i = 0; i < targets.length; i++) {
      final fill = targets.fill[i];
      paintTarget(canvas, targets.x[i], targets.y[i], targets.hp[i],
          scale: targets.scale[i], fill: fill == 0 ? null : Color(fill));
    }
  }

  void dispose();
}

/// Bir tema: yalnızca görünüm ve ses. Kurallar, yarıçaplar ve stateHash
/// hiçbir temada değişmez (PRD 7.4.1).
@immutable
class GameTheme {
  final String id;
  final bool isFree;

  /// M3a'da henüz tamamlanmamış tema (M3b–e'de doldurulacak).
  final bool isPlaceholder;
  final String Function(AppLocalizations l10n) displayName;
  final ThemePalette palette;
  final HpRamp hpRamp;
  final ThemeEffects effects;
  final ThemeSounds sounds;
  final ThemeRenderer Function(GameTheme theme) createRenderer;

  const GameTheme({
    required this.id,
    required this.isFree,
    required this.isPlaceholder,
    required this.displayName,
    required this.palette,
    required this.hpRamp,
    required this.effects,
    required this.sounds,
    required this.createRenderer,
  });

  @override
  String toString() => 'GameTheme($id)';
}

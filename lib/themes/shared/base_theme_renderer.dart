import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show mustCallSuper, protected;
import 'package:flutter/painting.dart' show FontWeight, Shadow, TextStyle;

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../game_theme.dart';
import '../text_cache.dart';

/// Temaların ortak çizim parçaları: HUD ve zemin çubuğu, HP rakamları, "+3"
/// yazısı, varsayılan yok olma diski ve kıvılcım. Temaya özgü olan (arka plan,
/// hedef, halka, yıldız, top) alt sınıflardadır.
///
/// HUD tüm temalarda aynı kurala uyar (referans oyundan ayrışma): dolu renk
/// çubuk değil; yarı saydam yüzey + oyun alanına bakan ince açık kenar + tema
/// vurgusu. Üst vurgu ortada sabit (süs); zemin vurgusu atış noktasını izler.
///
/// Paint'ler ve metinler bir kez üretilir; karede yeni Paint/Path/liste yok.
abstract class BaseThemeRenderer extends ThemeRenderer {
  static const Rect canvasRect = Rect.fromLTWH(0, 0, kVirtualW, kVirtualH);
  static const Rect _hudRect = Rect.fromLTWH(0, 0, kVirtualW, kCeilingY);
  static const Rect _floorRect = Rect.fromLTWH(0, kFloorY, kVirtualW, kVirtualH - kFloorY);
  static const Rect _dangerRect =
      Rect.fromLTWH(0, kFloorY - kDangerGlowHeight, kVirtualW, kDangerGlowHeight);

  final Paint _hud;
  final Paint _floor;
  final Paint _edge;
  final Paint _accentGlow;
  final Paint _accentLine;
  final Paint _overlay = Paint();
  final Paint _layer = Paint();
  final Paint _icon = Paint();
  final Paint _disc = Paint();
  final Paint _spark = Paint();

  final TextCache _hp2;
  final TextCache _hp3;
  final TextCache _hudNumbers;
  final TextCache _floatText;

  BaseThemeRenderer(super.theme)
      : _hud = Paint()..color = theme.palette.hudBar,
        _floor = Paint()..color = theme.palette.floorBar,
        _edge = Paint()
          ..strokeWidth = kHudEdgeStroke
          ..color = theme.palette.hudEdge,
        _accentGlow = Paint()
          ..strokeWidth = kHudAccentStroke
          ..strokeCap = StrokeCap.round
          ..color = theme.palette.hudAccent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kHudAccentGlowBlur),
        _accentLine = Paint()
          ..strokeWidth = kHudAccentStroke
          ..strokeCap = StrokeCap.round
          ..color = theme.palette.hudAccent,
        _hp2 = TextCache(numberStyle(theme, kTargetFontSize)),
        _hp3 = TextCache(numberStyle(theme, kTargetFontSize3Digits)),
        _hudNumbers = TextCache(numberStyle(theme, kHudFontSize)),
        _floatText = TextCache(floatTextStyle(theme));

  /// Yıldız "+3" yazısı: altın, kalın, büyük; 4 yönlü koyu ince kenarlık ve
  /// hafif gölge ile her zeminde okunur.
  static TextStyle floatTextStyle(GameTheme theme) {
    final outline = theme.palette.scrim.withValues(alpha: kFloatTextOutlineAlpha);
    return TextStyle(
      color: theme.palette.bonusText,
      fontSize: kFloatTextSize,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(color: outline, offset: const Offset(kFloatTextOutline, 0)),
        Shadow(color: outline, offset: const Offset(-kFloatTextOutline, 0)),
        Shadow(color: outline, offset: const Offset(0, kFloatTextOutline)),
        Shadow(color: outline, offset: const Offset(0, -kFloatTextOutline)),
        Shadow(color: outline, blurRadius: kFloatTextShadowBlur),
      ],
    );
  }

  /// Beyaz, kalın rakam ve hafif gölge (PRD 7.1).
  static TextStyle numberStyle(GameTheme theme, double size) => TextStyle(
        color: theme.palette.textPrimary,
        fontSize: size,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: theme.palette.scrim.withValues(alpha: kNumberShadowAlpha),
            offset: const Offset(0, kNumberShadowOffset),
            blurRadius: kNumberShadowBlur,
          ),
        ],
      );

  /// Orijin merkezli [kStarPoints] köşeli yıldız (bir kez üretilir).
  static Path buildStar() {
    const outer = kTargetRadius * kStarSizeRatio;
    const inner = outer * kStarInnerRatio;
    const vertices = kStarPoints * 2;
    final path = Path();
    for (var i = 0; i < vertices; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / kStarPoints;
      if (i == 0) {
        path.moveTo(r * math.cos(a), r * math.sin(a));
      } else {
        path.lineTo(r * math.cos(a), r * math.sin(a));
      }
    }
    return path..close();
  }

  /// Yıldız nabzı: [kStarPulseMin]…[kStarPulseMax], [kStarPulseSec] döngü.
  static double starPulse(double time) {
    final phase = math.sin(2 * math.pi * time / kStarPulseSec);
    return kStarPulseMin + (kStarPulseMax - kStarPulseMin) * (phase + 1) / 2;
  }

  /// Hedefin HP rakamı, (cx, cy) merkezli (3 hanede küçük yazı).
  @protected
  void paintHpNumber(Canvas canvas, int hp, double cx, double cy) =>
      (hp >= kThreeDigitThreshold ? _hp3 : _hp2).paintNumber(canvas, hp, cx, cy);

  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    _disc.color = color.withValues(alpha: opacity);
    canvas.drawCircle(Offset.zero, kTargetRadius, _disc);
  }

  /// Varsayılan kıvılcım: [size] çaplı nokta.
  @override
  void paintSpark(Canvas canvas, double x, double y, double vx, double vy, double size, Color color) {
    _spark.color = color;
    canvas.drawCircle(Offset(x, y), size / 2, _spark);
  }

  @override
  void paintHud(
    Canvas canvas, {
    required int score,
    required int counter,
    required double dangerGlow,
    required double sweep,
    required double scoreScale,
    required double floorAccentX,
  }) {
    canvas
      ..drawRect(_hudRect, _hud)
      ..drawRect(_floorRect, _floor)
      ..drawLine(const Offset(0, kCeilingY), const Offset(kVirtualW, kCeilingY), _edge)
      ..drawLine(const Offset(0, kFloorY), const Offset(kVirtualW, kFloorY), _edge);
    _paintAccents(canvas, _accentGlow, floorAccentX);
    _paintAccents(canvas, _accentLine, floorAccentX);
    if (dangerGlow > 0) {
      _overlay.color = theme.palette.danger.withValues(alpha: kDangerGlowAlpha * dangerGlow);
      canvas.drawRect(_dangerRect, _overlay);
    }
    if (sweep >= 0 && sweep <= 1) {
      final x = -kAdvanceSweepWidth + (kVirtualW + kAdvanceSweepWidth) * sweep;
      _overlay.color = theme.palette.accent.withValues(alpha: kSweepAlpha * (1 - sweep));
      canvas.drawRect(
        Rect.fromLTWH(x, kFloorY - kSweepHeight / 2, kAdvanceSweepWidth, kSweepHeight),
        _overlay,
      );
    }
    _icon.color = theme.palette.accent;
    canvas.drawCircle(
      const Offset(kHudBallIconX, kHudBallIconY),
      kHudBallIconDiameter / 2,
      _icon,
    );
    if (scoreScale != 1) {
      canvas
        ..save()
        ..translate(kHudScoreX, kHudScoreY)
        ..scale(scoreScale);
      _hudNumbers.paintNumber(canvas, score, 0, 0);
      canvas.restore();
    } else {
      _hudNumbers.paintNumber(canvas, score, kHudScoreX, kHudScoreY);
    }
    _hudNumbers.paintNumber(canvas, counter, kHudCounterX, kHudCounterY);
  }

  static const double _accentLeft = (kVirtualW - kHudAccentWidth) / 2;
  static const double _accentRight = (kVirtualW + kHudAccentWidth) / 2;
  static const double _accentHalf = kHudAccentWidth / 2;

  /// HUD alt kenarındaki (ortada) ve zemin üst kenarındaki ([floorX]) vurgu.
  static void _paintAccents(Canvas canvas, Paint paint, double floorX) => canvas
    ..drawLine(const Offset(_accentLeft, kCeilingY), const Offset(_accentRight, kCeilingY), paint)
    ..drawLine(Offset(floorX - _accentHalf, kFloorY), Offset(floorX + _accentHalf, kFloorY), paint);

  @override
  void paintFloatText(Canvas canvas, String text, double x, double y, double opacity) {
    if (opacity >= 1) {
      _floatText.paintText(canvas, text, x, y);
      return;
    }
    final size = _floatText.sizeOf(text);
    _layer.color = Color.fromRGBO(0, 0, 0, opacity);
    canvas.saveLayer(
      Rect.fromCenter(center: Offset(x, y), width: size.width, height: size.height),
      _layer,
    );
    _floatText.paintText(canvas, text, x, y);
    canvas.restore();
  }

  @override
  @mustCallSuper
  void dispose() {
    _hp2.dispose();
    _hp3.dispose();
    _hudNumbers.dispose();
    _floatText.dispose();
  }
}

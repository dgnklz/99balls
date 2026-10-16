import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/painting.dart' show FontWeight, Shadow, TextStyle;

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../game_theme.dart';
import '../text_cache.dart';

/// Orbitfall çizici: derin lacivert degrade, iki katmanlı kayan yıldız tozu,
/// HP renkli hedefler, nane halka, altın yıldız. Yer tutucu temalar da şimdilik
/// bu çiziciyi kendi paletleriyle kullanır.
///
/// Performans: degrade Shader'ı, Paint'ler, yıldız Path'i ve metinler bir kez
/// üretilir; yıldız tozu önceden ayrılmış Float32List'te tek `drawRawPoints`
/// çağrısıyla çizilir. Karede yeni Paint/Path/liste üretilmez.
class OrbitfallRenderer extends ThemeRenderer {
  static const Rect _canvasRect = Rect.fromLTWH(0, 0, kVirtualW, kVirtualH);
  static const Rect _hudRect = Rect.fromLTWH(0, 0, kVirtualW, kCeilingY);
  static const Rect _floorRect = Rect.fromLTWH(0, kFloorY, kVirtualW, kVirtualH - kFloorY);
  static const Rect _dangerRect =
      Rect.fromLTWH(0, kFloorY - kDangerGlowHeight, kVirtualW, kDangerGlowHeight);
  static const double _ringRadius = kPickupRadius - kPickupStroke / 2;
  static const double _ballRadius = kBallRadius - kBallStroke / 2;
  static const double _rimRadius = kTargetRadius - kTargetRimInset;

  final Paint _background;
  final Float32List _dustFar = Float32List(kStarDustPerLayer * 2);
  final Float32List _dustNear = Float32List(kStarDustPerLayer * 2);
  final Paint _dustFarPaint;
  final Paint _dustNearPaint;

  final Paint _fill = Paint();
  final Paint _rim;
  final Paint _ring;
  final Paint _ringGlow;
  final Paint _starPaint;
  final Paint _ball;
  final Paint _hud;
  final Paint _floor;
  final Paint _edge;
  final Paint _accentGlow;
  final Paint _accentLine;
  final Paint _overlay = Paint();
  final Paint _layer = Paint();
  final Path _starPath = _buildStar();

  final TextCache _hp2;
  final TextCache _hp3;
  final TextCache _hudNumbers;
  final TextCache _floatText;

  double _time = 0;

  OrbitfallRenderer(super.theme)
      : _background = Paint()
          ..shader = Gradient.linear(
            Offset.zero,
            const Offset(0, kVirtualH),
            [theme.palette.bgTop, theme.palette.bgBottom],
          ),
        _dustFarPaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = kStarDustSizeFar
          ..color = theme.palette.dust.withValues(alpha: kStarDustAlphaFar),
        _dustNearPaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = kStarDustSizeNear
          ..color = theme.palette.dust.withValues(alpha: kStarDustAlphaNear),
        _rim = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kTargetRimStroke
          ..color = theme.palette.textPrimary.withValues(alpha: kTargetRimAlpha),
        _ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kPickupStroke,
        _ringGlow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kPickupStroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kPickupGlowBlur),
        _starPaint = Paint(),
        _ball = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kBallStroke
          ..color = theme.palette.accent,
        _hud = Paint()..color = theme.palette.hudBar,
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
        _hp2 = TextCache(_numberStyle(theme, kTargetFontSize)),
        _hp3 = TextCache(_numberStyle(theme, kTargetFontSize3Digits)),
        _hudNumbers = TextCache(_numberStyle(theme, kHudFontSize)),
        _floatText = TextCache(_numberStyle(theme, kFloatTextSize)) {
    final random = math.Random(kVisualRandomSeed);
    for (final layer in [_dustFar, _dustNear]) {
      for (var i = 0; i < kStarDustPerLayer; i++) {
        layer[i * 2] = random.nextDouble() * kVirtualW;
        layer[i * 2 + 1] = random.nextDouble() * kVirtualH;
      }
    }
  }

  static TextStyle _numberStyle(GameTheme theme, double size) => TextStyle(
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

  static Path _buildStar() {
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

  @override
  void update(double dt) {
    if (!(dt > 0)) return;
    _time += dt;
    _drift(_dustFar, kStarDustSpeedFar * dt);
    _drift(_dustNear, kStarDustSpeedNear * dt);
  }

  static void _drift(Float32List points, double dy) {
    for (var i = 1; i < points.length; i += 2) {
      var y = points[i] + dy;
      if (y > kVirtualH) y -= kVirtualH;
      points[i] = y;
    }
  }

  @override
  void paintBackground(Canvas canvas) {
    canvas
      ..drawRect(_canvasRect, _background)
      ..drawRawPoints(PointMode.points, _dustFar, _dustFarPaint)
      ..drawRawPoints(PointMode.points, _dustNear, _dustNearPaint);
  }

  @override
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill}) {
    _fill.color = fill ?? theme.hpRamp.forHp(hp);
    final scaled = scale != 1;
    if (scaled) {
      canvas
        ..save()
        ..translate(x, y)
        ..scale(scale);
    }
    final cx = scaled ? 0.0 : x;
    final cy = scaled ? 0.0 : y;
    canvas
      ..drawCircle(Offset(cx, cy), kTargetRadius, _fill)
      ..drawCircle(Offset(cx, cy), _rimRadius, _rim);
    (hp >= kThreeDigitThreshold ? _hp3 : _hp2).paintNumber(canvas, hp, cx, cy);
    if (scaled) canvas.restore();
  }

  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    _fill.color = color.withValues(alpha: opacity);
    canvas.drawCircle(Offset.zero, kTargetRadius, _fill);
  }

  @override
  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final color = theme.palette.pickupGlow.withValues(alpha: opacity);
    _ringGlow.color = color;
    _ring.color = color;
    final r = _ringRadius * scale;
    canvas
      ..drawCircle(Offset(x, y), r, _ringGlow)
      ..drawCircle(Offset(x, y), r, _ring);
  }

  @override
  void paintStar(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final phase = math.sin(2 * math.pi * _time / kStarPulseSec);
    final pulse = kStarPulseMin + (kStarPulseMax - kStarPulseMin) * (phase + 1) / 2;
    _starPaint.color = theme.palette.star.withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(x, y)
      ..scale(scale * pulse)
      ..drawPath(_starPath, _starPaint)
      ..restore();
  }

  @override
  void paintBall(Canvas canvas, double x, double y) =>
      canvas.drawCircle(Offset(x, y), _ballRadius, _ball);

  @override
  void paintHud(
    Canvas canvas, {
    required int score,
    required int counter,
    required double dangerGlow,
    required double sweep,
    required double scoreScale,
  }) {
    // Yarı saydam yüzey + oyun alanına bakan ince açık kenar + ortada tema
    // vurgusu (dolu renk çubuk değil; referans oyundan ayrışma).
    canvas
      ..drawRect(_hudRect, _hud)
      ..drawRect(_floorRect, _floor)
      ..drawLine(const Offset(0, kCeilingY), const Offset(kVirtualW, kCeilingY), _edge)
      ..drawLine(const Offset(0, kFloorY), const Offset(kVirtualW, kFloorY), _edge);
    _paintAccents(canvas, _accentGlow);
    _paintAccents(canvas, _accentLine);
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
    _fill.color = theme.palette.accent;
    canvas.drawCircle(
      const Offset(kHudBallIconX, kHudBallIconY),
      kHudBallIconDiameter / 2,
      _fill,
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

  /// HUD alt kenarı ve zemin üst kenarının ortasındaki tema vurgusu.
  static void _paintAccents(Canvas canvas, Paint paint) => canvas
    ..drawLine(const Offset(_accentLeft, kCeilingY), const Offset(_accentRight, kCeilingY), paint)
    ..drawLine(const Offset(_accentLeft, kFloorY), const Offset(_accentRight, kFloorY), paint);

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
  void dispose() {
    _hp2.dispose();
    _hp3.dispose();
    _hudNumbers.dispose();
    _floatText.dispose();
  }
}

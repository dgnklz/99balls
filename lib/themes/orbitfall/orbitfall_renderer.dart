import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../shared/base_theme_renderer.dart';

/// Orbitfall çizici: derin lacivert degrade, iki katmanlı kayan yıldız tozu,
/// HP renkli hedefler, nane halka, altın yıldız. Yer tutucu temalar da şimdilik
/// bu çiziciyi kendi paletleriyle kullanır. HUD, rakamlar ve "+3" yazısı
/// [BaseThemeRenderer]'dadır.
///
/// Performans: degrade Shader'ı, Paint'ler ve yıldız Path'i bir kez üretilir;
/// yıldız tozu önceden ayrılmış Float32List'te tek `drawRawPoints` çağrısıyla
/// çizilir. Karede yeni Paint/Path/liste üretilmez.
class OrbitfallRenderer extends BaseThemeRenderer {
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
  final Path _starPath = BaseThemeRenderer.buildStar();

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
          ..color = theme.palette.accent {
    final random = math.Random(kVisualRandomSeed);
    for (final layer in [_dustFar, _dustNear]) {
      for (var i = 0; i < kStarDustPerLayer; i++) {
        layer[i * 2] = random.nextDouble() * kVirtualW;
        layer[i * 2 + 1] = random.nextDouble() * kVirtualH;
      }
    }
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
      ..drawRect(BaseThemeRenderer.canvasRect, _background)
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
    paintHpNumber(canvas, hp, cx, cy);
    if (scaled) canvas.restore();
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
    _starPaint.color = theme.palette.star.withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(x, y)
      ..scale(scale * BaseThemeRenderer.starPulse(_time))
      ..drawPath(_starPath, _starPaint)
      ..restore();
  }

  @override
  void paintBall(Canvas canvas, double x, double y) =>
      canvas.drawCircle(Offset(x, y), _ballRadius, _ball);
}

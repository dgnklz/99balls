import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../shared/base_theme_renderer.dart';
import 'candyburst_theme.dart';

/// Candy Burst çizici: erik moru degrade üzerinde iki kayan desen katmanı
/// (çapraz şeker şeritleri ve renkli serpinti), parlak vurgulu ve spiralli
/// şeker hedefler, sedefli beyaz top, nane sakız halkası, şeker kenarlı altın
/// yıldız, serpinti biçimli kıvılcımlar. HUD, rakamlar ve "+3" yazısı
/// [BaseThemeRenderer]'dadır.
///
/// Performans: desen katmanları bir kez [Picture] olarak kaydedilir; her karede
/// yalnızca kaydırılıp (translate) iki kez çizilir (sarma). Spiral ve yıldız
/// Path'leri ve tüm Paint'ler bir kez üretilir; karede tahsis yok.
class CandyBurstRenderer extends BaseThemeRenderer {
  static const double _ringRadius = kPickupRadius - kPickupStroke / 2;
  static const double _ballRadius = kBallRadius - kCandyBallRimStroke / 2;
  static const double _rimRadius = kTargetRadius - kTargetRimInset;
  static const Rect _gloss = Rect.fromLTRB(
    kCandyGlossX - kCandyGlossRadiusX,
    kCandyGlossY - kCandyGlossRadiusY,
    kCandyGlossX + kCandyGlossRadiusX,
    kCandyGlossY + kCandyGlossRadiusY,
  );

  final Paint _background;
  final Picture _stripes;
  final Picture _sprinkles;
  double _stripeOffset = 0;
  double _sprinkleOffset = 0;

  final Paint _fill = Paint();
  final Paint _glossPaint = Paint();
  final Paint _swirl;
  final Paint _rim;
  final Paint _ball;
  final Paint _ballRim;
  final Paint _ballGloss;
  final Paint _ring;
  final Paint _ringInner;
  final Paint _starFill = Paint();
  final Paint _starEdge;
  final Paint _sprinkle;
  final Path _swirlPath = _buildSwirl();
  final Path _starPath = BaseThemeRenderer.buildStar();

  double _time = 0;

  CandyBurstRenderer(super.theme)
      : _background = Paint()
          ..shader = Gradient.linear(
            Offset.zero,
            const Offset(0, kVirtualH),
            [theme.palette.bgTop, theme.palette.bgBottom],
          ),
        _stripes = _recordStripes(theme.palette.dust),
        _sprinkles = _recordSprinkles(theme.effects.confetti),
        _swirl = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kCandySwirlStroke
          ..strokeCap = StrokeCap.round
          ..color = theme.palette.textPrimary.withValues(alpha: kCandySwirlAlpha),
        _rim = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kTargetRimStroke
          ..color = theme.palette.textPrimary.withValues(alpha: kCandyRimAlpha),
        _ball = Paint()..color = theme.palette.accent,
        _ballRim = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kCandyBallRimStroke
          ..color = kCandyPearlRim.withValues(alpha: kCandyBallRimAlpha),
        _ballGloss = Paint()..color = theme.palette.textPrimary,
        _ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kPickupStroke,
        _ringInner = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kCandyRingInnerStroke,
        _starEdge = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kCandyStarEdgeStroke
          ..strokeJoin = StrokeJoin.round,
        _sprinkle = Paint()
          ..strokeWidth = kCandySparkWidth
          ..strokeCap = StrokeCap.round;

  /// Uzak katman: 45° şeker şeritleri. Periyot kVirtualH'yi tam böler, böylece
  /// desen dikeyde kendini tekrar eder.
  static Picture _recordStripes(Color color) {
    const period = kVirtualH / kCandyStripeCount;
    final paint = Paint()
      ..strokeWidth = kCandyStripeWidth
      ..color = color.withValues(alpha: kCandyStripeAlpha);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (var x = -kVirtualH; x < kVirtualW; x += period) {
      canvas.drawLine(Offset(x, 0), Offset(x + kVirtualH, kVirtualH), paint);
    }
    return recorder.endRecording();
  }

  /// Yakın katman: rastgele konum ve açıda serpinti çubukları (görsel Random;
  /// oyun tohumuna dokunmaz).
  static Picture _recordSprinkles(List<Color> colors) {
    final random = math.Random(kVisualRandomSeed);
    final paint = Paint()
      ..strokeWidth = kCandySprinkleWidth
      ..strokeCap = StrokeCap.round;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    if (colors.isNotEmpty) {
      for (var i = 0; i < kCandySprinkleCount; i++) {
        final x = random.nextDouble() * kVirtualW;
        final y = random.nextDouble() * kVirtualH;
        final a = random.nextDouble() * math.pi;
        final dx = math.cos(a) * kCandySprinkleLength / 2;
        final dy = math.sin(a) * kCandySprinkleLength / 2;
        paint.color = colors[i % colors.length].withValues(alpha: kCandySprinkleAlpha);
        canvas.drawLine(Offset(x - dx, y - dy), Offset(x + dx, y + dy), paint);
      }
    }
    return recorder.endRecording();
  }

  /// Hedefin dış bandında, orijin merkezli ince spiral.
  static Path _buildSwirl() {
    final path = Path();
    for (var i = 0; i <= kCandySwirlSegments; i++) {
      final u = i / kCandySwirlSegments;
      final r = kCandySwirlInnerRadius + (kCandySwirlOuterRadius - kCandySwirlInnerRadius) * u;
      final a = 2 * math.pi * kCandySwirlTurns * u;
      if (i == 0) {
        path.moveTo(r * math.cos(a), r * math.sin(a));
      } else {
        path.lineTo(r * math.cos(a), r * math.sin(a));
      }
    }
    return path;
  }

  @override
  void update(double dt) {
    if (!(dt > 0)) return;
    _time += dt;
    _stripeOffset = (_stripeOffset + kCandyStripeSpeed * dt) % kVirtualH;
    _sprinkleOffset = (_sprinkleOffset + kCandySprinkleSpeed * dt) % kVirtualH;
  }

  /// Desen katmanlarının o anki kayması [0, kVirtualH) (testler için).
  double get stripeOffset => _stripeOffset;
  double get sprinkleOffset => _sprinkleOffset;

  @override
  void paintBackground(Canvas canvas) {
    canvas
      ..drawRect(BaseThemeRenderer.canvasRect, _background)
      ..save()
      ..clipRect(BaseThemeRenderer.canvasRect);
    _paintLayer(canvas, _stripes, _stripeOffset);
    _paintLayer(canvas, _sprinkles, _sprinkleOffset);
    canvas.restore();
  }

  /// Katmanı [offset] kadar aşağı kaydırır; üstte kalan boşluğa bir kopyası sarar.
  static void _paintLayer(Canvas canvas, Picture layer, double offset) => canvas
    ..save()
    ..translate(0, offset)
    ..drawPicture(layer)
    ..translate(0, -kVirtualH)
    ..drawPicture(layer)
    ..restore();

  @override
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill}) {
    _fill.color = fill ?? theme.hpRamp.forHp(hp);
    _glossPaint.color = theme.palette.textPrimary.withValues(alpha: kCandyGlossAlpha);
    canvas
      ..save()
      ..translate(x, y);
    if (scale != 1) canvas.scale(scale);
    canvas
      ..drawCircle(Offset.zero, kTargetRadius, _fill)
      ..drawPath(_swirlPath, _swirl)
      ..drawOval(_gloss, _glossPaint)
      ..drawCircle(Offset.zero, _rimRadius, _rim);
    paintHpNumber(canvas, hp, 0, 0);
    canvas.restore();
  }

  /// Kırılan şeker: düz renkli disk + parlak vurgu (sayı yok).
  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    super.paintTargetDisc(canvas, color, opacity);
    _glossPaint.color =
        theme.palette.textPrimary.withValues(alpha: kCandyGlossAlpha * opacity);
    canvas.drawOval(_gloss, _glossPaint);
  }

  @override
  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final color = theme.palette.pickupGlow.withValues(alpha: opacity);
    _ring.color = color;
    _ringInner.color = kCandyRingInner.withValues(alpha: opacity);
    final r = _ringRadius * scale;
    final center = Offset(x, y);
    paintRingGlow(canvas, x, y, scale: scale, opacity: opacity);
    canvas
      ..drawCircle(center, r, _ring)
      ..drawCircle(center, r - kCandyRingInnerInset * scale, _ringInner);
  }

  @override
  void paintStar(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    _starFill.color = theme.palette.star.withValues(alpha: opacity);
    _starEdge.color =
        theme.palette.textPrimary.withValues(alpha: kCandyStarEdgeAlpha * opacity);
    _glossPaint.color = theme.palette.textPrimary.withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(x, y)
      ..scale(scale * BaseThemeRenderer.starPulse(_time))
      ..drawPath(_starPath, _starFill)
      ..drawPath(_starPath, _starEdge)
      ..drawCircle(const Offset(kCandyStarGlossX, kCandyStarGlossY), kCandyStarGlossRadius,
          _glossPaint)
      ..restore();
  }

  @override
  void paintBall(Canvas canvas, double x, double y) {
    final center = Offset(x, y);
    canvas
      ..drawCircle(center, _ballRadius, _ball)
      ..drawCircle(center, _ballRadius, _ballRim)
      ..drawCircle(
        Offset(x + kCandyBallGlossOffset, y + kCandyBallGlossOffset),
        kCandyBallGlossRadius,
        _ballGloss,
      );
  }

  /// Serpinti: ilk hız yönünde kısa, yuvarlak uçlu çubuk.
  @override
  void paintSpark(Canvas canvas, double x, double y, double vx, double vy, double size, Color color) {
    final speed = math.sqrt(vx * vx + vy * vy);
    if (!(speed > 0)) {
      super.paintSpark(canvas, x, y, vx, vy, size, color);
      return;
    }
    final dx = vx / speed * kCandySparkLength / 2;
    final dy = vy / speed * kCandySparkLength / 2;
    _sprinkle.color = color;
    canvas.drawLine(Offset(x - dx, y - dy), Offset(x + dx, y + dy), _sprinkle);
  }

  @override
  void dispose() {
    _stripes.dispose();
    _sprinkles.dispose();
    super.dispose();
  }
}

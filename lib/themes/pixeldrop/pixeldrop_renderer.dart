import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../hp_ramp.dart';
import '../shared/base_theme_renderer.dart';
import 'pixel_geometry.dart';

/// Pixel Drop çizici: koyu kahve-zeytin degrade + sabit tarama çizgileri ve
/// hücre adımlarıyla düşen seyrek piksel blokları; piksel silüetli hedefler
/// (açık kenar halkası, üst-sol parlak yay, 3×5 piksel rakam), piksel top,
/// iki kareli parıltılı piksel halka ve yıldız, ızgaraya oturan kare
/// kıvılcımlar. HUD ve "+3" yazısı [BaseThemeRenderer]'dadır.
///
/// Performans: tüm şekiller bir kez Path olarak üretilir; arka plan iki
/// Picture'dır (sabit katman + kayan bloklar). Hedef başına 4 çizim çağrısı
/// (dolgu, kenar, parlaklık, rakam). Rakam Path'leri HP başına bir kez üretilir
/// (en çok 198 giriş); karede yeni Paint/Path yok.
class PixelDropRenderer extends BaseThemeRenderer {
  /// Hedef silüeti ve parçaları (orijin merkezli hücreler; testler de kullanır).
  static final List<Rect> targetCells = PixelGeometry.discCells(kTargetRadius);
  static final List<Rect> targetRimCells = PixelGeometry.edgeCells(targetCells);
  static final List<Rect> targetInteriorCells = PixelGeometry.interiorCells(targetCells);
  static final List<Rect> targetGlossCells =
      PixelGeometry.arcCells(targetCells, kPixelGlossFromDeg, kPixelGlossToDeg);
  static final List<Rect> ballCells = PixelGeometry.discCells(kBallRadius);
  static const Rect ballGlint =
      Rect.fromLTWH(kPixelBallGlintX, kPixelBallGlintY, kPixelCell, kPixelCell);
  static final List<Rect> ringCells =
      PixelGeometry.annulusCells(kPickupRadius, kPixelRingCells);
  static final List<Rect> starCells = PixelGeometry.polygonCells(PixelGeometry.starPolygon());
  static const Rect starGlint =
      Rect.fromLTWH(kPixelStarGlintX, kPixelStarGlintY, kPixelCell, kPixelCell);

  final Picture _backdrop;
  final Picture _drops;
  double _dropOffset = 0;
  double _time = 0;

  final Path _target = PixelGeometry.pathOf(targetCells);
  final Path _targetRim = PixelGeometry.pathOf(targetRimCells);
  final Path _targetGloss = PixelGeometry.pathOf(targetGlossCells);
  final Path _ball = PixelGeometry.pathOf(ballCells);
  final Path _ring = PixelGeometry.pathOf(ringCells);
  final Path _star = PixelGeometry.pathOf(starCells);
  final Map<int, Path> _numbers = {};

  /// HP başına kenar rengi (HpRamp önbelleğiyle aynı aralık).
  final List<Color> _rimByHp;

  final Paint _fill = Paint();
  final Paint _rim = Paint();
  final Paint _gloss;
  final Paint _digits;
  final Paint _disc = Paint();
  final Paint _ballPaint;
  final Paint _ballGlintPaint;
  final Paint _ringPaint = Paint();
  final Paint _ringGlow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kPickupGlowBlur);
  final Paint _starPaint = Paint();
  final Paint _starGlintPaint = Paint();
  final Paint _sparkPaint = Paint();

  PixelDropRenderer(super.theme)
      : _backdrop = _recordBackdrop(theme.palette.bgTop, theme.palette.bgBottom, theme.palette.dust),
        _drops = _recordDrops(theme.effects.confetti),
        _rimByHp = List.unmodifiable([
          for (var hp = 0; hp <= HpRamp.keyframes.last.$1; hp++) rimColor(theme.hpRamp.forHp(hp)),
        ]),
        _gloss = Paint()..color = theme.palette.textPrimary.withValues(alpha: kPixelGlossAlpha),
        _digits = Paint()..color = theme.palette.textPrimary,
        _ballPaint = Paint()..color = theme.palette.accent,
        _ballGlintPaint = Paint()..color = theme.palette.textPrimary;

  /// Hedefin kenar halkası rengi: HP rengi ile beyazın karışımı.
  static Color rimColor(Color fill) =>
      Color.lerp(fill, const Color(0xFFFFFFFF), kPixelRimWhiteMix)!;

  /// Sabit katman: dikey degrade + çok soluk yatay tarama çizgileri.
  static Picture _recordBackdrop(Color top, Color bottom, Color line) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        BaseThemeRenderer.canvasRect,
        Paint()..shader = Gradient.linear(Offset.zero, const Offset(0, kVirtualH), [top, bottom]),
      );
    final lines = Path();
    for (var y = 0.0; y < kVirtualH; y += kPixelScanlinePeriod) {
      lines.addRect(Rect.fromLTWH(0, y, kVirtualW, kPixelScanlineHeight));
    }
    canvas.drawPath(lines, Paint()..color = line.withValues(alpha: kPixelScanlineAlpha));
    return recorder.endRecording();
  }

  /// Kayan katman: ızgaraya oturan 1–2 hücrelik bloklar (görsel Random; oyun
  /// tohumuna dokunmaz).
  static Picture _recordDrops(List<Color> colors) {
    final random = math.Random(kVisualRandomSeed);
    final paint = Paint();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    if (colors.isNotEmpty) {
      final cols = (kVirtualW / kPixelCell).floor();
      final rows = (kVirtualH / kPixelCell).floor();
      for (var i = 0; i < kPixelDropCount; i++) {
        final size = (1 + random.nextInt(kPixelDropMaxCells)) * kPixelCell;
        final x = random.nextInt(cols) * kPixelCell;
        final y = random.nextInt(rows) * kPixelCell;
        paint.color = colors[i % colors.length].withValues(alpha: kPixelDropAlpha);
        canvas.drawRect(Rect.fromLTWH(x, y, size, size), paint);
      }
    }
    return recorder.endRecording();
  }

  @override
  void update(double dt) {
    if (!(dt > 0)) return;
    _time += dt;
    _dropOffset = (_dropOffset + kPixelDropSpeed * dt) % kVirtualH;
  }

  /// Blok katmanının kayması [0, kVirtualH) (testler için).
  double get dropOffset => _dropOffset;

  /// Çizimde kullanılan, hücre adımına yuvarlanmış kayma.
  double get dropStep => (_dropOffset / kPixelCell).floorToDouble() * kPixelCell;

  /// İki kareli parıltının parlak karesinde mi (yalnız görsel).
  bool get blinkBright => (_time / kPixelBlinkSec).floor().isEven;

  @override
  void paintBackground(Canvas canvas) {
    final step = dropStep;
    canvas
      ..drawPicture(_backdrop)
      ..save()
      ..clipRect(BaseThemeRenderer.canvasRect)
      ..translate(0, step)
      ..drawPicture(_drops)
      ..translate(0, -kVirtualH)
      ..drawPicture(_drops)
      ..restore();
  }

  @override
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill}) {
    final last = HpRamp.keyframes.last.$1;
    _fill.color = fill ?? theme.hpRamp.forHp(hp);
    _rim.color = fill == null ? _rimByHp[hp < 0 ? 0 : (hp > last ? last : hp)] : rimColor(fill);
    canvas
      ..save()
      ..translate(x, y);
    if (scale != 1) canvas.scale(scale);
    canvas
      ..drawPath(_target, _fill)
      ..drawPath(_targetRim, _rim)
      ..drawPath(_targetGloss, _gloss)
      ..drawPath(_numberPath(hp), _digits)
      ..restore();
  }

  Path _numberPath(int hp) =>
      _numbers.putIfAbsent(hp, () => PixelGeometry.pathOf(PixelGeometry.numberPixels(hp)));

  /// Kırılan hedef: düz renkli piksel silüet (sayı yok).
  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    _disc.color = color.withValues(alpha: opacity);
    canvas.drawPath(_target, _disc);
  }

  @override
  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final glow = blinkBright ? opacity : opacity * kPixelBlinkDimAlpha;
    _ringGlow.color = theme.palette.pickupGlow.withValues(alpha: glow);
    _ringPaint.color = theme.palette.pickupGlow.withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(x, y);
    if (scale != 1) canvas.scale(scale);
    canvas
      ..drawPath(_ring, _ringGlow)
      ..drawPath(_ring, _ringPaint)
      ..restore();
  }

  @override
  void paintStar(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    _starPaint.color = theme.palette.star.withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(x, y);
    if (scale != 1) canvas.scale(scale);
    canvas.drawPath(_star, _starPaint);
    if (blinkBright) {
      _starGlintPaint.color = theme.palette.textPrimary.withValues(alpha: opacity);
      canvas.drawRect(starGlint, _starGlintPaint);
    }
    canvas.restore();
  }

  @override
  void paintBall(Canvas canvas, double x, double y) => canvas
    ..save()
    ..translate(x, y)
    ..drawPath(_ball, _ballPaint)
    ..drawRect(ballGlint, _ballGlintPaint)
    ..restore();

  /// Kare kıvılcım: konumu hücre ızgarasına oturur, kenarı en az bir hücre.
  @override
  void paintSpark(Canvas canvas, double x, double y, double vx, double vy, double size, Color color) {
    final side = math.max(1, (size / kPixelCell).round()) * kPixelCell;
    _sparkPaint.color = color;
    canvas.drawRect(
      Rect.fromLTWH(
        (x / kPixelCell).floorToDouble() * kPixelCell,
        (y / kPixelCell).floorToDouble() * kPixelCell,
        side,
        side,
      ),
      _sparkPaint,
    );
  }

  @override
  void dispose() {
    _backdrop.dispose();
    _drops.dispose();
    _numbers.clear();
    super.dispose();
  }
}

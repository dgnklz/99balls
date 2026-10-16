import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../hp_ramp.dart';
import '../render_batches.dart';
import '../shared/baked_sprite.dart';
import '../shared/base_theme_renderer.dart';
import 'pixel_atlas.dart';
import 'pixel_geometry.dart';

/// Pixel Drop çizici: koyu kahve-zeytin degrade + sabit tarama çizgileri ve
/// hücre adımlarıyla düşen seyrek piksel blokları; piksel silüetli hedefler
/// (açık kenar halkası, üst-sol parlak yay, 3×5 piksel rakam), piksel top,
/// 1 hücrelik yarı saydam haleli ve iki kareli parıltılı piksel halka, yıldız,
/// ızgaraya oturan kare kıvılcımlar. HUD ve "+3" yazısı [BaseThemeRenderer]'dadır.
///
/// Performans (M3p): hedefler, toplar, kıvılcımlar ve düşen bloklar tek bir
/// beyaz maske atlasından ([PixelAtlas]) renk başına boyanarak, her grup tek
/// `drawRawAtlas` çağrısıyla çizilir (56 hedef = 1 çağrı). Atlas cihaz
/// çözünürlüğünde üretilir; konum ve ölçek cihaz pikseline oturur, hücreler
/// titremez. Sabit zemin bir kez resme çevrilir. Halka, yıldız ve kırılma
/// diski (aynı anda az sayıda) Path'tir. Karede yeni Paint/Path/liste yok.
class PixelDropRenderer extends BaseThemeRenderer {
  /// Hedef silüeti ve parçaları (orijin merkezli hücreler; testler de kullanır).
  static final List<Rect> targetCells = PixelGeometry.discCells(kTargetRadius);
  static final List<Rect> targetRimCells = PixelGeometry.edgeCells(targetCells);
  static final List<Rect> targetInteriorCells = PixelGeometry.interiorCells(targetCells);
  static final List<Rect> targetGlossCells = PixelGeometry.arcCells(
    targetCells,
    kPixelGlossFromDeg,
    kPixelGlossToDeg,
  );
  static final List<Rect> ballCells = PixelGeometry.discCells(kBallRadius);
  static const Rect ballGlint = Rect.fromLTWH(
    kPixelBallGlintX,
    kPixelBallGlintY,
    kPixelCell,
    kPixelCell,
  );
  static final List<Rect> ringCells = PixelGeometry.annulusCells(kPickupRadius, kPixelRingCells);

  /// Halkanın dışında 1 hücrelik yarı saydam hale (bulanık parıltı yerine).
  static final List<Rect> ringHaloCells = PixelGeometry.outlineCells(
    ringCells,
    kPickupRadius - kPixelCell,
  );
  static final List<Rect> starCells = PixelGeometry.polygonCells(PixelGeometry.starPolygon());
  static const Rect starGlint = Rect.fromLTWH(
    kPixelStarGlintX,
    kPixelStarGlintY,
    kPixelCell,
    kPixelCell,
  );

  // Atlas sprite sırası.
  static const int _fillId = 0;
  static const int _rimId = 1;
  static const int _glossId = 2;
  static const int _ballId = 3;
  static const int _ballGlintId = 4;
  static const int _cellId = 5;
  static const int _digitId = 6;
  static const int _digit3Id = _digitId + 10;

  static final List<List<Rect>> _atlasShapes = [
    targetCells,
    targetRimCells,
    targetGlossCells,
    ballCells,
    const [ballGlint],
    const [Rect.fromLTWH(0, 0, kPixelCell, kPixelCell)],
    for (var d = 0; d < 10; d++) PixelGeometry.glyphPixels(d, kPixelDigitPx),
    for (var d = 0; d < 10; d++) PixelGeometry.glyphPixels(d, kPixelDigitPx3),
  ];

  /// Düşen bloklar: ızgaraya oturan 1–2 hücrelik kareler (görsel Random; oyun
  /// tohumuna dokunmaz).
  final List<(int, double, double, int)> _drops;
  double _dropOffset = 0;
  double _time = 0;

  PixelAtlas? _atlas;
  BakedSprite? _backdrop;
  final AtlasBatch _batch = AtlasBatch(kPixelAtlasBatchCapacity);
  final TargetBatch _oneTarget = TargetBatch();
  final BallBatch _oneBall = BallBatch();
  final SparkBatch _oneSpark = SparkBatch();
  final Map<int, List<(int, Offset)>> _layouts = {};

  final Path _target = PixelGeometry.pathOf(targetCells);
  final Path _ring = PixelGeometry.pathOf(ringCells);
  final Path _ringHalo = PixelGeometry.pathOf(ringHaloCells);
  final Path _star = PixelGeometry.pathOf(starCells);

  /// HP başına dolgu ve kenar rengi (HpRamp önbelleğiyle aynı aralık; ARGB).
  final List<int> _fillByHp;
  final List<int> _rimByHp;
  final int _white;
  final int _glossArgb;
  final int _ballArgb;

  final Paint _atlasPaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _backdropPaint = Paint()..filterQuality = FilterQuality.low;
  final Paint _disc = Paint();
  final Paint _ringPaint = Paint();
  final Paint _ringHaloPaint = Paint();
  final Paint _accentHalo;
  final Paint _starPaint = Paint();
  final Paint _starGlintPaint = Paint();

  PixelDropRenderer(super.theme)
    : _drops = _makeDrops(theme.effects.confetti),
      _fillByHp = List.unmodifiable([
        for (var hp = 0; hp <= HpRamp.keyframes.last.$1; hp++) theme.hpRamp.forHp(hp).toARGB32(),
      ]),
      _rimByHp = List.unmodifiable([
        for (var hp = 0; hp <= HpRamp.keyframes.last.$1; hp++)
          rimColor(theme.hpRamp.forHp(hp)).toARGB32(),
      ]),
      _white = theme.palette.textPrimary.toARGB32(),
      _glossArgb = theme.palette.textPrimary.withValues(alpha: kPixelGlossAlpha).toARGB32(),
      _ballArgb = theme.palette.accent.toARGB32(),
      _accentHalo = Paint()..color = theme.palette.hudAccent.withValues(alpha: kPixelHaloAlpha);

  /// Hedefin kenar halkası rengi: HP rengi ile beyazın karışımı.
  static Color rimColor(Color fill) =>
      Color.lerp(fill, const Color(0xFFFFFFFF), kPixelRimWhiteMix)!;

  /// Sıra (hücre sayısı, x, y, renk). Rastgele sayı sırası M3c'deki Picture ile
  /// aynıdır (boyut, x, y): bloklar aynı yerde.
  static List<(int, double, double, int)> _makeDrops(List<Color> colors) {
    if (colors.isEmpty) return const [];
    final random = math.Random(kVisualRandomSeed);
    final cols = (kVirtualW / kPixelCell).floor();
    final rows = (kVirtualH / kPixelCell).floor();
    final drops = <(int, double, double, int)>[];
    for (var i = 0; i < kPixelDropCount; i++) {
      final cells = 1 + random.nextInt(kPixelDropMaxCells);
      final x = random.nextInt(cols) * kPixelCell;
      final y = random.nextInt(rows) * kPixelCell;
      drops.add((
        cells,
        x,
        y,
        colors[i % colors.length].withValues(alpha: kPixelDropAlpha).toARGB32(),
      ));
    }
    return List.unmodifiable(drops);
  }

  /// Atlas (ve sabit zemin) ilk çizimde, piksel oranı değişince yeniden üretilir.
  PixelAtlas _ensureAtlas() => _atlas ??= PixelAtlas.build(pxPerGu, _atlasShapes);

  BakedSprite _ensureBackdrop() => _backdrop ??= BakedSprite.record(
    BaseThemeRenderer.canvasRect,
    math.min(pxPerGu, kPixelBackdropMaxPxPerGu),
    (canvas) {
      final p = theme.palette;
      canvas.drawRect(
        BaseThemeRenderer.canvasRect,
        Paint()
          ..shader = Gradient.linear(Offset.zero, const Offset(0, kVirtualH), [
            p.bgTop,
            p.bgBottom,
          ]),
      );
      final lines = Path();
      for (var y = 0.0; y < kVirtualH; y += kPixelScanlinePeriod) {
        lines.addRect(Rect.fromLTWH(0, y, kVirtualW, kPixelScanlineHeight));
      }
      canvas.drawPath(lines, Paint()..color = p.dust.withValues(alpha: kPixelScanlineAlpha));
    },
  );

  @override
  void onPixelRatioChanged() {
    _atlas?.dispose();
    _atlas = null;
    _backdrop?.dispose();
    _backdrop = null;
    super.onPixelRatioChanged();
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
    _ensureBackdrop().draw(canvas, 0, 0, _backdropPaint);
    final atlas = _ensureAtlas();
    final cell = atlas.sprites[_cellId];
    final step = dropStep;
    for (final shift in const [0.0, -kVirtualH]) {
      for (final (cells, x, y, argb) in _drops) {
        final top = y + step + shift;
        final size = cells * kPixelCell;
        if (top + size <= 0 || top >= kVirtualH) continue;
        _batch.add(cell, x, top, cells.toDouble(), argb, atlas.pxPerGu);
      }
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill}) {
    _oneTarget
      ..clear()
      ..add(x, y, hp, tscale: scale, tfill: fill?.toARGB32() ?? 0);
    paintTargets(canvas, _oneTarget);
  }

  /// Tüm hedefler tek atlas çağrısında: hedef başına dolgu, kenar, parlak yay
  /// ve hane sayısı kadar rakam sprite'ı (bu sırayla, üst üste).
  @override
  void paintTargets(Canvas canvas, TargetBatch targets) {
    final atlas = _ensureAtlas();
    final p = atlas.pxPerGu;
    final fillSprite = atlas.sprites[_fillId];
    final rimSprite = atlas.sprites[_rimId];
    final glossSprite = atlas.sprites[_glossId];
    final last = HpRamp.keyframes.last.$1;
    for (var i = 0; i < targets.length; i++) {
      final x = targets.x[i];
      final y = targets.y[i];
      final hp = targets.hp[i];
      final s = targets.scale[i];
      final custom = targets.fill[i];
      final key = hp < 0 ? 0 : (hp > last ? last : hp);
      final fillArgb = custom != 0 ? custom : _fillByHp[key];
      final rimArgb = custom != 0 ? rimColor(Color(custom)).toARGB32() : _rimByHp[key];
      _batch
        ..add(fillSprite, x, y, s, fillArgb, p)
        ..add(rimSprite, x, y, s, rimArgb, p)
        ..add(glossSprite, x, y, s, _glossArgb, p);
      final base = hp >= kThreeDigitThreshold ? _digit3Id : _digitId;
      for (final (digit, topLeft) in _layout(hp)) {
        _batch.add(
          atlas.sprites[base + digit],
          x + topLeft.dx * s,
          y + topLeft.dy * s,
          s,
          _white,
          p,
        );
      }
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  List<(int, Offset)> _layout(int hp) =>
      _layouts.putIfAbsent(hp, () => List.unmodifiable(PixelGeometry.digitLayout(hp)));

  /// Kırılan hedef: düz renkli piksel silüet (sayı yok).
  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    _disc.color = color.withValues(alpha: opacity);
    canvas.drawPath(_target, _disc);
  }

  @override
  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final halo = kPixelHaloAlpha * (blinkBright ? opacity : opacity * kPixelBlinkDimAlpha);
    _ringHaloPaint.color = theme.palette.pickupGlow.withValues(alpha: halo);
    _ringPaint.color = theme.palette.pickupGlow.withValues(alpha: opacity);
    canvas
      ..save()
      ..translate(x, y);
    if (scale != 1) canvas.scale(scale);
    canvas
      ..drawPath(_ringHalo, _ringHaloPaint)
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
  void paintBall(Canvas canvas, double x, double y) {
    _oneBall
      ..clear()
      ..add(x, y);
    paintBalls(canvas, _oneBall);
  }

  /// Tüm toplar tek atlas çağrısında (top + parlak hücre).
  @override
  void paintBalls(Canvas canvas, BallBatch balls) {
    final atlas = _ensureAtlas();
    final p = atlas.pxPerGu;
    final ball = atlas.sprites[_ballId];
    final glint = atlas.sprites[_ballGlintId];
    for (var i = 0; i < balls.length; i++) {
      _batch
        ..add(ball, balls.x[i], balls.y[i], 1, _ballArgb, p)
        ..add(glint, balls.x[i], balls.y[i], 1, _white, p);
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  /// HUD vurgu parıltısı yerine çizginin üstünde ve altında 1 hücrelik yarı
  /// saydam şerit (bulanıklık yok, piksel tarzı).
  @override
  void paintAccentGlow(Canvas canvas, double cx, double y) => canvas.drawRect(
    Rect.fromLTRB(
      cx - kHudAccentWidth / 2,
      y - kHudAccentStroke / 2 - kPixelCell,
      cx + kHudAccentWidth / 2,
      y + kHudAccentStroke / 2 + kPixelCell,
    ),
    _accentHalo,
  );

  @override
  void paintSpark(
    Canvas canvas,
    double x,
    double y,
    double vx,
    double vy,
    double size,
    Color color,
  ) {
    _oneSpark
      ..clear()
      ..add(x, y, vx, vy, size, color.toARGB32());
    paintSparks(canvas, _oneSpark);
  }

  /// Kare kıvılcımlar tek atlas çağrısında: konum hücre ızgarasına oturur,
  /// kenarı en az bir hücre.
  @override
  void paintSparks(Canvas canvas, SparkBatch sparks) {
    final atlas = _ensureAtlas();
    final cell = atlas.sprites[_cellId];
    for (var i = 0; i < sparks.length; i++) {
      final cells = math.max(1, (sparks.size[i] / kPixelCell).round());
      _batch.add(
        cell,
        (sparks.x[i] / kPixelCell).floorToDouble() * kPixelCell,
        (sparks.y[i] / kPixelCell).floorToDouble() * kPixelCell,
        cells.toDouble(),
        sparks.color[i],
        atlas.pxPerGu,
      );
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _atlas = null;
    _backdrop?.dispose();
    _backdrop = null;
    _layouts.clear();
    super.dispose();
  }
}

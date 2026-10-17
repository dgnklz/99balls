import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../hp_ramp.dart';
import '../render_batches.dart';
import '../shared/baked_sprite.dart';
import '../shared/base_theme_renderer.dart';
import '../shared/sprite_atlas.dart';
import 'ink_geometry.dart';

/// Ink & Paper çizici: el yapımı krem kâğıt (degrade + gren + lif, bir kez
/// pişirilmiş tek resim) üstünde çok yavaş kayan soluk mürekkep lekeleri;
/// mürekkep-yıkama pigment disk hedefler (HP renginde yayılma, düzensiz fırça
/// gövde, koyu enso kenarı, kuru fırça dokusu), sumi damlası top, vermilyon
/// fırça halka, koyu kenarlı altın yaprak yıldız, hız yönünde mürekkep damlası
/// kıvılcımlar. HUD'da kâğıt diskli top simgesi, fırça darbesi süpürmesi ve
/// mürekkep sızıntısı tehlike nefesi; gerisi [BaseThemeRenderer]'dadır.
///
/// Performans (PRD 7.4.1, M3p): tüm parçalar beyaz maske atlasından
/// ([SpriteAtlas]) renk başına boyanarak (BlendMode.modulate) her grup tek
/// `drawRawAtlas` ile çizilir. Bulanıklık yalnızca pişirmede. Gövde tam
/// opaktır: doku ayrı sprite'la yalnızca koyulaştırır, beyaz rakamın kontrastı
/// düşmez. Karede yeni Paint/Path/liste yok.
class InkPaperRenderer extends BaseThemeRenderer {
  /// Atlas sprite sırası (gövde, kenar, doku ve damla varyantlı).
  static const int bleedSprite = 0;
  static const int bodySprite = 1;
  static const int rimSprite = bodySprite + kInkTargetVariants;
  static const int streakSprite = rimSprite + kInkTargetVariants;
  static const int ballSprite = streakSprite + kInkTargetVariants;
  static const int glintSprite = ballSprite + 1;
  static const int ringSprite = glintSprite + 1;
  static const int starSprite = ringSprite + 1;
  static const int fleckSprite = starSprite + 1;
  static const int starEdgeSprite = fleckSprite + 1;
  static const int dropSprite = starEdgeSprite + 1;

  static const Color _white = Color(0xFFFFFFFF);
  static const double _sparkUnit = kInkSparkScale / (2 * kInkDropRadius);
  static const double _iconScale = kHudBallIconDiameter / 2 / kInkBallRadius;

  final Float32List _wash = Float32List(kInkWashCount * 2);
  final Float32List _washScale = Float32List(kInkWashCount);
  final Int32List _washArgb = Int32List(kInkWashCount);
  double _time = 0;

  SpriteAtlas? _atlas;
  SpriteAtlas? _washAtlas;
  BakedSprite? _paper;
  BakedSprite? _sweepSprite;
  BakedSprite? _seepSprite;
  final SpriteBatch _batch = SpriteBatch(kInkAtlasBatchCapacity);
  final SpriteBatch _washBatch = SpriteBatch(kInkWashCount);
  final TargetBatch _oneTarget = TargetBatch();
  final BallBatch _oneBall = BallBatch();
  final SparkBatch _oneSpark = SparkBatch();

  /// HP başına yayılma, dolgu ve kenar rengi (HpRamp önbelleğiyle aynı aralık; ARGB).
  final List<int> _bleedByHp;
  final List<int> _fillByHp;
  final List<int> _rimByHp;
  final int _streakArgb;
  final int _ballArgb;
  final int _glintArgb;

  final Path _disc = InkGeometry.body(0);
  final Paint _discPaint = Paint();
  final Paint _image = Paint()..filterQuality = FilterQuality.low;
  final Paint _fade = Paint()..filterQuality = FilterQuality.low;
  final Paint _atlasPaint = Paint()..filterQuality = FilterQuality.low;
  final Paint _iconBacking;

  InkPaperRenderer(super.theme)
      : _bleedByHp = _byHp(theme.hpRamp, (c) => c.withValues(alpha: kInkBleedAlpha)),
        _fillByHp = _byHp(theme.hpRamp, (c) => c),
        _rimByHp = _byHp(theme.hpRamp, (c) => rimColor(c, theme.palette.accent)),
        _streakArgb = theme.palette.accent.withValues(alpha: kInkStreakAlpha).toARGB32(),
        _ballArgb = theme.palette.accent.toARGB32(),
        _glintArgb = theme.palette.textPrimary.withValues(alpha: kInkBallGlintAlpha).toARGB32(),
        _iconBacking = Paint()..color = theme.palette.bgTop {
    final random = math.Random(kVisualRandomSeed + kInkWashCount);
    for (var i = 0; i < kInkWashCount; i++) {
      _wash[i * 2] = random.nextDouble() * kVirtualW;
      _wash[i * 2 + 1] = random.nextDouble() * kVirtualH;
      _washScale[i] = kInkWashMinScale + random.nextDouble() * (kInkWashMaxScale - kInkWashMinScale);
      final alpha = kInkWashAlphaMin + random.nextDouble() * (kInkWashAlphaMax - kInkWashAlphaMin);
      _washArgb[i] = theme.palette.dust.withValues(alpha: alpha).toARGB32();
    }
  }

  static List<int> _byHp(HpRamp ramp, Color Function(Color) map) => List.unmodifiable([
        for (var hp = 0; hp <= HpRamp.keyframes.last.$1; hp++) map(ramp.forHp(hp)).toARGB32(),
      ]);

  /// Enso kenarının rengi: HP rengi ile sumi ([ink]) karışımı (daha koyu).
  static Color rimColor(Color fill, Color ink) => Color.lerp(fill, ink, kInkRimDarkMix)!;

  /// Hedefin gövde varyantı: sütuna göre (satır kayınca ve vuruşta değişmez).
  static int variantFor(double x) => (x / kPitch).floor() % kInkTargetVariants;

  /// Damla varyantı: hızın çeyreğine göre (kıvılcım ömrü boyunca sabit).
  static int dropVariantFor(double vx, double vy) =>
      ((vx >= 0 ? 0 : 1) + (vy >= 0 ? 0 : 2)) % kInkTargetVariants;

  /// Leke bulutlarının merkezleri (x, y çiftleri; testler için salt okunur görünüm).
  Float32List get washPoints => Float32List.view(_wash.buffer);

  /// Leke bulutlarının sarmadan önce tuval dışına taşabileceği pay.
  static const double washMargin = InkGeometry.washExtent * kInkWashMaxScale;

  // --- Pişirme ---------------------------------------------------------------

  static Paint _whiteBlur(double sigma) => Paint()
    ..color = _white
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

  /// Atlas sprite'ları (beyaz maske; renk çizimde verilir). Sıra yukarıdaki
  /// kimliklerle aynıdır (testler atlas piksellerini okur).
  static List<SpriteSpec> atlasSpecs() {
    const target = Rect.fromLTRB(-kTargetRadius, -kTargetRadius, kTargetRadius, kTargetRadius);
    const starOuter = kTargetRadius * kStarSizeRatio + kInkStarEdgeStroke;
    final fill = Paint()..color = _white;
    final star = BaseThemeRenderer.buildStar();
    const glint = Rect.fromLTRB(
      kInkBallGlintX - kInkBallGlintRadiusX,
      kInkBallGlintY - kInkBallGlintRadiusY,
      kInkBallGlintX + kInkBallGlintRadiusX,
      kInkBallGlintY + kInkBallGlintRadiusY,
    );
    return [
      (
        Rect.fromCircle(center: Offset.zero, radius: InkGeometry.bleedSpriteExtent),
        (c) => c.drawCircle(Offset.zero, kInkBleedRadius, _whiteBlur(kInkBleedBlur)),
      ),
      for (var v = 0; v < kInkTargetVariants; v++)
        (target, (Canvas c) => c.drawPath(InkGeometry.body(v), fill)),
      for (var v = 0; v < kInkTargetVariants; v++)
        (target, (Canvas c) => c.drawPath(InkGeometry.rim(v), fill)),
      for (var v = 0; v < kInkTargetVariants; v++)
        (
          target,
          (Canvas c) => c
            ..save()
            ..clipPath(InkGeometry.body(v))
            ..drawPath(
              InkGeometry.streaks(v),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = kInkStreakStroke
                ..strokeCap = StrokeCap.round
                ..color = _white,
            )
            ..restore(),
        ),
      (
        Rect.fromCircle(center: Offset.zero, radius: kInkBallRadius + 1),
        (c) => c.drawCircle(Offset.zero, kInkBallRadius, fill),
      ),
      (glint.inflate(1), (c) => c.drawOval(glint, fill)),
      (
        Rect.fromCircle(center: Offset.zero, radius: kPickupRadius + 1),
        (c) => c.drawPath(InkGeometry.ring(), fill),
      ),
      (
        Rect.fromCircle(center: Offset.zero, radius: starOuter),
        (c) => c.drawPath(star, fill),
      ),
      (
        Rect.fromCircle(center: Offset.zero, radius: starOuter),
        (c) {
          c
            ..save()
            ..clipPath(star);
          for (var i = 0; i + 2 < kInkStarFlecks.length; i += 3) {
            c.drawCircle(Offset(kInkStarFlecks[i], kInkStarFlecks[i + 1]), kInkStarFlecks[i + 2], fill);
          }
          c.restore();
        },
      ),
      (
        Rect.fromCircle(center: Offset.zero, radius: starOuter),
        (c) => c.drawPath(
              star,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = kInkStarEdgeStroke
                ..strokeJoin = StrokeJoin.round
                ..color = _white,
            ),
      ),
      for (var v = 0; v < kInkTargetVariants; v++)
        (
          Rect.fromCircle(center: Offset.zero, radius: InkGeometry.dropExtent),
          (Canvas c) => c.drawPath(InkGeometry.drop(v), fill),
        ),
    ];
  }

  /// Atlas ilk çizimde, piksel oranı değişince yeniden üretilir.
  SpriteAtlas _ensureAtlas() => _atlas ??= SpriteAtlas.build(pxPerGu, atlasSpecs());

  /// Leke bulutları yumuşak içerik: düşük çözünürlüklü ayrı atlas.
  SpriteAtlas _ensureWashAtlas() => _washAtlas ??= SpriteAtlas.build(
        math.min(pxPerGu, kInkWashMaxPxPerGu),
        [
          (
            Rect.fromCircle(center: Offset.zero, radius: InkGeometry.washExtent),
            (c) {
              final paint = _whiteBlur(kInkWashBlur);
              for (final (center, radius) in InkGeometry.washBlobs()) {
                c.drawCircle(center, radius, paint);
              }
            },
          ),
        ],
      );

  /// Kâğıt: degrade + gren + lif, tek resim (görsel Random; oyun tohumuna dokunmaz).
  BakedSprite _bakePaper() {
    final p = theme.palette;
    return BakedSprite.record(
      BaseThemeRenderer.canvasRect,
      math.min(pxPerGu, kInkBackdropMaxPxPerGu),
      (c) {
        c.drawRect(
          BaseThemeRenderer.canvasRect,
          Paint()
            ..shader = Gradient.linear(
              Offset.zero,
              const Offset(0, kVirtualH),
              [p.bgTop, p.bgBottom],
            ),
        );
        final random = math.Random(kVisualRandomSeed + kInkGrainCount);
        final dark = Float32List(kInkGrainCount);
        final light = Float32List(kInkGrainCount);
        for (var i = 0; i < kInkGrainCount; i += 2) {
          dark[i] = random.nextDouble() * kVirtualW;
          dark[i + 1] = random.nextDouble() * kVirtualH;
          light[i] = random.nextDouble() * kVirtualW;
          light[i + 1] = random.nextDouble() * kVirtualH;
        }
        final grain = Paint()
          ..strokeWidth = kInkGrainSize
          ..strokeCap = StrokeCap.round;
        c
          ..drawRawPoints(PointMode.points, dark,
              grain..color = p.accent.withValues(alpha: kInkGrainDarkAlpha))
          ..drawRawPoints(PointMode.points, light,
              grain..color = p.textPrimary.withValues(alpha: kInkGrainLightAlpha));
        final fibers = Path();
        for (var i = 0; i < kInkFiberCount; i++) {
          final x = random.nextDouble() * kVirtualW;
          final y = random.nextDouble() * kVirtualH;
          final a = random.nextDouble() * math.pi;
          final length = kInkFiberMinLength +
              random.nextDouble() * (kInkFiberMaxLength - kInkFiberMinLength);
          final bend = (random.nextDouble() * 2 - 1) * kInkFiberBend;
          final dx = math.cos(a) * length;
          final dy = math.sin(a) * length;
          fibers
            ..moveTo(x, y)
            ..quadraticBezierTo(
              x + dx / 2 - math.sin(a) * bend,
              y + dy / 2 + math.cos(a) * bend,
              x + dx,
              y + dy,
            );
        }
        c.drawPath(
          fibers,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = kInkFiberStroke
            ..color = p.accent.withValues(alpha: kInkFiberAlpha),
        );
      },
    );
  }

  /// Satır süpürmesi: kuru fırça darbesi (sumi), ince boşluklu.
  BakedSprite _bakeSweep() {
    const bounds = Rect.fromLTRB(
      -kAdvanceSweepWidth / 2,
      -kInkSweepHeight / 2,
      kAdvanceSweepWidth / 2,
      kInkSweepHeight / 2,
    );
    return BakedSprite.record(bounds, pxPerGu, (c) {
      c
        ..saveLayer(bounds, Paint())
        ..drawPath(
          InkGeometry.brushStroke(kAdvanceSweepWidth, kInkSweepHeight),
          Paint()..color = theme.palette.accent,
        );
      final random = math.Random(kVisualRandomSeed + kInkSweepDryLines);
      final dry = Paint()
        ..strokeWidth = kInkSweepDryStroke
        ..blendMode = BlendMode.dstOut
        ..color = _white.withValues(alpha: kInkSweepDryAlpha);
      for (var i = 0; i < kInkSweepDryLines; i++) {
        final y = -kInkSweepHeight / 2 + kInkSweepHeight * (i + 1) / (kInkSweepDryLines + 1);
        final from = bounds.left + random.nextDouble() * kAdvanceSweepWidth / 2;
        c.drawLine(Offset(from, y), Offset(bounds.right, y), dry);
      }
      c.restore();
    });
  }

  /// Tehlike nefesi: zemin kenarından yukarı solan düzensiz mürekkep sızıntısı.
  BakedSprite _bakeSeep() {
    const bounds = Rect.fromLTRB(
      -kVirtualW / 2,
      -kInkSeepHeight / 2,
      kVirtualW / 2,
      kInkSeepHeight / 2,
    );
    final danger = theme.palette.danger;
    return BakedSprite.record(bounds, pxPerGu, (c) {
      c
        ..save()
        ..clipRect(bounds)
        ..drawRect(
          bounds,
          Paint()
            ..shader = Gradient.linear(
              bounds.topCenter,
              bounds.bottomCenter,
              [danger.withValues(alpha: 0), danger],
            ),
        );
      final random = math.Random(kVisualRandomSeed + kInkSeepBlobs);
      final blob = Paint()
        ..color = danger
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kInkSeepBlur);
      for (var i = 0; i < kInkSeepBlobs; i++) {
        final x = bounds.left + kVirtualW * (i + random.nextDouble()) / kInkSeepBlobs;
        final r = kInkSeepBlobRadius * (kInkWashBlobMinRatio + (1 - kInkWashBlobMinRatio) * random.nextDouble());
        c.drawCircle(Offset(x, bounds.bottom), r, blob);
      }
      c.restore();
    });
  }

  void _disposeBaked() {
    _atlas?.dispose();
    _atlas = null;
    _washAtlas?.dispose();
    _washAtlas = null;
    _paper?.dispose();
    _paper = null;
    _sweepSprite?.dispose();
    _sweepSprite = null;
    _seepSprite?.dispose();
    _seepSprite = null;
  }

  @override
  void onPixelRatioChanged() {
    _disposeBaked();
    super.onPixelRatioChanged();
  }

  // --- Kare ------------------------------------------------------------------

  @override
  void update(double dt) {
    if (!(dt > 0)) return;
    _time += dt;
    const spanX = kVirtualW + 2 * washMargin;
    const spanY = kVirtualH + 2 * washMargin;
    for (var i = 0; i < kInkWashCount; i++) {
      var x = _wash[i * 2] + kInkWashSpeedX * dt;
      var y = _wash[i * 2 + 1] + kInkWashSpeedY * dt;
      if (x > kVirtualW + washMargin) x -= spanX;
      if (y > kVirtualH + washMargin) y -= spanY;
      _wash[i * 2] = x;
      _wash[i * 2 + 1] = y;
    }
  }

  @override
  void paintBackground(Canvas canvas) {
    (_paper ??= _bakePaper()).draw(canvas, 0, 0, _image);
    final atlas = _ensureWashAtlas();
    final sprite = atlas.sprites.single;
    for (var i = 0; i < kInkWashCount; i++) {
      _washBatch.add(sprite, _wash[i * 2], _wash[i * 2 + 1], _washScale[i], _washArgb[i],
          atlas.pxPerGu);
    }
    _washBatch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill}) {
    _oneTarget
      ..clear()
      ..add(x, y, hp, tscale: scale, tfill: fill?.toARGB32() ?? 0);
    paintTargets(canvas, _oneTarget);
  }

  /// Tüm hedeflerin yayılma, gövde, kenar ve dokusu tek atlas çağrısında; sonra
  /// rakamlar. Hedefler çakışmadığı için (yayılma ≤ 27 gu, hücre aralığı 59.4 gu)
  /// görünüm hedef hedef çizimle aynıdır.
  @override
  void paintTargets(Canvas canvas, TargetBatch targets) {
    final atlas = _ensureAtlas();
    final p = atlas.pxPerGu;
    final sprites = atlas.sprites;
    final bleed = sprites[bleedSprite];
    final last = HpRamp.keyframes.last.$1;
    for (var i = 0; i < targets.length; i++) {
      final x = targets.x[i];
      final y = targets.y[i];
      final hp = targets.hp[i];
      final s = targets.scale[i];
      final custom = targets.fill[i];
      final v = variantFor(x);
      final key = hp < 0 ? 0 : (hp > last ? last : hp);
      if (custom != 0) {
        final color = Color(custom);
        _batch
          ..add(bleed, x, y, s, color.withValues(alpha: kInkBleedAlpha).toARGB32(), p)
          ..add(sprites[bodySprite + v], x, y, s, custom, p)
          ..add(sprites[rimSprite + v], x, y, s,
              rimColor(color, theme.palette.accent).toARGB32(), p);
      } else {
        _batch
          ..add(bleed, x, y, s, _bleedByHp[key], p)
          ..add(sprites[bodySprite + v], x, y, s, _fillByHp[key], p)
          ..add(sprites[rimSprite + v], x, y, s, _rimByHp[key], p);
      }
      _batch.add(sprites[streakSprite + v], x, y, s, _streakArgb, p);
    }
    _batch.flush(canvas, atlas, _atlasPaint);
    for (var i = 0; i < targets.length; i++) {
      final s = targets.scale[i];
      if (s == 1) {
        paintHpNumber(canvas, targets.hp[i], targets.x[i], targets.y[i]);
      } else {
        canvas
          ..save()
          ..translate(targets.x[i], targets.y[i])
          ..scale(s);
        paintHpNumber(canvas, targets.hp[i], 0, 0);
        canvas.restore();
      }
    }
  }

  /// Kırılan hedef: düz renkli fırça disk (dönen pigment parçası, sayı yok).
  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    _discPaint.color = color.withValues(alpha: opacity);
    canvas.drawPath(_disc, _discPaint);
  }

  @override
  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    paintRingGlow(canvas, x, y, scale: scale, opacity: opacity * kInkRingGlowAlpha);
    final atlas = _ensureAtlas();
    _batch.add(atlas.sprites[ringSprite], x, y, scale,
        theme.palette.pickupGlow.withValues(alpha: opacity).toARGB32(), atlas.pxPerGu);
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void paintStar(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final atlas = _ensureAtlas();
    final p = theme.palette;
    final s = scale * BaseThemeRenderer.starPulse(_time);
    final fleck = Color.lerp(p.star, _white, kInkStarFleckLightMix)!;
    _batch
      ..add(atlas.sprites[starSprite], x, y, s, p.star.withValues(alpha: opacity).toARGB32(),
          atlas.pxPerGu)
      ..add(atlas.sprites[fleckSprite], x, y, s, fleck.withValues(alpha: opacity).toARGB32(),
          atlas.pxPerGu)
      ..add(atlas.sprites[starEdgeSprite], x, y, s, p.accent.withValues(alpha: opacity).toARGB32(),
          atlas.pxPerGu);
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void paintBall(Canvas canvas, double x, double y) {
    _oneBall
      ..clear()
      ..add(x, y);
    paintBalls(canvas, _oneBall);
  }

  /// Tüm toplar tek atlas çağrısında (sumi damla + parlama).
  @override
  void paintBalls(Canvas canvas, BallBatch balls) {
    final atlas = _ensureAtlas();
    final ball = atlas.sprites[ballSprite];
    final glint = atlas.sprites[glintSprite];
    final p = atlas.pxPerGu;
    for (var i = 0; i < balls.length; i++) {
      _batch
        ..add(ball, balls.x[i], balls.y[i], 1, _ballArgb, p)
        ..add(glint, balls.x[i], balls.y[i], 1, _glintArgb, p);
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void paintSpark(Canvas canvas, double x, double y, double vx, double vy, double size, Color color) {
    _oneSpark
      ..clear()
      ..add(x, y, vx, vy, size, color.toARGB32());
    paintSparks(canvas, _oneSpark);
  }

  /// Mürekkep damlaları tek atlas çağrısında, hız yönüne çevrilmiş;
  /// görünen boy = kıvılcım boyu × [kInkSparkScale].
  @override
  void paintSparks(Canvas canvas, SparkBatch sparks) {
    final atlas = _ensureAtlas();
    for (var i = 0; i < sparks.length; i++) {
      final vx = sparks.vx[i];
      final vy = sparks.vy[i];
      final speed = math.sqrt(vx * vx + vy * vy);
      final cos = speed > 0 ? vx / speed : 1.0;
      final sin = speed > 0 ? vy / speed : 0.0;
      _batch.addRotated(atlas.sprites[dropSprite + dropVariantFor(vx, vy)], sparks.x[i], sparks.y[i],
          sparks.size[i] * _sparkUnit, cos, sin, sparks.color[i], atlas.pxPerGu);
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  // --- HUD kancaları ---------------------------------------------------------

  /// Koyu zemin çubuğunda sumi top okunmaz: kâğıt diski üstünde damla + parlama.
  @override
  void paintHudBallIcon(Canvas canvas) {
    canvas.drawCircle(
      const Offset(kHudBallIconX, kHudBallIconY),
      kHudBallIconDiameter / 2 + kInkHudIconBacking,
      _iconBacking,
    );
    final atlas = _ensureAtlas();
    _batch
      ..add(atlas.sprites[ballSprite], kHudBallIconX, kHudBallIconY, _iconScale, _ballArgb,
          atlas.pxPerGu)
      ..add(atlas.sprites[glintSprite], kHudBallIconX, kHudBallIconY, _iconScale, _glintArgb,
          atlas.pxPerGu);
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  /// Kâğıt kenarında (zemin kenarının hemen üstünde) solarak ilerleyen fırça darbesi.
  @override
  void paintAdvanceSweep(Canvas canvas, double sweep) {
    final x = -kAdvanceSweepWidth / 2 + (kVirtualW + kAdvanceSweepWidth) * sweep;
    _fade.color = Color.fromRGBO(0, 0, 0, kSweepAlpha * (1 - sweep));
    (_sweepSprite ??= _bakeSweep()).draw(canvas, x, kFloorY - kInkSweepHeight / 2, _fade);
  }

  /// Zemin kenarından yukarı sızan mürekkep, [glow] ile nefes alır.
  @override
  void paintDangerGlow(Canvas canvas, double glow) {
    _fade.color = Color.fromRGBO(0, 0, 0, kInkSeepAlpha * glow);
    (_seepSprite ??= _bakeSeep()).draw(canvas, kVirtualW / 2, kFloorY - kInkSeepHeight / 2, _fade);
  }

  @override
  void dispose() {
    _disposeBaked();
    super.dispose();
  }
}

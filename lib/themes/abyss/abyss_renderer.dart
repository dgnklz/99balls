import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../hp_ramp.dart';
import '../render_batches.dart';
import '../shared/base_theme_renderer.dart';
import '../shared/sprite_atlas.dart';
import 'jelly_geometry.dart';

/// Abyss çizici: koyu petrol-yeşil degrade, yavaşça yükselen halka kabarcıklar
/// ve çok yavaş inen plankton tozu (yönlü ışık yok); denizanası hedefler (HP
/// renginde hale, gövde, açık iç kenar + dokunaçlar, parlak vurgu), pişmiş
/// haleli aqua-beyaz top, fosforlu limon halka, yuvarlak kollu deniz yıldızı,
/// kabarcık kıvılcımlar. HUD, rakamlar ve "+3" yazısı [BaseThemeRenderer]'dadır.
///
/// Performans (PRD 7.4.1): hedef parçaları, toplar ve kıvılcımlar tek bir
/// pürüzsüz beyaz maske atlasından ([SpriteAtlas]) renk başına boyanarak her
/// grup tek `drawRawAtlas` çağrısıyla çizilir (56 hedef = 1 çağrı + rakamlar).
/// Bulanıklık (hale, top halesi) yalnızca atlas üretiminde yapılır. Kabarcık
/// katmanı bir kez kaydedilmiş Picture'dır; karede yalnızca kaydırılır.
/// Karede yeni Paint/Path/liste yok.
class AbyssRenderer extends BaseThemeRenderer {
  static const double _ringRadius = kPickupRadius - kPickupStroke / 2;

  // Atlas sprite sırası.
  static const int _haloId = 0;
  static const int _bodyId = 1;
  static const int _rimId = 2;
  static const int _glossId = 3;
  static const int _ballId = 4;
  static const int _bubbleId = 5;

  final Paint _background;
  final Picture _bubbles;
  final Float32List _dust = Float32List(kAbyssDustCount * 2);
  final Paint _dustPaint;
  double _bubbleOffset = 0;
  double _time = 0;

  SpriteAtlas? _atlas;
  final SpriteBatch _batch = SpriteBatch(kAbyssAtlasBatchCapacity);
  final TargetBatch _oneTarget = TargetBatch();
  final BallBatch _oneBall = BallBatch();
  final SparkBatch _oneSpark = SparkBatch();

  /// HP başına hale, dolgu ve kenar rengi (HpRamp önbelleğiyle aynı aralık; ARGB).
  final List<int> _haloByHp;
  final List<int> _fillByHp;
  final List<int> _rimByHp;
  final int _glossArgb;
  final int _ballArgb;

  final Path _body = JellyGeometry.body();
  final Path _star = JellyGeometry.starfish();
  final Paint _atlasPaint = Paint()..filterQuality = FilterQuality.low;
  final Paint _disc = Paint();
  final Paint _ring;
  final Paint _ringInner;
  final Paint _starPaint = Paint();
  final Paint _starDot = Paint();

  AbyssRenderer(super.theme)
      : _background = Paint()
          ..shader = Gradient.linear(
            Offset.zero,
            const Offset(0, kVirtualH),
            [theme.palette.bgTop, theme.palette.bgBottom],
          ),
        _bubbles = _recordBubbles(theme.palette.dust),
        _dustPaint = Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = kAbyssDustSize
          ..color = theme.palette.dust.withValues(alpha: kAbyssDustAlpha),
        _haloByHp = _byHp(theme.hpRamp, (c) => c.withValues(alpha: kAbyssHaloAlpha)),
        _fillByHp = _byHp(theme.hpRamp, (c) => c),
        _rimByHp = _byHp(theme.hpRamp, rimColor),
        _glossArgb = theme.palette.textPrimary.withValues(alpha: kAbyssGlossAlpha).toARGB32(),
        _ballArgb = theme.palette.accent.toARGB32(),
        _ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kPickupStroke,
        _ringInner = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kAbyssRingInnerStroke {
    final random = math.Random(kVisualRandomSeed);
    for (var i = 0; i < kAbyssDustCount; i++) {
      _dust[i * 2] = random.nextDouble() * kVirtualW;
      _dust[i * 2 + 1] = random.nextDouble() * kVirtualH;
    }
  }

  static List<int> _byHp(HpRamp ramp, Color Function(Color) map) => List.unmodifiable([
        for (var hp = 0; hp <= HpRamp.keyframes.last.$1; hp++) map(ramp.forHp(hp)).toARGB32(),
      ]);

  /// Hedefin açık iç kenarı ve dokunaçlarının rengi: HP rengi ile beyazın karışımı.
  static Color rimColor(Color fill) =>
      Color.lerp(fill, const Color(0xFFFFFFFF), kAbyssRimWhiteMix)!;

  /// Kabarcık katmanı: rastgele konum ve boyda halka kabarcıklar (görsel
  /// Random; oyun tohumuna dokunmaz).
  static Picture _recordBubbles(Color color) {
    final random = math.Random(kVisualRandomSeed + 1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = kAbyssBubbleStroke
      ..color = color.withValues(alpha: kAbyssBubbleAlpha);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    for (var i = 0; i < kAbyssBubbleCount; i++) {
      final x = random.nextDouble() * kVirtualW;
      final y = random.nextDouble() * kVirtualH;
      final r = kAbyssBubbleMinRadius +
          random.nextDouble() * (kAbyssBubbleMaxRadius - kAbyssBubbleMinRadius);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
    return recorder.endRecording();
  }

  /// Atlas sprite'ları (beyaz maske; renk çizimde verilir).
  static List<SpriteSpec> _specs() {
    const halo = JellyGeometry.haloSpriteExtent;
    const target = kTargetRadius;
    const ballExtent = kAbyssBallCoreRadius + kGlowSpriteSigmas * kAbyssBallHaloBlur;
    const bubble = kAbyssSparkBubbleRadius + kAbyssSparkBubbleStroke;
    const white = Color(0xFFFFFFFF);
    return [
      (
        Rect.fromCircle(center: Offset.zero, radius: halo),
        (c) => c.drawCircle(
              Offset.zero,
              kAbyssHaloRadius,
              Paint()
                ..color = white
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kAbyssHaloBlur),
            ),
      ),
      (
        const Rect.fromLTRB(-target, -target, target, target),
        (c) => c.drawPath(JellyGeometry.body(), Paint()..color = white),
      ),
      (
        const Rect.fromLTRB(-target, -target, target, target),
        (c) {
          final body = JellyGeometry.body();
          c
            ..save()
            ..clipPath(body)
            ..drawPath(
              body,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2 * kAbyssRimStroke
                ..color = white,
            )
            ..restore()
            ..drawPath(
              JellyGeometry.tentacles(),
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = kAbyssTentacleStroke
                ..strokeCap = StrokeCap.round
                ..color = white,
            );
        },
      ),
      (JellyGeometry.gloss.inflate(1), (c) => c.drawOval(JellyGeometry.gloss, Paint()..color = white)),
      (
        Rect.fromCircle(center: Offset.zero, radius: ballExtent),
        (c) => c
          ..drawCircle(
            Offset.zero,
            kAbyssBallCoreRadius,
            Paint()
              ..color = white.withValues(alpha: kAbyssBallHaloAlpha)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kAbyssBallHaloBlur),
          )
          ..drawCircle(Offset.zero, kAbyssBallCoreRadius, Paint()..color = white),
      ),
      (
        Rect.fromCircle(center: Offset.zero, radius: bubble),
        (c) => c
          ..drawCircle(
            Offset.zero,
            kAbyssSparkBubbleRadius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = kAbyssSparkBubbleStroke
              ..color = white,
          )
          ..drawCircle(
            const Offset(-kAbyssSparkBubbleRadius / 2, -kAbyssSparkBubbleRadius / 2),
            kAbyssSparkBubbleStroke,
            Paint()..color = white,
          ),
      ),
    ];
  }

  /// Atlas ilk çizimde, piksel oranı değişince yeniden üretilir.
  SpriteAtlas _ensureAtlas() => _atlas ??= SpriteAtlas.build(pxPerGu, _specs());

  @override
  void onPixelRatioChanged() {
    _atlas?.dispose();
    _atlas = null;
    super.onPixelRatioChanged();
  }

  @override
  void update(double dt) {
    if (!(dt > 0)) return;
    _time += dt;
    _bubbleOffset = (_bubbleOffset + kAbyssBubbleSpeed * dt) % kVirtualH;
    final dy = kAbyssDustSpeed * dt;
    for (var i = 1; i < _dust.length; i += 2) {
      var y = _dust[i] + dy;
      if (y > kVirtualH) y -= kVirtualH;
      _dust[i] = y;
    }
  }

  /// Kabarcık katmanının yukarı kayması [0, kVirtualH) (testler için).
  double get bubbleOffset => _bubbleOffset;

  /// Plankton tozunun y konumları (testler için, salt okunur görünüm).
  Float32List get dustPoints => Float32List.view(_dust.buffer);

  /// Halka opaklık nabzı [kAbyssRingPulseMin, 1] (yalnız görsel).
  double get ringPulse {
    final phase = math.sin(2 * math.pi * _time / kAbyssRingPulseSec);
    return kAbyssRingPulseMin + (1 - kAbyssRingPulseMin) * (phase + 1) / 2;
  }

  @override
  void paintBackground(Canvas canvas) {
    canvas
      ..drawRect(BaseThemeRenderer.canvasRect, _background)
      ..drawRawPoints(PointMode.points, _dust, _dustPaint)
      ..save()
      ..clipRect(BaseThemeRenderer.canvasRect)
      ..translate(0, -_bubbleOffset)
      ..drawPicture(_bubbles)
      ..translate(0, kVirtualH)
      ..drawPicture(_bubbles)
      ..restore();
  }

  @override
  void paintTarget(Canvas canvas, double x, double y, int hp, {double scale = 1, Color? fill}) {
    _oneTarget
      ..clear()
      ..add(x, y, hp, tscale: scale, tfill: fill?.toARGB32() ?? 0);
    paintTargets(canvas, _oneTarget);
  }

  /// Tüm hedeflerin hale, gövde, kenar ve vurgusu tek atlas çağrısında; sonra
  /// rakamlar. Hedefler çakışmadığı için (hale ≤ 28 gu, hücre aralığı 59.4 gu)
  /// görünüm hedef hedef çizimle aynıdır.
  @override
  void paintTargets(Canvas canvas, TargetBatch targets) {
    final atlas = _ensureAtlas();
    final p = atlas.pxPerGu;
    final halo = atlas.sprites[_haloId];
    final body = atlas.sprites[_bodyId];
    final rim = atlas.sprites[_rimId];
    final gloss = atlas.sprites[_glossId];
    final last = HpRamp.keyframes.last.$1;
    for (var i = 0; i < targets.length; i++) {
      final x = targets.x[i];
      final y = targets.y[i];
      final hp = targets.hp[i];
      final s = targets.scale[i];
      final custom = targets.fill[i];
      final key = hp < 0 ? 0 : (hp > last ? last : hp);
      if (custom != 0) {
        final color = Color(custom);
        _batch
          ..add(halo, x, y, s, color.withValues(alpha: kAbyssHaloAlpha).toARGB32(), p)
          ..add(body, x, y, s, custom, p)
          ..add(rim, x, y, s, rimColor(color).toARGB32(), p);
      } else {
        _batch
          ..add(halo, x, y, s, _haloByHp[key], p)
          ..add(body, x, y, s, _fillByHp[key], p)
          ..add(rim, x, y, s, _rimByHp[key], p);
      }
      _batch.add(gloss, x, y, s, _glossArgb, p);
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

  /// Kırılan hedef: düz renkli denizanası silüeti (sayı yok).
  @override
  void paintTargetDisc(Canvas canvas, Color color, double opacity) {
    _disc.color = color.withValues(alpha: opacity);
    canvas.drawPath(_body, _disc);
  }

  @override
  void paintRing(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    final alpha = opacity * ringPulse;
    _ring.color = theme.palette.pickupGlow.withValues(alpha: alpha);
    _ringInner.color = theme.palette.pickupGlow.withValues(alpha: alpha * kAbyssRingInnerAlpha);
    final center = Offset(x, y);
    final r = _ringRadius * scale;
    paintRingGlow(canvas, x, y, scale: scale, opacity: alpha);
    canvas
      ..drawCircle(center, r, _ring)
      ..drawCircle(center, r - kAbyssRingInnerInset * scale, _ringInner);
  }

  @override
  void paintStar(Canvas canvas, double x, double y, {double scale = 1, double opacity = 1}) {
    _starPaint.color = theme.palette.star.withValues(alpha: opacity);
    _starDot.color = theme.palette.textPrimary.withValues(alpha: kAbyssStarDotAlpha * opacity);
    canvas
      ..save()
      ..translate(x, y)
      ..scale(scale * BaseThemeRenderer.starPulse(_time))
      ..drawPath(_star, _starPaint)
      ..drawCircle(Offset.zero, kAbyssStarDotRadius, _starDot)
      ..restore();
  }

  @override
  void paintBall(Canvas canvas, double x, double y) {
    _oneBall
      ..clear()
      ..add(x, y);
    paintBalls(canvas, _oneBall);
  }

  /// Tüm toplar tek atlas çağrısında (çekirdek + pişmiş hale).
  @override
  void paintBalls(Canvas canvas, BallBatch balls) {
    final atlas = _ensureAtlas();
    final ball = atlas.sprites[_ballId];
    for (var i = 0; i < balls.length; i++) {
      _batch.add(ball, balls.x[i], balls.y[i], 1, _ballArgb, atlas.pxPerGu);
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

  /// Kabarcık kıvılcımlar tek atlas çağrısında; çap = boy × [kAbyssSparkScale].
  @override
  void paintSparks(Canvas canvas, SparkBatch sparks) {
    final atlas = _ensureAtlas();
    final bubble = atlas.sprites[_bubbleId];
    const unit = kAbyssSparkScale / (2 * kAbyssSparkBubbleRadius);
    for (var i = 0; i < sparks.length; i++) {
      _batch.add(bubble, sparks.x[i], sparks.y[i], sparks.size[i] * unit, sparks.color[i],
          atlas.pxPerGu);
    }
    _batch.flush(canvas, atlas, _atlasPaint);
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _atlas = null;
    _bubbles.dispose();
    super.dispose();
  }
}

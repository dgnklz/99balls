import 'dart:typed_data';
import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/abyss/abyss_renderer.dart';
import 'package:balls_99/themes/abyss/abyss_theme.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/pixeldrop/pixel_atlas.dart';
import 'package:balls_99/themes/pixeldrop/pixeldrop_renderer.dart';
import 'package:balls_99/themes/pixeldrop/pixeldrop_theme.dart';
import 'package:balls_99/themes/render_batches.dart';
import 'package:flutter_test/flutter_test.dart';

import 'logging_canvas.dart';

/// M3p toplu çizim: Pixel Drop hedef, top ve kıvılcımları tek drawRawAtlas
/// çağrısıyla, cihaz pikseline oturarak çizer; diğer temalarda varsayılan yol
/// tek tek çağrılara eşdeğerdir.

/// Galaxy J8: 720 px genişlik / 416 gu.
const double _j8PxPerGu = 720 / kVirtualW;

bool _wholePixel(double gu, double pxPerGu) {
  final px = gu * pxPerGu;
  return (px - px.roundToDouble()).abs() < 1e-3;
}

/// Kayıttaki tek drawRawAtlas çağrısının (rst, rects, colors) dizileri.
(Float32List, Float32List, Int32List) _atlasCall(LoggingCanvas canvas) {
  final call = canvas.calls.singleWhere((c) => c.memberName == #drawRawAtlas);
  final args = call.positionalArguments;
  return (args[1] as Float32List, args[2] as Float32List, args[3] as Int32List);
}

void main() {
  late PixelDropRenderer pixel;

  setUp(() => pixel = PixelDropRenderer(pixelDropTheme)..setPixelRatio(_j8PxPerGu));
  tearDown(() => pixel.dispose());

  group('Pixel Drop draws each group in a single drawRawAtlas call', () {
    test('99 balls', () {
      final balls = BallBatch();
      for (var i = 0; i < kMaxBalls; i++) {
        balls.add(20 + i * 3.7, 300 + i * 1.3);
      }
      final canvas = LoggingCanvas();
      pixel.paintBalls(canvas, balls);
      expect(canvas.calls, hasLength(1));
      final (rst, _, colors) = _atlasCall(canvas);
      expect(colors, hasLength(kMaxBalls * 2), reason: 'ball + glint per ball');
      expect(rst, hasLength(kMaxBalls * 2 * 4));
    });

    test('64 sparks', () {
      final sparks = SparkBatch();
      for (var i = 0; i < kParticlePool; i++) {
        sparks.add(10 + i * 5.3, 200, 1, 0, kSparkSize, 0xFF66E6FF);
      }
      final canvas = LoggingCanvas();
      pixel.paintSparks(canvas, sparks);
      expect(canvas.calls, hasLength(1));
      expect(_atlasCall(canvas).$3, hasLength(kParticlePool));
    });

    test('56 targets, with fill, rim, gloss and one sprite per digit', () {
      final targets = TargetBatch();
      for (var i = 0; i < kCols * kPlayableRows; i++) {
        targets.add(30 + (i % kCols) * kPitch, kRow0CenterY + (i ~/ kCols) * kPitch, 1 + i * 3);
      }
      final canvas = LoggingCanvas();
      pixel.paintTargets(canvas, targets);
      expect(canvas.calls, hasLength(1));
      var expected = 0;
      for (var i = 0; i < targets.length; i++) {
        expected += 3 + '${targets.hp[i]}'.length;
      }
      expect(_atlasCall(canvas).$3, hasLength(expected));
    });

    test('colours: HP fill, light rim, translucent gloss, white digits; danger fill', () {
      final targets = TargetBatch()
        ..add(100, 200, 7)
        ..add(200, 200, 150, tfill: pixelDropPalette.danger.toARGB32());
      final canvas = LoggingCanvas();
      pixel.paintTargets(canvas, targets);
      final colors = _atlasCall(canvas).$3.map((c) => c.toUnsigned(32)).toList();
      final hpColor = pixelDropTheme.hpRamp.forHp(7);
      final white = pixelDropPalette.textPrimary.toARGB32();
      expect(colors.sublist(0, 4), [
        hpColor.toARGB32(),
        PixelDropRenderer.rimColor(hpColor).toARGB32(),
        pixelDropPalette.textPrimary.withValues(alpha: kPixelGlossAlpha).toARGB32(),
        white,
      ]);
      expect(colors[4], pixelDropPalette.danger.toARGB32());
      expect(colors[5], PixelDropRenderer.rimColor(pixelDropPalette.danger).toARGB32());
      expect(colors.sublist(7), [white, white, white]);
    });
  });

  group('pixel snapping (FilterQuality.none, no shimmer)', () {
    test('a ball moving by fractional steps lands on whole device pixels every frame', () {
      final balls = BallBatch();
      for (var frame = 0; frame < 120; frame++) {
        balls
          ..clear()
          ..add(50 + frame * 0.37, 600 - frame * 2.11);
        final canvas = LoggingCanvas();
        pixel.paintBalls(canvas, balls);
        final (rst, _, _) = _atlasCall(canvas);
        for (var i = 0; i < rst.length; i += 4) {
          expect(rst[i] * _j8PxPerGu, closeTo(1, 1e-6), reason: '1 atlas px = 1 device px');
          expect(rst[i + 1], 0);
          expect(_wholePixel(rst[i + 2], _j8PxPerGu), isTrue, reason: 'frame $frame x');
          expect(_wholePixel(rst[i + 3], _j8PxPerGu), isTrue, reason: 'frame $frame y');
        }
      }
    });

    test('targets (incl. hit pulse) and sparks keep whole-pixel position and size', () {
      final targets = TargetBatch()
        ..add(101.3, 205.7, 42)
        ..add(160.9, 205.7, 150, tscale: kHitPulseScale);
      final sparks = SparkBatch()..add(80.77, 91.31, 1, 1, kSparkSize, 0xFFFFFFFF);
      for (final draw in <void Function(Canvas)>[
        (c) => pixel.paintTargets(c, targets),
        (c) => pixel.paintSparks(c, sparks),
      ]) {
        final canvas = LoggingCanvas();
        draw(canvas);
        final (rst, rects, _) = _atlasCall(canvas);
        for (var i = 0; i < rst.length; i += 4) {
          final widthPx = (rects[i + 2] - rects[i]) * rst[i] * _j8PxPerGu;
          expect(widthPx, closeTo(widthPx.roundToDouble(), 1e-3), reason: 'sprite $i width');
          expect(_wholePixel(rst[i + 2], _j8PxPerGu), isTrue);
          expect(_wholePixel(rst[i + 3], _j8PxPerGu), isTrue);
        }
      }
    });

    test('the atlas has crisp cells: every pixel is fully opaque or fully clear', () async {
      final atlas = PixelAtlas.build(_j8PxPerGu, [
        PixelDropRenderer.targetCells,
        PixelDropRenderer.ballCells,
      ]);
      final data = (await atlas.image.toByteData(format: ImageByteFormat.rawRgba))!;
      for (var i = 3; i < data.lengthInBytes; i += 4) {
        final a = data.getUint8(i);
        expect(a == 0 || a == 255, isTrue, reason: 'alpha $a at byte $i');
      }
      atlas.dispose();
    });

    test('atlas is rebuilt at a new pixel ratio', () {
      int atlasWidth() {
        final canvas = LoggingCanvas();
        pixel.paintBall(canvas, 100, 100);
        final call = canvas.calls.single;
        return (call.positionalArguments[0] as Image).width;
      }

      final before = atlasWidth();
      pixel.setPixelRatio(_j8PxPerGu * 2);
      expect(atlasWidth(), greaterThan(before));
    });
  });

  group('Abyss draws each group in a single drawRawAtlas call', () {
    late AbyssRenderer abyss;

    setUp(() => abyss = AbyssRenderer(abyssTheme)..setPixelRatio(_j8PxPerGu));
    tearDown(() => abyss.dispose());

    test('99 balls and 64 sparks: one call each, one sprite per item', () {
      final balls = BallBatch();
      for (var i = 0; i < kMaxBalls; i++) {
        balls.add(20 + i * 3.7, 300 + i * 1.3);
      }
      var canvas = LoggingCanvas();
      abyss.paintBalls(canvas, balls);
      expect(canvas.calls, hasLength(1));
      expect(_atlasCall(canvas).$3, hasLength(kMaxBalls));

      final sparks = SparkBatch();
      for (var i = 0; i < kParticlePool; i++) {
        sparks.add(10 + i * 5.3, 200, 1, 0, kSparkSize, 0xFF5FF5E0);
      }
      canvas = LoggingCanvas();
      abyss.paintSparks(canvas, sparks);
      expect(canvas.calls, hasLength(1));
      expect(_atlasCall(canvas).$3, hasLength(kParticlePool));
    });

    test('56 targets: one atlas call (halo, body, rim, gloss) + one paragraph each', () {
      final targets = TargetBatch();
      for (var i = 0; i < kCols * kPlayableRows; i++) {
        targets.add(30 + (i % kCols) * kPitch, kRow0CenterY + (i ~/ kCols) * kPitch, 1 + i * 3,
            tscale: i.isEven ? 1 : kHitPulseScale);
      }
      final canvas = LoggingCanvas();
      abyss.paintTargets(canvas, targets);
      expect(canvas.count('drawRawAtlas'), 1);
      expect(_atlasCall(canvas).$3, hasLength(targets.length * 4));
      expect(canvas.count('drawParagraph'), targets.length);
      expect(canvas.count('drawPath') + canvas.count('drawCircle'), 0);
    });

    test('colours: HP halo, fill, light rim, translucent gloss; danger fill', () {
      final targets = TargetBatch()
        ..add(100, 200, 7)
        ..add(200, 200, 150, tfill: abyssPalette.danger.toARGB32());
      final canvas = LoggingCanvas();
      abyss.paintTargets(canvas, targets);
      final colors = _atlasCall(canvas).$3.map((c) => c.toUnsigned(32)).toList();
      final hpColor = abyssTheme.hpRamp.forHp(7);
      final gloss = abyssPalette.textPrimary.withValues(alpha: kAbyssGlossAlpha).toARGB32();
      expect(colors.sublist(0, 4), [
        hpColor.withValues(alpha: kAbyssHaloAlpha).toARGB32(),
        hpColor.toARGB32(),
        AbyssRenderer.rimColor(hpColor).toARGB32(),
        gloss,
      ]);
      final danger = abyssPalette.danger;
      expect(colors.sublist(4), [
        danger.withValues(alpha: kAbyssHaloAlpha).toARGB32(),
        danger.toARGB32(),
        AbyssRenderer.rimColor(danger).toARGB32(),
        gloss,
      ]);
    });

    test('atlas is rebuilt at a new pixel ratio', () {
      int atlasWidth() {
        final canvas = LoggingCanvas();
        abyss.paintBall(canvas, 100, 100);
        return (canvas.calls.single.positionalArguments[0] as Image).width;
      }

      final before = atlasWidth();
      abyss.setPixelRatio(_j8PxPerGu * 2);
      expect(atlasWidth(), greaterThan(before));
    });
  });

  test('themes without their own batching fall back to one call per item', () {
    final renderer = orbitfallTheme.createRenderer(orbitfallTheme);
    final balls = BallBatch();
    for (var i = 0; i < kMaxBalls; i++) {
      balls.add(20 + i * 3.0, 300);
    }
    final canvas = LoggingCanvas();
    renderer.paintBalls(canvas, balls);
    expect(canvas.count('drawCircle'), kMaxBalls);
    renderer.dispose();
  });
}

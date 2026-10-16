import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/abyss/abyss_renderer.dart';
import 'package:balls_99/themes/abyss/abyss_theme.dart';
import 'package:balls_99/themes/abyss/jelly_geometry.dart';
import 'package:balls_99/themes/candyburst/candyburst_theme.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/pixeldrop/pixeldrop_theme.dart';
import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';

/// Abyss: çizim çağrıları, denizanası silüeti çarpışma dairesinin içinde,
/// rakam kutuları gövdede, zemin ve palet ayrışması, halka ayırt edilebilirliği.

/// En büyük HP: t ≤ kMaxBalls, çarpan en çok ×2 (hpFor(99, 4) = 198).
const int _maxHp = 2 * kMaxBalls;
const double _sample = 0.25;

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

double _rgbDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255;
  final dg = (a.g - b.g) * 255;
  final db = (a.b - b.b) * 255;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

double _hueGap(double a, double b) {
  final d = (a - b).abs() % 360;
  return math.min(d, 360 - d);
}

/// [rect]'in her örnek noktası (kenarlar dahil) [path]'in içinde mi.
bool _inside(Path path, Rect rect) {
  for (var x = rect.left; x <= rect.right + 1e-9; x += _sample) {
    for (var y = rect.top; y <= rect.bottom + 1e-9; y += _sample) {
      if (!path.contains(Offset(x, y))) return false;
    }
  }
  return true;
}

void main() {
  test('all paint calls succeed', () {
    final renderer = AbyssRenderer(abyssTheme);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    renderer
      ..update(1 / 60)
      ..paintBackground(canvas)
      ..paintTarget(canvas, 100, 200, 7)
      ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
      ..paintTarget(canvas, 100, 200, _maxHp)
      ..paintTarget(canvas, 100, 200, 3, fill: abyssPalette.danger)
      ..paintRing(canvas, 50, 50)
      ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
      ..paintStar(canvas, 60, 60, opacity: 0.3)
      ..paintBall(canvas, 208, kLaunchY)
      ..paintSpark(canvas, 80, 80, kSparkSpeed, -kSparkSpeed, kSparkSize, const Color(0xFF5FF5E0))
      ..paintSpark(canvas, 80, 80, 0, 0, kSparkSize, const Color(0xFF5FF5E0))
      ..paintHud(canvas,
          score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: 120)
      ..paintFloatText(canvas, '+3', 100, 100, 0.5);
    canvas
      ..save()
      ..scale(1, 0.3);
    renderer.paintTargetDisc(canvas, abyssPalette.danger, 0.5);
    canvas.restore();
    recorder.endRecording().dispose();
    renderer.dispose();
  });

  test('bubbles rise, plankton dust sinks; both wrap inside the canvas', () {
    final renderer = AbyssRenderer(abyssTheme);
    final before = List<double>.of(renderer.dustPoints);
    renderer.update(1);
    expect(renderer.bubbleOffset, closeTo(kAbyssBubbleSpeed, 1e-9));
    for (var i = 1; i < before.length; i += 2) {
      final moved = renderer.dustPoints[i] - before[i];
      // Aşağı iner (sararken bir kez tuval boyu kadar geri döner).
      expect(moved, anyOf(closeTo(kAbyssDustSpeed, 1e-3), closeTo(kAbyssDustSpeed - kVirtualH, 1e-3)));
    }
    for (var i = 0; i < 10000; i++) {
      renderer.update(1 / 30);
      expect(renderer.bubbleOffset, inInclusiveRange(0, kVirtualH));
    }
    for (var i = 1; i < renderer.dustPoints.length; i += 2) {
      expect(renderer.dustPoints[i], inInclusiveRange(0, kVirtualH));
    }
    renderer
      ..update(0)
      ..update(double.nan); // geçersiz dt yok sayılır
    expect(renderer.bubbleOffset.isFinite, isTrue);
    expect(kAbyssBubbleSpeed, greaterThan(kAbyssDustSpeed), reason: 'parallax');
    renderer.dispose();
  });

  test('ring opacity pulse stays within [kAbyssRingPulseMin, 1]', () {
    final renderer = AbyssRenderer(abyssTheme);
    for (var i = 0; i < 200; i++) {
      renderer.update(kAbyssRingPulseSec / 37);
      expect(renderer.ringPulse, inInclusiveRange(kAbyssRingPulseMin, 1));
    }
    renderer.dispose();
  });

  group('jellyfish silhouette', () {
    final body = JellyGeometry.body();
    final bounds = body.getBounds();

    test('every body point lies inside the collision circle (kTargetRadius)', () {
      for (var x = bounds.left; x <= bounds.right; x += _sample) {
        for (var y = bounds.top; y <= bounds.bottom; y += _sample) {
          if (body.contains(Offset(x, y))) {
            expect(Offset(x, y).distance, lessThanOrEqualTo(kTargetRadius), reason: '($x, $y)');
          }
        }
      }
      expect(bounds.top, closeTo(kAbyssBellCenterY - kAbyssBellRadiusY, 0.01));
      expect(bounds.width, closeTo(2 * kAbyssBellRadiusX, 0.01));
    });

    test('tentacles (incl. stroke and round caps) stay inside the collision circle', () {
      for (final metric in JellyGeometry.tentacles().computeMetrics()) {
        for (var d = 0.0; d <= metric.length; d += _sample) {
          final p = metric.getTangentForOffset(d)!.position;
          expect(p.distance + kAbyssTentacleStroke / 2, lessThanOrEqualTo(kTargetRadius),
              reason: '$p');
        }
      }
    });

    test('is mirror-symmetric about the vertical axis', () {
      for (var x = 0.0; x <= bounds.right; x += 1) {
        for (var y = bounds.top; y <= bounds.bottom; y += 1) {
          expect(body.contains(Offset(x, y)), body.contains(Offset(-x, y)), reason: '($x, $y)');
        }
      }
    });

    test('halo stays clear of neighbouring cells', () {
      expect(JellyGeometry.haloVisibleExtent, lessThanOrEqualTo(28));
      expect(2 * JellyGeometry.haloVisibleExtent, lessThan(kPitch));
    });

    test('digit boxes (1–2 and 3 digits, shadow and rim clearance) sit inside the body', () {
      for (final box in [JellyGeometry.digitBox, JellyGeometry.digitBox3]) {
        final withShadow = box.expandToInclude(box.shift(const Offset(0, kNumberShadowOffset)));
        expect(_inside(body, withShadow.inflate(kAbyssRimStroke / 2)), isTrue, reason: '$box');
        expect(withShadow.overlaps(JellyGeometry.gloss), isFalse, reason: 'gloss vs $box');
      }
      expect(_inside(body, JellyGeometry.gloss), isTrue);
      // 3 hane daha geniş ama daha kısa kutu (yazı %80).
      expect(JellyGeometry.digitBox3.width, greaterThan(JellyGeometry.digitBox.width));
    });

    test('starfish: five rounded arms reaching the shared star size, inside the target', () {
      // getBounds kontrol noktalarını da sayar; gerçek eğri örneklenir.
      const outer = kTargetRadius * kStarSizeRatio;
      var top = 0.0;
      var farthest = 0.0;
      for (final metric in JellyGeometry.starfish().computeMetrics()) {
        for (var d = 0.0; d <= metric.length; d += _sample) {
          final p = metric.getTangentForOffset(d)!.position;
          top = math.min(top, p.dy);
          farthest = math.max(farthest, p.distance);
        }
      }
      expect(top, closeTo(-outer, 0.3), reason: 'top arm tip at the shared star size');
      expect(farthest, closeTo(outer, 0.3), reason: 'all five tips alike');
      expect(farthest, lessThan(kTargetRadius));
    });
  });

  group('palette', () {
    const p = abyssPalette;

    test('background: very dark sea green, apart from Orbitfall navy and Pixel Drop olive', () {
      final orbitHue = HSLColor.fromColor(orbitfallPalette.bgBottom).hue;
      for (final pair in [
        (p.bgTop, orbitfallPalette.bgTop, pixelDropPalette.bgTop),
        (p.bgBottom, orbitfallPalette.bgBottom, pixelDropPalette.bgBottom),
      ]) {
        final hsl = HSLColor.fromColor(pair.$1);
        expect(hsl.hue, inInclusiveRange(160, 195), reason: '${pair.$1}');
        expect(hsl.saturation, greaterThanOrEqualTo(0.4));
        expect(hsl.lightness, lessThanOrEqualTo(0.15));
        expect(_hueGap(hsl.hue, HSLColor.fromColor(pair.$2).hue), greaterThanOrEqualTo(40));
        expect(_hueGap(hsl.hue, HSLColor.fromColor(pair.$3).hue), greaterThanOrEqualTo(90));
        expect(_hueGap(hsl.hue, orbitHue), greaterThanOrEqualTo(40));
      }
    });

    test('target rim stands out from the background (≥ 3:1) for every HP and danger', () {
      for (final bg in [p.bgTop, p.bgBottom]) {
        for (var hp = 1; hp <= _maxHp; hp++) {
          final rim = AbyssRenderer.rimColor(abyssTheme.hpRamp.forHp(hp));
          expect(_contrast(rim, bg), greaterThanOrEqualTo(3), reason: 'hp=$hp');
        }
        expect(_contrast(AbyssRenderer.rimColor(p.danger), bg), greaterThanOrEqualTo(3));
      }
    });

    test('HP stops differ from Orbitfall, Candy Burst and Pixel Drop at the same index', () {
      for (var i = 0; i < abyssHpStops.length; i++) {
        for (final other in [orbitfallHpStops, candyBurstHpStops, pixelDropHpStops]) {
          expect(_rgbDistance(abyssHpStops[i], other[i]), greaterThanOrEqualTo(30),
              reason: 'c$i');
        }
      }
    });

    test('pickup ring colour is far from other themes\' rings, the ball, the star and every HP stop',
        () {
      const minDistance = 60.0;
      for (final other in [
        orbitfallPalette.pickupGlow,
        candyBurstPalette.pickupGlow,
        pixelDropPalette.pickupGlow,
        p.accent,
        p.star,
        ...abyssHpStops,
      ]) {
        expect(_rgbDistance(p.pickupGlow, other), greaterThanOrEqualTo(minDistance),
            reason: '$other');
      }
    });

    test('ball looks like a kBallRadius orb; ring is ≈ 38% larger (PRD 7.4)', () {
      expect(kAbyssBallCoreRadius + kAbyssBallHaloBlur, closeTo(kBallRadius, 0.5));
      expect(kAbyssBallCoreRadius, lessThan(kPickupRadius - kPickupStroke));
    });
  });

  test('effects fit the particle budget; four confetti colours', () {
    const e = abyssEffects;
    expect(e.confetti, hasLength(4));
    for (final n in [e.hitSparks, e.breakSparks, e.ringSparks, e.starSparks]) {
      expect(n, lessThanOrEqualTo(kMaxSparksPerFrame));
    }
    expect(e.breakSparks, candyBurstEffects.breakSparks);
    expect(e.hitSparks, candyBurstEffects.hitSparks);
  });
}

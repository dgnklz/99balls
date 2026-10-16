import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/candyburst/candyburst_theme.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/pixeldrop/pixel_geometry.dart';
import 'package:balls_99/themes/pixeldrop/pixeldrop_renderer.dart';
import 'package:balls_99/themes/pixeldrop/pixeldrop_theme.dart';
import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';

/// Pixel Drop: çizim çağrıları, piksel silüet = çarpışma dairesi, rakam
/// okunurluğu ölçütü, koyu duraklar için kenar halkası ve zemin rengi.
const double _diameter = 2 * kTargetRadius;

/// En büyük HP: t ≤ kMaxBalls, çarpan en çok ×2 (hpFor(99, 4) = 198).
const int _maxHp = 2 * kMaxBalls;

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

/// [rect]'in her noktası (0.5 gu örnekleme, kenarlar dahil) [cells] birleşiminde mi.
bool _coveredBy(Rect r, List<Rect> cells) {
  const step = 0.5;
  for (var x = r.left; x <= r.right + 1e-9; x += step) {
    for (var y = r.top; y <= r.bottom + 1e-9; y += step) {
      final inside = cells.any((c) =>
          x >= c.left - 1e-9 && x <= c.right + 1e-9 && y >= c.top - 1e-9 && y <= c.bottom + 1e-9);
      if (!inside) return false;
    }
  }
  return true;
}

Rect _bounds(List<Rect> rects) => rects.reduce((a, b) => a.expandToInclude(b));

void main() {
  test('all paint calls succeed', () {
    final renderer = PixelDropRenderer(pixelDropTheme);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    renderer
      ..update(1 / 60)
      ..paintBackground(canvas)
      ..paintTarget(canvas, 100, 200, 7)
      ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
      ..paintTarget(canvas, 100, 200, _maxHp)
      ..paintTarget(canvas, 100, 200, 3, fill: pixelDropPalette.danger)
      ..paintRing(canvas, 50, 50)
      ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
      ..paintStar(canvas, 60, 60, opacity: 0.3)
      ..paintBall(canvas, 208, kLaunchY)
      ..paintSpark(canvas, 80, 80, kSparkSpeed, -kSparkSpeed, kSparkSize, const Color(0xFF66E6FF))
      ..paintSpark(canvas, 80, 80, 0, 0, kSparkSize, const Color(0xFF66E6FF))
      ..paintHud(canvas,
          score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: 120)
      ..paintFloatText(canvas, '+3', 100, 100, 0.5)
      ..update(kPixelBlinkSec) // sönük parıltı karesi
      ..paintRing(canvas, 50, 50)
      ..paintStar(canvas, 60, 60);
    canvas
      ..save()
      ..scale(1, 0.3);
    renderer.paintTargetDisc(canvas, pixelDropPalette.danger, 0.5);
    canvas.restore();
    recorder.endRecording().dispose();
    renderer.dispose();
  });

  test('drop layer falls in whole-cell steps and wraps inside the canvas', () {
    final renderer = PixelDropRenderer(pixelDropTheme);
    renderer.update(1);
    expect(renderer.dropOffset, closeTo(kPixelDropSpeed, 1e-9));
    for (var i = 0; i < 10000; i++) {
      renderer.update(1 / 30);
      expect(renderer.dropOffset, inInclusiveRange(0, kVirtualH));
      final steps = renderer.dropStep / kPixelCell;
      expect(steps, closeTo(steps.roundToDouble(), 1e-9), reason: 'on the pixel grid');
      expect(renderer.dropStep, lessThanOrEqualTo(renderer.dropOffset));
    }
    renderer
      ..update(0)
      ..update(double.nan); // geçersiz dt yok sayılır
    expect(renderer.dropOffset.isFinite, isTrue);
    renderer.dispose();
  });

  test('blink alternates between two frames every kPixelBlinkSec', () {
    final renderer = PixelDropRenderer(pixelDropTheme);
    renderer.update(kPixelBlinkSec * 0.5);
    expect(renderer.blinkBright, isTrue);
    renderer.update(kPixelBlinkSec);
    expect(renderer.blinkBright, isFalse);
    renderer.update(kPixelBlinkSec);
    expect(renderer.blinkBright, isTrue);
    renderer.dispose();
  });

  group('target silhouette', () {
    final cells = PixelDropRenderer.targetCells;

    test('every cell lies inside the collision circle (kTargetRadius)', () {
      for (final c in cells) {
        for (final p in [c.topLeft, c.topRight, c.bottomLeft, c.bottomRight]) {
          expect(p.distance, lessThanOrEqualTo(kTargetRadius + 1e-9), reason: '$c');
        }
      }
    });

    test('reads as a circle: ≥ 85% of the disc area, symmetric, ≤ 1 gu short of it on the axes',
        () {
      final area = PixelGeometry.area(cells);
      expect(area / (math.pi * kTargetRadius * kTargetRadius), greaterThanOrEqualTo(0.85));
      final bounds = _bounds(cells);
      expect(bounds.width, greaterThanOrEqualTo(_diameter - 2));
      expect(bounds.height, greaterThanOrEqualTo(_diameter - 2));
      expect(bounds.center.dx, closeTo(0, 1e-9));
      expect(bounds.center.dy, closeTo(0, 1e-9));
      final keys = {for (final c in cells) (c.center.dx, c.center.dy)};
      for (final c in cells) {
        expect(keys.contains((-c.center.dx, c.center.dy)), isTrue, reason: 'mirror x $c');
        expect(keys.contains((c.center.dx, -c.center.dy)), isTrue, reason: 'mirror y $c');
      }
    });

    test('rim + interior partition the silhouette; gloss sits in the interior', () {
      final rim = PixelDropRenderer.targetRimCells;
      final interior = PixelDropRenderer.targetInteriorCells;
      expect(rim.length + interior.length, cells.length);
      expect(rim, isNotEmpty);
      final interiorSet = interior.toSet();
      for (final g in PixelDropRenderer.targetGlossCells) {
        expect(interiorSet.contains(g), isTrue, reason: '$g');
      }
      expect(PixelDropRenderer.targetGlossCells, isNotEmpty);
    });
  });

  group('HP digits (readability criteria)', () {
    final interior = PixelDropRenderer.targetInteriorCells;

    test('1–2 digits: height ≥ 45% of the diameter, stroke ≥ 8%', () {
      for (var hp = 1; hp < 100; hp++) {
        final b = _bounds(PixelGeometry.numberPixels(hp));
        expect(b.height, greaterThanOrEqualTo(0.45 * _diameter), reason: 'hp=$hp');
        expect(PixelGeometry.digitStroke(hp), greaterThanOrEqualTo(0.08 * _diameter));
      }
    });

    test('3 digits: height ≥ 40% of the diameter, stroke ≥ 8% (ASSUMPTIONS)', () {
      for (var hp = 100; hp <= _maxHp; hp++) {
        final b = _bounds(PixelGeometry.numberPixels(hp));
        expect(b.height, greaterThanOrEqualTo(0.40 * _diameter), reason: 'hp=$hp');
        expect(PixelGeometry.digitStroke(hp), greaterThanOrEqualTo(0.08 * _diameter));
      }
    });

    test('every HP 1–198 fits inside the silhouette, clear of the light rim', () {
      for (var hp = 1; hp <= _maxHp; hp++) {
        for (final px in PixelGeometry.numberPixels(hp)) {
          expect(_coveredBy(px, interior), isTrue, reason: 'hp=$hp $px');
        }
      }
    });

    test('3-digit pixels sit on the target grid (4 gu = 2 cells)', () {
      for (final px in PixelGeometry.numberPixels(188)) {
        for (final v in [px.left, px.top, px.right, px.bottom]) {
          final cells = v / kPixelCell;
          expect(cells, closeTo(cells.roundToDouble(), 1e-9), reason: '$px');
        }
      }
    });

    test('glyphs are centred on the target centre', () {
      for (final hp in [1, 7, 42, 100, _maxHp]) {
        final b = _bounds(PixelGeometry.numberPixels(hp));
        expect(b.center.dx, closeTo(0, 1e-9), reason: 'hp=$hp');
        expect(b.center.dy, closeTo(0, 1e-9), reason: 'hp=$hp');
      }
    });

    test('the gloss arc never touches a digit pixel', () {
      for (var hp = 1; hp <= _maxHp; hp++) {
        for (final px in PixelGeometry.numberPixels(hp)) {
          for (final g in PixelDropRenderer.targetGlossCells) {
            final overlap = px.intersect(g);
            expect(overlap.width > 1e-9 && overlap.height > 1e-9, isFalse,
                reason: 'hp=$hp $px vs $g');
          }
        }
      }
    });

    test('all ten glyphs are distinct', () {
      expect(PixelGeometry.digitMasks.map((m) => m.join(',')).toSet(), hasLength(10));
    });
  });

  test('row merging keeps every shape area and cuts the target to one part per row', () {
    for (final cells in [
      PixelDropRenderer.targetCells,
      PixelDropRenderer.targetRimCells,
      PixelDropRenderer.targetGlossCells,
      PixelDropRenderer.ballCells,
      PixelDropRenderer.ringCells,
      PixelDropRenderer.starCells,
    ]) {
      final merged = PixelGeometry.mergeRows(cells);
      expect(PixelGeometry.area(merged), closeTo(PixelGeometry.area(cells), 1e-6));
      expect(merged.length, lessThanOrEqualTo(cells.length));
      for (final c in cells) {
        expect(_coveredBy(c, merged), isTrue, reason: '$c');
      }
    }
    final rows = {for (final c in PixelDropRenderer.targetCells) c.top};
    expect(PixelGeometry.mergeRows(PixelDropRenderer.targetCells), hasLength(rows.length));
  });

  test('rim colour stands out from the background (≥ 3:1 vs bgBottom) for every HP', () {
    final bg = pixelDropPalette.bgBottom;
    for (var hp = 1; hp <= _maxHp; hp++) {
      final rim = PixelDropRenderer.rimColor(pixelDropTheme.hpRamp.forHp(hp));
      expect(_contrast(rim, bg), greaterThanOrEqualTo(3), reason: 'hp=$hp');
    }
    expect(_contrast(PixelDropRenderer.rimColor(pixelDropPalette.danger), bg),
        greaterThanOrEqualTo(3));
  });

  test('ball, ring and star stay inside their shapes; ring is larger than the ball', () {
    for (final c in PixelDropRenderer.ballCells) {
      expect(c.bottomRight.distance, lessThanOrEqualTo(kBallRadius + 1e-9));
      expect(c.topLeft.distance, lessThanOrEqualTo(kBallRadius + 1e-9));
    }
    expect(PixelDropRenderer.ballCells.toSet().contains(PixelDropRenderer.ballGlint), isTrue,
        reason: 'glint is one of the ball cells');
    for (final c in PixelDropRenderer.ringCells) {
      for (final p in [c.topLeft, c.topRight, c.bottomLeft, c.bottomRight]) {
        expect(p.distance, lessThanOrEqualTo(kPickupRadius + 1e-9));
      }
    }
    final ball = _bounds(PixelDropRenderer.ballCells);
    final ring = _bounds(PixelDropRenderer.ringCells);
    expect(ring.width / ball.width, closeTo(kPickupRadius / kBallRadius, 0.1),
        reason: 'ring ≈ 38% larger (PRD 7.4)');
    expect(PixelDropRenderer.starCells.toSet().contains(PixelDropRenderer.starGlint), isTrue,
        reason: 'glint is one of the star cells');
  });

  group('palette', () {
    test('background is dark brown-olive: not green, not navy, not plum', () {
      final p = pixelDropPalette;
      for (final bg in [p.bgTop, p.bgBottom]) {
        final hsl = HSLColor.fromColor(bg);
        expect(hsl.hue, inInclusiveRange(30, 60), reason: 'brown-olive, not green');
        expect(hsl.lightness, lessThanOrEqualTo(0.15));
      }
      expect(_rgbDistance(p.bgTop, orbitfallPalette.bgTop), greaterThanOrEqualTo(25));
      expect(_rgbDistance(p.bgBottom, orbitfallPalette.bgBottom), greaterThanOrEqualTo(25));
      expect(_rgbDistance(p.bgTop, candyBurstPalette.bgTop), greaterThanOrEqualTo(25));
      expect(_rgbDistance(p.bgBottom, candyBurstPalette.bgBottom), greaterThanOrEqualTo(25));
    });

    test('HP stops reach 4.5:1 with white digits (no anti-aliasing on pixels)', () {
      for (final stop in pixelDropHpStops) {
        expect(_contrast(stop, const Color(0xFFFFFFFF)), greaterThanOrEqualTo(4.5),
            reason: '$stop');
      }
    });

    test('HP stops differ from Candy Burst at the same index', () {
      for (var i = 0; i < pixelDropHpStops.length; i++) {
        expect(_rgbDistance(pixelDropHpStops[i], candyBurstHpStops[i]), greaterThanOrEqualTo(30),
            reason: 'c$i');
      }
    });
  });
}

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/app/system_bar_style.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/inkpaper/ink_geometry.dart';
import 'package:balls_99/themes/inkpaper/inkpaper_renderer.dart';
import 'package:balls_99/themes/inkpaper/inkpaper_theme.dart';
import 'package:balls_99/themes/shared/sprite_atlas.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter/painting.dart' show EdgeInsets, HSLColor;
import 'package:flutter_test/flutter_test.dart';

/// Ink & Paper: tek açık zeminli tema. Çizim çağrıları, fırça disk silüeti
/// çarpışma dairesinin içinde, rakam kutuları opak gövdede, halka içi boş,
/// açık zeminde kontrastlar (rakam, pigment, halka, top, HUD, öğretici).

/// En büyük HP: t ≤ kMaxBalls, çarpan en çok ×2 (hpFor(99, 4) = 198).
const int _maxHp = 2 * kMaxBalls;
const double _sample = 0.25;
const Color _white = Color(0xFFFFFFFF);

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

/// [rect]'in her örnek noktası (kenarlar dahil) [path]'in içinde mi.
bool _inside(Path path, Rect rect) {
  for (var x = rect.left; x <= rect.right + 1e-9; x += _sample) {
    for (var y = rect.top; y <= rect.bottom + 1e-9; y += _sample) {
      if (!path.contains(Offset(x, y))) return false;
    }
  }
  return true;
}

/// [path]'in içindeki örnek noktaları.
Iterable<Offset> _filled(Path path) sync* {
  final b = path.getBounds();
  for (var x = b.left; x <= b.right; x += _sample) {
    for (var y = b.top; y <= b.bottom; y += _sample) {
      final p = Offset(x, y);
      if (path.contains(p)) yield p;
    }
  }
}

void main() {
  const p = inkPaperPalette;
  final otherThemes = ThemeRegistry.all.where((t) => t.id != kInkPaperId).toList();

  test('all paint calls succeed', () {
    final renderer = InkPaperRenderer(inkPaperTheme);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    renderer
      ..update(1 / 60)
      ..paintBackground(canvas)
      ..paintTarget(canvas, 100, 200, 7)
      ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
      ..paintTarget(canvas, 100, 200, _maxHp)
      ..paintTarget(canvas, 100, 200, 3, fill: p.danger)
      ..paintRing(canvas, 50, 50)
      ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
      ..paintStar(canvas, 60, 60, opacity: 0.3)
      ..paintBall(canvas, 208, kLaunchY)
      ..paintSpark(canvas, 80, 80, kSparkSpeed, -kSparkSpeed, kSparkSize, inkPaperConfetti[1])
      ..paintSpark(canvas, 80, 80, 0, 0, kSparkSize, inkPaperConfetti[0])
      ..paintHud(canvas,
          score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: 120)
      ..paintFloatText(canvas, '+3', 100, 100, 0.5);
    canvas
      ..save()
      ..scale(1, 0.3);
    renderer.paintTargetDisc(canvas, p.danger, 0.5);
    canvas.restore();
    recorder.endRecording().dispose();
    renderer.dispose();
  });

  test('ink washes drift slowly and wrap around the canvas (with margin)', () {
    final renderer = InkPaperRenderer(inkPaperTheme);
    final before = List<double>.of(renderer.washPoints);
    renderer.update(1);
    const spanX = kVirtualW + 2 * InkPaperRenderer.washMargin;
    const spanY = kVirtualH + 2 * InkPaperRenderer.washMargin;
    for (var i = 0; i < before.length; i += 2) {
      expect(renderer.washPoints[i] - before[i],
          anyOf(closeTo(kInkWashSpeedX, 1e-3), closeTo(kInkWashSpeedX - spanX, 1e-3)));
      expect(renderer.washPoints[i + 1] - before[i + 1],
          anyOf(closeTo(kInkWashSpeedY, 1e-3), closeTo(kInkWashSpeedY - spanY, 1e-3)));
    }
    for (var i = 0; i < 20000; i++) {
      renderer.update(1 / 30);
    }
    for (var i = 0; i < renderer.washPoints.length; i += 2) {
      expect(renderer.washPoints[i],
          inInclusiveRange(-InkPaperRenderer.washMargin, kVirtualW + InkPaperRenderer.washMargin));
      expect(renderer.washPoints[i + 1],
          inInclusiveRange(-InkPaperRenderer.washMargin, kVirtualH + InkPaperRenderer.washMargin));
    }
    final frozen = List<double>.of(renderer.washPoints);
    renderer
      ..update(0)
      ..update(double.nan); // geçersiz dt yok sayılır
    expect(renderer.washPoints, frozen);
    renderer.dispose();
  });

  test('target variant follows the column (stable while rows move); drop variant per quadrant', () {
    for (var col = 0; col < kCols; col++) {
      final x = 30 + col * kPitch;
      expect(InkPaperRenderer.variantFor(x), col % kInkTargetVariants);
    }
    for (final (vx, vy) in [(1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0), (0.0, 0.0)]) {
      expect(InkPaperRenderer.dropVariantFor(vx, vy), inInclusiveRange(0, kInkTargetVariants - 1));
    }
  });

  group('brush silhouettes', () {
    for (var v = 0; v < kInkTargetVariants; v++) {
      group('variant $v', () {
        final body = InkGeometry.body(v);

        test('body lies inside the collision circle and stays a near-circle', () {
          for (final pt in _filled(body)) {
            expect(pt.distance, lessThanOrEqualTo(kTargetRadius), reason: '$pt');
          }
          for (var a = 0.0; a < 2 * math.pi; a += 0.01) {
            expect(InkGeometry.bodyRadius(v, a),
                inInclusiveRange(kInkBodyRadius - kInkBodyWobble, kInkBodyRadius + kInkBodyWobble));
          }
        });

        test('enso rim lies inside the body', () {
          for (final pt in _filled(InkGeometry.rim(v))) {
            expect(body.contains(pt), isTrue, reason: '$pt');
          }
        });

        test('digit boxes (1–2 and 3 digits, with shadow) sit inside the body', () {
          for (final box in [InkGeometry.digitBox, InkGeometry.digitBox3]) {
            final withShadow = box.expandToInclude(box.shift(const Offset(0, kNumberShadowOffset)));
            expect(_inside(body, withShadow), isTrue, reason: '$box');
          }
        });
      });
    }

    test('ink bleed stays clear of neighbouring cells', () {
      expect(InkGeometry.bleedVisibleExtent, lessThanOrEqualTo(28));
      expect(2 * InkGeometry.bleedVisibleExtent, lessThan(kPitch));
    });

    test('ring: outer edge at kPickupRadius, hollow; ball ≈ kBallRadius (ring 38% larger)', () {
      final ring = InkGeometry.ring();
      var farthest = 0.0;
      var nearest = double.infinity;
      for (final pt in _filled(ring)) {
        farthest = math.max(farthest, pt.distance);
        nearest = math.min(nearest, pt.distance);
      }
      expect(farthest, closeTo(kPickupRadius, 0.5));
      expect(nearest, greaterThanOrEqualTo(kPickupRadius - kInkRingMaxStroke - _sample));
      expect(ring.contains(Offset.zero), isFalse);
      expect(kInkBallRadius, closeTo(kBallRadius, 0.5));
    });

    test('ink drops stay within their sprite', () {
      for (var v = 0; v < kInkTargetVariants; v++) {
        for (final pt in _filled(InkGeometry.drop(v))) {
          expect(pt.distance, lessThanOrEqualTo(InkGeometry.dropExtent), reason: 'v$v $pt');
        }
      }
    });
  });

  group('atlas pixels', () {
    const px = 3.0;
    late SpriteAtlas atlas;
    late ByteData data;

    setUpAll(() async {
      atlas = SpriteAtlas.build(px, InkPaperRenderer.atlasSpecs());
      data = (await atlas.image.toByteData(format: ImageByteFormat.rawRgba))!;
    });
    tearDownAll(() => atlas.dispose());

    /// [sprite] içinde çapaya göre (gu) noktanın alfası.
    int alphaAt(int sprite, Offset gu) {
      final s = atlas.sprites[sprite];
      final x = (s.src.left + (gu.dx - s.bounds.left) * px).floor();
      final y = (s.src.top + (gu.dy - s.bounds.top) * px).floor();
      return data.getUint8((y * atlas.image.width + x) * 4 + 3);
    }

    test('ring is hollow, ball is solid', () {
      expect(alphaAt(InkPaperRenderer.ringSprite, Offset.zero), 0);
      expect(alphaAt(InkPaperRenderer.ringSprite, const Offset(kPickupRadius / 2, 0)), 0);
      expect(alphaAt(InkPaperRenderer.ballSprite, Offset.zero), 255);
    });

    test('body is fully opaque under the digits (paper never shows through)', () {
      for (var v = 0; v < kInkTargetVariants; v++) {
        for (final box in [InkGeometry.digitBox, InkGeometry.digitBox3]) {
          for (var x = box.left; x <= box.right; x += 1) {
            for (var y = box.top; y <= box.bottom; y += 1) {
              expect(alphaAt(InkPaperRenderer.bodySprite + v, Offset(x, y)), 255,
                  reason: 'v$v ($x, $y)');
            }
          }
        }
      }
    });
  });

  group('palette (light paper)', () {
    test('background is warm cream; the only light theme', () {
      for (final bg in [p.bgTop, p.bgBottom]) {
        final hsl = HSLColor.fromColor(bg);
        expect(hsl.lightness, greaterThanOrEqualTo(0.8), reason: '$bg');
        expect(hsl.hue, inInclusiveRange(30, 50), reason: '$bg');
      }
      for (final theme in otherThemes) {
        expect(HSLColor.fromColor(theme.palette.bgBottom).lightness, lessThanOrEqualTo(0.3),
            reason: theme.id);
      }
    });

    test('white digits ≥ 3:1 for every HP and danger; pigments and rims stand out from paper', () {
      for (var hp = 1; hp <= _maxHp; hp++) {
        final fill = inkPaperTheme.hpRamp.forHp(hp);
        final rim = InkPaperRenderer.rimColor(fill, p.accent);
        expect(_contrast(_white, fill), greaterThanOrEqualTo(3), reason: 'hp=$hp');
        expect(_contrast(_white, rim), greaterThanOrEqualTo(_contrast(_white, fill)),
            reason: 'rim is darker, hp=$hp');
        for (final bg in [p.bgTop, p.bgBottom]) {
          expect(_contrast(fill, bg), greaterThanOrEqualTo(3), reason: 'hp=$hp');
          expect(_contrast(rim, bg), greaterThanOrEqualTo(3), reason: 'hp=$hp');
        }
      }
      expect(_contrast(_white, p.danger), greaterThanOrEqualTo(4.5));
    });

    test('HP stops differ from every other theme at the same index', () {
      for (var i = 0; i < inkPaperHpStops.length; i++) {
        for (final theme in otherThemes) {
          expect(_rgbDistance(inkPaperHpStops[i], theme.hpRamp.stops[i]), greaterThanOrEqualTo(30),
              reason: '${theme.id} c$i');
        }
      }
    });

    test('vermilion ring: far from other rings, ball, star, danger and every HP stop; reads on paper',
        () {
      for (final other in [
        for (final theme in otherThemes) theme.palette.pickupGlow,
        p.accent,
        p.star,
        p.danger,
        ...inkPaperHpStops,
      ]) {
        expect(_rgbDistance(p.pickupGlow, other), greaterThanOrEqualTo(60), reason: '$other');
      }
      for (final bg in [p.bgTop, p.bgBottom]) {
        expect(_contrast(p.pickupGlow, bg), greaterThanOrEqualTo(3));
        expect(_contrast(p.accent, bg), greaterThanOrEqualTo(7), reason: 'sumi ball');
        expect(_contrast(p.accent, bg), greaterThanOrEqualTo(3), reason: 'star edge (sumi)');
        expect(_contrast(p.guide, bg), greaterThanOrEqualTo(4.5), reason: 'aim guide');
      }
    });

    test('danger / game over is dark ink, not red', () {
      expect(HSLColor.fromColor(p.danger).lightness, lessThanOrEqualTo(0.2));
      for (final bg in [p.bgTop, p.bgBottom]) {
        expect(_contrast(p.danger, bg), greaterThanOrEqualTo(7));
      }
    });

    test('HUD on paper: white digits and gold accent read on the translucent sumi bar', () {
      for (final (bar, bg) in [(p.hudBar, p.bgTop), (p.floorBar, p.bgBottom)]) {
        final surface = Color.alphaBlend(bar, bg);
        expect(_contrast(p.textPrimary, surface), greaterThanOrEqualTo(4.5));
        expect(_contrast(p.hudAccent, surface), greaterThanOrEqualTo(3));
      }
      expect(_contrast(p.onAccent, p.hudAccent), greaterThanOrEqualTo(4.5));
      for (final bg in [p.bgTop, p.bgBottom]) {
        expect(_contrast(p.onBackground, bg), greaterThanOrEqualTo(4.5), reason: 'tutorial');
      }
    });

    test('system bar icons: dark over cream corners, light over the sumi bars', () {
      // Yan letterbox: köşe kâğıt.
      final wide = CanvasFit.compute(const Size(800, 1000), EdgeInsets.zero);
      var style = systemBarStyle(p, wide);
      expect(style.statusBarIconBrightness, Brightness.dark);
      expect(style.systemNavigationBarIconBrightness, Brightness.dark);
      // Üst/alt letterbox: köşe yarı saydam sumi çubuk.
      final tall = CanvasFit.compute(const Size(360, 800), EdgeInsets.zero);
      style = systemBarStyle(p, tall);
      expect(style.statusBarIconBrightness, Brightness.light);
      expect(style.systemNavigationBarIconBrightness, Brightness.light);
    });
  });

  test('effects fit the particle budget; four ink droplet colours that read on paper', () {
    const e = inkPaperEffects;
    expect(e.confetti, hasLength(4));
    for (final n in [e.hitSparks, e.breakSparks, e.ringSparks, e.starSparks]) {
      expect(n, lessThanOrEqualTo(kMaxSparksPerFrame));
    }
    for (final c in e.confetti) {
      for (final bg in [p.bgTop, p.bgBottom]) {
        expect(_contrast(c, bg), greaterThanOrEqualTo(3), reason: '$c');
      }
    }
  });
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter/painting.dart' show HSLColor;
import 'package:flutter_test/flutter_test.dart';

/// Referans oyundan görsel ayrışma (ASSUMPTIONS): düşük HP kırmızı/pembe değil,
/// HUD çubukları dolu mavi değil. Tüm temalar (yer tutucular dahil) için.
const Color _referenceLowHp = Color(0xFFFF3B4E);
const Color _referenceBar = Color(0xFF3F5AA6);

/// Turuncu/amber ton aralığı (derece).
const double _warmHueMin = 15;
const double _warmHueMax = 50;
const double _minHueGapFromReference = 25;

/// Çubuk yüzeyi: yarı saydam ve koyu.
const double _maxBarOpacity = 0.7;
const double _maxBarLightness = 0.15;
const double _minRgbDistanceFromReference = 100;

double _hueGap(double a, double b) {
  final d = (a - b).abs() % 360;
  return math.min(d, 360 - d);
}

double _rgbDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255;
  final dg = (a.g - b.g) * 255;
  final db = (a.b - b.b) * 255;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

void main() {
  final referenceHue = HSLColor.fromColor(_referenceLowHp).hue;

  for (final theme in ThemeRegistry.all) {
    group(theme.id, () {
      test('low-HP targets (1–2) are warm orange/amber, not red/pink', () {
        for (final hp in [1, 2]) {
          final hue = HSLColor.fromColor(theme.hpRamp.forHp(hp)).hue;
          expect(hue, inInclusiveRange(_warmHueMin, _warmHueMax), reason: 'hp=$hp hue=$hue');
          expect(_hueGap(hue, referenceHue), greaterThan(_minHueGapFromReference),
              reason: 'hp=$hp');
        }
      });

      test('HUD and floor bars are translucent dark surfaces, not solid blue', () {
        final p = theme.palette;
        for (final bar in [p.hudBar, p.floorBar]) {
          expect(bar.a, lessThanOrEqualTo(_maxBarOpacity), reason: 'translucent');
          expect(HSLColor.fromColor(bar).lightness, lessThanOrEqualTo(_maxBarLightness));
          expect(_rgbDistance(bar, _referenceBar), greaterThan(_minRgbDistanceFromReference));
        }
        final edge = HSLColor.fromColor(p.hudEdge).lightness;
        expect(edge, greaterThan(HSLColor.fromColor(p.hudBar).lightness),
            reason: 'thin light edge line');
      });
    });
  }

  test('placeholder hue shifts never touch the HUD surface', () {
    for (final theme in ThemeRegistry.all) {
      expect(theme.palette.hudBar, orbitfallPalette.hudBar, reason: theme.id);
      expect(theme.palette.floorBar, orbitfallPalette.floorBar, reason: theme.id);
      expect(theme.palette.hudEdge, orbitfallPalette.hudEdge, reason: theme.id);
    }
  });
}

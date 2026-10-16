import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boost butonu her temada okunur ve referans maviye benzemez
/// (reference_distinction_test'in eşi). Açıkken dolgu `hudAccent`, "»" rengi
/// `bgTop`'tur (lib/features/game/widgets/boost_button.dart); kapalıyken "»"
/// `hudAccent` rengindedir ve zemin üstündedir.
const Color _referenceBar = Color(0xFF3F5AA6);
const double _minRgbDistanceFromReference = 100;
const double _minContrast = 3;

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

void main() {
  for (final theme in ThemeRegistry.all) {
    group(theme.id, () {
      final p = theme.palette;

      test('boost "on": dark chevron on the accent fill has ≥ 3:1 contrast', () {
        expect(_contrast(p.hudAccent, p.bgTop), greaterThanOrEqualTo(_minContrast));
      });

      test('boost "off": accent chevron stands out from the background (≥ 3:1)', () {
        for (final bg in [p.bgTop, p.bgBottom]) {
          expect(_contrast(p.hudAccent, bg), greaterThanOrEqualTo(_minContrast));
        }
      });

      test('accent is far from the reference blue', () {
        expect(_rgbDistance(p.hudAccent, _referenceBar),
            greaterThan(_minRgbDistanceFromReference));
      });
    });
  }
}

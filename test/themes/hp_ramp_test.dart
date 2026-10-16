import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/hp_ramp.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 7.1 HP renk durakları — her kayıtlı tema için.
double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrastWithWhite(Color c) => 1.05 / (_luminance(c) + 0.05);

/// Ardışık iki durak gözle ayrı seçilebilmeli (PRD 7.1): sRGB uzaklığı (0–255).
const double _minStopDistance = 30;

double _rgbDistance(Color a, Color b) {
  final dr = (a.r - b.r) * 255;
  final dg = (a.g - b.g) * 255;
  final db = (a.b - b.b) * 255;
  return math.sqrt(dr * dr + dg * dg + db * db);
}

void main() {
  for (final theme in ThemeRegistry.all) {
    group('${theme.id} HP ramp', () {
      final ramp = theme.hpRamp;
      final c = ramp.stops;

      test('keyframes land exactly on their stops', () {
        for (final (hp, stop) in HpRamp.keyframes) {
          expect(ramp.forHp(hp), c[stop], reason: 'hp=$hp');
        }
      });

      test('constant ranges: 1–3, 7–13, 17–24, 27–32, 50+', () {
        void constant(int from, int to, Color color) {
          for (var hp = from; hp <= to; hp++) {
            expect(ramp.forHp(hp), color, reason: 'hp=$hp');
          }
        }

        constant(1, 3, c[0]);
        constant(7, 13, c[2]);
        constant(17, 24, c[3]);
        constant(27, 32, c[5]);
        constant(50, 2 * kMaxBalls, c[10]);
      });

      test('between keyframes the color is a linear sRGB blend', () {
        expect(ramp.forHp(4), Color.lerp(c[0], c[1], 1 / 3));
        expect(ramp.forHp(15), Color.lerp(c[2], c[3], 2 / 4));
        expect(ramp.forHp(40), Color.lerp(c[7], c[8], 4 / 8));
      });

      test('11 stops, consecutive stops are distinct', () {
        expect(c, hasLength(HpRamp.stopCount));
        for (var i = 1; i < c.length; i++) {
          expect(c[i], isNot(c[i - 1]), reason: 'c${i - 1} vs c$i');
        }
      });

      test('consecutive stops are visibly apart (RGB distance ≥ $_minStopDistance)', () {
        for (var i = 1; i < c.length; i++) {
          expect(_rgbDistance(c[i], c[i - 1]), greaterThanOrEqualTo(_minStopDistance),
              reason: 'c${i - 1} vs c$i');
        }
      });

      test('white digits have at least 3:1 contrast for every HP', () {
        for (var hp = 1; hp <= 2 * kMaxBalls; hp++) {
          expect(_contrastWithWhite(ramp.forHp(hp)), greaterThanOrEqualTo(3),
              reason: 'hp=$hp');
        }
      });
    });
  }
}

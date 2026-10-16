import 'dart:math' as math;
import 'dart:ui';

import 'package:balls_99/core/theme/hp_colors.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 7.1 HP renk durakları.
double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _contrastWithWhite(Color c) => 1.05 / (_luminance(c) + 0.05);

void main() {
  const c = HpColors.stops;

  test('keyframes land exactly on their stops', () {
    final expected = {
      3: c[0], 6: c[1], 7: c[2], 13: c[2], 17: c[3], 24: c[3], 26: c[4], //
      27: c[5], 32: c[5], 34: c[6], 36: c[7], 44: c[8], 48: c[9], 50: c[10],
    };
    expected.forEach((hp, color) => expect(HpColors.forHp(hp), color, reason: 'hp=$hp'));
  });

  test('constant ranges: 1–3, 7–13, 17–24, 27–32, 50+', () {
    void constant(int from, int to, Color color) {
      for (var hp = from; hp <= to; hp++) {
        expect(HpColors.forHp(hp), color, reason: 'hp=$hp');
      }
    }

    constant(1, 3, c[0]);
    constant(7, 13, c[2]);
    constant(17, 24, c[3]);
    constant(27, 32, c[5]);
    constant(50, 2 * kMaxBalls, c[10]);
  });

  test('between keyframes the color is a linear sRGB blend', () {
    expect(HpColors.forHp(4), Color.lerp(c[0], c[1], 1 / 3));
    expect(HpColors.forHp(15), Color.lerp(c[2], c[3], 2 / 4));
    expect(HpColors.forHp(40), Color.lerp(c[7], c[8], 4 / 8));
  });

  test('11 stops, consecutive stops are distinct', () {
    expect(c, hasLength(11));
    for (var i = 1; i < c.length; i++) {
      expect(c[i], isNot(c[i - 1]), reason: 'c${i - 1} vs c$i');
    }
  });

  test('white digits have at least 3:1 contrast for every HP', () {
    for (var hp = 1; hp <= 2 * kMaxBalls; hp++) {
      expect(_contrastWithWhite(HpColors.forHp(hp)), greaterThanOrEqualTo(3),
          reason: 'hp=$hp');
    }
  });
}

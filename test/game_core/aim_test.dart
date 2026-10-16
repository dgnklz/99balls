import 'dart:math' as math;

import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD Bölüm 5.1.
double _angleAboveHorizontalDeg(Shot s) =>
    math.atan2(-s.vy, s.vx.abs()) * 180 / math.pi;

void main() {
  test('kMinAimSin/Cos match kMinAimAngleDeg', () {
    final rad = kMinAimAngleDeg * math.pi / 180;
    expect(kMinAimSin, closeTo(math.sin(rad), 1e-15));
    expect(kMinAimCos, closeTo(math.cos(rad), 1e-15));
  });

  test('aim is a = -d and shot = round(a * 100)', () {
    // Aşağı-sola çek → yukarı-sağa at.
    expect(aimFromDrag(-30.123, 40.456), const Shot(3012, -4046));
  });

  test('aim is relative to the press point, not absolute', () {
    final shots = <Shot?>[];
    for (final start in [(0.0, 0.0), (120.0, 700.0), (390.0, 15.0)]) {
      final tracker = AimTracker()..down(1, start.$1, start.$2);
      tracker.move(1, start.$1 - 50, start.$2 + 80, 1.0);
      shots.add(tracker.up(1));
    }
    expect(shots.toSet(), hasLength(1));
    expect(shots.first, const Shot(5000, -8000));
  });

  test('drag is divided by the scale s', () {
    final tracker = AimTracker()..down(1, 100, 100);
    tracker.move(1, 100 - 20, 100 + 40, 2.0);
    expect(tracker.up(1), const Shot(1000, -2000));
  });

  test('dead zone: |d| < 10 gu gives no aim', () {
    expect(aimFromDrag(0, 9.99), isNull);
    expect(aimFromDrag(6, 7.9), isNull); // |d| ≈ 9.92
    expect(aimFromDrag(0, 10), const Shot(0, -1000));
  });

  test('aim pointing down or horizontal (a.y >= 0) cancels', () {
    expect(aimFromDrag(0, -50), isNull); // yukarı çekme → aşağı nişan
    expect(aimFromDrag(50, 0), isNull); // tam yatay
    expect(aimFromDrag(-50, 0), isNull);
  });

  test('aim below 5° is clamped to 5°, side preserved', () {
    final right = aimFromDrag(-100, 3.5)!; // ~2° sağa
    final left = aimFromDrag(100, 3.5)!; // ~2° sola
    expect(right.vx, greaterThan(0));
    expect(left.vx, lessThan(0));
    for (final s in [right, left]) {
      expect(_angleAboveHorizontalDeg(s), closeTo(kMinAimAngleDeg, 0.01));
      expect(_angleAboveHorizontalDeg(s), greaterThanOrEqualTo(kMinAimAngleDeg));
      expect(isValidShot(s), isTrue);
    }
  });

  test('aim above 5° is not changed', () {
    final s = aimFromDrag(-86.6, 50)!; // 30°
    expect(s, const Shot(8660, -5000));
    expect(_angleAboveHorizontalDeg(s), closeTo(30, 0.01));
  });

  test('every clamped shot is valid across many drags', () {
    for (var i = 1; i <= 2000; i++) {
      final dx = (i % 2 == 0 ? -1 : 1) * (10.0 + i * 0.37);
      final dy = (i % 7) * 0.31 + 0.001;
      final s = aimFromDrag(dx, dy);
      expect(s, isNotNull);
      expect(isValidShot(s!), isTrue, reason: '$dx,$dy → $s');
    }
  });

  test('isValidShot rejects down, horizontal and below-5° shots', () {
    expect(isValidShot(const Shot(0, -1)), isTrue);
    expect(isValidShot(const Shot(100, 0)), isFalse);
    expect(isValidShot(const Shot(0, 1)), isFalse);
    expect(isValidShot(const Shot(1000, -50)), isFalse); // ~2.9°
  });

  group('AimTracker', () {
    test('release without a valid aim is a cancel', () {
      final tracker = AimTracker()..down(1, 0, 0);
      tracker.move(1, 0, 5, 1);
      expect(tracker.current, isNull);
      expect(tracker.up(1), isNull);
    });

    test('pulling back over the start point cancels', () {
      final tracker = AimTracker()..down(1, 0, 0);
      tracker.move(1, 0, 50, 1);
      expect(tracker.current, isNotNull);
      tracker.move(1, 0, -50, 1);
      expect(tracker.up(1), isNull);
    });

    test('pointerCancel always cancels', () {
      final tracker = AimTracker()..down(1, 0, 0);
      tracker.move(1, 0, 50, 1);
      tracker.cancel();
      expect(tracker.isTracking, isFalse);
      expect(tracker.up(1), isNull);
    });

    test('second and later fingers are ignored', () {
      final tracker = AimTracker()..down(1, 0, 0);
      tracker.down(2, 300, 300);
      tracker.move(2, 0, 500, 1);
      expect(tracker.current, isNull);
      expect(tracker.up(2), isNull);
      expect(tracker.isTracking, isTrue);
      tracker.move(1, -10, 20, 1);
      expect(tracker.up(1), const Shot(1000, -2000));
    });
  });
}

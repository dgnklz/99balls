import 'dart:math' as math;

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_view/aim_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// İnce nişan: hassasiyet, mutlak başlangıç, histerezis, atış = çizgi.
double _deg(Shot s) => math.atan2(-s.vy, s.vx) * 180 / math.pi;

/// φ derece yönünde nişan için sürükleme vektörü (d = −a).
(double, double) _drag(double angleDeg, double length) {
  final r = angleDeg * math.pi / 180;
  return (-math.cos(r) * length, math.sin(r) * length);
}

const _directions = [
  (1.0, 0.0), (-1.0, 0.0), (0.0, 1.0), (0.0, -1.0), //
  (0.7071, 0.7071), (-0.7071, 0.7071), (0.7071, -0.7071), (-0.7071, -0.7071),
];

/// [length] ve [angle]'dan başlayıp 1 gu'luk her hareketin en büyük açı etkisi.
double _worstOneGuChange(double angle, double length) {
  var worst = 0.0;
  final (dx, dy) = _drag(angle, length);
  for (final (ux, uy) in _directions) {
    final c = AimController()..updateDrag(dx, dy);
    final before = _deg(c.current!);
    c.updateDrag(dx + ux, dy + uy);
    worst = math.max(worst, (_deg(c.current!) - before).abs());
  }
  return worst;
}

void main() {
  test('acceptance: for drags ≥ 60 gu a 1 gu move changes the angle ≤ 0.5°', () {
    for (final length in <double>[60, 70, 80, 100, 120, 160, 250, 400]) {
      for (final angle in <double>[10, 30, 60, 90, 120, 150, 170]) {
        expect(_worstOneGuChange(angle, length), lessThanOrEqualTo(0.5),
            reason: 'L=$length φ=$angle');
      }
    }
  });

  test('short drags are damped as well (≤ 0.5° per gu)', () {
    for (final length in <double>[12, 20, 40]) {
      expect(_worstOneGuChange(60, length), lessThanOrEqualTo(0.5), reason: 'L=$length');
    }
  });

  test('raw absolute mapping cannot meet the criterion at 60 gu (diagnosis)', () {
    final (dx, dy) = _drag(60, 60);
    final perp = (math.sin(math.pi / 3), math.cos(math.pi / 3));
    final change = (_deg(aimFromDrag(dx + perp.$1, dy + perp.$2)!) - _deg(aimFromDrag(dx, dy)!)).abs();
    expect(change, closeTo(0.955, 0.01));
  });

  test('first direction out of the dead zone is absolute', () {
    final (dx, dy) = _drag(60, 30);
    final c = AimController()..updateDrag(dx, dy);
    expect(_deg(c.current!), closeTo(60, 0.01));
  });

  test('dead zone hysteresis: enter at 10 gu, exit below 6 gu', () {
    final c = AimController();
    c.updateDrag(0, 8);
    expect(c.current, isNull);
    c.updateDrag(0, kAimEnterDistance);
    expect(c.current, isNotNull);
    c.updateDrag(0, 7);
    expect(c.current, isNotNull, reason: 'stays active above the exit distance');
    c.updateDrag(0, kAimExitDistance - 0.1);
    expect(c.current, isNull);
    c.updateDrag(0, 8);
    expect(c.current, isNull, reason: 'must cross the enter distance again');
  });

  test('cancel region resets; coming back starts absolute again', () {
    final c = AimController();
    final (dx, dy) = _drag(60, 80);
    c.updateDrag(dx, dy);
    for (var i = 0; i < 50; i++) {
      c.updateDrag(dx + i, dy); // ince ayar, açı değişir
    }
    c.updateDrag(0, -40); // yukarı çek: iptal
    expect(c.current, isNull);
    final (rx, ry) = _drag(120, 80);
    c.updateDrag(rx, ry);
    expect(_deg(c.current!), closeTo(120, 0.01));
  });

  test('angle is clamped to 5° above horizontal and every shot is valid', () {
    final c = AimController()..updateDrag(-100, 0.5);
    expect(_deg(c.current!), closeTo(kMinAimAngleDeg, 0.01));
    expect(_deg(c.current!), greaterThanOrEqualTo(kMinAimAngleDeg));

    final random = math.Random(7);
    final sweep = AimController();
    for (var i = 0; i < 5000; i++) {
      sweep.updateDrag(random.nextDouble() * 400 - 200, random.nextDouble() * 300 + 0.1);
      final shot = sweep.current;
      if (shot != null) expect(isValidShot(shot), isTrue, reason: '$shot');
    }
  });

  test('released shot is exactly the shot being drawn', () {
    final c = AimController()..down(1, 200, 300);
    c.move(1, 160, 380, 0.865);
    final drawn = c.current;
    expect(drawn, isNotNull);
    expect(c.up(1), drawn);
    expect(c.current, isNull);
  });

  test('second finger is ignored, move uses the scale', () {
    final c = AimController()..down(1, 0, 0);
    c.down(2, 50, 50);
    c.move(2, 0, 300, 1);
    expect(c.current, isNull);
    c.move(1, -15, 15 * math.sqrt(3), 0.5); // gu: (−30, 52) → 60°
    expect(c.dragDistance, closeTo(60, 1e-9));
    expect(_deg(c.current!), closeTo(60, 0.01));
  });
}

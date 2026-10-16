import 'dart:math' as math;

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/engine/simulation.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_view/guide_path.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 5.2: nişan çizgisi topun gerçek yolunu 490 gu boyunca önceden çizer.
const double _eps = 1e-6;

void main() {
  test('unobstructed path is a straight line of exactly 490 gu', () {
    final guide = GuidePath()..compute(Board(), kLaunchStartX, 0, -100);
    expect(guide.pointCount, 2);
    expect(guide.length, closeTo(kGuideLength, 1e-9));
    expect(guide.xAt(1), closeTo(kLaunchStartX, 1e-9));
    expect(guide.yAt(1), closeTo(kLaunchY - kGuideLength, 1e-9));
    expect(guide.endsOnFloor, isFalse);
  });

  test('reflects off the side wall at x = 13', () {
    final guide = GuidePath()..compute(Board(), kLaunchStartX, -300, -100);
    expect(guide.pointCount, 3);
    expect(guide.xAt(1), kBallMinX);
    expect(guide.xAt(2), greaterThan(kBallMinX));
    expect(guide.length, closeTo(kGuideLength, 1e-9));
  });

  test('ignores rings and stars', () {
    final board = Board()
      ..setCell(3, 3, const PickupCell(PickupKind.ring))
      ..setCell(5, 3, const PickupCell(PickupKind.star));
    final guide = GuidePath()..compute(board, Board.centerX(3), 0, -100);
    expect(guide.pointCount, 2);
    expect(guide.length, closeTo(kGuideLength, 1e-9));
  });

  test('bounces off a target and ends on the floor', () {
    final board = Board()..setCell(kPlayableRows - 1, 3, const TargetCell(5));
    final x = Board.centerX(3);
    final guide = GuidePath()..compute(board, x, 0, -100);
    final contactY = Board.centerY(kPlayableRows - 1) + kHitDistance;
    expect(guide.endsOnFloor, isTrue);
    expect(guide.yAt(1), closeTo(contactY, 1e-9));
    expect(guide.yAt(2), kLaunchY);
    expect(guide.length, closeTo(2 * (kLaunchY - contactY), 1e-9));
    expect(board.cellAt(kPlayableRows - 1, 3), const TargetCell(5), reason: 'board untouched');
  });

  test('never exceeds the segment limit in a tight corner', () {
    final guide = GuidePath()..compute(Board(), kBallMinX, -1, -1000, maxLength: 1e6);
    expect(guide.pointCount, lessThanOrEqualTo(kGuideMaxSegments + 1));
  });

  test('matches the real Simulation trajectory step by step', () {
    final board = Board();
    for (final (row, col) in [(2, 1), (3, 4), (4, 2), (5, 5), (6, 3), (1, 6)]) {
      board.setCell(row, col, const TargetCell(999));
    }
    for (final (vx, vy) in [(150, -400), (-220, -300), (90, -500), (400, -120)]) {
      final guide = GuidePath()..compute(board, kLaunchStartX, vx, vy);
      final events = <GameEvent>[];
      final sim = Simulation(board, events)..beginVolley();
      final ball = sim.balls[sim.launch(kLaunchStartX, kLaunchY, vx.toDouble(), vy.toDouble())];

      for (var k = 1; k * kBallStepDistance <= guide.length; k++) {
        sim.step();
        final (gx, gy) = guide.pointAt(k * kBallStepDistance);
        final error = math.sqrt(math.pow(ball.x - gx, 2) + math.pow(ball.y - gy, 2));
        expect(error, lessThan(_eps), reason: 'shot ($vx,$vy) step $k');
      }
      expect(events.whereType<TargetHit>(), isNotEmpty, reason: 'shot ($vx,$vy) hits a target');
    }
  });
}

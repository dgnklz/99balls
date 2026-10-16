import 'dart:math' as math;

import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/engine/collisions.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/engine/simulation.dart';
import 'package:balls_99/game_core/model/ball.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD Bölüm 5.3 çarpışma tablosu ve 5.10 uç durumları.
const double _eps = 1e-9;
const double _v = kBallStepDistance;

class _Rig {
  final Board board = Board();
  final List<GameEvent> events = [];
  late final Simulation sim = Simulation(board, events);

  _Rig() {
    sim.beginVolley();
  }

  void steps(int n) {
    for (var i = 0; i < n; i++) {
      sim.step();
    }
  }

  /// En fazla [max] adım, [done] doğru olana kadar ilerler.
  void stepUntil(bool Function() done, {int max = 2000}) {
    for (var i = 0; i < max && !done(); i++) {
      sim.step();
    }
    expect(done(), isTrue, reason: 'condition not reached in $max steps');
  }

  List<T> eventsOf<T extends GameEvent>() => events.whereType<T>().toList();
}

double _speed(Ball b) => math.sqrt(b.vx * b.vx + b.vy * b.vy);

void main() {
  group('helpers', () {
    test('circleToi returns 0 when overlapping and approaching', () {
      expect(circleToi(0, 30, 0, -1, 0, 0, kHitDistance), 0);
    });

    test('circleToi ignores a circle the ball moves away from', () {
      expect(circleToi(0, 30, 0, 1, 0, 0, kHitDistance), kNoHit);
    });
  });

  test('speed: 585 gu/s = 4.875 gu per step, constant through bounces', () {
    final rig = _Rig();
    rig.board
      ..setCell(3, 2, const TargetCell(50))
      ..setCell(2, 4, const TargetCell(50));
    final ball = rig.sim.balls[rig.sim.launch(Board.centerX(3), kLaunchY, -3, -7)];
    rig.sim.step();
    expect(_speed(ball), closeTo(_v, _eps));
    for (var i = 0; i < 600 && ball.state == BallState.flying; i++) {
      rig.sim.step();
      if (ball.state == BallState.flying) expect(_speed(ball), closeTo(_v, _eps));
    }
    expect(rig.eventsOf<TargetHit>(), isNotEmpty);
    expect(rig.eventsOf<WallHit>(), isNotEmpty);
  });

  test('balls are launched 17 steps apart', () {
    final session = GameSession.forTest(board: Board(), initialBallCount: 4);
    expect(session.tryShoot(const Shot(0, -100)), isTrue);
    while (session.phase == GamePhase.firing) {
      session.step();
    }
    final launchSteps =
        session.drainEvents().whereType<BallLaunched>().map((e) => e.step).toList();
    expect(launchSteps, [0, 17, 34, 51]);
  });

  test('balls pass through each other', () {
    final rig = _Rig();
    final a = rig.sim.balls[rig.sim.launch(100, 300, 1, 0)];
    final b = rig.sim.balls[rig.sim.launch(200, 300, -1, 0)];
    rig.steps(30);
    expect(a.x, closeTo(100 + 30 * _v, _eps));
    expect(b.x, closeTo(200 - 30 * _v, _eps));
    expect(a.vx, greaterThan(0));
    expect(b.vx, lessThan(0));
  });

  group('walls and ceiling reflect with radius taken into account', () {
    test('left wall at x = 13', () {
      final rig = _Rig();
      final ball = rig.sim.balls[rig.sim.launch(30, 300, -1, 0)];
      var minX = ball.x;
      for (var i = 0; i < 10; i++) {
        rig.sim.step();
        minX = math.min(minX, ball.x);
      }
      expect(minX, greaterThanOrEqualTo(kBallMinX - _eps));
      expect(ball.vx, closeTo(_v, _eps));
      expect(ball.x, closeTo(kBallMinX + (10 * _v - (30 - kBallMinX)), _eps));
      expect(rig.eventsOf<WallHit>().single.side, WallSide.left);
    });

    test('right wall at x = 403', () {
      final rig = _Rig();
      final ball = rig.sim.balls[rig.sim.launch(390, 300, 1, 0)];
      rig.steps(10);
      expect(ball.vx, closeTo(-_v, _eps));
      expect(ball.x, closeTo(kBallMaxX - (10 * _v - (kBallMaxX - 390)), _eps));
      expect(rig.eventsOf<WallHit>().single.side, WallSide.right);
    });

    test('ceiling at y = 66', () {
      final rig = _Rig();
      final ball = rig.sim.balls[rig.sim.launch(208, 90, 0, -1)];
      rig.steps(10);
      expect(ball.vy, closeTo(_v, _eps));
      expect(ball.y, closeTo(kBallMinY + (10 * _v - (90 - kBallMinY)), _eps));
      expect(rig.eventsOf<WallHit>().single.side, WallSide.ceiling);
    });

    test('corner reflects both axes in the same step', () {
      final rig = _Rig();
      final ball = rig.sim.balls[rig.sim.launch(kBallMinX + 3, kBallMinY + 3, -1, -1)];
      rig.sim.step();
      expect(ball.vx, greaterThan(0));
      expect(ball.vy, greaterThan(0));
      expect(rig.eventsOf<WallHit>().map((e) => e.side).toSet(),
          {WallSide.left, WallSide.ceiling});
    });
  });

  group('targets', () {
    test('contact at distance 38, head-on hit reverses direction, HP -1', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const TargetCell(5));
      final cx = Board.centerX(3);
      final cy = Board.centerY(3);
      final ball = rig.sim.balls[rig.sim.launch(cx, kLaunchY, 0, -1)];
      var minDistance = double.infinity;
      rig.stepUntil(() {
        final d = math.sqrt(math.pow(ball.x - cx, 2) + math.pow(ball.y - cy, 2));
        minDistance = math.min(minDistance, d);
        return rig.eventsOf<TargetHit>().isNotEmpty;
      });
      expect(minDistance, greaterThanOrEqualTo(kHitDistance - _eps));
      expect(ball.vy, closeTo(_v, _eps));
      expect(ball.vx, closeTo(0, _eps));
      expect(rig.board.cellAt(3, 3), const TargetCell(4));
      final hit = rig.eventsOf<TargetHit>().single;
      expect([hit.row, hit.col, hit.hpLeft], [3, 3, 4]);
    });

    test('HP 0 removes the target at once; next ball passes through', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const TargetCell(1));
      final x = Board.centerX(3);
      rig.sim.launch(x, kLaunchY, 0, -1);
      rig.stepUntil(() => rig.eventsOf<TargetDestroyed>().isNotEmpty);
      expect(rig.board.cellAt(3, 3), isNull);

      final second = rig.sim.balls[rig.sim.launch(x, kLaunchY, 0, -1)];
      rig.stepUntil(() => second.vy > 0); // tavandan döndü
      expect(rig.eventsOf<TargetHit>().where((e) => e.ballIndex == 1), isEmpty);
      expect(rig.eventsOf<WallHit>().where((e) => e.ballIndex == 1).single.side,
          WallSide.ceiling);
    });

    test('double-hit guard: a ball inside the radius moving away does not hit', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const TargetCell(5));
      rig.sim.launch(Board.centerX(3), Board.centerY(3) + 30, 0, 1);
      rig.steps(5);
      expect(rig.eventsOf<TargetHit>(), isEmpty);
      expect(rig.board.cellAt(3, 3), const TargetCell(5));
    });

    test('two targets at the same time: smaller (row, col) is hit first', () {
      final rig = _Rig();
      rig.board
        ..setCell(1, 2, const TargetCell(9))
        ..setCell(1, 3, const TargetCell(9));
      final x = (Board.centerX(2) + Board.centerX(3)) / 2;
      final y = Board.centerY(1) + kHitDistance + 1;
      // Ön koşul: iki hedefe temas zamanı bit düzeyinde eşit.
      expect(circleToi(x, y, 0, -_v, Board.centerX(2), Board.centerY(1), kHitDistance),
          circleToi(x, y, 0, -_v, Board.centerX(3), Board.centerY(1), kHitDistance));
      rig.sim.launch(x, y, 0, -1);
      rig.stepUntil(() => rig.eventsOf<TargetHit>().isNotEmpty, max: 10);
      final first = rig.eventsOf<TargetHit>().first;
      expect([first.row, first.col], [1, 2]);
    });

    test('tunneling: swept test catches a graze that endpoint checks miss', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const TargetCell(5));
      final cx = Board.centerX(3);
      final cy = Board.centerY(3);
      final y = cy + 37.99;
      final startX = cx - 2.87;
      double dist(double x) => math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
      // Ön koşul: adımın iki ucu da temas mesafesinin dışında.
      expect(dist(startX), greaterThan(kHitDistance));
      expect(dist(startX + _v), greaterThan(kHitDistance));
      rig.sim.launch(startX, y, 1, 0);
      rig.sim.step();
      expect(rig.eventsOf<TargetHit>(), hasLength(1));
    });
  });

  group('PRD 5.10: two balls hit the same target in the same step', () {
    List<TargetHit> twoBallsStraightUp(int hp) {
      final rig = _Rig();
      rig.board.setCell(3, 3, TargetCell(hp));
      final x = Board.centerX(3);
      final a = rig.sim.balls[rig.sim.launch(x, kLaunchY, 0, -1)];
      final b = rig.sim.balls[rig.sim.launch(x, kLaunchY, 0, -1)];
      rig.stepUntil(() => rig.eventsOf<TargetHit>().isNotEmpty);
      final hits = rig.eventsOf<TargetHit>();
      if (hp >= 2) {
        expect(rig.board.cellAt(3, 3), hp > 2 ? TargetCell(hp - 2) : isNull);
        expect(a.vy, greaterThan(0));
        expect(b.vy, greaterThan(0));
      } else {
        expect(rig.board.cellAt(3, 3), isNull);
        expect(a.vy, greaterThan(0));
        expect(b.vy, lessThan(0), reason: 'second ball passes through');
      }
      return hits;
    }

    test('HP 5 drops by exactly 2', () {
      expect(twoBallsStraightUp(5).map((e) => e.hpLeft), [4, 3]);
    });

    test('HP 2 is destroyed by the second ball, never below 0', () {
      expect(twoBallsStraightUp(2).map((e) => e.hpLeft), [1, 0]);
    });

    test('HP 1: first ball destroys it, second passes through', () {
      final hits = twoBallsStraightUp(1);
      expect(hits.single.ballIndex, 0);
      expect(hits.single.hpLeft, 0);
    });
  });

  group('pickups', () {
    test('ring collected within 31 gu, direction unchanged', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const PickupCell(PickupKind.ring));
      final ball = rig.sim.balls[rig.sim.launch(Board.centerX(3) + 30.9, kLaunchY, 0, -1)];
      rig.stepUntil(() => rig.board.cellAt(3, 3) == null, max: 200);
      expect(ball.vx, 0);
      expect(ball.vy, -_v);
      expect(rig.sim.takeCollected().rings, 1);
      expect(rig.eventsOf<PickupCollected>().single.kind, PickupKind.ring);
    });

    test('ring beyond 31 gu is not collected', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const PickupCell(PickupKind.ring));
      rig.sim.launch(Board.centerX(3) + 31.1, kLaunchY, 0, -1);
      rig.steps(150);
      expect(rig.board.cellAt(3, 3), const PickupCell(PickupKind.ring));
      expect(rig.eventsOf<PickupCollected>(), isEmpty);
    });

    test('only the first ball collects a ring', () {
      final rig = _Rig();
      rig.board.setCell(3, 3, const PickupCell(PickupKind.ring));
      final x = Board.centerX(3);
      rig.sim.launch(x, kLaunchY, 0, -1);
      rig.sim.launch(x, kLaunchY, 0, -1);
      rig.steps(150);
      final collected = rig.eventsOf<PickupCollected>();
      expect(collected.single.ballIndex, 0);
      expect(rig.sim.takeCollected().rings, 1);
    });
  });

  group('floor', () {
    test('ball lands at y = 622, stops; first landing x is kept', () {
      final rig = _Rig();
      final a = rig.sim.balls[rig.sim.launch(100, 610, 0, 1)];
      final b = rig.sim.balls[rig.sim.launch(300, 500, 0, 1)];
      rig.stepUntil(() => rig.sim.flyingCount == 0);
      for (final ball in [a, b]) {
        expect(ball.state, BallState.landed);
        expect(ball.y, kLaunchY);
        expect([ball.vx, ball.vy], [0, 0]);
      }
      expect(rig.sim.firstLandingX, 100);
      expect(rig.eventsOf<BallLanded>().map((e) => e.ballIndex), [0, 1]);
    });

    test('next shot launches from the first landing x', () {
      final session = GameSession.forTest(board: Board(), initialBallCount: 2);
      session.tryShoot(const Shot(-150, -100));
      while (session.phase != GamePhase.collecting) {
        session.step();
      }
      final firstLanding =
          session.drainEvents().whereType<BallLanded>().first;
      expect(session.launchX, firstLanding.x);
      expect(session.launchX, isNot(kLaunchStartX));
    });
  });

  test('flight timeout: a ball stuck for more than 20 s lands where it is', () {
    final rig = _Rig();
    final ball = rig.sim.balls[rig.sim.launch(100, 300, 1, 0)]; // yatay, sonsuz sekme
    rig.steps(kFlightTimeoutSteps);
    expect(ball.state, BallState.flying);
    final x = ball.x;
    rig.sim.step();
    expect(ball.state, BallState.landed);
    expect(ball.x, x);
    expect(ball.y, kLaunchY);
    expect(rig.eventsOf<BallLanded>().single.timedOut, isTrue);
  });
}

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/engine/simulation.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/ball_merge_animator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_core/game_script.dart';

/// Topların ilk inen topa birleşmesi (yalnızca görsel).
const double _dt = 1 / kStepsPerSec;

void main() {
  test('first ball stays; others slide at constant speed and merge without overshoot', () {
    final events = <GameEvent>[];
    final sim = Simulation(Board(), events)..beginVolley();
    final animator = BallMergeAnimator();
    sim
      ..launch(50, 600, 0, 1) // ilk iner
      ..launch(300, 560, 0, 1)
      ..launch(400, 500, 0, 1);

    final previous = <int, double>{};
    for (var step = 0; step < 200; step++) {
      sim.step();
      for (final e in events) {
        animator.onEvent(e, sim);
      }
      events.clear();
      animator.update(_dt);

      if (animator.isVisible(0)) expect(animator.xOf(0), 50, reason: 'first ball stays');
      for (final i in [1, 2]) {
        if (!animator.isVisible(i) && !animator.isMerged(i)) continue;
        final x = animator.xOf(i);
        expect(x, greaterThanOrEqualTo(50), reason: 'no overshoot');
        final before = previous[i];
        if (before != null && animator.isVisible(i)) {
          expect(before - x, closeTo(kMergeSpeed * _dt, 1e-9), reason: 'constant speed');
        }
        previous[i] = x;
      }
    }
    expect(animator.isVisible(0), isTrue);
    expect(animator.isMerged(1), isTrue);
    expect(animator.isMerged(2), isTrue);
    expect(animator.xOf(2), 50);
  });

  test('the farthest possible ball arrives within collecting', () {
    expect(kMergeSpeed * kCollectSec, greaterThanOrEqualTo(kLaunchMaxX - kLaunchMinX));
  });

  test('when collecting ends, balls still sliding snap to the target', () {
    final events = <GameEvent>[];
    final sim = Simulation(Board(), events)..beginVolley();
    final animator = BallMergeAnimator(speed: 10);
    sim
      ..launch(50, 600, 0, 1)
      ..launch(400, 590, 0, 1);
    for (var step = 0; step < 20; step++) {
      sim.step();
      for (final e in events) {
        animator.onEvent(e, sim);
      }
      events.clear();
      animator.update(_dt);
    }
    expect(animator.isVisible(1), isTrue);
    animator.onEvent(const RowAdvanced(0, 2), sim);
    expect(animator.isMerged(1), isTrue);
    expect(animator.xOf(1), 50);
  });

  test('a new volley resets the animation', () {
    final events = <GameEvent>[];
    final sim = Simulation(Board(), events)..beginVolley();
    final animator = BallMergeAnimator();
    sim.launch(50, 600, 0, 1);
    for (var step = 0; step < 10; step++) {
      sim.step();
    }
    for (final e in events) {
      animator.onEvent(e, sim);
    }
    expect(animator.isVisible(0), isTrue);
    animator.onEvent(const BallLaunched(0, 0), sim);
    expect(animator.isVisible(0), isFalse);
  });

  test('the animation does not touch core state: stateHash is identical', () {
    List<int> run({required bool animate}) {
      final hashes = <int>[];
      final animator = BallMergeAnimator();
      final session = GameSession(4242);
      var next = 0;
      while (session.phase != GamePhase.gameOver && session.round <= 40) {
        if (session.phase == GamePhase.ready) {
          session.tryShoot(mixedShots[next++ % mixedShots.length]);
        }
        session.step();
        final events = session.drainEvents();
        if (animate) {
          for (final e in events) {
            animator.onEvent(e, session.simulation);
          }
          animator.update(_dt);
        }
        hashes.add(session.stateHash());
      }
      return hashes;
    }

    final plain = run(animate: false);
    final animated = run(animate: true);
    expect(plain.length, greaterThan(1000));
    expect(animated, plain);
  });
}

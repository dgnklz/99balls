import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/engine/simulation.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/floor_accent_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../game_core/game_script.dart';

/// Zemin neonu atış noktasını izler (yalnızca görünüm).
const double _slideSec = kFloorAccentSlideMs / Duration.millisecondsPerSecond;
const double _minX = kFloorAccentEdgeMargin + kHudAccentWidth / 2;
const double _maxX = kVirtualW - kFloorAccentEdgeMargin - kHudAccentWidth / 2;

/// Topu [x]'ten düz aşağı indirip olayları izleyiciye verir.
void _land(FloorAccentTracker tracker, double x) {
  final events = <GameEvent>[];
  final sim = Simulation(Board(), events)..beginVolley();
  tracker.onEvent(const BallLaunched(0, 0), sim);
  sim.launch(x, kLaunchY - 5, 0, 1);
  for (var i = 0; i < 10 && sim.flyingCount > 0; i++) {
    sim.step();
  }
  for (final e in events) {
    tracker.onEvent(e, sim);
  }
}

void main() {
  test('starts and resets at the default launch x (canvas center)', () {
    final tracker = FloorAccentTracker();
    expect(tracker.x, kLaunchStartX);
    _land(tracker, 100);
    tracker.update(_slideSec);
    expect(tracker.x, 100);
    tracker.reset();
    expect(tracker.x, kLaunchStartX);
    expect(tracker.target, kLaunchStartX);
  });

  test('first landing updates the target at once and slides with ease-out', () {
    final tracker = FloorAccentTracker();
    _land(tracker, 300);
    expect(tracker.target, 300, reason: 'target follows firstLandingX immediately');
    expect(tracker.x, kLaunchStartX, reason: 'slide has not advanced yet');
    tracker.update(_slideSec / 2);
    final half = (tracker.x - kLaunchStartX) / (300 - kLaunchStartX);
    expect(half, closeTo(1 - 0.125, 1e-6), reason: 'easeOutCubic at u = 0.5');
    tracker.update(_slideSec);
    expect(tracker.x, 300);
    // Yeni atışa kadar orada durur.
    tracker.update(1);
    expect(tracker.x, 300);
  });

  test('only the first landing of a volley moves it', () {
    final tracker = FloorAccentTracker();
    _land(tracker, 150);
    final events = <GameEvent>[];
    final sim = Simulation(Board(), events)..beginVolley();
    // Aynı atışın ikinci inişi (BallLaunched(0) gelmeden): yok sayılır.
    sim.launch(350, kLaunchY - 5, 0, 1);
    sim.step();
    for (final e in events) {
      tracker.onEvent(e, sim);
    }
    expect(tracker.target, 150);
  });

  test('clamped so the segment never leaves the canvas', () {
    expect(FloorAccentTracker.clampX(kBallMinX), _minX);
    expect(FloorAccentTracker.clampX(kBallMaxX), _maxX);
    expect(FloorAccentTracker.clampX(kLaunchStartX), kLaunchStartX);
    final tracker = FloorAccentTracker();
    _land(tracker, kBallMinX);
    tracker.update(_slideSec);
    expect(tracker.x, _minX);
    expect(tracker.x - kHudAccentWidth / 2, greaterThanOrEqualTo(kFloorAccentEdgeMargin));
  });

  test('following the launch point does not change core state', () {
    List<int> run({required bool track}) {
      final tracker = FloorAccentTracker();
      final hashes = <int>[];
      playScripted(20261016, shots: const [Shot(-300, -100), Shot(400, -150)],
          onEvents: (events, s) {
        if (!track) return;
        for (final e in events) {
          tracker.onEvent(e, s.simulation);
        }
        tracker.update(1 / kStepsPerSec);
      }, onStep: (s) => hashes.add(s.stateHash()));
      return hashes;
    }

    final plain = run(track: false);
    expect(plain.length, greaterThan(500));
    expect(run(track: true), plain);
  });

  test('in a real session the target ends at the next launch x', () {
    final session = GameSession.forTest(board: Board());
    final tracker = FloorAccentTracker();
    session.tryShoot(const Shot(-200, -100));
    while (session.phase != GamePhase.ready) {
      session.step();
      for (final e in session.drainEvents()) {
        tracker.onEvent(e, session.simulation);
      }
    }
    expect(tracker.target, FloorAccentTracker.clampX(session.launchX));
  });
}

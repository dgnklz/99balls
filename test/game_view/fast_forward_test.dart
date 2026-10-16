import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/fast_forward.dart';
import 'package:balls_99/game_view/game_loop.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uzun kuyrukta otomatik hızlanma: yalnızca kare saati, çekirdek etkilenmez.
const double _frame = 1 / 60;

/// Yataya yakın (≈5.1°) atış: tek top boş tahtada uzun süre uçar.
const Shot _flat = Shot(1000, -90);

/// [seconds] saniye boyunca [phase] ile kare çalıştırır, son çarpanı döndürür.
double _run(FastForward ff, GamePhase phase, double seconds) {
  var m = 1.0;
  final frames = (seconds / _frame).round();
  for (var i = 0; i < frames; i++) {
    m = ff.update(phase, _frame);
  }
  return m;
}

void main() {
  group('FastForward', () {
    test('multiplier is 1 during the first 5 s of flying', () {
      final ff = FastForward();
      for (var t = 0.0; t < kFastForwardAfter - _frame; t += _frame) {
        expect(ff.update(GamePhase.flying, _frame), 1);
      }
    });

    test('ramps linearly 1 → 4 over 1.5 s, then stays at 4', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, kFastForwardAfter);
      expect(_run(ff, GamePhase.flying, kFastForwardRamp / 2), closeTo(2.5, 0.05));
      expect(_run(ff, GamePhase.flying, kFastForwardRamp / 2), closeTo(4, 1e-9));
      expect(_run(ff, GamePhase.flying, 10), kFastForwardMax);
    });

    test('outside flying it is 1 at once and the timer restarts', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, 8);
      for (final phase in [GamePhase.ready, GamePhase.firing, GamePhase.collecting]) {
        expect(ff.update(phase, _frame), 1);
      }
      expect(_run(ff, GamePhase.flying, 4.9), 1, reason: 'counter restarted on entry');
    });

    test('firing time is not counted (99-ball volley)', () {
      final ff = FastForward();
      expect(_run(ff, GamePhase.firing, 14), 1);
      expect(_run(ff, GamePhase.flying, 4.9), 1);
      expect(_run(ff, GamePhase.flying, 1), greaterThan(1));
    });

    test('noteShot resets the counter', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, 6);
      ff.noteShot();
      expect(_run(ff, GamePhase.flying, 4.9), 1);
    });

    test('invalid dt counts as zero', () {
      final ff = FastForward();
      ff.update(GamePhase.flying, double.nan);
      ff.update(GamePhase.flying, -5);
      ff.update(GamePhase.flying, double.infinity);
      expect(ff.flyingTime, 0);
    });
  });

  group('GameLoop', () {
    test('99-ball volley: multiplier is 1 in firing and in the first 5 s of flying, '
        'rises in the long tail, never more than 32 steps per frame', () {
      final session = GameSession.forTest(board: Board(), initialBallCount: 99);
      final loop = GameLoop();
      expect(session.tryShoot(_flat), isTrue);
      loop.noteShot();

      var flyingTime = 0.0;
      var maxMultiplier = 1.0;
      var sawFlying = false;
      for (var frame = 0; frame < 60 * 120 && session.phase != GamePhase.ready; frame++) {
        final phase = session.phase;
        flyingTime = phase == GamePhase.flying ? flyingTime + _frame : 0;
        final steps = loop.advance(session, _frame);
        expect(steps, lessThanOrEqualTo(kMaxStepsPerFrameFast));
        if (phase != GamePhase.flying) {
          expect(loop.multiplier, 1, reason: 'outside flying ($phase)');
        } else {
          sawFlying = true;
          if (flyingTime <= kFastForwardAfter) {
            expect(loop.multiplier, 1, reason: 'first 5 s of flying (t=$flyingTime)');
          }
        }
        if (loop.multiplier > maxMultiplier) maxMultiplier = loop.multiplier;
      }
      expect(sawFlying, isTrue);
      expect(maxMultiplier, greaterThan(1), reason: 'long tail sped up');
      expect(session.phase, GamePhase.ready);
    });

    test('same state hash at the same step count with and without fast forward', () {
      // Hızlı: gerçek kare döngüsü, atışlar kareler arasında.
      final fast = GameSession.forTest(board: Board());
      final loop = GameLoop();
      final checkpoints = <int, int>{};
      var maxSteps = 0;
      var volleys = 0;
      for (var frame = 0; frame < 60 * 200 && volleys <= 3; frame++) {
        if (fast.phase == GamePhase.ready) {
          if (volleys == 3) break;
          fast.tryShoot(_flat);
          loop.noteShot();
          volleys++;
        }
        final steps = loop.advance(fast, _frame);
        if (steps > maxSteps) maxSteps = steps;
        checkpoints[fast.stepCount] = fast.stateHash();
      }
      // 60 Hz'de normal kare 2 adım; tam hızlanmada 2 × 4 = 8 adım.
      expect(maxSteps, 2 * kFastForwardMax, reason: 'fast forward engaged at full speed');
      expect(maxSteps, lessThanOrEqualTo(kMaxStepsPerFrameFast));

      // Düz: aynı atışlar aynı adımlarda, tek tek adım.
      final plain = GameSession.forTest(board: Board());
      final shotSteps = {for (final s in fast.shots) s.step: Shot(s.vx, s.vy)};
      final lastStep = checkpoints.keys.reduce((a, b) => a > b ? a : b);
      while (plain.stepCount < lastStep) {
        final shot = shotSteps[plain.stepCount];
        if (shot != null) expect(plain.tryShoot(shot), isTrue);
        plain.step();
        final expected = checkpoints[plain.stepCount];
        if (expected != null) {
          expect(plain.stateHash(), expected, reason: 'step ${plain.stepCount}');
        }
      }
    });
  });
}

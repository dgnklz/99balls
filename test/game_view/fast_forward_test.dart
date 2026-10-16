import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/fast_forward.dart';
import 'package:balls_99/game_view/game_loop.dart';
import 'package:flutter_test/flutter_test.dart';

/// Oyuncu kontrollü hızlanma (boost): yalnızca kare saati, çekirdek etkilenmez.
const double _frame = 1 / 60;

/// Yataya yakın (≈5.1°) atış: tek top boş tahtada uzun süre uçar.
const Shot _flat = Shot(1000, -90);

/// Eşiğin hemen altı/üstü için pay (sn); bir kareden büyük, eşikten küçük.
const double _margin = 0.5;
const double _belowThreshold = kFastForwardAfter - _margin;
const double _aboveThreshold = kFastForwardAfter + _margin;

/// Rampanın ortasındaki çarpan: 1 + (max − 1) / 2.
const double _midRampMultiplier = 1 + (kFastForwardMax - 1) / 2;

/// 99 toplu atışın firing süresi: kMaxBalls × kLaunchIntervalSteps / kStepsPerSec ≈ 14 sn.
const double _fullVolleyFiringSec = kMaxBalls * kLaunchIntervalSteps / kStepsPerSec;

/// Bir atışın üst süresi için güvenlik sınırı (firing + uçuş zaman aşımı, ×2).
const double _volleyCapSec = 2 * (_fullVolleyFiringSec + kFlightTimeoutSec);

/// 60 Hz karede normal adım sayısı (120 × 1/60 = 2).
final int _stepsPerFrame = (kStepsPerSec * _frame).round();

/// Hash testinde atılacak atış sayısı.
const int _volleys = 3;

/// Boost açıkken kapatmadan önce geçen süre (sn): rampa tamamlanır.
const double _boostHoldSec = kFastForwardRamp + _margin;

int _framesFor(double seconds) => (seconds / _frame).ceil();

/// [seconds] saniye boyunca [phase] ile kare çalıştırır, son çarpanı döndürür.
double _run(FastForward ff, GamePhase phase, double seconds) {
  var m = 1.0;
  final frames = (seconds / _frame).round();
  for (var i = 0; i < frames; i++) {
    m = ff.update(phase, _frame);
  }
  return m;
}

/// Boost'lu oyuncu: buton çıkınca açar, [_boostHoldSec] sonra kapatır, sonra
/// yine açar (rampa iniş ve kalkışını birlikte sınar).
class _BoostPlayer {
  double _onFor = -1;
  bool _cycled = false;

  void frame(FastForward ff) {
    if (!ff.available) {
      _onFor = -1;
      _cycled = false;
      return;
    }
    if (!ff.engaged && (_onFor < 0 || _cycled)) {
      ff.toggle();
      _onFor = 0;
    } else if (ff.engaged && !_cycled) {
      _onFor += _frame;
      if (_onFor >= _boostHoldSec) {
        ff.toggle();
        _cycled = true;
      }
    }
  }
}

/// Gerçek kare döngüsüyle [_volleys] düz atış; atışlar ready'ye dönülen
/// karede yapılır. Adım sayısı → stateHash kontrol noktalarını döndürür.
({GameSession session, Map<int, int> checkpoints, int maxSteps, double maxMultiplier}) _play(
    {required bool boost}) {
  final session = GameSession.forTest(board: Board());
  final loop = GameLoop();
  final player = _BoostPlayer();
  final checkpoints = <int, int>{};
  var maxSteps = 0;
  var maxMultiplier = 1.0;
  var volleys = 0;
  final maxFrames = _framesFor(_volleys * _volleyCapSec);
  for (var frame = 0; frame < maxFrames; frame++) {
    if (session.phase == GamePhase.ready) {
      if (volleys == _volleys) break;
      expect(session.tryShoot(_flat), isTrue);
      loop.noteShot();
      volleys++;
    }
    if (boost) player.frame(loop.fastForward);
    final steps = loop.advance(session, _frame);
    if (steps > maxSteps) maxSteps = steps;
    if (loop.multiplier > maxMultiplier) maxMultiplier = loop.multiplier;
    checkpoints[session.stepCount] = session.stateHash();
  }
  expect(volleys, _volleys);
  return (
    session: session,
    checkpoints: checkpoints,
    maxSteps: maxSteps,
    maxMultiplier: maxMultiplier,
  );
}

void main() {
  group('FastForward', () {
    test('before kFastForwardAfter: multiplier 1, button hidden, toggle ignored', () {
      final ff = FastForward();
      for (var t = 0.0; t < kFastForwardAfter - _frame; t += _frame) {
        expect(ff.update(GamePhase.flying, _frame), 1);
        expect(ff.available, isFalse);
        expect(ff.state, BoostState.hidden);
      }
      ff.toggle();
      expect(ff.engaged, isFalse, reason: 'button not available yet');
    });

    test('after kFastForwardAfter the button is available but nothing speeds up by itself',
        () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, _aboveThreshold);
      expect(ff.available, isTrue);
      expect(ff.state, BoostState.off);
      expect(_run(ff, GamePhase.flying, kFlightTimeoutSec.toDouble()), 1, reason: 'no auto fast forward');
    });

    test('toggle on ramps 1 → kFastForwardMax over kFastForwardRamp', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, _aboveThreshold);
      ff.toggle();
      expect(ff.state, BoostState.on);
      expect(_run(ff, GamePhase.flying, kFastForwardRamp / 2),
          closeTo(_midRampMultiplier, 0.05));
      expect(_run(ff, GamePhase.flying, kFastForwardRamp / 2), closeTo(kFastForwardMax, 1e-9));
      expect(_run(ff, GamePhase.flying, kFastForwardRamp), kFastForwardMax);
    });

    test('toggle off ramps back to 1 over kFastForwardRamp', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, _aboveThreshold);
      ff.toggle();
      _run(ff, GamePhase.flying, kFastForwardRamp + _margin);
      ff.toggle();
      expect(ff.state, BoostState.off);
      expect(_run(ff, GamePhase.flying, kFastForwardRamp / 2),
          closeTo(_midRampMultiplier, 0.05));
      expect(_run(ff, GamePhase.flying, kFastForwardRamp / 2), closeTo(1, 1e-9));
      expect(_run(ff, GamePhase.flying, kFastForwardRamp), 1);
    });

    test('leaving flying resets everything; the next flight starts hidden at 1', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, _aboveThreshold);
      ff.toggle();
      _run(ff, GamePhase.flying, kFastForwardRamp);
      for (final phase in [GamePhase.collecting, GamePhase.ready, GamePhase.gameOver]) {
        expect(ff.update(phase, _frame), 1);
        expect(ff.engaged, isFalse, reason: '$phase');
        expect(ff.state, BoostState.hidden, reason: '$phase');
      }
      expect(_run(ff, GamePhase.flying, _belowThreshold), 1, reason: 'counter restarted');
      expect(ff.state, BoostState.hidden);
    });

    test('firing time is not counted (99-ball volley)', () {
      final ff = FastForward();
      _run(ff, GamePhase.firing, _fullVolleyFiringSec);
      _run(ff, GamePhase.flying, _belowThreshold);
      expect(ff.available, isFalse);
      // Toplam flying süresi kFastForwardAfter + _margin olur: eşik aşıldı.
      _run(ff, GamePhase.flying, 2 * _margin);
      expect(ff.available, isTrue);
    });

    test('noteShot resets the counter and the boost', () {
      final ff = FastForward();
      _run(ff, GamePhase.flying, _aboveThreshold);
      ff.toggle();
      ff.noteShot();
      expect(ff.engaged, isFalse);
      expect(ff.multiplier, 1);
      _run(ff, GamePhase.flying, _belowThreshold);
      expect(ff.state, BoostState.hidden);
    });

    test('invalid dt counts as zero and does not move the ramp', () {
      final ff = FastForward();
      ff.update(GamePhase.flying, double.nan);
      ff.update(GamePhase.flying, -_frame);
      ff.update(GamePhase.flying, double.infinity);
      expect(ff.flyingTime, 0);
      expect(ff.multiplier, 1);
    });
  });

  group('GameLoop', () {
    test('99-ball volley without pressing boost: multiplier never leaves 1', () {
      final session = GameSession.forTest(board: Board(), initialBallCount: kMaxBalls);
      final loop = GameLoop();
      expect(session.tryShoot(_flat), isTrue);
      loop.noteShot();
      var sawAvailable = false;
      final maxFrames = _framesFor(_volleyCapSec);
      for (var frame = 0; frame < maxFrames && session.phase != GamePhase.ready; frame++) {
        final steps = loop.advance(session, _frame);
        if (loop.fastForward.available) sawAvailable = true;
        expect(loop.multiplier, 1, reason: 'frame $frame');
        expect(steps, lessThanOrEqualTo(kMaxStepsPerFrame));
      }
      expect(sawAvailable, isTrue, reason: 'the long tail offered the button');
      expect(session.phase, GamePhase.ready);
    });

    test('99-ball volley with boost: 1 in firing and until the button, then speeds up, '
        'never above kMaxStepsPerFrameFast', () {
      final session = GameSession.forTest(board: Board(), initialBallCount: kMaxBalls);
      final loop = GameLoop();
      expect(session.tryShoot(_flat), isTrue);
      loop.noteShot();
      var maxMultiplier = 1.0;
      final maxFrames = _framesFor(_volleyCapSec);
      for (var frame = 0; frame < maxFrames && session.phase != GamePhase.ready; frame++) {
        final phase = session.phase;
        final available = loop.fastForward.available;
        if (available && !loop.fastForward.engaged) loop.fastForward.toggle();
        final steps = loop.advance(session, _frame);
        expect(steps, lessThanOrEqualTo(kMaxStepsPerFrameFast));
        if (phase != GamePhase.flying || !available) {
          expect(loop.multiplier, 1, reason: 'frame $frame ($phase)');
        }
        if (loop.multiplier > maxMultiplier) maxMultiplier = loop.multiplier;
      }
      expect(maxMultiplier, kFastForwardMax, reason: 'long tail reached full speed');
      expect(loop.fastForward.state, BoostState.hidden, reason: 'reset after flying');
      expect(session.phase, GamePhase.ready);
    });

    test('boost changes nothing in the simulation: same hashes at the same steps', () {
      final fast = _play(boost: true);
      // 60 Hz'de normal kare 2 adım; tam hızlanmada 2 × kFastForwardMax adım.
      expect(fast.maxSteps, _stepsPerFrame * kFastForwardMax,
          reason: 'boost engaged at full speed');
      expect(fast.maxSteps, lessThanOrEqualTo(kMaxStepsPerFrameFast));

      // Düz: aynı atışlar aynı adımlarda, tek tek adım.
      final plain = GameSession.forTest(board: Board());
      final shotSteps = {for (final s in fast.session.shots) s.step: Shot(s.vx, s.vy)};
      final lastStep = fast.checkpoints.keys.reduce((a, b) => a > b ? a : b);
      while (plain.stepCount < lastStep) {
        final shot = shotSteps[plain.stepCount];
        if (shot != null) expect(plain.tryShoot(shot), isTrue);
        plain.step();
        final expected = fast.checkpoints[plain.stepCount];
        if (expected != null) {
          expect(plain.stateHash(), expected, reason: 'step ${plain.stepCount}');
        }
      }
    });

    test('with and without boost: same score, round, shots and final board', () {
      final boosted = _play(boost: true);
      final normal = _play(boost: false);
      expect(boosted.maxMultiplier, kFastForwardMax);
      expect(normal.maxMultiplier, 1);
      expect(boosted.session.score, normal.session.score);
      expect(boosted.session.round, normal.session.round);
      expect(boosted.session.ballCount, normal.session.ballCount);
      // Kayıtta yalnızca atışlar (vx, vy) var; boost yazılmaz.
      List<(int, int)> shots(GameSession s) => [for (final x in s.shots) (x.vx, x.vy)];
      expect(shots(boosted.session), shots(normal.session));
      for (var row = 0; row < kBoardRows; row++) {
        for (var col = 0; col < kCols; col++) {
          expect(boosted.session.board.cellAt(row, col), normal.session.board.cellAt(row, col),
              reason: 'cell ($row, $col)');
        }
      }
    });
  });
}

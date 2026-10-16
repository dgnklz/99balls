import '../game_core/rules/round_state_machine.dart';
import 'fast_forward.dart';
import 'fixed_step_clock.dart';

/// Kare döngüsü: sabit adım saati + uzun kuyruk hızlanması.
///
/// Her adım yine `session.step()`'tir (1/120 sn); çarpan yalnızca karede kaç
/// adım işleneceğini değiştirir. Simülasyon, replay ve stateHash etkilenmez.
/// Döngü sabit sayaçlıdır (≤ kMaxStepsPerFrameFast).
class GameLoop {
  final FixedStepClock clock = FixedStepClock();
  final FastForward fastForward = FastForward();
  double _multiplier = 1;

  /// Son karede kullanılan çarpan.
  double get multiplier => _multiplier;

  double get alpha => clock.alpha;

  void reset() {
    clock.reset();
    fastForward.reset();
    _multiplier = 1;
  }

  /// Başarılı atıştan sonra çağrılır; hızlanma sayacını sıfırlar.
  void noteShot() => fastForward.noteShot();

  /// [dt] saniyelik kare için oturumu ilerletir; işlenen adım sayısını döndürür.
  int advance(GameSession session, double dt) {
    _multiplier = fastForward.update(session.phase, dt);
    final steps = clock.consume(dt, timeScale: _multiplier);
    var run = 0;
    for (var i = 0; i < steps; i++) {
      if (session.phase == GamePhase.gameOver) break;
      final wasFlying = session.phase == GamePhase.flying;
      session.step();
      run++;
      // flying bitti: çarpan hemen 1'e döner, karenin kalan hızlı adımları atılır.
      if (_multiplier > 1 && wasFlying && session.phase != GamePhase.flying) {
        _multiplier = 1;
        fastForward.reset();
        break;
      }
    }
    return run;
  }
}

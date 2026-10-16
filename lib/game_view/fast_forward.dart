import '../core/config/game_config.dart';
import '../game_core/rules/round_state_machine.dart';

/// Uzun kuyrukta kare saati çarpanı (yalnızca görünüm/saat katmanı).
///
/// Sayaç yalnızca faz `flying` iken geçen gerçek süreyi sayar; flying'e
/// girişte, flying'den çıkışta ve her yeni atışta ([noteShot]) sıfırlanır.
/// Böylece 99 toplu bir turda ~14 sn süren firing fazı sayılmaz.
/// [kFastForwardAfter] aşılınca çarpan [kFastForwardRamp] içinde 1'den
/// [kFastForwardMax]'a doğrusal yükselir; flying dışında her zaman 1'dir.
class FastForward {
  double _flyingTime = 0;
  bool _wasFlying = false;

  /// flying'de geçen gerçek süre (sn).
  double get flyingTime => _flyingTime;

  void noteShot() => reset();

  void reset() {
    _flyingTime = 0;
    _wasFlying = false;
  }

  /// Bu kare için çarpan. [phase] karenin başındaki fazdır.
  double update(GamePhase phase, double dt) {
    if (phase != GamePhase.flying) {
      reset();
      return 1;
    }
    if (!_wasFlying) {
      _flyingTime = 0;
      _wasFlying = true;
    }
    if (dt > 0 && dt.isFinite) _flyingTime += dt;
    final over = _flyingTime - kFastForwardAfter;
    if (over <= 0) return 1;
    final t = over >= kFastForwardRamp ? 1.0 : over / kFastForwardRamp;
    return 1 + (kFastForwardMax - 1) * t;
  }
}

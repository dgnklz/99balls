import '../core/config/game_config.dart';
import '../game_core/rules/round_state_machine.dart';

/// Boost butonunun görünür durumu.
enum BoostState {
  /// Buton yok (flying değil ya da uçuş henüz [kFastForwardAfter]'ı aşmadı).
  hidden,

  /// Buton görünür, hızlanma kapalı.
  off,

  /// Buton görünür, hızlanma açık.
  on,
}

/// Uzun kuyrukta oyuncu kontrollü kare saati çarpanı (yalnızca görünüm/saat
/// katmanı; simülasyon, skor, stateHash ve replay etkilenmez).
///
/// Sayaç yalnızca faz `flying` iken geçen gerçek süreyi sayar; flying'e
/// girişte, flying'den çıkışta ve her yeni atışta ([noteShot]) sıfırlanır.
/// Böylece 99 toplu bir turda ~14 sn süren firing fazı sayılmaz.
/// [kFastForwardAfter] aşılınca hızlanma **kullanılabilir** olur (boost
/// butonu); kendiliğinden hızlanma yoktur. Oyuncu açınca çarpan
/// [kFastForwardRamp] içinde 1'den [kFastForwardMax]'a, kapatınca aynı hızla
/// 1'e doğrusal gider. flying dışında her zaman 1'dir ve durum sıfırlanır.
class FastForward {
  /// Rampa hızı (çarpan / sn): tam rampa [kFastForwardRamp] sürer.
  static const double _rampRate = (kFastForwardMax - 1) / kFastForwardRamp;

  double _flyingTime = 0;
  bool _wasFlying = false;
  bool _engaged = false;
  double _multiplier = 1;

  /// flying'de geçen gerçek süre (sn).
  double get flyingTime => _flyingTime;

  /// Boost butonu kullanılabilir mi (uçuş [kFastForwardAfter]'ı aştı).
  bool get available => _wasFlying && _flyingTime > kFastForwardAfter;

  /// Oyuncu hızlanmayı açtı mı.
  bool get engaged => _engaged;

  /// Son hesaplanan çarpan.
  double get multiplier => _multiplier;

  BoostState get state => !available ? BoostState.hidden : (_engaged ? BoostState.on : BoostState.off);

  /// Butona basış: yalnızca kullanılabilirken açar/kapatır.
  void toggle() {
    if (available) _engaged = !_engaged;
  }

  void noteShot() => reset();

  void reset() {
    _flyingTime = 0;
    _wasFlying = false;
    _engaged = false;
    _multiplier = 1;
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
    if (dt > 0 && dt.isFinite) {
      _flyingTime += dt;
      final target = _engaged ? kFastForwardMax.toDouble() : 1.0;
      final step = _rampRate * dt;
      if (_multiplier < target) {
        _multiplier = _multiplier + step > target ? target : _multiplier + step;
      } else if (_multiplier > target) {
        _multiplier = _multiplier - step < target ? target : _multiplier - step;
      }
    }
    return _multiplier;
  }
}

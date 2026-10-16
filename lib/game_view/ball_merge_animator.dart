import 'dart:typed_data';

import '../core/config/game_config.dart';
import '../game_core/constants.dart';
import '../game_core/engine/events.dart';
import '../game_core/engine/simulation.dart';

/// İnen topların ilk inen topa kayması (yalnızca görsel).
///
/// Çekirdek durumu yalnızca okunur (olaylar ve `sim.firstLandingX`);
/// görsel konumlar burada tutulur. İlk inen top yerinde kalır, sonra inen her
/// top sabit [speed] ile ona kayar; vardığında birleşir (çizilmez) ve tek top
/// görünür. Hedefi geçmez. collecting bittiğinde (RowAdvanced) yetişemeyen
/// toplar hedefe oturur.
class BallMergeAnimator {
  static const int _none = 0;
  static const int _resting = 1;
  static const int _moving = 2;
  static const int _merged = 3;

  final double speed;
  final Float64List _x = Float64List(kMaxBalls);
  final Uint8List _state = Uint8List(kMaxBalls);
  double _target = 0;
  bool _hasFirst = false;

  BallMergeAnimator({this.speed = kMergeSpeed});

  /// İnmiş ve henüz birleşmemiş top çizilmeli mi.
  bool isVisible(int index) => _state[index] == _resting || _state[index] == _moving;

  bool isMerged(int index) => _state[index] == _merged;

  /// Görsel x (yalnızca [isVisible] iken anlamlı).
  double xOf(int index) => _x[index];

  void reset() {
    _state.fillRange(0, kMaxBalls, _none);
    _hasFirst = false;
  }

  void onEvent(GameEvent event, Simulation sim) {
    switch (event) {
      case BallLaunched(ballIndex: 0):
        reset();
      case BallLanded(:final ballIndex, :final x):
        _x[ballIndex] = x;
        if (!_hasFirst) {
          _hasFirst = true;
          _target = sim.firstLandingX ?? x;
          _state[ballIndex] = _resting;
        } else {
          _state[ballIndex] = _moving;
        }
      case RowAdvanced():
        finishAll();
      default:
        break;
    }
  }

  /// Kayan topları [dt] saniye ilerletir.
  void update(double dt) {
    if (!_hasFirst || !(dt > 0)) return;
    final step = speed * dt;
    for (var i = 0; i < kMaxBalls; i++) {
      if (_state[i] != _moving) continue;
      final diff = _target - _x[i];
      if (diff.abs() <= step) {
        _x[i] = _target;
        _state[i] = _merged;
      } else {
        _x[i] += diff > 0 ? step : -step;
      }
    }
  }

  /// collecting bitti: kayan tüm toplar hedefe oturur.
  void finishAll() {
    for (var i = 0; i < kMaxBalls; i++) {
      if (_state[i] == _moving) {
        _x[i] = _target;
        _state[i] = _merged;
      }
    }
  }
}

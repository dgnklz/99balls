import '../core/config/game_config.dart';
import '../game_core/constants.dart';

/// Kare süresini sabit simülasyon adımlarına çevirir (PRD 2.3 ve 10.2).
///
/// Süre adım cinsinden biriktirilir. Bir karede en fazla [kMaxStepsPerFrame]
/// adım verilir, fazlası atılır (yavaş cihazda oyun yavaşlar ama tutarlı kalır).
/// İlk karede ve [reset] sonrasında dt en fazla [kFirstFrameMaxDt] sayılır;
/// böylece arka planda geçen süre oyuna eklenmez.
class FixedStepClock {
  /// Kayan nokta birikim hatasına karşı tolerans (adım cinsinden).
  static const double _epsilon = 1e-6;

  double _pendingSteps = 0;
  bool _firstFrame = true;

  /// Son adımdan bu yana geçen süre / adım süresi, [0, 1). Çizimde kullanılır.
  double get alpha => _pendingSteps;

  void reset() {
    _pendingSteps = 0;
    _firstFrame = true;
  }

  /// [dt] saniyelik kare için işlenecek adım sayısı.
  int consume(double dt) {
    var seconds = dt > 0 ? dt : 0.0;
    if (_firstFrame) {
      if (seconds > kFirstFrameMaxDt) seconds = kFirstFrameMaxDt;
      _firstFrame = false;
    }
    _pendingSteps += seconds * kStepsPerSec;
    final steps = (_pendingSteps + _epsilon).floor();
    if (steps > kMaxStepsPerFrame) {
      _pendingSteps = 0;
      return kMaxStepsPerFrame;
    }
    _pendingSteps -= steps;
    if (_pendingSteps < 0) _pendingSteps = 0;
    return steps;
  }
}

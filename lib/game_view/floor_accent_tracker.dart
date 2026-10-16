import '../core/config/game_config.dart';
import '../game_core/constants.dart';
import '../game_core/engine/events.dart';
import '../game_core/engine/simulation.dart';

/// Zemin çizgisindeki neon vurgunun x'i (yalnızca görünüm).
///
/// Başta ve yeniden başlatmada varsayılan atış x'inde (tuval ortası) durur.
/// Turun ilk topu indiği anda (`BallLanded`, `sim.firstLandingX` belli olur)
/// o x'e ease-out ile [kFloorAccentSlideMs] içinde kayar; yeni atışa kadar
/// orada kalır (bir sonraki atış x'i zaten budur). Çekirdek durumu yalnızca okunur.
/// Segment hiçbir zaman tuvalden taşmaz: merkez kenar payıyla sıkıştırılır.
class FloorAccentTracker {
  static const double _minX = kFloorAccentEdgeMargin + kHudAccentWidth / 2;
  static const double _maxX = kVirtualW - kFloorAccentEdgeMargin - kHudAccentWidth / 2;
  static const double _slideSec = kFloorAccentSlideMs / Duration.millisecondsPerSecond;

  double _from;
  double _to;
  double _elapsed = _slideSec;
  bool _landedThisVolley = false;

  FloorAccentTracker([double launchX = kLaunchStartX])
      : _from = clampX(launchX),
        _to = clampX(launchX);

  /// Segment merkezinin tuval içinde kalacağı x.
  static double clampX(double x) => x < _minX ? _minX : (x > _maxX ? _maxX : x);

  /// Hedef x (kayma bitince varılacak).
  double get target => _to;

  /// Şu anki x.
  double get x {
    if (_elapsed >= _slideSec) return _to;
    final u = _elapsed / _slideSec;
    final inv = 1 - u;
    final eased = 1 - inv * inv * inv; // easeOutCubic
    return _from + (_to - _from) * eased;
  }

  /// Oyun başı / yeniden başlatma: kaymadan [launchX]'e (varsayılan: orta).
  void reset([double launchX = kLaunchStartX]) {
    _from = clampX(launchX);
    _to = _from;
    _elapsed = _slideSec;
    _landedThisVolley = false;
  }

  void onEvent(GameEvent event, Simulation sim) {
    switch (event) {
      case BallLaunched(ballIndex: 0):
        _landedThisVolley = false;
      case BallLanded():
        if (_landedThisVolley) return;
        _landedThisVolley = true;
        final landing = sim.firstLandingX;
        if (landing != null) _slideTo(landing);
      default:
        break;
    }
  }

  void _slideTo(double x) {
    final target = clampX(x);
    if (target == _to) return;
    _from = this.x;
    _to = target;
    _elapsed = 0;
  }

  void update(double dt) {
    if (dt > 0 && _elapsed < _slideSec) _elapsed += dt;
  }
}

import 'dart:math' as math;

import '../core/config/game_config.dart';
import '../game_core/constants.dart';
import '../game_core/engine/aim.dart';

/// Görünüm katmanının ince nişan denetçisi (PRD 5.1 üzerine).
///
/// Mutlak eşlemede açı değişimi atan(1/L)'dir; kısa çekişte parmağın küçük
/// oynaması büyük sıçramalara dönüşür (L=60'ta 0.955°/gu). Burada:
/// - Ölü bölgeden çıkışta ilk yön ham yönden alınır (mutlak başlangıç).
/// - Sonraki her harekette ham açı farkı min(1, L / [kAimMinRadius])
///   kazancıyla uygulanır (etkin yarıçap ≥ 120 gu → ≤ 0.48°/gu).
/// - Ölü bölge histerezislidir: [kAimEnterDistance]'ta başlar,
///   [kAimExitDistance] altında biter. İptal bölgesi (a.y ≥ 0) ve ölü bölge
///   nişanı sıfırlar; tekrar çıkınca yine mutlak başlar.
///
/// Atış game_core'un aynı arayüzüyle üretilir: `aimFromDrag` aynı yuvarlama
/// ve 5° kuralını uygular. [current] hem kılavuzun çizildiği hem de
/// bırakınca ateşlenen atıştır.
class AimController {
  static const double _minAngle = kMinAimAngleDeg * math.pi / 180;
  static const double _maxAngle = math.pi - _minAngle;

  int? _pointer;
  double _startX = 0;
  double _startY = 0;
  bool _active = false;
  double _angle = 0;
  double _rawPrevious = 0;
  double _dragDistance = 0;
  Shot? _current;

  bool get isTracking => _pointer != null;

  /// O anki geçerli nişan; yoksa null.
  Shot? get current => _current;

  /// Ham sürükleme uzunluğu (gu); kılavuz boyu rampası için.
  double get dragDistance => _dragDistance;

  void down(int pointer, double x, double y) {
    if (_pointer != null) return;
    _pointer = pointer;
    _startX = x;
    _startY = y;
    _reset();
  }

  /// Konumlar ekran pikseli, [scale] = CanvasFit ölçeği.
  void move(int pointer, double x, double y, double scale) {
    if (pointer != _pointer) return;
    updateDrag((x - _startX) / scale, (y - _startY) / scale);
  }

  /// Sürükleme vektörü d (gu) ile nişanı günceller.
  void updateDrag(double dx, double dy) {
    final length = math.sqrt(dx * dx + dy * dy);
    _dragDistance = length;
    final threshold = _active ? kAimExitDistance : kAimEnterDistance;
    // a = −d; y aşağı doğru artar. a.y ≥ 0 (dy ≤ 0) iptal bölgesidir.
    if (!(length >= threshold) || dy <= 0) {
      _active = false;
      _current = null;
      return;
    }
    // a'nın yataydan yukarı açısı, (0, π).
    final raw = math.atan2(dy, -dx);
    if (!_active) {
      _angle = raw;
      _active = true;
    } else {
      final gain = length >= kAimMinRadius ? 1.0 : length / kAimMinRadius;
      _angle += (raw - _rawPrevious) * gain;
    }
    _rawPrevious = raw;
    if (_angle < _minAngle) _angle = _minAngle;
    if (_angle > _maxAngle) _angle = _maxAngle;
    _current = aimFromDrag(
      -math.cos(_angle) * kAimShotLength,
      math.sin(_angle) * kAimShotLength,
    );
  }

  /// Bırakma: geçerli nişan varsa atışı döndürür, yoksa null (iptal).
  Shot? up(int pointer) {
    if (pointer != _pointer) return null;
    final shot = _current;
    cancel();
    return shot;
  }

  /// `pointerCancel`, duraklatma ya da arka plan: her zaman iptal.
  void cancel() {
    _pointer = null;
    _reset();
  }

  void _reset() {
    _active = false;
    _current = null;
    _dragDistance = 0;
  }
}

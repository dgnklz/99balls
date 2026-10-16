import 'dart:math' show sqrt;

import '../constants.dart';

/// Atış yönü, tamsayı çifti olarak (PRD Bölüm 5.1, 2.3). y aşağı doğru artar;
/// geçerli bir atışta vy < 0'dır.
class Shot {
  final int vx;
  final int vy;

  const Shot(this.vx, this.vy);

  @override
  bool operator ==(Object other) => other is Shot && other.vx == vx && other.vy == vy;

  @override
  int get hashCode => Object.hash(vx, vy);

  @override
  String toString() => 'Shot($vx, $vy)';
}

/// Atış yukarı bakıyor ve yataydan en az [kMinAimAngleDeg] yukarıdaysa geçerlidir.
bool isValidShot(Shot shot) {
  if (shot.vy >= 0) return false;
  final x = shot.vx.toDouble();
  final y = shot.vy.toDouble();
  return -y >= sqrt(x * x + y * y) * kMinAimSin;
}

/// Sürükleme vektörü d (gu, d = (p − P0) / s) için atış; nişan yoksa null.
///
/// Nişan a = −d (sapan). |d| < [kAimDeadZone] → yok; a aşağı ya da yatay
/// bakıyorsa (a.y ≥ 0) → iptal; [kMinAimAngleDeg]'den az yukarı bakıyorsa yön
/// 5°'ye sıkıştırılır (sol/sağ korunur). Sonuç (round(a.x·100), round(a.y·100)).
Shot? aimFromDrag(double dx, double dy) {
  final lengthSq = dx * dx + dy * dy;
  if (lengthSq < kAimDeadZone * kAimDeadZone) return null;
  var ax = -dx;
  var ay = -dy;
  if (ay >= 0) return null;

  final length = sqrt(lengthSq);
  if (-ay < length * kMinAimSin) {
    final side = ax < 0 ? -length : length;
    ax = side * kMinAimCos;
    ay = -length * kMinAimSin;
  }

  final vx = (ax * kShotScale).round();
  var vy = (ay * kShotScale).round();
  // Yuvarlama açıyı sınırın altına itebilir; geçerli olana kadar yukarı çevir.
  while (!isValidShot(Shot(vx, vy))) {
    vy--;
  }
  return Shot(vx, vy);
}

/// Tek parmaklı nişan takibi (PRD 5.1). Konumlar ekran pikselidir; ölçek s
/// her harekette verilir. İlk parmak izlenir, diğerleri yok sayılır.
/// Oyun fazı kontrolü (yalnızca ready) oturumun işidir.
class AimTracker {
  int? _pointer;
  double _startX = 0;
  double _startY = 0;
  Shot? _current;

  bool get isTracking => _pointer != null;

  /// O anki geçerli nişan (kılavuz çizgisi için); yoksa null.
  Shot? get current => _current;

  void down(int pointer, double x, double y) {
    if (_pointer != null) return;
    _pointer = pointer;
    _startX = x;
    _startY = y;
    _current = null;
  }

  void move(int pointer, double x, double y, double scale) {
    if (pointer != _pointer) return;
    _current = aimFromDrag((x - _startX) / scale, (y - _startY) / scale);
  }

  /// Bırakma: geçerli nişan varsa atışı döndürür, yoksa null (iptal).
  Shot? up(int pointer) {
    if (pointer != _pointer) return null;
    final shot = _current;
    cancel();
    return shot;
  }

  /// `pointerCancel` ya da duraklatma: her zaman iptal.
  void cancel() {
    _pointer = null;
    _current = null;
  }
}

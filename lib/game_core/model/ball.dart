/// Atılan topun durumu.
enum BallState {
  /// Bu atışta henüz fırlatılmadı.
  idle,

  /// Havada.
  flying,

  /// Zemine indi (veya zaman aşımıyla inmiş sayıldı).
  landed,
}

/// Atılan top. Havuzdan yeniden kullanılır; adım döngüsünde yeni top üretilmez.
class Ball {
  double x = 0;
  double y = 0;

  /// Hız (gu/adım).
  double vx = 0;
  double vy = 0;

  BallState state = BallState.idle;

  /// Fırlatıldığından beri geçen adım sayısı.
  int flightSteps = 0;

  void reset() {
    x = 0;
    y = 0;
    vx = 0;
    vy = 0;
    state = BallState.idle;
    flightSteps = 0;
  }
}

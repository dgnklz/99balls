import 'dart:typed_data';

/// Kıvılcım parçacıkları havuzu (PRD 7.3): struct-of-arrays, sabit kapasite.
///
/// Doluyken yeni parçacık en eski yuvanın üzerine yazılır (halka tampon);
/// taşma ve tahsis yoktur. Hız ömür boyunca doğrusal olarak 0'a iner
/// (PRD 7.2: 120 → 0 gu/sn).
class SparkPool {
  final int capacity;
  final Float32List x;
  final Float32List y;
  final Float32List vx;
  final Float32List vy;
  final Float32List age;
  final Float32List life;
  final Float32List size;
  final Uint32List color;
  int _next = 0;

  SparkPool(this.capacity)
      : x = Float32List(capacity),
        y = Float32List(capacity),
        vx = Float32List(capacity),
        vy = Float32List(capacity),
        age = Float32List(capacity),
        life = Float32List(capacity),
        size = Float32List(capacity),
        color = Uint32List(capacity);

  bool isAlive(int i) => age[i] < life[i];

  int get liveCount {
    var n = 0;
    for (var i = 0; i < capacity; i++) {
      if (isAlive(i)) n++;
    }
    return n;
  }

  void spawn({
    required double x,
    required double y,
    required double vx,
    required double vy,
    required double life,
    required double size,
    required int color,
  }) {
    final i = _next;
    _next = (_next + 1) % capacity;
    this.x[i] = x;
    this.y[i] = y;
    this.vx[i] = vx;
    this.vy[i] = vy;
    age[i] = 0;
    this.life[i] = life;
    this.size[i] = size;
    this.color[i] = color;
  }

  void update(double dt) {
    if (!(dt > 0)) return;
    for (var i = 0; i < capacity; i++) {
      if (!isAlive(i)) continue;
      final remaining = 1 - age[i] / life[i];
      x[i] += vx[i] * remaining * dt;
      y[i] += vy[i] * remaining * dt;
      age[i] += dt;
    }
  }

  void clear() {
    life.fillRange(0, capacity, 0);
    age.fillRange(0, capacity, 0);
    _next = 0;
  }
}

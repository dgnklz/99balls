import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/config/game_config.dart';

/// Kısa animasyon havuzları. Her biri ayrı ve sabit kapasitelidir; doluyken en
/// eski yuva yeniden kullanılır (taşma ve tahsis yok). Kıvılcımlar ayrı
/// havuzdadır (SparkPool, kParticlePool).
abstract class RingSlots {
  final int capacity;
  final Float32List age;
  final Float32List duration;
  int _next = 0;

  RingSlots(this.capacity)
      : age = Float32List(capacity),
        duration = Float32List(capacity);

  bool isAlive(int i) => age[i] < duration[i];

  int get liveCount {
    var n = 0;
    for (var i = 0; i < capacity; i++) {
      if (isAlive(i)) n++;
    }
    return n;
  }

  /// İlerleme u = yaş / süre ∈ [0, 1).
  double progress(int i) => age[i] / duration[i];

  int _take(double seconds) {
    final i = _next;
    _next = (_next + 1) % capacity;
    age[i] = 0;
    duration[i] = seconds;
    return i;
  }

  void update(double dt) {
    if (!(dt > 0)) return;
    for (var i = 0; i < capacity; i++) {
      if (isAlive(i)) age[i] += dt;
    }
  }

  void clear() {
    duration.fillRange(0, capacity, 0);
    age.fillRange(0, capacity, 0);
    _next = 0;
  }
}

/// Yok olma (madeni para dönüşü) animasyonu, PRD 7.2.1.
class BreakPool extends RingSlots {
  final Float32List x;
  final Float32List y;

  /// Yatay sürüklenme yönü (±1), görsel rastgelelikle seçilir.
  final Float32List dir;
  final Uint32List color;

  BreakPool(super.capacity)
      : x = Float32List(capacity),
        y = Float32List(capacity),
        dir = Float32List(capacity),
        color = Uint32List(capacity);

  void spawn(double x, double y, double dir, int color) {
    final i = _take(kBreakAnimSec);
    this.x[i] = x;
    this.y[i] = y;
    this.dir[i] = dir;
    this.color[i] = color;
  }

  /// Ölçek Y = |cos(1.5·π·u)|.
  static double scaleY(double u) => math.cos(kBreakFlipTurns * math.pi * u).abs();

  /// Ölçek X = 1 + 0.1·sin(π·u).
  static double scaleX(double u) => 1 + kBreakWobbleX * math.sin(math.pi * u);

  /// Dönme = −0.6·u rad.
  static double rotation(double u) => kBreakRotation * u;

  /// Yer değiştirme: yatay ±35 gu/sn, aşağı ½·g·t².
  static double offsetX(double t, double dir) => kBreakDriftSpeed * t * dir;
  static double offsetY(double t) => kBreakGravity * t * t / 2;

  /// u < 0.5 iken 1, sonra 0'a doğrusal.
  static double opacity(double u) =>
      u < kBreakFadeStart ? 1 : ((1 - u) / (1 - kBreakFadeStart)).clamp(0.0, 1.0);
}

/// Halka/yıldız toplama ve oyun sonu şok halkası.
enum PopKind { ring, star, shock }

class PopPool extends RingSlots {
  final Float32List x;
  final Float32List y;
  final Uint8List kind;

  PopPool(super.capacity)
      : x = Float32List(capacity),
        y = Float32List(capacity),
        kind = Uint8List(capacity);

  void spawn(double x, double y, PopKind kind) {
    final i = _take(kind == PopKind.shock ? kShockSec : kPopSec);
    this.x[i] = x;
    this.y[i] = y;
    this.kind[i] = kind.index;
  }

  PopKind kindOf(int i) => PopKind.values[kind[i]];
}

/// Yıldız "+3" yazısı: yukarı süzülüp solar.
class FloatTextPool extends RingSlots {
  final Float32List x;
  final Float32List y;
  final Int32List value;

  FloatTextPool(super.capacity)
      : x = Float32List(capacity),
        y = Float32List(capacity),
        value = Int32List(capacity);

  void spawn(double x, double y, int value) {
    final i = _take(kFloatTextSec);
    this.x[i] = x;
    this.y[i] = y;
    this.value[i] = value;
  }
}

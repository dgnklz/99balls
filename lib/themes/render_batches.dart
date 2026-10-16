import 'dart:typed_data';

import '../core/config/game_config.dart';
import '../game_core/constants.dart';

/// Toplu çizim için önceden ayrılmış diziler (karede tahsis yok). Bileşenler
/// her karede [clear] edip doldurur, çizici tek çağrıda çizebilir
/// (bkz. ThemeRenderer.paintBalls / paintSparks / paintTargets).

/// Atılan toplar: merkezler (gu).
class BallBatch {
  /// Uçan toplar + fırlatma noktasındaki top.
  static const int capacity = kMaxBalls + 1;

  final Float32List x = Float32List(capacity);
  final Float32List y = Float32List(capacity);
  int length = 0;

  void clear() => length = 0;

  void add(double bx, double by) {
    if (length >= capacity) return;
    x[length] = bx;
    y[length] = by;
    length++;
  }
}

/// Kıvılcımlar: konum, ilk hız yönü, boyut ve solmuş renk (ARGB).
class SparkBatch {
  static const int capacity = kParticlePool;

  final Float32List x = Float32List(capacity);
  final Float32List y = Float32List(capacity);
  final Float32List vx = Float32List(capacity);
  final Float32List vy = Float32List(capacity);
  final Float32List size = Float32List(capacity);
  final Uint32List color = Uint32List(capacity);
  int length = 0;

  void clear() => length = 0;

  void add(double sx, double sy, double svx, double svy, double ssize, int argb) {
    if (length >= capacity) return;
    final i = length++;
    x[i] = sx;
    y[i] = sy;
    vx[i] = svx;
    vy[i] = svy;
    size[i] = ssize;
    color[i] = argb;
  }
}

/// Sayılı hedefler: merkez, HP, vuruş nabzı ölçeği ve isteğe bağlı dolgu
/// (ARGB; 0 = HP rengi).
class TargetBatch {
  static const int capacity = kCols * kBoardRows;

  final Float32List x = Float32List(capacity);
  final Float32List y = Float32List(capacity);
  final Int32List hp = Int32List(capacity);
  final Float32List scale = Float32List(capacity);
  final Uint32List fill = Uint32List(capacity);
  int length = 0;

  void clear() => length = 0;

  void add(double tx, double ty, int thp, {double tscale = 1, int tfill = 0}) {
    if (length >= capacity) return;
    final i = length++;
    x[i] = tx;
    y[i] = ty;
    hp[i] = thp;
    scale[i] = tscale;
    fill[i] = tfill;
  }
}

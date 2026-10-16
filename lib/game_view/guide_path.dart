import 'dart:math' show sqrt;
import 'dart:typed_data';

import '../core/config/game_config.dart';
import '../game_core/constants.dart';
import '../game_core/engine/collisions.dart';
import '../game_core/model/board.dart';
import '../game_core/model/cell.dart';

/// Nişan çizgisinin izlediği yol (PRD 5.2).
///
/// Fırlatma noktasından başlar; duvar, tavan ve sayılı toplardan yansır,
/// halka ve yıldızları yok sayar, zeminde ya da [kGuideLength]'te biter.
/// Temas zamanları game_core'un çarpışma fonksiyonlarıyla, aynı öncelik
/// sırasıyla (hedef (satır, sütun), sol, sağ, tavan, zemin) hesaplanır.
/// Hız birim vektördür, dolayısıyla "zaman" = yol uzunluğu.
class GuidePath {
  final Float64List _points = Float64List((kGuideMaxSegments + 1) * 2);
  int _pointCount = 0;
  double _length = 0;
  bool _endsOnFloor = false;

  int get pointCount => _pointCount;
  double xAt(int i) => _points[i * 2];
  double yAt(int i) => _points[i * 2 + 1];

  /// Çizilen toplam uzunluk.
  double get length => _length;

  /// Yol zemine değerek mi bitti.
  bool get endsOnFloor => _endsOnFloor;

  /// Yolu yeniden hesaplar. Tahta değiştirilmez.
  void compute(Board board, double startX, int vx, int vy, {double maxLength = kGuideLength}) {
    final norm = sqrt(vx.toDouble() * vx + vy.toDouble() * vy);
    var dx = vx / norm;
    var dy = vy / norm;
    var x = startX;
    var y = kLaunchY;
    var remaining = maxLength;
    _pointCount = 0;
    _length = 0;
    _endsOnFloor = false;
    _addPoint(x, y);

    // Açık sayaçlı döngü: her turda en fazla bir segment eklenir ve tur sayısı
    // kGuideMaxSegments ile sınırlıdır (sonlanma _addPoint'e bağlı değildir).
    for (var segment = 0; segment < kGuideMaxSegments && remaining > 0; segment++) {
      var best = kNoHit;
      var contact = _Contact.none;
      var hitRow = -1;
      var hitCol = -1;

      for (var row = 0; row < kBoardRows; row++) {
        final cy = Board.centerY(row);
        for (var col = 0; col < kCols; col++) {
          if (board.cellAt(row, col) is! TargetCell) continue;
          final t = circleToi(x, y, dx, dy, Board.centerX(col), cy, kHitDistance);
          if (t < best) {
            best = t;
            contact = _Contact.target;
            hitRow = row;
            hitCol = col;
          }
        }
      }
      var t = lowerBoundToi(x, dx, kBallMinX);
      if (t < best) {
        best = t;
        contact = _Contact.left;
      }
      t = upperBoundToi(x, dx, kBallMaxX);
      if (t < best) {
        best = t;
        contact = _Contact.right;
      }
      t = lowerBoundToi(y, dy, kBallMinY);
      if (t < best) {
        best = t;
        contact = _Contact.ceiling;
      }
      t = upperBoundToi(y, dy, kLaunchY);
      if (t < best) {
        best = t;
        contact = _Contact.floor;
      }

      if (best >= remaining) {
        x += dx * remaining;
        y += dy * remaining;
        _length += remaining;
        _addPoint(x, y);
        return;
      }

      x += dx * best;
      y += dy * best;
      _length += best;
      remaining -= best;

      switch (contact) {
        case _Contact.target:
          // Simulation ile aynı formül: n = (top − hedef)/|…|, v' = v − 2(v·n)n.
          var nx = x - Board.centerX(hitCol);
          var ny = y - Board.centerY(hitRow);
          final len = sqrt(nx * nx + ny * ny);
          if (len == 0) {
            dx = -dx;
            dy = -dy;
          } else {
            nx /= len;
            ny /= len;
            final dot = dx * nx + dy * ny;
            final rx = dx - (dot + dot) * nx;
            final ry = dy - (dot + dot) * ny;
            final rLen = sqrt(rx * rx + ry * ry);
            dx = rx / rLen;
            dy = ry / rLen;
          }
        case _Contact.left:
          x = kBallMinX;
          dx = -dx;
        case _Contact.right:
          x = kBallMaxX;
          dx = -dx;
        case _Contact.ceiling:
          y = kBallMinY;
          dy = -dy;
        case _Contact.floor:
          _endsOnFloor = true;
          _addPoint(x, y);
          return;
        case _Contact.none:
          return;
      }
      _addPoint(x, y);
    }
  }

  /// Yol üzerinde başlangıçtan [distance] uzaklıktaki nokta.
  (double, double) pointAt(double distance) {
    var walked = 0.0;
    for (var i = 1; i < _pointCount; i++) {
      final ax = xAt(i - 1);
      final ay = yAt(i - 1);
      final segX = xAt(i) - ax;
      final segY = yAt(i) - ay;
      final segLen = sqrt(segX * segX + segY * segY);
      if (walked + segLen >= distance && segLen > 0) {
        final f = (distance - walked) / segLen;
        return (ax + segX * f, ay + segY * f);
      }
      walked += segLen;
    }
    return (xAt(_pointCount - 1), yAt(_pointCount - 1));
  }

  void _addPoint(double x, double y) {
    if (_pointCount > kGuideMaxSegments) return;
    _points[_pointCount * 2] = x;
    _points[_pointCount * 2 + 1] = y;
    _pointCount++;
  }
}

enum _Contact { none, target, left, right, ceiling, floor }

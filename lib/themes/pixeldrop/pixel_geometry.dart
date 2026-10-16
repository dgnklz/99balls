import 'dart:math' as math;
import 'dart:ui';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';

/// Pixel Drop'un piksel şekilleri: hücre listeleri (orijin merkezli, gu).
/// Çizici bunları bir kez Path'e çevirir; testler doğrudan hücreleri ölçer.
///
/// Izgara çizgileri orijinden geçer: hücreler [i·cell, (i+1)·cell] aralığıdır.
abstract final class PixelGeometry {
  static const double _eps = 1e-9;

  /// 3×5 rakam glifleri; her satır 3 bit (soldan sağa, en anlamlı bit solda).
  static const List<List<int>> digitMasks = [
    [7, 5, 5, 5, 7], // 0
    [2, 6, 2, 2, 7], // 1
    [7, 1, 7, 4, 7], // 2
    [7, 1, 3, 1, 7], // 3
    [5, 5, 7, 1, 1], // 4
    [7, 4, 7, 1, 7], // 5
    [7, 4, 7, 5, 7], // 6
    [7, 1, 2, 2, 2], // 7
    [7, 5, 7, 5, 7], // 8
    [7, 5, 7, 1, 7], // 9
  ];

  /// Tamamı [radius] dairesinin içinde kalan hücreler (dört köşesi de içeride).
  static List<Rect> discCells(double radius, {double cell = kPixelCell}) {
    final n = (radius / cell).ceil();
    return [
      for (var j = -n; j < n; j++)
        for (var i = -n; i < n; i++)
          if (_cornersWithin(i * cell, j * cell, cell, radius))
            Rect.fromLTWH(i * cell, j * cell, cell, cell),
    ];
  }

  /// Dış yarıçapı [outer] olan, [thickness] hücre kalınlığında halka: tamamı
  /// [outer] içinde ve merkezi en az outer − thickness·cell uzakta olan hücreler.
  static List<Rect> annulusCells(double outer, int thickness, {double cell = kPixelCell}) {
    final inner = outer - thickness * cell;
    return [
      for (final r in discCells(outer, cell: cell))
        if (_length(r.center) >= inner) r,
    ];
  }

  /// Merkezi [polygon] içinde kalan hücreler (tek-çift kuralı).
  static List<Rect> polygonCells(List<Offset> polygon, {double cell = kPixelCell}) {
    var extent = 0.0;
    for (final p in polygon) {
      extent = math.max(extent, math.max(p.dx.abs(), p.dy.abs()));
    }
    final n = (extent / cell).ceil();
    return [
      for (var j = -n; j < n; j++)
        for (var i = -n; i < n; i++)
          if (_contains(polygon, Offset((i + 0.5) * cell, (j + 0.5) * cell)))
            Rect.fromLTWH(i * cell, j * cell, cell, cell),
    ];
  }

  /// Ortak yıldızla aynı ölçüde [kStarPoints] köşeli yıldızın köşeleri
  /// (BaseThemeRenderer.buildStar ile aynı formül).
  static List<Offset> starPolygon() {
    const outer = kTargetRadius * kStarSizeRatio;
    const inner = outer * kStarInnerRatio;
    return [
      for (var i = 0; i < kStarPoints * 2; i++)
        Offset(
          (i.isEven ? outer : inner) * math.cos(-math.pi / 2 + i * math.pi / kStarPoints),
          (i.isEven ? outer : inner) * math.sin(-math.pi / 2 + i * math.pi / kStarPoints),
        ),
    ];
  }

  /// Şeklin kenar hücreleri: dört komşusundan en az biri şekilde olmayanlar.
  static List<Rect> edgeCells(List<Rect> cells, {double cell = kPixelCell}) {
    final keys = {for (final r in cells) _key(r, cell)};
    return [
      for (final r in cells)
        if (!_hasAllNeighbours(keys, _key(r, cell))) r,
    ];
  }

  /// Şeklin iç hücreleri (kenar hücreleri hariç).
  static List<Rect> interiorCells(List<Rect> cells, {double cell = kPixelCell}) {
    final keys = {for (final r in cells) _key(r, cell)};
    return [
      for (final r in cells)
        if (_hasAllNeighbours(keys, _key(r, cell))) r,
    ];
  }

  /// İç hücrelerin en dıştaki halkasından, merkez açısı [fromDeg]–[toDeg]
  /// aralığında olanlar (ekran koordinatı: y aşağı, 225° = sol üst).
  static List<Rect> arcCells(List<Rect> cells, double fromDeg, double toDeg,
      {double cell = kPixelCell}) {
    final interior = interiorCells(cells, cell: cell);
    return [
      for (final r in edgeCells(interior, cell: cell))
        if (_angleIn(r.center, fromDeg, toDeg)) r,
    ];
  }

  /// [value]'nun rakam pikselleri, orijin (hedef merkezi) merkezli. Her
  /// glif satırındaki bitişik pikseller tek dikdörtgende birleşir.
  static List<Rect> numberPixels(int value) {
    final text = value.abs().toString();
    final threeDigits = text.length >= 3;
    final px = threeDigits ? kPixelDigitPx3 : kPixelDigitPx;
    final gap = threeDigits ? kPixelDigitGap3 : kPixelDigitGap;
    final glyphW = kPixelGlyphCols * px;
    final width = text.length * glyphW + (text.length - 1) * gap;
    final left = -width / 2;
    final top = -kPixelGlyphRows * px / 2;
    final rects = <Rect>[];
    for (var d = 0; d < text.length; d++) {
      final mask = digitMasks[text.codeUnitAt(d) - 0x30];
      final x0 = left + d * (glyphW + gap);
      for (var row = 0; row < kPixelGlyphRows; row++) {
        final bits = mask[row];
        var col = 0;
        while (col < kPixelGlyphCols) {
          if (!_bit(bits, col)) {
            col++;
            continue;
          }
          final start = col;
          while (col < kPixelGlyphCols && _bit(bits, col)) {
            col++;
          }
          rects.add(Rect.fromLTWH(x0 + start * px, top + row * px, (col - start) * px, px));
        }
      }
    }
    return rects;
  }

  /// Rakam pikselinin kenarı (gu): glif kalınlığı.
  static double digitStroke(int value) =>
      value.abs() >= 100 ? kPixelDigitPx3 : kPixelDigitPx;

  /// Hücreleri tek Path'te birleştirir. Aynı satırdaki bitişik hücreler önce
  /// tek dikdörtgene katılır ([mergeRows]): Path'teki parça sayısı düşer, GPU'da
  /// üçgenleme maliyeti hücre sayısıyla değil satır parçasıyla ölçeklenir
  /// (hedef silüeti 440 hücre → 24 parça).
  static Path pathOf(List<Rect> rects) {
    final path = Path();
    for (final r in mergeRows(rects)) {
      path.addRect(r);
    }
    return path;
  }

  /// Aynı üst kenar ve yükseklikteki, yan yana değen dikdörtgenleri birleştirir.
  /// Kapladığı alan değişmez.
  static List<Rect> mergeRows(List<Rect> rects) {
    final sorted = [...rects]..sort((a, b) {
        final byTop = a.top.compareTo(b.top);
        return byTop != 0 ? byTop : a.left.compareTo(b.left);
      });
    final merged = <Rect>[];
    for (final r in sorted) {
      if (merged.isNotEmpty) {
        final last = merged.last;
        if ((last.top - r.top).abs() < _eps &&
            (last.bottom - r.bottom).abs() < _eps &&
            (last.right - r.left).abs() < _eps) {
          merged[merged.length - 1] = Rect.fromLTRB(last.left, last.top, r.right, last.bottom);
          continue;
        }
      }
      merged.add(r);
    }
    return merged;
  }

  /// Hücrelerin alanı (gu²).
  static double area(List<Rect> rects) =>
      rects.fold(0.0, (sum, r) => sum + r.width * r.height);

  static bool _bit(int bits, int col) => (bits >> (kPixelGlyphCols - 1 - col)) & 1 == 1;

  static bool _cornersWithin(double x, double y, double cell, double radius) {
    final r2 = radius * radius + _eps;
    for (final (cx, cy) in [(x, y), (x + cell, y), (x, y + cell), (x + cell, y + cell)]) {
      if (cx * cx + cy * cy > r2) return false;
    }
    return true;
  }

  static double _length(Offset o) => math.sqrt(o.dx * o.dx + o.dy * o.dy);

  static (int, int) _key(Rect r, double cell) =>
      ((r.left / cell).round(), (r.top / cell).round());

  static bool _hasAllNeighbours(Set<(int, int)> keys, (int, int) k) =>
      keys.contains((k.$1 + 1, k.$2)) &&
      keys.contains((k.$1 - 1, k.$2)) &&
      keys.contains((k.$1, k.$2 + 1)) &&
      keys.contains((k.$1, k.$2 - 1));

  static bool _angleIn(Offset p, double fromDeg, double toDeg) {
    var deg = math.atan2(p.dy, p.dx) * 180 / math.pi;
    if (deg < 0) deg += 360;
    return deg >= fromDeg && deg <= toDeg;
  }

  static bool _contains(List<Offset> polygon, Offset p) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }
}

import 'package:flutter/painting.dart';

/// Sayıların önbellekli metin çizimi: her değer bir kez yerleştirilir (layout),
/// sonraki karelerde yeniden kullanılır.
class NumberTextCache {
  final TextStyle _style;
  final Map<int, TextPainter> _cache = {};

  NumberTextCache(this._style);

  /// [value]'yu (cx, cy) merkezli çizer.
  void paintCentered(Canvas canvas, int value, double cx, double cy) {
    final painter = _cache.putIfAbsent(
      value,
      () => TextPainter(
        text: TextSpan(text: value.toString(), style: _style),
        textDirection: TextDirection.ltr,
      )..layout(),
    );
    painter.paint(canvas, Offset(cx - painter.width / 2, cy - painter.height / 2));
  }

  void dispose() {
    for (final painter in _cache.values) {
      painter.dispose();
    }
    _cache.clear();
  }
}

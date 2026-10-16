import 'package:flutter/painting.dart';

/// Sayı ve kısa metinlerin önbellekli çizimi: her değer bir kez yerleştirilir
/// (layout), sonraki karelerde yeniden kullanılır.
class TextCache {
  final TextStyle _style;
  final Map<Object, TextPainter> _cache = {};

  TextCache(this._style);

  TextPainter _painter(Object key, String text) => _cache.putIfAbsent(
        key,
        () => TextPainter(
          text: TextSpan(text: text, style: _style),
          textDirection: TextDirection.ltr,
        )..layout(),
      );

  /// [value]'yu (cx, cy) merkezli çizer.
  void paintNumber(Canvas canvas, int value, double cx, double cy) =>
      _paintCentered(canvas, _painter(value, value.toString()), cx, cy);

  /// [text]'i (cx, cy) merkezli çizer.
  void paintText(Canvas canvas, String text, double cx, double cy) =>
      _paintCentered(canvas, _painter(text, text), cx, cy);

  /// Önbellekteki metnin boyutu (saydamlık katmanı sınırı için).
  Size sizeOf(String text) => _painter(text, text).size;

  void _paintCentered(Canvas canvas, TextPainter p, double cx, double cy) =>
      p.paint(canvas, Offset(cx - p.width / 2, cy - p.height / 2));

  void dispose() {
    for (final painter in _cache.values) {
      painter.dispose();
    }
    _cache.clear();
  }
}

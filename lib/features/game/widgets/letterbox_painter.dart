import 'package:flutter/widgets.dart';

import '../../../app/canvas_fit.dart';
import '../../../themes/game_theme.dart';

/// Letterbox degradesinin önbelleği: Shader yalnızca ekran boyutu ya da
/// palet değişince bir kez üretilir (zayıf cihazlarda karede nesne üretme).
class LetterboxShaderCache {
  Size? _size;
  ThemePalette? _palette;
  final Paint gradient = Paint();
  final Paint top = Paint();
  final Paint bottom = Paint();

  void ensure(Size size, ThemePalette palette) {
    if (_size == size && identical(_palette, palette)) return;
    _size = size;
    _palette = palette;
    gradient.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [palette.bgTop, palette.bgBottom],
    ).createShader(Offset.zero & size);
    top.color = palette.hudBar;
    bottom.color = palette.floorBar;
  }
}

/// Tuval dışındaki alanı doldurur (PRD 3.1): üst boşluk HUD rengi, alt boşluk
/// zemin rengi, yanlar arka plan gradyanı. Siyah bant oluşmaz.
class LetterboxPainter extends CustomPainter {
  final CanvasFit fit;
  final ThemePalette palette;
  final LetterboxShaderCache cache;

  LetterboxPainter(this.fit, this.palette, this.cache);

  @override
  void paint(Canvas canvas, Size size) {
    cache.ensure(size, palette);
    canvas
      ..drawRect(Offset.zero & size, cache.gradient)
      ..drawRect(fit.topBand, cache.top)
      ..drawRect(fit.bottomBand, cache.bottom);
  }

  @override
  bool shouldRepaint(LetterboxPainter oldDelegate) =>
      oldDelegate.fit.canvasRect != fit.canvasRect ||
      oldDelegate.fit.screenSize != fit.screenSize ||
      !identical(oldDelegate.palette, palette);
}

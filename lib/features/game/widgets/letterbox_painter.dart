import 'package:flutter/widgets.dart';

import '../../../app/canvas_fit.dart';
import '../../../core/theme/palette.dart';

/// Tuval dışındaki alanı doldurur (PRD 3.1): üst boşluk HUD rengi, alt boşluk
/// zemin rengi, yanlar arka plan gradyanı. Siyah bant oluşmaz.
class LetterboxPainter extends CustomPainter {
  final CanvasFit fit;

  LetterboxPainter(this.fit);

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    canvas
      ..drawRect(
        full,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.bgGradientTop, Palette.bgGradientBottom],
          ).createShader(full),
      )
      ..drawRect(fit.topBand, Paint()..color = Palette.hudBar)
      ..drawRect(fit.bottomBand, Paint()..color = Palette.floorBar);
  }

  @override
  bool shouldRepaint(LetterboxPainter oldDelegate) =>
      oldDelegate.fit.canvasRect != fit.canvasRect ||
      oldDelegate.fit.screenSize != fit.screenSize;
}

import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/theme/palette.dart';
import '../../game_core/constants.dart';

/// Tuval arka planı: dikey gradyan (PRD 4.5.1, katman 1).
class BackgroundComponent extends Component {
  static const Rect _rect = Rect.fromLTWH(0, 0, kVirtualW, kVirtualH);

  final Paint _paint = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, kVirtualH),
      const [Palette.bgGradientTop, Palette.bgGradientBottom],
    );

  @override
  void render(Canvas canvas) => canvas.drawRect(_rect, _paint);
}

import 'dart:math' show min, sqrt;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/palette.dart';
import '../game_view.dart';

/// Kesikli nişan çizgisi (PRD 5.2, katman 6): kalınlık 3, çizgi 12, boşluk
/// 12.6, opaklık 0.9; son 40 gu içinde saydamlaşır. Yol [BallGame.guide]'dan
/// okunur; burada yalnızca çizilir.
class GuideComponent extends Component with HasGameReference<BallGame> {
  static const double _period = kGuideDash + kGuideGap;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kGuideStroke;

  @override
  void render(Canvas canvas) {
    if (!game.guideVisible) return;
    final guide = game.guide;
    final total = guide.length;
    var walked = 0.0;

    for (var i = 1; i < guide.pointCount; i++) {
      final ax = guide.xAt(i - 1);
      final ay = guide.yAt(i - 1);
      final segX = guide.xAt(i) - ax;
      final segY = guide.yAt(i) - ay;
      final segLen = sqrt(segX * segX + segY * segY);
      if (segLen == 0) continue;
      final ux = segX / segLen;
      final uy = segY / segLen;

      var s = 0.0;
      while (s < segLen) {
        final phase = (walked + s) % _period;
        if (phase < kGuideDash) {
          final len = min(kGuideDash - phase, segLen - s);
          final mid = walked + s + len / 2;
          final fade = min(1.0, (total - mid) / kGuideFadeLength);
          if (fade > 0) {
            _paint.color = Palette.accent.withValues(alpha: kGuideOpacity * fade);
            canvas.drawLine(
              Offset(ax + ux * s, ay + uy * s),
              Offset(ax + ux * (s + len), ay + uy * (s + len)),
              _paint,
            );
          }
          s += len;
        } else {
          s += min(_period - phase, segLen - s);
        }
      }
      walked += segLen;
    }
  }
}

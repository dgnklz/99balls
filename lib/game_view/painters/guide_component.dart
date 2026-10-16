import 'dart:math' show min;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../dash_walker.dart';
import '../game_view.dart';

/// Kesikli nişan çizgisi (PRD 5.2, katman 6): kalınlık 3, çizgi 12, boşluk
/// 12.6, opaklık 0.9; son 40 gu içinde saydamlaşır. Yol [BallGame.guide]'dan,
/// parçalar [walkDashes]'ten gelir; burada yalnızca çizilir.
class GuideComponent extends Component with HasGameReference<BallGame> {
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kGuideStroke;

  /// Ziyaretçi bir kez oluşturulur; çizim sırasında tahsis yapılmaz.
  late final DashVisitor _visitor = _drawDash;
  late final double Function(int) _xAt = game.guide.xAt;
  late final double Function(int) _yAt = game.guide.yAt;
  Canvas? _canvas;
  double _total = 0;

  @override
  void render(Canvas canvas) {
    if (!game.guideVisible) return;
    final guide = game.guide;
    _canvas = canvas;
    _total = guide.length;
    walkDashes(pointCount: guide.pointCount, xAt: _xAt, yAt: _yAt, onDash: _visitor);
    _canvas = null;
  }

  void _drawDash(double x0, double y0, double x1, double y1, double from, double to) {
    final mid = (from + to) / 2;
    final fade = min(1.0, (_total - mid) / kGuideFadeLength);
    if (fade <= 0) return;
    _paint.color = game.theme.palette.guide.withValues(alpha: kGuideOpacity * fade);
    _canvas!.drawLine(Offset(x0, y0), Offset(x1, y1), _paint);
  }
}

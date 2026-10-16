import 'dart:ui';

import 'package:flame/components.dart';

import '../game_view.dart';

/// Tuval arka planı (PRD 4.5.1, katman 1); çizim temanın çizicisinden gelir.
class BackgroundComponent extends Component with HasGameReference<BallGame> {
  @override
  void render(Canvas canvas) => game.renderer.paintBackground(canvas);
}

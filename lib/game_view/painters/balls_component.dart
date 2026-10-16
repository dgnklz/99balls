import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/palette.dart';
import '../../game_core/constants.dart';
import '../../game_core/model/ball.dart';
import '../../game_core/rules/round_state_machine.dart';
import '../game_view.dart';

/// Atılan topları `session.simulation.balls`'tan doğrudan çizer (PRD 4.5.1,
/// katman 5). Havadaki toplar son adımdan bu yana geçen süre kadar ileri
/// kestirilir (x + vx·alpha), böylece kare hızı adım hızından farklı olsa da
/// hareket akıcı görünür.
class BallsComponent extends Component with HasGameReference<BallGame> {
  static const double _drawRadius = kBallRadius - kBallStroke / 2;

  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kBallStroke
    ..color = Palette.accent;

  @override
  void render(Canvas canvas) {
    final session = game.session;
    final sim = session.simulation;
    final launchX = session.launchX;

    switch (session.phase) {
      case GamePhase.ready:
      case GamePhase.advancing:
      case GamePhase.gameOver:
        _draw(canvas, launchX, kLaunchY);
      case GamePhase.firing:
      case GamePhase.flying:
        if (session.counterDisplay > 0) _draw(canvas, launchX, kLaunchY);
        final alpha = game.alpha;
        for (var i = 0; i < sim.launchedCount; i++) {
          final ball = sim.balls[i];
          switch (ball.state) {
            case BallState.flying:
              _draw(
                canvas,
                _clamp(ball.x + ball.vx * alpha, kBallMinX, kBallMaxX),
                _clamp(ball.y + ball.vy * alpha, kBallMinY, kLaunchY),
              );
            case BallState.landed:
              _draw(canvas, ball.x, kLaunchY);
            case BallState.idle:
              break;
          }
        }
      case GamePhase.collecting:
        final t = Curves.easeInOut.transform(game.collectProgress);
        for (var i = 0; i < sim.launchedCount; i++) {
          final x = sim.balls[i].x;
          _draw(canvas, x + (launchX - x) * t, kLaunchY);
        }
    }
  }

  void _draw(Canvas canvas, double x, double y) =>
      canvas.drawCircle(Offset(x, y), _drawRadius, _paint);

  static double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
}

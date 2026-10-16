import 'dart:ui';

import 'package:flame/components.dart';

import '../../core/config/game_config.dart';
import '../../core/theme/palette.dart';
import '../../game_core/constants.dart';
import '../../game_core/model/ball.dart';
import '../../game_core/rules/round_state_machine.dart';
import '../game_view.dart';

/// Atılan topları `session.simulation.balls`'tan doğrudan çizer (PRD 4.5.1,
/// katman 5). Havadaki toplar son adımdan bu yana geçen süre kadar ileri
/// kestirilir (x + vx·alpha), böylece kare hızı adım hızından farklı olsa da
/// hareket akıcı görünür. İnen toplar [BallGame.merge] ile ilk inen topa kayar.
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
      case GamePhase.collecting:
        if (session.phase == GamePhase.firing && session.counterDisplay > 0) {
          _draw(canvas, launchX, kLaunchY);
        }
        final alpha = game.alpha;
        final merge = game.merge;
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
              // İnen top ilk inen topa kayar; birleşince çizilmez.
              if (merge.isVisible(i)) _draw(canvas, merge.xOf(i), kLaunchY);
            case BallState.idle:
              break;
          }
        }
    }
  }

  void _draw(Canvas canvas, double x, double y) =>
      canvas.drawCircle(Offset(x, y), _drawRadius, _paint);

  static double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
}

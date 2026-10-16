import 'dart:ui';

import 'package:flame/components.dart';

import '../game_view.dart';

/// HUD ve zemin çubuğu (PRD 4.1, 4.5; katman 8): canlı skor, top ikonu,
/// eldeki top sayısı, tehlike parlaması ve satır ilerleme süpürmesi.
/// Müzik ve duraklat ikonları M4/M5'te eklenecek.
class HudComponent extends Component with HasGameReference<BallGame> {
  @override
  void render(Canvas canvas) {
    final session = game.session;
    final effects = game.effects;
    game.renderer.paintHud(
      canvas,
      score: session.score,
      counter: session.counterDisplay,
      dangerGlow: effects.dangerGlow,
      sweep: effects.sweep,
      scoreScale: effects.scoreScale,
    );
  }
}

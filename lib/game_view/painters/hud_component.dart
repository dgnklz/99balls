import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../../core/config/game_config.dart';
import '../../core/theme/palette.dart';
import '../../game_core/constants.dart';
import '../game_view.dart';
import 'number_text_cache.dart';

/// HUD ve zemin çubuğu (PRD 4.1, 4.5; katman 8): canlı skor, top ikonu ve
/// eldeki top sayısı. Müzik ve duraklat ikonları M4/M5'te eklenecek.
class HudComponent extends Component with HasGameReference<BallGame> {
  static const Rect _hudRect = Rect.fromLTWH(0, 0, kVirtualW, kCeilingY);
  static const Rect _floorRect =
      Rect.fromLTWH(0, kFloorY, kVirtualW, kVirtualH - kFloorY);

  final Paint _hudPaint = Paint()..color = Palette.hudBar;
  final Paint _floorPaint = Paint()..color = Palette.floorBar;
  final Paint _iconPaint = Paint()..color = Palette.accent;
  final NumberTextCache _numbers = NumberTextCache(const TextStyle(
    color: Palette.textPrimary,
    fontSize: kHudFontSize,
    fontWeight: FontWeight.bold,
  ));

  @override
  void render(Canvas canvas) {
    final session = game.session;
    canvas
      ..drawRect(_hudRect, _hudPaint)
      ..drawRect(_floorRect, _floorPaint)
      ..drawCircle(
        const Offset(kHudBallIconX, kHudBallIconY),
        kHudBallIconDiameter / 2,
        _iconPaint,
      );
    _numbers
      ..paintCentered(canvas, session.score, kHudScoreX, kHudScoreY)
      ..paintCentered(canvas, session.counterDisplay, kHudCounterX, kHudCounterY);
  }

  @override
  void onRemove() {
    _numbers.dispose();
    super.onRemove();
  }
}

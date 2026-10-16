import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../game_core/constants.dart';
import '../../game_core/model/board.dart';
import '../../game_core/model/cell.dart';
import '../../game_core/model/pickup.dart';
import '../../game_core/rules/round_state_machine.dart';
import '../game_view.dart';

/// Tahtayı `session.board`'dan doğrudan çizer: önce halka/yıldız, sonra
/// sayılı toplar (PRD 4.5.1, katman 2–3). advancing sırasında satırlar
/// easeOutCubic ile kayar; yeni satır r = −1'den gelirken 0 → 1 belirir.
/// Şekil ve renkler temanın çizicisinden, vuruş nabzı efekt denetçisinden gelir.
class BoardComponent extends Component with HasGameReference<BallGame> {
  final Paint _layerPaint = Paint();

  @override
  void render(Canvas canvas) {
    final session = game.session;
    final board = session.board;
    final renderer = game.renderer;
    final effects = game.effects;
    final danger = game.theme.palette.danger;

    var offsetY = 0.0;
    var newRowOpacity = 1.0;
    if (session.phase == GamePhase.advancing) {
      final p = Curves.easeOutCubic.transform(game.advanceProgress);
      offsetY = -kPitch * (1 - p);
      newRowOpacity = p;
    }
    final blinkRow = game.gameOverBlinkOn ? kGameOverRow : -1;

    for (var row = 0; row < kBoardRows; row++) {
      final fading = row == 0 && newRowOpacity < 1;
      if (fading) {
        _layerPaint.color = Color.fromRGBO(0, 0, 0, newRowOpacity);
        canvas.saveLayer(null, _layerPaint);
      }
      final cy = Board.centerY(row) + offsetY;
      for (var col = 0; col < kCols; col++) {
        final cell = board.cellAt(row, col);
        if (cell is PickupCell) {
          final cx = Board.centerX(col);
          if (cell.kind == PickupKind.ring) {
            renderer.paintRing(canvas, cx, cy);
          } else {
            renderer.paintStar(canvas, cx, cy);
          }
        }
      }
      for (var col = 0; col < kCols; col++) {
        final cell = board.cellAt(row, col);
        if (cell is! TargetCell) continue;
        renderer.paintTarget(
          canvas,
          Board.centerX(col),
          cy,
          cell.hp,
          scale: effects.pulseScale(row, col),
          fill: row == blinkRow ? danger : null,
        );
      }
      if (fading) canvas.restore();
    }
  }
}

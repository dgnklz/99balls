import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../game_core/constants.dart';
import '../../game_core/model/board.dart';
import '../../game_core/model/cell.dart';
import '../../game_core/model/pickup.dart';
import '../../game_core/rules/round_state_machine.dart';
import '../../themes/render_batches.dart';
import '../game_view.dart';

/// Tahtayı `session.board`'dan doğrudan çizer: önce halka/yıldız, sonra
/// sayılı toplar (PRD 4.5.1, katman 2–3). advancing sırasında satırlar
/// easeOutCubic ile kayar; yeni satır r = −1'den gelirken 0 → 1 belirir.
/// Şekil ve renkler temanın çizicisinden, vuruş nabzı efekt denetçisinden gelir.
///
/// Hedefler bir [TargetBatch]'te toplanıp tek seferde çizilir (M3p): belirmekte
/// olan satır 0 kendi saydamlık katmanında, diğer satırlar tüm halka/yıldızlardan
/// sonra. Komşu satırlarda hedef ile halka çakışmadığından görünüm aynıdır.
class BoardComponent extends Component with HasGameReference<BallGame> {
  final Paint _layerPaint = Paint();
  final TargetBatch _targets = TargetBatch();

  @override
  void render(Canvas canvas) {
    final session = game.session;
    var offsetY = 0.0;
    var newRowOpacity = 1.0;
    if (session.phase == GamePhase.advancing) {
      final p = Curves.easeOutCubic.transform(game.advanceProgress);
      offsetY = -kPitch * (1 - p);
      newRowOpacity = p;
    }

    var firstRow = 0;
    if (newRowOpacity < 1) {
      _layerPaint.color = Color.fromRGBO(0, 0, 0, newRowOpacity);
      canvas.saveLayer(null, _layerPaint);
      _paintRows(canvas, 0, 1, offsetY);
      canvas.restore();
      firstRow = 1;
    }
    _paintRows(canvas, firstRow, kBoardRows, offsetY);
  }

  /// [from, to) satırlarının halka/yıldızlarını, ardından hedeflerini çizer.
  void _paintRows(Canvas canvas, int from, int to, double offsetY) {
    final board = game.session.board;
    final renderer = game.renderer;
    final effects = game.effects;
    final danger = game.theme.palette.danger.toARGB32();
    final blinkRow = game.gameOverBlinkOn ? kGameOverRow : -1;

    _targets.clear();
    for (var row = from; row < to; row++) {
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
        } else if (cell is TargetCell) {
          _targets.add(
            Board.centerX(col),
            cy,
            cell.hp,
            tscale: effects.pulseScale(row, col),
            tfill: row == blinkRow ? danger : 0,
          );
        }
      }
    }
    if (_targets.length > 0) renderer.paintTargets(canvas, _targets);
  }
}

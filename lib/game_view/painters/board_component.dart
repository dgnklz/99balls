import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;

import '../../core/config/game_config.dart';
import '../../core/theme/hp_colors.dart';
import '../../core/theme/palette.dart';
import '../../game_core/constants.dart';
import '../../game_core/model/board.dart';
import '../../game_core/model/cell.dart';
import '../../game_core/model/pickup.dart';
import '../../game_core/rules/round_state_machine.dart';
import '../game_view.dart';
import 'number_text_cache.dart';

/// Tahtayı `session.board`'dan doğrudan çizer: önce halka/yıldız, sonra
/// sayılı toplar (PRD 4.5.1, katman 2–3). advancing sırasında satırlar
/// easeOutCubic ile kayar; yeni satır r = −1'den gelirken 0 → 1 belirir.
class BoardComponent extends Component with HasGameReference<BallGame> {
  static const double _ringRadius = kPickupRadius - kPickupStroke / 2;

  final Paint _targetPaint = Paint();
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kPickupStroke;
  final Paint _ringGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = kPickupStroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, kPickupGlowBlur);
  final Paint _starPaint = Paint();
  final Paint _layerPaint = Paint();
  final Path _starPath = _buildStar();

  final NumberTextCache _hp2 = NumberTextCache(const TextStyle(
    color: Palette.textPrimary,
    fontSize: kTargetFontSize,
    fontWeight: FontWeight.bold,
  ));
  final NumberTextCache _hp3 = NumberTextCache(const TextStyle(
    color: Palette.textPrimary,
    fontSize: kTargetFontSize3Digits,
    fontWeight: FontWeight.bold,
  ));

  static Path _buildStar() {
    const outer = kTargetRadius * kStarSizeRatio;
    const inner = outer * kStarInnerRatio;
    const vertices = kStarPoints * 2;
    final path = Path();
    for (var i = 0; i < vertices; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / kStarPoints;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  @override
  void render(Canvas canvas) {
    final session = game.session;
    final board = session.board;

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
      _paintPickups(canvas, board, row, cy);
      _paintTargets(canvas, board, row, cy, danger: row == blinkRow);
      if (fading) canvas.restore();
    }
  }

  void _paintPickups(Canvas canvas, Board board, int row, double cy) {
    for (var col = 0; col < kCols; col++) {
      final cell = board.cellAt(row, col);
      if (cell is! PickupCell) continue;
      final cx = Board.centerX(col);
      switch (cell.kind) {
        case PickupKind.ring:
          _ringGlowPaint.color = Palette.pickupGlow;
          _ringPaint.color = Palette.pickupGlow;
          canvas.drawCircle(Offset(cx, cy), _ringRadius, _ringGlowPaint);
          canvas.drawCircle(Offset(cx, cy), _ringRadius, _ringPaint);
        case PickupKind.star:
          _starPaint.color = Palette.star;
          canvas
            ..save()
            ..translate(cx, cy)
            ..drawPath(_starPath, _starPaint)
            ..restore();
      }
    }
  }

  void _paintTargets(Canvas canvas, Board board, int row, double cy, {required bool danger}) {
    for (var col = 0; col < kCols; col++) {
      final cell = board.cellAt(row, col);
      if (cell is! TargetCell) continue;
      final cx = Board.centerX(col);
      _targetPaint.color = danger ? Palette.danger : HpColors.forHp(cell.hp);
      canvas.drawCircle(Offset(cx, cy), kTargetRadius, _targetPaint);
      (cell.hp >= kThreeDigitThreshold ? _hp3 : _hp2).paintCentered(canvas, cell.hp, cx, cy);
    }
  }

  @override
  void onRemove() {
    _hp2.dispose();
    _hp3.dispose();
    super.onRemove();
  }
}

import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD Bölüm 5.4, 5.5, 5.6.
const Shot _up = Shot(0, -100);

/// [phase]'e girene kadar ilerler; geçen adım sayısını döndürür.
int _stepUntilPhase(GameSession s, GamePhase phase, {int max = 20000}) {
  var n = 0;
  while (s.phase != phase) {
    s.step();
    n++;
    if (n > max) fail('phase $phase not reached; stuck in ${s.phase}');
  }
  return n;
}

void main() {
  test('step constants are derived from the presentation durations', () {
    expect(kCollectSteps, (kCollectSec * kStepsPerSec).round());
    expect(kAdvanceSteps, (kAdvanceSec * kStepsPerSec).ceil());
  });

  test('new game: ready, round 1, 1 ball, only row 0 filled, launch x 208', () {
    final s = GameSession(42);
    expect(s.phase, GamePhase.ready);
    expect(s.round, 1);
    expect(s.ballCount, 1);
    expect(s.pendingBalls, 0);
    expect(s.counterDisplay, 1);
    expect(s.score, 1);
    expect(s.launchX, kLaunchStartX);
    var row0 = 0;
    for (var col = 0; col < kCols; col++) {
      if (s.board.cellAt(0, col) is TargetCell) row0++;
      for (var row = 1; row < kBoardRows; row++) {
        expect(s.board.cellAt(row, col), isNull);
      }
    }
    expect(row0, inInclusiveRange(2, 5));
  });

  test('full round: ready → firing → flying → collecting → advancing → ready', () {
    final s = GameSession.forTest(board: Board(), initialBallCount: 3);
    expect(s.tryShoot(_up), isTrue);
    expect(s.phase, GamePhase.firing);
    expect(s.counterDisplay, 3);

    final counters = <int>[];
    while (s.phase == GamePhase.firing) {
      s.step();
      counters.add(s.counterDisplay);
    }
    expect(counters.toSet().toList(), [2, 1, 0]);
    expect(s.phase, GamePhase.flying);
    expect(s.counterDisplay, 0);

    _stepUntilPhase(s, GamePhase.collecting);
    expect(s.counterDisplay, 0);
    expect(_stepUntilPhase(s, GamePhase.advancing), kCollectSteps);
    expect(s.round, 2);
    expect(s.counterDisplay, 3);
    expect(_stepUntilPhase(s, GamePhase.ready), kAdvanceSteps);
    expect(s.counterDisplay, 3);
  });

  test('input is ignored outside ready and for invalid aims', () {
    final s = GameSession.forTest(board: Board());
    expect(s.tryShoot(const Shot(100, 0)), isFalse);
    expect(s.tryShoot(const Shot(0, 50)), isFalse);
    expect(s.phase, GamePhase.ready);
    expect(s.tryShoot(_up), isTrue);
    for (final phase in [GamePhase.flying, GamePhase.collecting, GamePhase.advancing]) {
      _stepUntilPhase(s, phase);
      expect(s.tryShoot(_up), isFalse, reason: '$phase');
    }
    expect(s.shots, hasLength(1));
  });

  test('rings go to pendingBalls and are added only when the round ends', () {
    final board = Board()..setCell(3, 3, const PickupCell(PickupKind.ring));
    final s = GameSession.forTest(
        board: board, initialLaunchX: Board.centerX(3));
    s.tryShoot(_up);
    _stepUntilPhase(s, GamePhase.collecting);
    expect(s.pendingBalls, 1);
    expect(s.ballCount, 1);
    _stepUntilPhase(s, GamePhase.advancing);
    expect(s.pendingBalls, 0);
    expect(s.ballCount, 2);
  });

  test('ball count is capped at 99', () {
    final board = Board()..setCell(3, 3, const PickupCell(PickupKind.ring));
    final s = GameSession.forTest(
        board: board, initialBallCount: kMaxBalls, initialLaunchX: Board.centerX(3));
    s.tryShoot(_up);
    _stepUntilPhase(s, GamePhase.collecting);
    expect(s.pendingBalls, 1);
    _stepUntilPhase(s, GamePhase.ready);
    expect(s.ballCount, kMaxBalls);
  });

  test('target reaching row 8 ends the game; score counts the new row', () {
    // Hedef 7. satırda, atış yolunun dışında (sütun 0, atış sütun 3'ten dik).
    final board = Board()..setCell(kPlayableRows - 1, 0, const TargetCell(99));
    final s = GameSession.forTest(
        board: board, initialRound: 34, initialLaunchX: Board.centerX(3));
    s.tryShoot(_up);
    _stepUntilPhase(s, GamePhase.gameOver);
    expect(s.board.cellAt(kGameOverRow, 0), const TargetCell(99));
    expect(s.round, 35);
    expect(s.score, 35);
    final over = s.drainEvents().whereType<GameOver>().single;
    expect(over.score, 35);
    s.step();
    expect(s.phase, GamePhase.gameOver);
  });

  test('ring or star reaching row 8 vanishes and the game goes on', () {
    final board = Board()
      ..setCell(kPlayableRows - 1, 0, const PickupCell(PickupKind.ring))
      ..setCell(kPlayableRows - 1, 6, const PickupCell(PickupKind.star));
    final s = GameSession.forTest(board: board, initialLaunchX: Board.centerX(3));
    s.tryShoot(_up);
    _stepUntilPhase(s, GamePhase.ready);
    expect(s.board.cellAt(kGameOverRow, 0), isNull);
    expect(s.board.cellAt(kGameOverRow, 6), isNull);
    expect(s.drainEvents().whereType<PickupExpired>().map((e) => e.kind),
        [PickupKind.ring, PickupKind.star]);
    expect(s.starsCollected, 0);
  });

  test('new row uses ballCount after this round\'s rings', () {
    final board = Board()..setCell(3, 3, const PickupCell(PickupKind.ring));
    final s = GameSession.forTest(
        board: board, initialBallCount: 4, initialLaunchX: Board.centerX(3));
    s.tryShoot(_up);
    _stepUntilPhase(s, GamePhase.advancing);
    // T = 5 → HP ∈ {5, 8 (7.5 çifte), 10}.
    for (var col = 0; col < kCols; col++) {
      final cell = s.board.cellAt(0, col);
      if (cell is TargetCell) expect(cell.hp, anyOf(5, 8, 10));
    }
  });
}

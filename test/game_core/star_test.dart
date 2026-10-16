import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/engine/rng.dart';
import 'package:balls_99/game_core/engine/simulation.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_core/rules/row_generator.dart';
import 'package:balls_99/game_core/rules/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_test_utils.dart';

/// PRD Bölüm 5.11 yıldız testleri (1)-(5).
void main() {
  const star = PickupCell(PickupKind.star);
  const t = 10;

  List<int?> starColumns(int seed, int rows) {
    final gen = RowGenerator(SplitMix64(seed));
    gen.initialRow();
    return [
      for (var i = 0; i < rows; i++)
        () {
          final idx = gen.nextRow(t).cells.indexOf(star);
          return idx < 0 ? null : idx;
        }(),
    ];
  }

  test('(1) same seed gives same star positions in two runs', () {
    final first = starColumns(31337, 200);
    expect(first.whereType<int>(), isNotEmpty);
    expect(starColumns(31337, 200), first);
  });

  test('(2) with chance 0, row from same RNG state matches starred row minus star', () {
    var starsSeen = 0;
    for (var seed = 0; seed < 2000; seed++) {
      final withStars = RowGenerator(SplitMix64(seed)).nextRow(t);
      final noStars = RowGenerator(SplitMix64(seed), starChancePct: 0).nextRow(t);

      expect(noStars.cells, isNot(contains(star)), reason: 'seed=$seed');
      expect(noStars.cells, withoutStars(withStars), reason: 'seed=$seed');
      if (withStars.cells.contains(star)) starsSeen++;
    }
    expect(starsSeen, greaterThan(0));
  });

  test('(3) star never shares a cell with a target or ring', () {
    // Şans 100 iken her satırda yıldız olur. Yıldız bir topun ya da halkanın
    // üzerine yazılsaydı, aynı RNG durumundan şans 0 ile üretilen satırdan farklı
    // olurdu: yıldızsız içerik aynı kalmalı ve yıldızın hücresi orada boş olmalı.
    for (var seed = 0; seed < 2000; seed++) {
      final always = RowGenerator(SplitMix64(seed), starChancePct: 100).nextRow(t);
      final never = RowGenerator(SplitMix64(seed), starChancePct: 0).nextRow(t);

      final starCol = always.cells.indexOf(star);
      expect(starCol, isNonNegative, reason: 'seed=$seed');
      expect(never.cells[starCol], isNull, reason: 'seed=$seed');
      expect(withoutStars(always), never.cells, reason: 'seed=$seed');
    }
  });

  test('(4) score formula: round 12 and 4 stars → 24', () {
    expect(scoreFor(12, 4), 24);
    expect(scoreFor(12, 4), 12 + kStarScore * 4);
  });

  test('(5) a star is counted once, even if several balls touch it', () {
    final board = Board()..setCell(3, 3, star);
    final session = GameSession.forTest(
        board: board, initialBallCount: 3, initialLaunchX: Board.centerX(3));
    session.tryShoot(const Shot(0, -100));
    while (session.phase != GamePhase.ready) {
      session.step();
    }
    final collected = session.drainEvents().whereType<PickupCollected>().toList();
    expect(collected.single.kind, PickupKind.star);
    expect(collected.single.ballIndex, 0);
    expect(session.starsCollected, 1);
    expect(session.score, session.round + kStarScore);

    // Sonraki turda aynı yıldız yeniden sayılmaz.
    session.tryShoot(const Shot(0, -100));
    while (session.phase != GamePhase.ready) {
      session.step();
    }
    expect(session.starsCollected, 1);
  });

  test('two balls on the same star in the same step: counted once', () {
    final board = Board()..setCell(3, 3, star);
    final events = <GameEvent>[];
    final sim = Simulation(board, events)..beginVolley();
    sim.launch(Board.centerX(3), kLaunchY, 0, -1);
    sim.launch(Board.centerX(3), kLaunchY, 0, -1);
    for (var i = 0; i < 150; i++) {
      sim.step();
    }
    expect(events.whereType<PickupCollected>().single.ballIndex, 0);
    expect(sim.takeCollected().stars, 1);
  });

  test('initial row never has a star', () {
    for (var seed = 0; seed < 1000; seed++) {
      final row = RowGenerator(SplitMix64(seed), starChancePct: 100).initialRow();
      expect(row.cells, isNot(contains(star)));
    }
  });
}

import 'package:balls_99/game_core/engine/rng.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_core/rules/row_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_script.dart';

/// PRD Bölüm 2.3 ve 14.1: aynı tohum + aynı girdi → her adımda aynı durum.
List<int> _hashes(int seed) {
  final hashes = <int>[];
  playScripted(seed, onStep: (s) => hashes.add(s.stateHash()));
  return hashes;
}

/// Çok toplu, çok çarpışmalı senaryo: 3 dolu satır ve 40 top.
List<int> _heavyHashes() {
  const seed = 99;
  const balls = 40;
  const filledRows = 3;
  final board = Board();
  final rows = RowGenerator(SplitMix64(seed));
  for (var i = 0; i < filledRows; i++) {
    board
      ..shiftDown()
      ..insertRow(rows.nextRow(balls));
  }
  final hashes = <int>[];
  playScripted(
    seed,
    start: GameSession.forTest(board: board, seed: seed, initialBallCount: balls),
    maxRounds: 12,
    onStep: (s) => hashes.add(s.stateHash()),
  );
  return hashes;
}

void main() {
  test('same seed and inputs give the same state hash at every step', () {
    final first = _hashes(20261016);
    final second = _hashes(20261016);
    expect(first.length, greaterThan(1000));
    expect(second.length, first.length);
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) fail('state diverged at step $i');
    }
  });

  test('many balls and collisions: same state hash at every step', () {
    final first = _heavyHashes();
    final second = _heavyHashes();
    expect(first.length, greaterThan(4000));
    expect(second.length, first.length);
    for (var i = 0; i < first.length; i++) {
      if (first[i] != second[i]) fail('state diverged at step $i');
    }
  });

  test('the scripted game runs several rounds and ends in gameOver', () {
    final session = playScripted(20261016);
    expect(session.phase, GamePhase.gameOver);
    expect(session.round, greaterThan(3));
  });

  test('a different seed diverges', () {
    final a = _hashes(1);
    final b = _hashes(2);
    expect(a.take(10).toList(), isNot(b.take(10).toList()));
  });
}

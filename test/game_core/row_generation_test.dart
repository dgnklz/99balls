import 'dart:convert';
import 'dart:io';

import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/rng.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/rules/hp_rules.dart';
import 'package:balls_99/game_core/rules/row_generator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_test_utils.dart';

/// Golden: sabit tohumla ilk 30 satır. 0. satır ilk tahta (T = 1),
/// i. satır `nextRow(i + 1)` (bkz. docs/ASSUMPTIONS.md).
/// Yeniden üretmek için: UPDATE_GOLDEN=1 flutter test test/game_core/row_generation_test.dart
const int _goldenSeed = 20261015;
const int _goldenRowCount = 30;
const String _goldenPath = 'test/game_core/golden/rows_seed_20261015.json';

List<Map<String, Object>> _generateGoldenRows() {
  final gen = RowGenerator(SplitMix64(_goldenSeed));
  return [
    {'t': kStartBalls, 'cells': encodeRow(gen.initialRow())},
    for (var i = 1; i < _goldenRowCount; i++)
      {'t': i + 1, 'cells': encodeRow(gen.nextRow(i + 1))},
  ];
}

List<String> _encodeRows(int seed, int count, int t) {
  final gen = RowGenerator(SplitMix64(seed));
  return [encodeRow(gen.initialRow()), for (var i = 1; i < count; i++) encodeRow(gen.nextRow(t))];
}

void main() {
  test('first $_goldenRowCount rows match golden file', () {
    final rows = _generateGoldenRows();
    final file = File(_goldenPath);
    if (Platform.environment['UPDATE_GOLDEN'] == '1') {
      const encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync('${encoder.convert({'seed': _goldenSeed, 'rows': rows})}\n');
    }
    expect(file.existsSync(), isTrue, reason: 'golden missing: $_goldenPath');
    final golden = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(golden['seed'], _goldenSeed);
    expect(golden['rows'], rows);
  });

  test('initial row: 2-5 targets with HP 1 or 2, no ring, no star', () {
    for (var seed = 0; seed < 1000; seed++) {
      final row = RowGenerator(SplitMix64(seed)).initialRow();
      final counts = countCells(row);
      expect(counts.targets, inInclusiveRange(2, 5));
      expect(counts.rings, 0);
      expect(counts.stars, 0);
      for (final cell in row.cells.whereType<TargetCell>()) {
        expect(cell.hp, anyOf(1, 2));
      }
    }
  });

  test('every HP is in {hpFor(T,2), hpFor(T,3), hpFor(T,4)}', () {
    final gen = RowGenerator(SplitMix64(7));
    for (var t = 1; t <= kMaxBalls; t++) {
      final allowed = {for (final m2 in kMultipliersM2) hpFor(t, m2)};
      for (var i = 0; i < 50; i++) {
        for (final cell in gen.nextRow(t).cells.whereType<TargetCell>()) {
          expect(allowed, contains(cell.hp), reason: 't=$t');
        }
      }
    }
  });

  test('distribution with T=10 over 10000 rows is within ±2 points', () {
    const t = 10;
    const rows = 10000;
    const tolerancePts = 2.0;
    final gen = RowGenerator(SplitMix64(123456789));

    final targetCountHist = {for (final k in kRowTargetCounts) k: 0};
    final m2ByHp = {for (final m2 in kMultipliersM2) hpFor(t, m2): m2};
    final m2Hist = {for (final m2 in kMultipliersM2) m2: 0};
    var ringRows = 0;
    var totalTargets = 0;

    for (var i = 0; i < rows; i++) {
      final row = gen.nextRow(t);
      expect(row.cells.length, kCols);
      final counts = countCells(row);
      expect(counts.targets + counts.rings + counts.stars, lessThanOrEqualTo(kCols));
      expect(counts.rings, lessThanOrEqualTo(1));
      expect(counts.stars, lessThanOrEqualTo(1));

      targetCountHist[counts.targets] = targetCountHist[counts.targets]! + 1;
      if (counts.rings == 1) ringRows++;
      for (final cell in row.cells.whereType<TargetCell>()) {
        final m2 = m2ByHp[cell.hp]!;
        m2Hist[m2] = m2Hist[m2]! + 1;
        totalTargets++;
      }
    }

    double pct(int n, int of) => 100.0 * n / of;
    for (var i = 0; i < kRowTargetCounts.length; i++) {
      final k = kRowTargetCounts[i];
      expect(pct(targetCountHist[k]!, rows),
          closeTo(kBallCountWeights[i].toDouble(), tolerancePts),
          reason: 'k=$k');
    }
    expect(pct(ringRows, rows), closeTo(kRingChancePct.toDouble(), tolerancePts));
    for (final m2 in kMultipliersM2) {
      expect(pct(m2Hist[m2]!, totalTargets),
          closeTo(100.0 / kMultipliersM2.length, tolerancePts),
          reason: 'm2=$m2');
    }
  });

  test('same seed produces identical 100 rows twice', () {
    expect(_encodeRows(555, 100, 10), _encodeRows(555, 100, 10));
  });

  test('different seeds produce different rows', () {
    expect(_encodeRows(1, 30, 10), isNot(_encodeRows(2, 30, 10)));
  });
}

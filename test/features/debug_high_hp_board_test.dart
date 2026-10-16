import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/prefs_service.dart';
import 'package:balls_99/features/game/debug_high_hp_board.dart';
import 'package:balls_99/features/game/game_screen.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Her HP durağının sınırları (PRD 7.1), üç haneliler ve 99.
const List<int> _requiredHp = [
  1, 3, 6, 7, 13, 17, 24, 26, 27, 32, 34, 36, 44, 48, 50, //
  99, 100, 111, 148, 188, 198,
];
const int _filledRows = 6;
const int _maxTargetsPerRow = 5;

List<int> _hps(Board board) => [
      for (var row = 0; row < kBoardRows; row++)
        for (var col = 0; col < kCols; col++)
          if (board.cellAt(row, col) case TargetCell(:final hp)) hp,
    ];

int _pickups(Board board, PickupKind kind) => [
      for (var row = 0; row < kBoardRows; row++)
        for (var col = 0; col < kCols; col++)
          if (board.cellAt(row, col) == PickupCell(kind)) 1,
    ].length;

void _expectDebugBoard(Board board) {
  for (var row = 0; row < kBoardRows; row++) {
    for (var col = 0; col < kCols; col++) {
      final expected = row < kDebugHighHpRows.length ? kDebugHighHpRows[row][col] : null;
      expect(board.cellAt(row, col), expected, reason: '($row, $col)');
    }
  }
}

Future<(BallGame, SharedPreferences)> _pumpScreen(
  WidgetTester tester,
  Map<String, Object> initialPrefs, {
  bool debugTools = kDebugToolsEnabled,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  late BallGame game;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs))],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(gameFactory: () => game = BallGame(seed: 1), debugTools: debugTools),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return (game, prefs);
}

void main() {
  group('board table', () {
    final board = buildDebugHighHpBoard();

    test('rows 0–5 match the table, rows 6–7 are empty', () {
      expect(kDebugHighHpRows, hasLength(_filledRows));
      for (final row in kDebugHighHpRows) {
        expect(row, hasLength(kCols));
      }
      _expectDebugBoard(board);
      for (var row = _filledRows; row < kBoardRows; row++) {
        for (var col = 0; col < kCols; col++) {
          expect(board.cellAt(row, col), isNull, reason: '($row, $col)');
        }
      }
    });

    test('every HP stop boundary, the three-digit values and 99 are on the board', () {
      final hps = _hps(board);
      for (final hp in _requiredHp) {
        expect(hps, contains(hp), reason: 'hp $hp');
      }
      expect(hps.reduce((a, b) => a > b ? a : b), 2 * kMaxBalls); // 198
      expect(hps.every((hp) => hp >= 1 && hp <= 2 * kMaxBalls), isTrue);
    });

    test('at least 2 rings and 1 star; rows respect the generator limits', () {
      expect(_pickups(board, PickupKind.ring), greaterThanOrEqualTo(2));
      expect(_pickups(board, PickupKind.star), greaterThanOrEqualTo(1));
      for (final row in kDebugHighHpRows) {
        expect(row.whereType<TargetCell>().length, lessThanOrEqualTo(_maxTargetsPerRow));
        expect(row.whereType<PickupCell>().length, lessThanOrEqualTo(1));
      }
    });

    test('session: 99 balls, round $kDebugBoardRound, ready to shoot', () {
      final session = debugHighHpSession(7);
      expect(session.ballCount, kMaxBalls);
      expect(session.round, kDebugBoardRound);
      expect(session.phase, GamePhase.ready);
      _expectDebugBoard(session.board);
    });
  });

  testWidgets('with debug tools off the picker and the option are not in the tree',
      (tester) async {
    await _pumpScreen(tester, {PrefsRepository.keyTutorialSeen: true}, debugTools: false);
    expect(find.byKey(const Key('debugThemePicker')), findsNothing);
    expect(find.byKey(const Key('debugHighHpBoard')), findsNothing);
  });

  testWidgets('the option starts the debug board and writes nothing to prefs', (tester) async {
    const initial = <String, Object>{
      'best_score': 7,
      PrefsRepository.keyTutorialSeen: false,
      PrefsRepository.keyThemeId: 'orbitfall',
    };
    final (game, prefs) = await _pumpScreen(tester, initial);
    Map<String, Object?> snapshot() => {for (final k in prefs.getKeys()) k: prefs.get(k)};
    final before = snapshot();
    expect(before, initial);

    await tester.tap(find.byKey(const Key('debugThemePicker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('High HP board'), findsOneWidget);
    await tester.tap(find.byKey(const Key('debugHighHpBoard')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(game.isDebugGame, isTrue);
    expect(game.session.ballCount, kMaxBalls);
    expect(game.session.round, kDebugBoardRound);
    _expectDebugBoard(game.session.board);

    // Bir atış: aşağı bas, geri çek, bırak (ilk atış normalde tutorial_seen yazar).
    final shot = tester.getCenter(find.byType(GameScreen));
    final gesture = await tester.startGesture(shot);
    await gesture.moveBy(const Offset(10, 40));
    await gesture.moveBy(const Offset(10, 40));
    await gesture.up();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(game.session.phase, isNot(GamePhase.ready), reason: 'shot was fired');

    game.gameOverScore.value = game.session.score;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(snapshot(), before);

    await tester.tap(find.text('Play Again'));
    await tester.pump();
    expect(game.isDebugGame, isFalse);
  });
}

import 'package:balls_99/core/services/prefs_service.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/features/game/game_screen.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyun ekranındaki metinlerin bir Material atası olmalı; yoksa Flutter'ın
/// sarı çift alt çizgili, monospace hata stili görünür.
void _expectPlainText(WidgetTester tester, String text) {
  final rich = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)).first,
  );
  final style = rich.text.style!;
  expect(style.decoration ?? TextDecoration.none, TextDecoration.none, reason: text);
  expect(style.decorationStyle, isNot(TextDecorationStyle.double), reason: text);
  expect(style.fontFamily, isNot('monospace'), reason: text);
  expect(style.debugLabel ?? '', isNot(contains('fallback style')), reason: text);
}

void main() {
  testWidgets('tutorial and game over texts inherit a Material text style',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late BallGame game;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs))],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(brightness: Brightness.dark),
          home: GameScreen(gameFactory: () => game = BallGame(seed: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    const tutorial = 'Press anywhere, pull back and release to shoot';
    expect(find.text(tutorial), findsOneWidget);
    _expectPlainText(tester, tutorial);
    final tutorialStyle = tester
        .widget<RichText>(
            find.descendant(of: find.text(tutorial), matching: find.byType(RichText)))
        .text
        .style!;
    expect(tutorialStyle.color, orbitfallPalette.textPrimary);

    game.gameOverScore.value = 42;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    for (final text in ['Game Over', 'Score', '42', 'Play Again']) {
      expect(find.text(text), findsOneWidget, reason: text);
      _expectPlainText(tester, text);
    }
  });
}

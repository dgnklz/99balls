import 'package:balls_99/core/services/prefs_service.dart';
import 'package:balls_99/features/game/game_screen.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:balls_99/l10n/app_localizations.dart';
import 'package:balls_99/themes/theme_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Debug yapıda (testler debug'dır) oyun ekranındaki gizli tema seçici.
void main() {
  testWidgets('picking a theme updates the provider, prefs and the running game',
      (tester) async {
    SharedPreferences.setMockInitialValues({PrefsRepository.keyTutorialSeen: true});
    final prefs = await SharedPreferences.getInstance();
    late BallGame game;
    final container = ProviderContainer(overrides: [
      prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(gameFactory: () => game = BallGame(seed: 1)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('debugThemePicker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    for (final id in ['orbitfall', 'candybust', 'pixeldrop', 'abyss', 'inkpaper']) {
      expect(find.byKey(Key('theme_$id')), findsOneWidget, reason: id);
    }
    expect(find.text('placeholder'), findsNWidgets(4));

    await tester.tap(find.byKey(const Key('theme_abyss')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(selectedThemeProvider).id, 'abyss');
    expect(prefs.getString(PrefsRepository.keyThemeId), 'abyss');
    expect(game.theme.id, 'abyss');
  });
}

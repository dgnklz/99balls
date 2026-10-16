import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/game_config.dart';
import '../features/game/game_screen.dart';
import '../l10n/app_localizations.dart';
import '../themes/theme_providers.dart';

/// Uygulama kabuğu. M3a'da doğrudan oyun ekranı açılır; go_router, splash
/// ekranı ve menüler M4'te eklenecek.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(selectedThemeProvider).palette;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: palette.bgBottom,
      ),
      // Sistem yazı ölçeği en fazla 1.15 (PRD 3.1).
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: kMaxTextScale,
        child: child!,
      ),
      home: const GameScreen(),
    );
  }
}

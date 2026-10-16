import 'package:flutter/material.dart';

import '../core/config/game_config.dart';
import '../core/theme/palette.dart';
import '../features/game/game_screen.dart';
import '../l10n/app_localizations.dart';

/// Uygulama kabuğu. M2'de doğrudan oyun ekranı açılır; go_router, splash ve
/// menüler M4'te eklenecek.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.bgGradientBottom,
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

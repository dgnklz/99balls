// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tutorialAim => 'Press anywhere, pull back and release to shoot';

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get scoreLabel => 'Score';

  @override
  String get playAgain => 'Play Again';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get tutorialAim =>
      'Herhangi bir yere bas, geri çek ve atmak için bırak';

  @override
  String get gameOverTitle => 'Oyun Bitti';

  @override
  String get scoreLabel => 'Skor';

  @override
  String get playAgain => 'Tekrar Oyna';

  @override
  String starBonusPopup(int n) {
    return '+$n';
  }

  @override
  String get themeOrbitfall => 'Orbitfall';

  @override
  String get themeCandyBurst => 'Candy Burst';

  @override
  String get themePixelDrop => 'Pixel Drop';

  @override
  String get themeAbyss => 'Abyss';

  @override
  String get themeInkPaper => 'Ink & Paper';

  @override
  String get themePickerTitle => 'Tema';

  @override
  String get themePlaceholderTag => 'yer tutucu';
}

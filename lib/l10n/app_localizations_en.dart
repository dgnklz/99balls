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
  String get themePickerTitle => 'Theme';

  @override
  String get themePlaceholderTag => 'placeholder';

  @override
  String get boostLabel => 'Speed up';

  @override
  String get debugHighHpBoard => 'High HP board';
}

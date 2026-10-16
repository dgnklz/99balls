import '../core/config/game_config.dart';
import 'game_theme.dart';

/// Tema kilidi sorusunun tek kapısı (PRD 7.4.1).
///
/// v1'de [kAllThemesUnlocked] = true. İleride üyelik mağaza faturalandırması
/// ve doğrulamasıyla gelecek; yerel bir bayrak güvenli değildir.
class ThemeAccess {
  final bool allUnlocked;

  const ThemeAccess({this.allUnlocked = kAllThemesUnlocked});

  bool isUnlocked(GameTheme theme) => allUnlocked || theme.isFree;
}

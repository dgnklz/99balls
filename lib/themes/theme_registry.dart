import '../core/config/game_config.dart';
import 'game_theme.dart';
import 'orbitfall/orbitfall_theme.dart';
import 'placeholder/placeholder_themes.dart';
import 'theme_access.dart';

/// Beş tema (PRD 7.4.1). M3a'da yalnızca Orbitfall tam; diğerleri yer tutucu.
abstract final class ThemeRegistry {
  static final List<GameTheme> all = List.unmodifiable([
    orbitfallTheme,
    candyBurstTheme,
    pixelDropTheme,
    abyssTheme,
    inkPaperTheme,
  ]);

  /// Ücretsiz varsayılan tema; her geri düşüş buraya yapılır.
  static GameTheme get fallback => byId(kDefaultThemeId)!;

  static GameTheme? byId(String id) {
    for (final theme in all) {
      if (theme.id == id) return theme;
    }
    return null;
  }

  /// Kayıtlı id'yi temaya çözer. Bulunamaz ya da kilitliyse ücretsiz temaya düşer.
  static GameTheme resolve(String? id, {ThemeAccess access = const ThemeAccess()}) {
    final theme = id == null ? null : byId(id);
    if (theme == null || !access.isUnlocked(theme)) return fallback;
    return theme;
  }
}

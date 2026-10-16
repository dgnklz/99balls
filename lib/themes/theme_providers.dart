import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/prefs_service.dart';
import 'game_theme.dart';
import 'theme_access.dart';
import 'theme_registry.dart';

/// Tema erişim kapısı; testlerde kilitli senaryo için override edilebilir.
final themeAccessProvider = Provider<ThemeAccess>((ref) => const ThemeAccess());

/// Seçili tema. `theme_id`'den yüklenir; bilinmeyen/kilitli id → Orbitfall.
class SelectedThemeNotifier extends Notifier<GameTheme> {
  @override
  GameTheme build() => ThemeRegistry.resolve(
        ref.read(prefsRepositoryProvider).themeId,
        access: ref.watch(themeAccessProvider),
      );

  /// Temayı seçer ve kalıcı yapar. Kilitliyse yok sayılır ve false döner.
  bool select(GameTheme theme) {
    if (!ref.read(themeAccessProvider).isUnlocked(theme)) return false;
    state = theme;
    ref.read(prefsRepositoryProvider).setThemeId(theme.id);
    return true;
  }
}

final selectedThemeProvider =
    NotifierProvider<SelectedThemeNotifier, GameTheme>(SelectedThemeNotifier.new);

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/themes/theme_access.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 7.4.1: ThemeAccess.isUnlocked tek kapı; v1'de hepsi açık.
void main() {
  test('v1 default: every theme is unlocked', () {
    expect(kAllThemesUnlocked, isTrue);
    const access = ThemeAccess();
    for (final theme in ThemeRegistry.all) {
      expect(access.isUnlocked(theme), isTrue, reason: theme.id);
    }
  });

  test('when locking is enabled only the free theme is unlocked', () {
    const access = ThemeAccess(allUnlocked: false);
    for (final theme in ThemeRegistry.all) {
      expect(access.isUnlocked(theme), theme.id == 'orbitfall', reason: theme.id);
    }
  });

  test('a locked theme resolves to the free theme', () {
    const locked = ThemeAccess(allUnlocked: false);
    expect(ThemeRegistry.resolve('abyss', access: locked).id, 'orbitfall');
    expect(ThemeRegistry.resolve('orbitfall', access: locked).id, 'orbitfall');
  });
}

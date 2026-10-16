import 'package:balls_99/core/services/prefs_service.dart';
import 'package:balls_99/themes/theme_access.dart';
import 'package:balls_99/themes/theme_providers.dart';
import 'package:balls_99/themes/theme_registry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seçili tema `theme_id` ile kalıcıdır; bilinmeyen/kilitli/bozuk → Orbitfall.
Future<(ProviderContainer, SharedPreferences)> _container(
  Map<String, Object> stored, {
  ThemeAccess access = const ThemeAccess(),
}) async {
  SharedPreferences.setMockInitialValues(stored);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
    themeAccessProvider.overrideWithValue(access),
  ]);
  addTearDown(container.dispose);
  return (container, prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('default is Orbitfall', () async {
    final (c, _) = await _container({});
    expect(c.read(selectedThemeProvider).id, 'orbitfall');
  });

  test('a stored theme id is restored', () async {
    final (c, _) = await _container({PrefsRepository.keyThemeId: 'pixeldrop'});
    expect(c.read(selectedThemeProvider).id, 'pixeldrop');
  });

  test('unknown id and wrong type fall back to Orbitfall', () async {
    final (unknown, _) = await _container({PrefsRepository.keyThemeId: 'vaporwave'});
    expect(unknown.read(selectedThemeProvider).id, 'orbitfall');
    final (wrongType, _) = await _container({PrefsRepository.keyThemeId: 5});
    expect(wrongType.read(selectedThemeProvider).id, 'orbitfall');
  });

  test('a stored but locked theme falls back to Orbitfall', () async {
    final (c, _) = await _container(
      {PrefsRepository.keyThemeId: 'abyss'},
      access: const ThemeAccess(allUnlocked: false),
    );
    expect(c.read(selectedThemeProvider).id, 'orbitfall');
  });

  test('select persists theme_id', () async {
    final (c, prefs) = await _container({});
    final abyss = ThemeRegistry.byId('abyss')!;
    expect(c.read(selectedThemeProvider.notifier).select(abyss), isTrue);
    expect(c.read(selectedThemeProvider).id, 'abyss');
    expect(prefs.getString(PrefsRepository.keyThemeId), 'abyss');
  });

  test('selecting a locked theme is refused', () async {
    final (c, prefs) = await _container({}, access: const ThemeAccess(allUnlocked: false));
    final abyss = ThemeRegistry.byId('abyss')!;
    expect(c.read(selectedThemeProvider.notifier).select(abyss), isFalse);
    expect(c.read(selectedThemeProvider).id, 'orbitfall');
    expect(prefs.getString(PrefsRepository.keyThemeId), isNull);
  });
}

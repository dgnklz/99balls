import 'package:balls_99/core/services/prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PRD 10.1: varsayılanlar ve bozuk veri (M2'de yalnızca tutorial_seen).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tutorial_seen defaults to false', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    expect(repo.tutorialSeen, isFalse);
  });

  test('tutorial_seen is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PrefsRepository(prefs).setTutorialSeen(true);
    expect(prefs.getBool(PrefsRepository.keyTutorialSeen), isTrue);
    expect(PrefsRepository(prefs).tutorialSeen, isTrue);
  });

  test('wrong type falls back to the default without throwing', () async {
    SharedPreferences.setMockInitialValues({PrefsRepository.keyTutorialSeen: 'yes'});
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    expect(repo.tutorialSeen, isFalse);
  });

  test('music_on and sfx_on default to true and persist', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = PrefsRepository(prefs);
    expect(repo.musicOn, isTrue);
    expect(repo.sfxOn, isTrue);
    await repo.setMusicOn(false);
    await repo.setSfxOn(false);
    expect(PrefsRepository(prefs).musicOn, isFalse);
    expect(PrefsRepository(prefs).sfxOn, isFalse);
  });

  test('corrupt music_on / sfx_on / theme_id fall back without throwing', () async {
    SharedPreferences.setMockInitialValues({
      PrefsRepository.keyMusicOn: 'off',
      PrefsRepository.keySfxOn: 0,
      PrefsRepository.keyThemeId: 42,
    });
    final repo = PrefsRepository(await SharedPreferences.getInstance());
    expect(repo.musicOn, isTrue);
    expect(repo.sfxOn, isTrue);
    expect(repo.themeId, isNull);
  });

  test('theme_id is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await PrefsRepository(prefs).setThemeId('abyss');
    expect(PrefsRepository(prefs).themeId, 'abyss');
  });
}

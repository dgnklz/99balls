import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yerel tercihler (PRD Bölüm 10.1). Hatalar yutulur, varsayılana dönülür.
/// M3a: tutorial_seen, music_on, sfx_on ve theme_id. Diğer anahtarlar M4'te.
class PrefsRepository {
  static const String keyTutorialSeen = 'tutorial_seen';
  static const String keyMusicOn = 'music_on';
  static const String keySfxOn = 'sfx_on';
  static const String keyThemeId = 'theme_id';

  final SharedPreferences _prefs;

  PrefsRepository(this._prefs);

  bool get tutorialSeen => _readBool(keyTutorialSeen, defaultValue: false);

  Future<void> setTutorialSeen(bool value) => _writeBool(keyTutorialSeen, value);

  bool get musicOn => _readBool(keyMusicOn, defaultValue: true);

  Future<void> setMusicOn(bool value) => _writeBool(keyMusicOn, value);

  bool get sfxOn => _readBool(keySfxOn, defaultValue: true);

  Future<void> setSfxOn(bool value) => _writeBool(keySfxOn, value);

  /// Kayıtlı tema id'si; yoksa ya da yanlış tipteyse null (çözümleme ThemeRegistry'de).
  String? get themeId {
    try {
      final value = _prefs.get(keyThemeId);
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setThemeId(String id) async {
    try {
      await _prefs.setString(keyThemeId, id);
    } catch (_) {
      // Yazılamazsa sessizce geç; bir sonraki açılışta varsayılan kullanılır.
    }
  }

  bool _readBool(String key, {required bool defaultValue}) {
    try {
      final value = _prefs.get(key);
      return value is bool ? value : defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }

  Future<void> _writeBool(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
    } catch (_) {
      // Yazılamazsa sessizce geç; bir sonraki açılışta varsayılan kullanılır.
    }
  }
}

/// main() içinde yüklenmiş SharedPreferences ile override edilir.
final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => throw UnimplementedError('prefsRepositoryProvider must be overridden'),
);

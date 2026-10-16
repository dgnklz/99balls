import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yerel tercihler (PRD Bölüm 10.1). Hatalar yutulur, varsayılana dönülür.
/// M2'de yalnızca `tutorial_seen` vardır; diğer anahtarlar M4'te eklenecek.
class PrefsRepository {
  static const String keyTutorialSeen = 'tutorial_seen';

  final SharedPreferences _prefs;

  PrefsRepository(this._prefs);

  bool get tutorialSeen => _readBool(keyTutorialSeen, defaultValue: false);

  Future<void> setTutorialSeen(bool value) => _writeBool(keyTutorialSeen, value);

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

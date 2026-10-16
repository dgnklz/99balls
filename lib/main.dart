import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/immersive_mode.dart';
import 'core/services/audio_service.dart';
import 'core/services/flame_audio_backend.dart';
import 'core/services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Yalnızca dikey (PRD 2.7); tam ekran: durum ve gezinti çubukları gizli.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final immersive = ImmersiveMode();
  await immersive.apply();
  immersive.attach();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
        audioBackendProvider.overrideWithValue(FlameAudioBackend()),
        immersiveModeProvider.overrideWithValue(immersive),
      ],
      child: const App(),
    ),
  );
  // İlk karede bir kez daha (bazı cihazlar ilk çağrıyı pencere hazır olmadan alır).
  WidgetsBinding.instance.addPostFrameCallback((_) => immersive.apply());
}

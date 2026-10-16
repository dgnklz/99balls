import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Yalnızca dikey, kenardan kenara çizim (PRD 2.7).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        prefsRepositoryProvider.overrideWithValue(PrefsRepository(prefs)),
      ],
      child: const App(),
    ),
  );
}

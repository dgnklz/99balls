import 'package:balls_99/core/services/flame_audio_backend.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gerçek oynatıcı: platform yokken (test ortamı) hatalar yutulur, oyun sürer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('platform errors are swallowed', () async {
    final backend = FlameAudioBackend();
    await backend.preload(sfx: orbitfallSounds.sfxFiles, music: orbitfallSounds.music);
    backend.playSfx(orbitfallSounds.sfxFiles.first, 1);
    await backend.playMusic(orbitfallSounds.music, 0.35);
    await backend.pauseMusic();
    await backend.resumeMusic();
    await backend.stopMusic();
  }, timeout: const Timeout(Duration(seconds: 20)));
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/game_theme.dart';
import '../config/game_config.dart';
import 'prefs_service.dart';

/// Gerçek oynatıcıyı soyutlar (üretimde flame_audio, testlerde sahte).
abstract class AudioBackend {
  /// SFX'leri ve müziği belleğe alır (ilk çalmada gecikme olmasın).
  Future<void> preload({required List<String> sfx, required String music});

  void playSfx(String file, double volume);

  Future<void> playMusic(String file, double volume);

  Future<void> pauseMusic();

  Future<void> resumeMusic();

  Future<void> stopMusic();
}

/// Hiçbir şey çalmayan oynatıcı (varsayılan; testler ve ses yokken).
class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<void> preload({required List<String> sfx, required String music}) async {}

  @override
  void playSfx(String file, double volume) {}

  @override
  Future<void> playMusic(String file, double volume) async {}

  @override
  Future<void> pauseMusic() async {}

  @override
  Future<void> resumeMusic() async {}

  @override
  Future<void> stopMusic() async {}
}

/// Ses kuralları (PRD 8.1–8.3):
/// - `sfx_on` / `music_on` kapalıysa çalmaz.
/// - Aynı SFX [kSfxMinGapMs] içinde tekrar çalmaz; aynı anda en fazla
///   [kSfxMaxConcurrent] SFX. İkisi de **duvar saatiyle** ölçülür, simülasyon
///   adımıyla değil: hızlanmada bir karede gelen olay yağmuru da sınırlanır.
/// - Vuruş varyantları simülasyondan bağımsız bir sayaçla sırayla döner.
/// - Müzik ilk dokunuştan sonra başlar; arka planda duraklar, öne gelince sürer.
///   Müzik hızlanmadan etkilenmez.
class AudioService {
  final AudioBackend backend;
  final bool Function() musicEnabled;
  final bool Function() sfxEnabled;
  final int Function() _nowMs;

  ThemeSounds? _sounds;
  final Int64List _lastPlayedMs = Int64List(SfxKey.values.length)..fillRange(0, SfxKey.values.length, _never);
  final Int64List _activeUntilMs = Int64List(kSfxMaxConcurrent);
  int _hitVariant = 0;
  bool _interacted = false;
  bool _backgrounded = false;
  bool _musicStarted = false;

  static const int _never = -1 << 40;

  AudioService({
    required this.backend,
    required this.musicEnabled,
    required this.sfxEnabled,
    int Function()? nowMs,
  }) : _nowMs = nowMs ?? _stopwatchMs;

  static final Stopwatch _clock = Stopwatch()..start();
  static int _stopwatchMs() => _clock.elapsedMilliseconds;

  bool get musicPlaying => _musicStarted && !_backgrounded;

  /// Temanın seslerini ön yükler; müzik çalıyorsa yeni temanın müziğine geçer.
  Future<void> setTheme(ThemeSounds sounds) async {
    if (identical(_sounds, sounds)) return;
    _sounds = sounds;
    _hitVariant = 0;
    await backend.preload(sfx: sounds.sfxFiles, music: sounds.music);
    if (_musicStarted) await backend.playMusic(sounds.music, kMusicVolume);
  }

  /// SFX çalmayı dener; çalındıysa true döner.
  bool play(SfxKey key) {
    final sounds = _sounds;
    if (sounds == null || _backgrounded || !sfxEnabled()) return false;
    final files = sounds.sfx[key];
    if (files == null || files.isEmpty) return false;

    final now = _nowMs();
    if (now - _lastPlayedMs[key.index] < kSfxMinGapMs) return false;
    final slot = _freeSlot(now);
    if (slot < 0) return false;

    final file = key == SfxKey.hit ? files[_nextHitVariant(files.length)] : files.first;
    _lastPlayedMs[key.index] = now;
    _activeUntilMs[slot] = now + (sounds.durationsMs[file] ?? kSfxMinGapMs);
    backend.playSfx(file, kSfxVolume);
    return true;
  }

  int _freeSlot(int now) {
    for (var i = 0; i < _activeUntilMs.length; i++) {
      if (_activeUntilMs[i] <= now) return i;
    }
    return -1;
  }

  int _nextHitVariant(int count) {
    final index = _hitVariant % count;
    _hitVariant = (_hitVariant + 1) % kHitVariants;
    return index;
  }

  /// Kullanıcının ilk dokunuşu: müzik (açıksa) burada başlar (PRD 8.3).
  void onUserInteraction() {
    if (_interacted) return;
    _interacted = true;
    _startMusicIfAllowed();
  }

  /// Müzik anahtarı: kapanınca anında durur, açılınca baştan başlar.
  Future<void> onMusicSettingChanged() async {
    if (musicEnabled()) {
      _startMusicIfAllowed();
    } else if (_musicStarted) {
      _musicStarted = false;
      await backend.stopMusic();
    }
  }

  /// Uygulama arka plana geçti/öne geldi.
  Future<void> setBackgrounded(bool backgrounded) async {
    if (_backgrounded == backgrounded) return;
    _backgrounded = backgrounded;
    if (!_musicStarted) return;
    if (backgrounded) {
      await backend.pauseMusic();
    } else {
      await backend.resumeMusic();
    }
  }

  void _startMusicIfAllowed() {
    final sounds = _sounds;
    if (!_interacted || _musicStarted || sounds == null || !musicEnabled()) return;
    _musicStarted = true;
    if (!_backgrounded) backend.playMusic(sounds.music, kMusicVolume);
  }
}

/// Uygulamanın oynatıcısı; main() gerçek (flame_audio) oynatıcıyla override eder.
final audioBackendProvider = Provider<AudioBackend>((ref) => const SilentAudioBackend());

final audioServiceProvider = Provider<AudioService>((ref) {
  final prefs = ref.watch(prefsRepositoryProvider);
  return AudioService(
    backend: ref.watch(audioBackendProvider),
    musicEnabled: () => prefs.musicOn,
    sfxEnabled: () => prefs.sfxOn,
  );
});

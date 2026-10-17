import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../themes/game_theme.dart';
import '../config/game_config.dart';
import 'prefs_service.dart';

/// Uçuş sonu kesmesinin özeti (yalnızca tanı günlüğü için).
@immutable
class SfxCutReport {
  /// Kesme anında süren başlatma sayısı (tüm sesler).
  final int pending;

  /// Kesme anında çalmakta olup durdurulan uçuş sesi sayısı.
  final int stopped;

  /// Uçuş bittikten sonra tamamlanıp hemen durdurulan başlatma sayısı.
  final int lateStopped;

  /// Uçuş boyunca geri basınçla atlanan istek sayısı.
  final int skippedBackpressure;

  const SfxCutReport({
    required this.pending,
    required this.stopped,
    required this.lateStopped,
    required this.skippedBackpressure,
  });
}

/// Gerçek oynatıcıyı soyutlar (üretimde flame_audio, testlerde sahte).
abstract class AudioBackend {
  /// SFX'leri ve müziği belleğe alır (ilk çalmada gecikme olmasın).
  Future<void> preload({required List<String> sfx, required String music});

  /// [important]: geri basınçta yalnızca kendi dosyası meşgulse atlanır.
  /// [flightSound]: uçuşa ait ses (vuruş, duvar); uçuş bitince kesilir.
  /// [durationMs]: sesin süresi (uçuş sesi takibi için).
  void playSfx(
    String file,
    double volume, {
    bool important = false,
    bool flightSound = false,
    int durationMs = 0,
  });

  /// Uçuş bitti: çalan ve başlatılmayı bekleyen uçuş seslerini keser.
  /// [onReport]: bekleyen başlatmalar da sonuçlanınca özetle çağrılır.
  void cutFlightSfx({void Function(SfxCutReport report)? onReport});

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
  void playSfx(
    String file,
    double volume, {
    bool important = false,
    bool flightSound = false,
    int durationMs = 0,
  }) {}

  @override
  void cutFlightSfx({void Function(SfxCutReport report)? onReport}) {}

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
/// - Kalabalık uçuşta (havada [kSfxCrowdBalls] ve üstü top) vuruş ve duvar en az
///   [kSfxCrowdMinGapMs] aralıkla çalar; önemli sesler etkilenmez.
/// - Arka uç geri basınç uygular: önemsiz sesler ([importantKeys] dışı) yoğunlukta
///   atlanır (geç ses yerine sessizlik).
/// - Uçuş bitince ([endFlight]) uçuşa ait sesler ([flightKeys]: vuruş, duvar)
///   kesilir; bekleyen başlatmaları çalmaz. Diğer sesler (kırılma, halka,
///   yıldız, toplama, satır, rekor, oyun sonu, tık) kesilmez.
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
  int _crowd = 0;
  int _thinned = 0;
  int _flightStartMs = -1;
  bool _interacted = false;
  bool _backgrounded = false;
  bool _musicStarted = false;

  static const int _never = -1 << 40;

  /// Uçuşa ait sesler: uçuş bitince kesilir. Topun yere inmesinin sesi yoktur
  /// (PRD 8.2), bu yüzden listede yalnızca vuruş ve duvar var.
  static const Set<SfxKey> flightKeys = {SfxKey.hit, SfxKey.wall};

  /// Önemli sesler: geri basınçta yalnızca kendi dosyası meşgulse atlanır,
  /// kalabalıkta seyreltilmez. Önemsiz: vuruş, duvar, atış.
  static const Set<SfxKey> importantKeys = {
    SfxKey.breakTarget,
    SfxKey.pickup,
    SfxKey.star,
    SfxKey.collect,
    SfxKey.advance,
    SfxKey.record,
    SfxKey.gameOver,
    SfxKey.click,
  };

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
    final sinceLast = now - _lastPlayedMs[key.index];
    if (sinceLast < kSfxMinGapMs) return false;
    final flightSound = flightKeys.contains(key);
    if (flightSound && _crowd >= kSfxCrowdBalls && sinceLast < kSfxCrowdMinGapMs) {
      _thinned++;
      return false;
    }
    final slot = _freeSlot(now);
    if (slot < 0) return false;

    final file = key == SfxKey.hit ? files[_nextHitVariant(files.length)] : files.first;
    final durationMs = sounds.durationsMs[file] ?? kSfxMinGapMs;
    _lastPlayedMs[key.index] = now;
    _activeUntilMs[slot] = now + durationMs;
    if (key == SfxKey.shoot && _flightStartMs < 0) _flightStartMs = now;
    backend.playSfx(
      file,
      kSfxVolume,
      important: importantKeys.contains(key),
      flightSound: flightSound,
      durationMs: durationMs,
    );
    return true;
  }

  /// Havadaki top sayısı (oyun her karede verir; yalnızca ses seyreltmesi için).
  void setCrowd(int flyingBalls) => _crowd = flyingBalls;

  /// Uçuş bitti (son top yere indi): uçuşa ait sesleri keser. Geliştirici
  /// yapısında (debug/profile) tek satır tanı günlüğü yazar; release'te yazmaz.
  void endFlight() {
    final thinned = _thinned;
    final flightMs = _flightStartMs < 0 ? 0 : _nowMs() - _flightStartMs;
    _thinned = 0;
    _flightStartMs = -1;
    if (!kDebugToolsEnabled) {
      backend.cutFlightSfx();
      return;
    }
    final seconds = (flightMs / Duration.millisecondsPerSecond).toStringAsFixed(1);
    backend.cutFlightSfx(
      onReport: (r) => debugPrint(
        'SFXEND bekleyen=${r.pending} izlenen=${r.stopped} '
        'gecikmeli_durdurulan=${r.lateStopped} atlanan_geri_basınç=${r.skippedBackpressure} '
        'seyreltilen=$thinned uçuş_süresi=${seconds}sn',
      ),
    );
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

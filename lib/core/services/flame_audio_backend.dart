import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../config/game_config.dart';
import 'audio_service.dart';
import 'flight_sfx_gate.dart';
import 'sfx_dispatcher.dart';

/// flame_audio ile gerçek oynatıcı. SFX'ler dosya başına bir AudioPool ile
/// önceden açılır (düşük gecikme); müzik Bgm ile döngüde çalar.
/// Platform hataları yutulur: ses çalmasa da oyun sürer.
///
/// Başlatmalar [SfxDispatcher]'dan geçer (geri basınç): AudioPool'un dosya
/// kilidinde ve Android ana iş parçacığında kuyruk birikmez; durdurma komutları
/// da uzun bir kuyruğun arkasında kalmaz.
///
/// Uçuş sesleri uçuş bitince [FlightSfxGate] ile kesilir. Kesme sert durdurmadır:
/// AudioPool yalnızca durdurma işlevi verir, oynatıcıya (ses seviyesi rampası
/// için) erişim vermez; sesler ≤ 110 ms olduğundan yalnızca son kısımları kesilir.
class FlameAudioBackend implements AudioBackend {
  final Map<String, AudioPool> _pools = {};
  final FlightSfxGate _flight = FlightSfxGate();
  final SfxDispatcher _dispatcher = SfxDispatcher();

  @override
  Future<void> preload({required List<String> sfx, required String music}) async {
    try {
      await FlameAudio.audioCache.loadAll([...sfx, music]);
      for (final file in sfx) {
        if (_pools.containsKey(file)) continue;
        _pools[file] = await FlameAudio.createPool(file, maxPlayers: kSfxPoolPlayers);
      }
    } catch (e) {
      debugPrint('Audio preload failed: $e');
    }
  }

  @override
  void playSfx(
    String file,
    double volume, {
    bool important = false,
    bool flightSound = false,
    int durationMs = 0,
  }) {
    final pool = _pools[file];
    if (pool == null) return;
    final started = _dispatcher.dispatch<StopSfx>(
      file,
      () => pool.start(volume: volume).catchError((Object e) {
        debugPrint('SFX failed: $e');
        return () async {};
      }),
      important: important,
    );
    if (started == null) return;
    _flight.track(started, flightSound: flightSound, durationMs: durationMs);
  }

  @override
  void cutFlightSfx({void Function(SfxCutReport report)? onReport}) {
    final pending = _dispatcher.pending;
    final skipped = _dispatcher.takeSkipped();
    final playing = _flight.playing;
    _flight.cut(
      onSettled: onReport == null
          ? null
          : (late) => onReport(SfxCutReport(
                pending: pending,
                stopped: playing,
                lateStopped: late,
                skippedBackpressure: skipped,
              )),
    );
  }

  @override
  Future<void> playMusic(String file, double volume) => _guard(() => FlameAudio.bgm.play(file, volume: volume));

  @override
  Future<void> pauseMusic() => _guard(FlameAudio.bgm.pause);

  @override
  Future<void> resumeMusic() => _guard(FlameAudio.bgm.resume);

  @override
  Future<void> stopMusic() => _guard(FlameAudio.bgm.stop);

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }
}

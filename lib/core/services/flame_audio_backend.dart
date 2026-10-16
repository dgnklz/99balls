import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../config/game_config.dart';
import 'audio_service.dart';

/// flame_audio ile gerçek oynatıcı. SFX'ler dosya başına bir AudioPool ile
/// önceden açılır (düşük gecikme); müzik Bgm ile döngüde çalar.
/// Platform hataları yutulur: ses çalmasa da oyun sürer.
class FlameAudioBackend implements AudioBackend {
  final Map<String, AudioPool> _pools = {};

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
  void playSfx(String file, double volume) {
    final pool = _pools[file];
    if (pool == null) return;
    pool.start(volume: volume).catchError((Object e) {
      debugPrint('SFX failed: $e');
      return () async {};
    });
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

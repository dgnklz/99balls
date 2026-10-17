import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/audio_service.dart';
import 'package:balls_99/themes/candyburst/candyburst_theme.dart';
import 'package:balls_99/themes/game_theme.dart';
import 'package:balls_99/themes/inkpaper/inkpaper_theme.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sahte oynatıcı: çağrıları kaydeder.
class FakeAudioBackend implements AudioBackend {
  final List<String> sfx = [];
  final List<double> sfxVolumes = [];
  final List<String> calls = [];
  final List<List<String>> preloads = [];

  @override
  Future<void> preload({required List<String> sfx, required String music}) async =>
      preloads.add([...sfx, music]);

  final List<bool> flightSounds = [];
  final List<bool> important = [];
  final List<int> durations = [];
  int cuts = 0;

  @override
  void playSfx(
    String file,
    double volume, {
    bool important = false,
    bool flightSound = false,
    int durationMs = 0,
  }) {
    sfx.add(file);
    sfxVolumes.add(volume);
    flightSounds.add(flightSound);
    this.important.add(important);
    durations.add(durationMs);
  }

  @override
  void cutFlightSfx({void Function(SfxCutReport report)? onReport}) {
    cuts++;
    onReport?.call(const SfxCutReport(pending: 0, stopped: 0, lateStopped: 0, skippedBackpressure: 0));
  }

  @override
  Future<void> playMusic(String file, double volume) async => calls.add('play:$file@$volume');

  @override
  Future<void> pauseMusic() async => calls.add('pause');

  @override
  Future<void> resumeMusic() async => calls.add('resume');

  @override
  Future<void> stopMusic() async => calls.add('stop');
}

class _Harness {
  final FakeAudioBackend backend = FakeAudioBackend();
  int now = 0;
  bool music = true;
  bool sfx = true;
  late final AudioService service = AudioService(
    backend: backend,
    musicEnabled: () => music,
    sfxEnabled: () => sfx,
    nowMs: () => now,
  );
}

Future<_Harness> _ready() async {
  final h = _Harness();
  await h.service.setTheme(orbitfallSounds);
  return h;
}

void main() {
  group('SFX', () {
    test('nothing plays when sfx_on is off', () async {
      final h = await _ready();
      h.sfx = false;
      expect(h.service.play(SfxKey.shoot), isFalse);
      expect(h.backend.sfx, isEmpty);
    });

    test('same key is not replayed within 50 ms (wall clock)', () async {
      final h = await _ready();
      expect(h.service.play(SfxKey.shoot), isTrue);
      h.now += kSfxMinGapMs - 1;
      expect(h.service.play(SfxKey.shoot), isFalse);
      expect(h.service.play(SfxKey.wall), isTrue, reason: 'other keys unaffected');
      h.now += 1;
      expect(h.service.play(SfxKey.shoot), isTrue);
    });

    test('at most 8 sounds at once; slots free when sounds end', () async {
      final h = await _ready();
      final keys = SfxKey.values.where((k) => k != SfxKey.click).toList();
      var played = 0;
      for (final key in keys) {
        if (h.service.play(key)) played++;
      }
      expect(keys.length, greaterThan(kSfxMaxConcurrent));
      expect(played, kSfxMaxConcurrent);
      h.now += orbitfallSounds.durationsMs.values.reduce((a, b) => a > b ? a : b);
      expect(h.service.play(SfxKey.click), isTrue);
    });

    test('hit variants rotate 1 → 2 → 3 → 1 independent of the simulation', () async {
      final h = await _ready();
      for (var i = 0; i < 4; i++) {
        h.service.play(SfxKey.hit);
        h.now += kSfxMinGapMs;
      }
      expect(h.backend.sfx, [
        'orbitfall/sfx_hit_1.wav',
        'orbitfall/sfx_hit_2.wav',
        'orbitfall/sfx_hit_3.wav',
        'orbitfall/sfx_hit_1.wav',
      ]);
    });

    test('headroom: SFX at 0.8, music stays at 0.35', () async {
      expect(kSfxVolume, 0.8);
      expect(kMusicVolume, 0.35);
      final h = await _ready();
      h.service.play(SfxKey.shoot);
      h.service.play(SfxKey.wall);
      h.service.onUserInteraction();
      expect(h.backend.sfxVolumes, [kSfxVolume, kSfxVolume]);
      expect(h.backend.calls.single, endsWith('@$kMusicVolume'));
    });

    test('no sfx while the app is in the background', () async {
      final h = await _ready();
      await h.service.setBackgrounded(true);
      expect(h.service.play(SfxKey.shoot), isFalse);
    });
  });

  group('music', () {
    test('starts only after the first interaction, once, at 0.35', () async {
      final h = await _ready();
      expect(h.backend.calls, isEmpty);
      h.service.onUserInteraction();
      h.service.onUserInteraction();
      expect(h.backend.calls, ['play:orbitfall/music_loop.wav@$kMusicVolume']);
      expect(h.service.musicPlaying, isTrue);
    });

    test('music_on off: never starts; turning it on later starts from the top', () async {
      final h = await _ready();
      h.music = false;
      h.service.onUserInteraction();
      expect(h.backend.calls, isEmpty);
      h.music = true;
      await h.service.onMusicSettingChanged();
      expect(h.backend.calls, ['play:orbitfall/music_loop.wav@$kMusicVolume']);
      h.music = false;
      await h.service.onMusicSettingChanged();
      expect(h.backend.calls.last, 'stop');
    });

    test('pauses in the background and resumes in the foreground', () async {
      final h = await _ready();
      h.service.onUserInteraction();
      await h.service.setBackgrounded(true);
      await h.service.setBackgrounded(true);
      await h.service.setBackgrounded(false);
      expect(h.backend.calls.skip(1), ['pause', 'resume']);
    });

    test('Ink & Paper preloads its own set', () async {
      final h = await _ready();
      expect(h.backend.preloads.single, contains('orbitfall/music_loop.wav'));
      h.service.onUserInteraction();
      await h.service.setTheme(inkPaperTheme.sounds);
      expect(h.backend.preloads, hasLength(2));
      expect(h.backend.preloads.last, inkPaperSounds.sfxFiles + [inkPaperSounds.music]);
      expect(h.backend.preloads.last.every((f) => f.startsWith('inkpaper/')), isTrue);
    });

    test('Candy Burst preloads its own set and switches the track', () async {
      final h = await _ready();
      h.service.onUserInteraction();
      await h.service.setTheme(candyBurstTheme.sounds);
      expect(h.backend.preloads, hasLength(2));
      expect(h.backend.preloads.last, candyBurstSounds.sfxFiles + [candyBurstSounds.music]);
      expect(h.backend.preloads.last.every((f) => f.startsWith('candyburst/')), isTrue);
      expect(h.backend.calls.last, 'play:candyburst/music_loop.wav@$kMusicVolume');
      expect(h.service.play(SfxKey.hit), isTrue);
      expect(h.backend.sfx.last, 'candyburst/sfx_hit_1.wav');
    });

    test('a different sound set is preloaded and its music played', () async {
      final h = await _ready();
      h.service.onUserInteraction();
      const other = ThemeSounds(
        music: 'other/music_loop.wav',
        sfx: {SfxKey.shoot: ['other/sfx_shoot.wav']},
        durationsMs: {'other/sfx_shoot.wav': 60},
      );
      await h.service.setTheme(other);
      expect(h.backend.preloads.last, ['other/sfx_shoot.wav', 'other/music_loop.wav']);
      expect(h.backend.calls.last, 'play:other/music_loop.wav@$kMusicVolume');
    });
  });

  group('flight end', () {
    test('only hit and wall are flight sounds; the rest are never cut', () async {
      final h = await _ready();
      for (final key in SfxKey.values) {
        h.now += 1000;
        expect(h.service.play(key), isTrue, reason: '$key');
        expect(h.backend.flightSounds.last, key == SfxKey.hit || key == SfxKey.wall,
            reason: '$key');
      }
    });

    test('endFlight asks the backend to cut flight sounds; later sounds still play', () async {
      final h = await _ready();
      expect(h.service.play(SfxKey.hit), isTrue);
      h.service.endFlight();
      expect(h.backend.cuts, 1);
      // Toplama ve satır sesleri uçuş sonunda çalar, kesilmez.
      expect(h.service.play(SfxKey.collect), isTrue);
      expect(h.backend.flightSounds.last, isFalse);
      // Yeni uçuşun vuruşları normal çalar (50 ms kuralı aynen).
      h.now += kSfxMinGapMs;
      expect(h.service.play(SfxKey.hit), isTrue);
      expect(h.backend.flightSounds.last, isTrue);
    });
  });

  group('priority and crowd thinning', () {
    const unimportant = {SfxKey.hit, SfxKey.wall, SfxKey.shoot};

    test('hit, wall and shoot are unimportant; every other key is important', () async {
      final h = await _ready();
      for (final key in SfxKey.values) {
        h.now += 1000;
        expect(h.service.play(key), isTrue, reason: '$key');
        expect(h.backend.important.last, !unimportant.contains(key), reason: '$key');
      }
    });

    test('the sound duration is passed to the backend', () async {
      final h = await _ready();
      expect(h.service.play(SfxKey.hit), isTrue);
      expect(h.backend.durations.last, orbitfallSounds.durationsMs[h.backend.sfx.last]);
    });

    test('$kSfxCrowdBalls+ balls in flight: hit plays at t=0, not at t=60, again at t=100',
        () async {
      final h = await _ready();
      h.service.setCrowd(kSfxCrowdBalls);
      expect(h.service.play(SfxKey.hit), isTrue);
      h.now = 60;
      expect(h.service.play(SfxKey.hit), isFalse);
      h.now = kSfxCrowdMinGapMs;
      expect(h.service.play(SfxKey.hit), isTrue);
      // Duvar da aynı kurala uyar.
      h.now = 1000;
      expect(h.service.play(SfxKey.wall), isTrue);
      h.now = 1060;
      expect(h.service.play(SfxKey.wall), isFalse);
    });

    test('${kSfxCrowdBalls - 1} balls: the PRD 8.1 gap of $kSfxMinGapMs ms is unchanged', () async {
      final h = await _ready();
      h.service.setCrowd(kSfxCrowdBalls - 1);
      expect(h.service.play(SfxKey.hit), isTrue);
      h.now = kSfxMinGapMs - 1;
      expect(h.service.play(SfxKey.hit), isFalse);
      h.now = kSfxMinGapMs;
      expect(h.service.play(SfxKey.hit), isTrue);
    });

    test('in a crowd, break, pickup and star still play every $kSfxMinGapMs ms', () async {
      final h = await _ready();
      h.service.setCrowd(99);
      for (final key in [SfxKey.breakTarget, SfxKey.pickup, SfxKey.star]) {
        h.now += 1000;
        expect(h.service.play(key), isTrue, reason: '$key');
        h.now += kSfxMinGapMs;
        expect(h.service.play(key), isTrue, reason: '$key again after 50 ms');
      }
    });

    test('in a crowd, hit variants still rotate 1-2-3', () async {
      final h = await _ready();
      h.service.setCrowd(99);
      for (var i = 0; i < 6; i++) {
        h.now += 30; // seyreltilen istekler sırayı ilerletmez
        h.service.play(SfxKey.hit);
      }
      final hits = h.backend.sfx.where((f) => f.contains('sfx_hit')).toList();
      expect(hits, ['orbitfall/sfx_hit_1.wav', 'orbitfall/sfx_hit_2.wav']);
    });

    test('at most $kSfxMaxConcurrent sounds at once still holds (PRD 8.1)', () async {
      final h = await _ready();
      h.service.setCrowd(99);
      var played = 0;
      for (final key in SfxKey.values) {
        if (h.service.play(key)) played++;
      }
      expect(played, lessThanOrEqualTo(kSfxMaxConcurrent));
    });
  });
}

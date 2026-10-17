import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/audio_service.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/game_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/audio_service_test.dart' show FakeAudioBackend;

/// Uçuş bitince (son top yere indi, CollectStarted) oyun uçuş seslerini keser;
/// uçuş sırasında kesmez. Simülasyon etkilenmez.
const double _frame = 1 / 60;
const Shot _up = Shot(30, -100);

void main() {
  test('BallGame cuts flight sounds once, when the last ball lands', () async {
    final backend = FakeAudioBackend();
    final audio = AudioService(backend: backend, musicEnabled: () => false, sfxEnabled: () => true);
    final game = BallGame(
      seed: 1,
      audio: audio,
      session: GameSession.forTest(board: Board(), initialBallCount: 3),
    );
    await Future<void>.delayed(Duration.zero); // tema sesleri yüklensin
    expect(game.session.tryShoot(_up), isTrue);
    var cutsWhileFlying = 0;
    for (var i = 0; i < 60 * 30 && game.session.phase != GamePhase.collecting; i++) {
      game.update(_frame);
      if (game.session.phase == GamePhase.firing || game.session.phase == GamePhase.flying) {
        cutsWhileFlying = backend.cuts;
      }
    }
    expect(game.session.phase, GamePhase.collecting);
    expect(cutsWhileFlying, 0, reason: 'no cut during the flight');
    expect(backend.cuts, 1, reason: 'one cut when the last ball landed');
    expect(backend.sfx.where((f) => f.contains('sfx_wall') || f.contains('sfx_hit')), isNotEmpty);
  });

  test('BallGame passes the number of balls in flight: walls are thinned in a crowd', () async {
    final backend = FakeAudioBackend();
    var now = 0;
    final audio = AudioService(
      backend: backend,
      musicEnabled: () => false,
      sfxEnabled: () => true,
      nowMs: () => now,
    );
    final game = BallGame(
      seed: 1,
      audio: audio,
      session: GameSession.forTest(board: Board(), initialBallCount: 60),
    );
    await Future<void>.delayed(Duration.zero);
    expect(game.session.tryShoot(const Shot(100, -60)), isTrue);
    final wallTimes = <int>[];
    var crowdSeen = false;
    for (var i = 0; i < 60 * 30 && game.session.phase != GamePhase.collecting; i++) {
      now += 16;
      final before = backend.sfx.length;
      game.update(_frame);
      final crowd = game.session.simulation.flyingCount >= kSfxCrowdBalls;
      crowdSeen |= crowd;
      for (final f in backend.sfx.sublist(before)) {
        if (crowd && f.contains('sfx_wall')) wallTimes.add(now);
      }
    }
    expect(crowdSeen, isTrue, reason: 'the shot builds a crowd');
    expect(wallTimes.length, greaterThan(2));
    for (var i = 1; i < wallTimes.length; i++) {
      expect(wallTimes[i] - wallTimes[i - 1], greaterThanOrEqualTo(kSfxCrowdMinGapMs - 16),
          reason: 'wall sounds ≥ ~100 ms apart in a crowd');
    }
  });
}


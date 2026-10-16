import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/audio_service.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:balls_99/game_view/effects/effects_controller.dart';
import 'package:balls_99/game_view/game_loop.dart';
import 'package:balls_99/themes/candyburst/candyburst_theme.dart';
import 'package:balls_99/themes/game_theme.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/placeholder/placeholder_themes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/audio_service_test.dart' show FakeAudioBackend;
import '../../game_core/game_script.dart';

void _expectPoolsWithinCapacity(EffectsController e) {
  expect(e.sparks.liveCount, lessThanOrEqualTo(kParticlePool));
  expect(e.breaks.liveCount, lessThanOrEqualTo(kBreakAnimPool));
  expect(e.pops.liveCount, lessThanOrEqualTo(kPopAnimPool));
  expect(e.texts.liveCount, lessThanOrEqualTo(kFloatTextPool));
}

void main() {
  group('event → effect and sound', () {
    late EffectsController effects;
    final board = Board();
    setUp(() => effects = EffectsController(theme: orbitfallTheme)..beginFrame());

    test('sound keys', () {
      expect(effects.onEvent(const BallLaunched(0, 0), board), SfxKey.shoot);
      expect(effects.onEvent(const WallHit(0, 0, WallSide.left), board), SfxKey.wall);
      expect(effects.onEvent(const TargetHit(0, 0, 2, 3, 4), board), SfxKey.hit);
      expect(effects.onEvent(const TargetHit(0, 0, 2, 3, 0), board), isNull,
          reason: 'destroy plays break instead');
      expect(effects.onEvent(const TargetDestroyed(0, 0, 2, 3), board), SfxKey.breakTarget);
      expect(effects.onEvent(const PickupCollected(0, 0, 1, 1, PickupKind.ring), board),
          SfxKey.pickup);
      expect(effects.onEvent(const PickupCollected(0, 0, 1, 2, PickupKind.star), board),
          SfxKey.star);
      expect(effects.onEvent(const CollectStarted(0), board), SfxKey.collect);
      expect(effects.onEvent(const RowAdvanced(0, 2), board), SfxKey.advance);
      expect(effects.onEvent(const GameOver(0, 5), board), SfxKey.gameOver);
      expect(effects.onEvent(const BallLanded(0, 0, 10), board), isNull);
      expect(effects.onEvent(const PickupExpired(0, 1, PickupKind.ring), board), isNull);
    });

    test('hit pulses the target 1 → 1.12 → 1', () {
      effects.onEvent(const TargetHit(0, 0, 2, 3, 4), board);
      effects.update(kHitPulseSec / 2, danger: false);
      expect(effects.pulseScale(2, 3), closeTo(kHitPulseScale, 1e-3));
      expect(effects.pulseScale(2, 4), 1);
      effects.update(kHitPulseSec, danger: false);
      expect(effects.pulseScale(2, 3), 1);
    });

    test('destroy spawns the coin-flip animation and sparks', () {
      effects.onEvent(const TargetDestroyed(0, 0, 2, 3), board);
      expect(effects.breaks.liveCount, 1);
      expect(effects.sparks.liveCount, orbitfallEffects.breakSparks);
    });

    test('ring: pop + 8 sparks; star: pop + "+3" text + sparks', () {
      effects.onEvent(const PickupCollected(0, 0, 1, 1, PickupKind.ring), board);
      expect(effects.pops.liveCount, 1);
      expect(effects.sparks.liveCount, 8);
      effects.onEvent(const PickupCollected(0, 0, 1, 2, PickupKind.star), board);
      expect(effects.pops.liveCount, 2);
      expect(effects.texts.liveCount, 1);
      expect(effects.texts.value.contains(kStarScore), isTrue);
    });

    test('game over: a shock ring per target in the end row', () {
      final over = Board()
        ..setCell(kGameOverRow, 1, const TargetCell(5))
        ..setCell(kGameOverRow, 4, const TargetCell(9));
      effects.onEvent(const GameOver(0, 5), over);
      expect(effects.pops.liveCount, 2);
    });

    test('row advance starts the sweep and score pulse; danger breathes', () {
      effects.onEvent(const RowAdvanced(0, 2), board);
      effects.update(kAdvanceSweepSec / 2, danger: true);
      expect(effects.sweep, closeTo(0.5, 1e-6));
      expect(effects.scoreScale, greaterThan(1));
      effects.update(kDangerPulseSec / 2 - kAdvanceSweepSec / 2, danger: true);
      expect(effects.dangerGlow, closeTo(1, 1e-6));
      effects.update(kAdvanceSweepSec, danger: false);
      expect(effects.sweep, -1);
      expect(effects.dangerGlow, 0);
    });
  });

  group('per-frame budget (fast forward event storms)', () {
    test('caps new sparks and animations per frame; budget resets next frame', () {
      final effects = EffectsController(theme: orbitfallTheme)..beginFrame();
      final board = Board();
      for (var i = 0; i < 100; i++) {
        effects.onEvent(TargetDestroyed(0, 0, i % kBoardRows, i % kCols), board);
      }
      expect(effects.sparksThisFrame, kMaxSparksPerFrame);
      expect(effects.animsThisFrame, kMaxAnimsPerFrame);
      expect(effects.breaks.liveCount, kMaxAnimsPerFrame);
      _expectPoolsWithinCapacity(effects);
      effects.beginFrame();
      expect(effects.sparksThisFrame, 0);
      effects.onEvent(const TargetDestroyed(0, 0, 0, 0), board);
      expect(effects.animsThisFrame, 1);
    });

    test('32 steps in one frame: ≤ kSfxMaxConcurrent sounds, pools within limits', () {
      // 99 top, yataya yakın atış, boş tahta: toplar duvarlar arasında sekerek
      // ~11 sn tırmanır ve iner (flying > kFastForwardAfter + rampa → 4x).
      // Her karede onlarca duvar olayı ve iniş gelir.
      final session = GameSession.forTest(board: Board(), initialBallCount: kMaxBalls);
      final loop = GameLoop();
      final effects = EffectsController(theme: orbitfallTheme);
      final backend = FakeAudioBackend();
      var wallMs = 0;
      final audio = AudioService(
        backend: backend,
        musicEnabled: () => false,
        sfxEnabled: () => true,
        nowMs: () => wallMs,
      );
      audio.setTheme(orbitfallSounds);
      expect(session.tryShoot(const Shot(1000, -90)), isTrue);
      loop.noteShot();

      // Yavaş cihaz: 1/15 sn'lik kareler → normalde 8, 4x'te 32 adım.
      const dt = 1 / 15;
      final frameMs = (dt * Duration.millisecondsPerSecond).round();
      var maxSteps = 0;
      for (var frame = 0; frame < 2000 && session.phase != GamePhase.ready; frame++) {
        effects.beginFrame();
        final before = backend.sfx.length;
        final steps = loop.advance(session, dt);
        if (steps > maxSteps) maxSteps = steps;
        for (final event in session.drainEvents()) {
          final key = effects.onEvent(event, session.board);
          if (key != null) audio.play(key);
        }
        effects.update(dt, danger: false);
        expect(backend.sfx.length - before, lessThanOrEqualTo(kSfxMaxConcurrent),
            reason: 'frame $frame ($steps steps)');
        expect(effects.sparksThisFrame, lessThanOrEqualTo(kMaxSparksPerFrame));
        expect(effects.animsThisFrame, lessThanOrEqualTo(kMaxAnimsPerFrame));
        _expectPoolsWithinCapacity(effects);
        wallMs += frameMs;
      }
      expect(maxSteps, kMaxStepsPerFrameFast, reason: 'a 32-step frame happened');
    });
  });

  group('theme sparks', () {
    final board = Board();
    Set<int> liveColors(EffectsController e) => {
          for (var i = 0; i < e.sparks.capacity; i++)
            if (e.sparks.isAlive(i)) e.sparks.color[i],
        };
    final confetti = candyBurstConfetti.map((c) => c.toARGB32()).toSet();

    test('Orbitfall: single-colour hit sparks (no confetti)', () {
      final e = EffectsController(theme: orbitfallTheme)..beginFrame();
      e.onEvent(const TargetHit(0, 0, 2, 3, 4), board);
      expect(liveColors(e), {orbitfallPalette.spark.toARGB32()});
    });

    test('Candy Burst: hit sparks are confetti colours', () {
      final e = EffectsController(theme: candyBurstTheme)..beginFrame();
      e.onEvent(const TargetHit(0, 0, 2, 3, 4), board);
      expect(e.sparks.liveCount, candyBurstEffects.hitSparks);
      expect(confetti.containsAll(liveColors(e)), isTrue);
    });

    test('Candy Burst: break sparks alternate candy (HP) colour and confetti', () {
      final e = EffectsController(theme: candyBurstTheme)..beginFrame();
      e.onEvent(const TargetDestroyed(0, 0, 2, 3), board);
      expect(e.sparks.liveCount, candyBurstEffects.breakSparks);
      final hpColor = candyBurstTheme.hpRamp.forHp(1).toARGB32();
      for (var i = 0; i < candyBurstEffects.breakSparks; i++) {
        final color = e.sparks.color[i];
        if (i.isEven) {
          expect(color, hpColor, reason: 'spark $i');
        } else {
          expect(confetti, contains(color), reason: 'spark $i');
        }
      }
    });

    test('theme switch mid-game uses the new effect set', () {
      final e = EffectsController(theme: orbitfallTheme)..beginFrame();
      e.theme = candyBurstTheme;
      e.onEvent(const TargetHit(0, 0, 2, 3, 4), board);
      expect(confetti.containsAll(liveColors(e)), isTrue);
    });
  });

  test('effects and sounds never change core state, whatever the theme', () {
    List<int> run(GameTheme? theme) {
      final hashes = <int>[];
      final effects = theme == null ? null : EffectsController(theme: theme);
      final audio = AudioService(
        backend: FakeAudioBackend(),
        musicEnabled: () => true,
        sfxEnabled: () => true,
        nowMs: () => hashes.length,
      );
      if (theme != null) audio.setTheme(theme.sounds);
      playScripted(20261016, onStep: (s) {
        hashes.add(s.stateHash());
      }, onEvents: (events, s) {
        if (effects == null) return;
        effects.beginFrame();
        for (final e in events) {
          final key = effects.onEvent(e, s.board);
          if (key != null) audio.play(key);
        }
        effects.update(1 / kStepsPerSec, danger: s.board.hasTargetInRow(kPlayableRows - 1));
      });
      return hashes;
    }

    final none = run(null);
    expect(none.length, greaterThan(1000));
    expect(run(orbitfallTheme), none);
    expect(run(candyBurstTheme), none);
    expect(run(inkPaperTheme), none);
  });
}

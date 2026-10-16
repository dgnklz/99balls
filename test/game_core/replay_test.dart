import 'dart:convert';

import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/replay/replay_runner.dart';
import 'package:balls_99/game_core/replay/shot_log.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_script.dart';

/// PRD Bölüm 11.8.
const int _seed = 777;

void main() {
  late GameSession recorded;
  late String encoded;

  setUpAll(() {
    recorded = playScripted(_seed);
    encoded = encodeShots(recorded.shots);
  });

  ReplayRejection? verify(String data, int score, {int seed = _seed}) =>
      verifyReplay(seed: seed, encoded: data, claimedScore: score).rejection;

  test('recorded game ends in gameOver with several shots', () {
    expect(recorded.phase, GamePhase.gameOver);
    expect(recorded.shots.length, greaterThan(3));
  });

  test('encode/decode round-trips', () {
    expect(decodeShots(encoded), recorded.shots);
  });

  test('negative and large components round-trip', () {
    const shots = [ShotRecord(0, -123456, -1), ShotRecord(5000, 99999, -654321)];
    expect(decodeShots(encodeShots(shots)), shots);
  });

  test('replaying a recorded game reproduces the score', () {
    final verdict =
        verifyReplay(seed: _seed, encoded: encoded, claimedScore: recorded.score);
    expect(verdict.isValid, isTrue, reason: '$verdict');
    expect(verdict.replayedScore, recorded.score);
  });

  test('tampered score is rejected', () {
    expect(verify(encoded, recorded.score + 1), ReplayRejection.scoreMismatch);
  });

  test('wrong seed does not reproduce the game', () {
    expect(verify(encoded, recorded.score, seed: _seed + 1), isNotNull);
  });

  group('malformed input is rejected', () {
    List<int> bytes() => base64Decode(encodeShots(recorded.shots));

    test('invalid base64', () {
      expect(verify('!!not base64!!', 1), ReplayRejection.malformed);
    });

    test('wrong version', () {
      final b = bytes()..[0] = kReplayFormatVersion + 1;
      expect(verify(base64Encode(b), 1), ReplayRejection.malformed);
    });

    test('truncated', () {
      final b = bytes();
      expect(verify(base64Encode(b.sublist(0, b.length - 1)), 1),
          ReplayRejection.malformed);
    });

    test('trailing bytes', () {
      expect(verify(base64Encode([...bytes(), 0]), 1), ReplayRejection.malformed);
    });

    test('over-long varint', () {
      final b = [kReplayFormatVersion, ...List.filled(11, 0xFF), 0];
      expect(verify(base64Encode(b), 1), ReplayRejection.malformed);
    });

    test('larger than kReplayMaxBytes', () {
      expect(verify('A' * (kReplayMaxBytes + 4), 1), ReplayRejection.tooLarge);
      expect(() => decodeShots('A' * (kReplayMaxBytes + 4)),
          throwsA(isA<ReplayFormatException>()));
    });
  });

  group('plausibility limits', () {
    test('no shots', () {
      expect(verify(encodeShots(const []), 1), ReplayRejection.noShots);
    });

    test('score above kMaxPlausibleScore', () {
      expect(verify(encoded, kMaxPlausibleScore + 1), ReplayRejection.implausibleScore);
    });

    test('shots closer than 17 steps', () {
      const shots = [ShotRecord(0, 0, -100), ShotRecord(kLaunchIntervalSteps - 1, 0, -100)];
      expect(verify(encodeShots(shots), 1), ReplayRejection.shotIntervalTooShort);
    });

    test('invalid direction', () {
      expect(verify(encodeShots(const [ShotRecord(0, 100, 50)]), 1),
          ReplayRejection.invalidShot);
    });

    test('shot while the previous one is still in the air', () {
      final shots = [...recorded.shots];
      shots[1] = ShotRecord(shots[0].step + kLaunchIntervalSteps, shots[1].vx, shots[1].vy);
      expect(verify(encodeShots(shots), recorded.score), ReplayRejection.shotNotReady);
    });

    test('game that did not end', () {
      final shots = recorded.shots.take(1).toList();
      expect(verify(encodeShots(shots), 2), ReplayRejection.notFinished);
    });
  });

  test('idle time in ready does not change the result', () {
    // Her atışı 1000 adım geç yap: tahta aynı kalmalı, skor değişmemeli.
    final delayed = [
      for (var i = 0; i < recorded.shots.length; i++)
        ShotRecord(recorded.shots[i].step + 1000 * (i + 1), recorded.shots[i].vx,
            recorded.shots[i].vy),
    ];
    final verdict = verifyReplay(
        seed: _seed, encoded: encodeShots(delayed), claimedScore: recorded.score);
    expect(verdict.isValid, isTrue, reason: '$verdict');
  });
}

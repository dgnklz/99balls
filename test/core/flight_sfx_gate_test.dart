import 'dart:async';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/core/services/flight_sfx_gate.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sahte başlatma: tamamlanınca bir durdurma işlevi verir; durdurulup
/// durdurulmadığı izlenir.
class _FakeStart {
  final Completer<StopSfx> _completer = Completer<StopSfx>();
  int stops = 0;

  Future<StopSfx> get future => _completer.future;

  void begin() => _completer.complete(() async => stops++);

  void fail() => _completer.completeError(StateError('platform'));
}

const int _hitMs = 110;

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late int now;
  late FlightSfxGate gate;

  setUp(() {
    now = 0;
    gate = FlightSfxGate(nowMs: () => now);
  });

  _FakeStart track({bool flightSound = true}) {
    final s = _FakeStart();
    gate.track(s.future, flightSound: flightSound, durationMs: _hitMs);
    return s;
  }

  test('a flight sound still playing is stopped when the flight ends', () async {
    final hit = track()..begin();
    await _flush();
    expect(gate.cut(), 1);
    await _flush();
    expect(hit.stops, 1);
  });

  test('non-flight sounds (break, pickup, star, advance …) are never cut', () async {
    final other = track(flightSound: false)..begin();
    await _flush();
    expect(gate.cut(), 0);
    await _flush();
    expect(other.stops, 0);
  });

  test('every start of the ended flight that completes later is stopped at once', () async {
    // Takip sınırı yok: 100 bekleyen başlatmanın hepsi.
    final late = [for (var i = 0; i < 100; i++) track()];
    gate.cut();
    for (final s in late) {
      s.begin();
    }
    await _flush();
    expect(late.every((s) => s.stops == 1), isTrue);
    expect(gate.lateStopped, 100);
  });

  test('sounds that already ended are not stopped (their player may be reused)', () async {
    final old = track()..begin();
    await _flush();
    now += _hitMs + kSfxFlightStopMarginMs;
    final recent = track()..begin();
    await _flush();
    expect(gate.cut(), 1);
    await _flush();
    expect(old.stops, 0);
    expect(recent.stops, 1);
  });

  test('the next flight is not affected by the previous cut', () async {
    gate.cut();
    final next = track()..begin();
    await _flush();
    expect(next.stops, 0, reason: 'new flight plays');
    expect(gate.cut(), 1, reason: 'cut at the end of its own flight');
    await _flush();
    expect(next.stops, 1);
  });

  test('onSettled reports once the ended flight\'s last start completed', () async {
    final a = track();
    final b = track();
    int? reported;
    gate.cut(onSettled: (late) => reported = late);
    a.begin();
    await _flush();
    expect(reported, isNull, reason: 'one start still pending');
    b.fail();
    await _flush();
    expect(reported, 1, reason: 'a was stopped late; b failed');

    int? immediate;
    gate.cut(onSettled: (late) => immediate = late);
    expect(immediate, 0, reason: 'nothing pending: reported at once');
  });
}

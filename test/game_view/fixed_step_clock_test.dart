import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_view/fixed_step_clock.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD 2.3 (sabit adım, karede en fazla 8) ve 10.2 (ilk karede dt ≤ 1/30).
void main() {
  test('60 Hz frame runs 2 steps, 120 Hz runs 1', () {
    final clock = FixedStepClock();
    expect(clock.consume(1 / 60), 2);
    for (var i = 0; i < 100; i++) {
      expect(clock.consume(1 / 60), 2);
    }
    final fast = FixedStepClock();
    for (var i = 0; i < 100; i++) {
      expect(fast.consume(1 / 120), 1);
    }
  });

  test('90 Hz frames accumulate to the right number of steps', () {
    final clock = FixedStepClock();
    var total = 0;
    for (var i = 0; i < 90; i++) {
      final steps = clock.consume(1 / 90);
      expect(steps, anyOf(1, 2));
      total += steps;
    }
    expect(total, inInclusiveRange(119, 120));
  });

  test('first frame dt is capped at 1/30 s', () {
    final clock = FixedStepClock();
    expect(clock.consume(5.0), 4);
    expect(kFirstFrameMaxDt, 1 / 30);
  });

  test('at most 8 steps per frame; the excess is dropped', () {
    final clock = FixedStepClock()..consume(0);
    expect(clock.consume(1.0), kMaxStepsPerFrame);
    expect(clock.alpha, 0);
    expect(clock.consume(1 / 120), 1);
  });

  test('reset caps the next frame again (time in background is not added)', () {
    final clock = FixedStepClock()..consume(1 / 60);
    clock.reset();
    expect(clock.consume(60.0), 4);
  });

  test('alpha is the fraction of a step since the last step', () {
    final clock = FixedStepClock();
    expect(clock.consume(1 / 240), 0);
    expect(clock.alpha, closeTo(0.5, 1e-9));
    expect(clock.consume(1 / 240), 1);
    expect(clock.alpha, closeTo(0, 1e-6));
    for (var i = 0; i < 50; i++) {
      clock.consume(1 / 75);
      expect(clock.alpha, inInclusiveRange(0, 1));
      expect(clock.alpha, lessThan(1));
    }
  });

  test('negative dt is treated as zero', () {
    final clock = FixedStepClock();
    expect(clock.consume(-1), 0);
    expect(clock.alpha, 0);
  });
}

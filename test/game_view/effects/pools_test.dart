import 'dart:math' as math;

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_view/effects/anim_pools.dart';
import 'package:balls_99/game_view/effects/particle_pool.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ayrı, sabit kapasiteli havuzlar; doluyken en eskisi yeniden kullanılır.
void main() {
  group('SparkPool (kParticlePool, yalnızca kıvılcımlar)', () {
    test('never holds more than its capacity', () {
      final pool = SparkPool(kParticlePool);
      for (var i = 0; i < 1000; i++) {
        pool.spawn(x: 0, y: 0, vx: 1, vy: 0, life: 10, size: kSparkSize, color: 0);
        expect(pool.liveCount, lessThanOrEqualTo(kParticlePool));
      }
      expect(pool.liveCount, kParticlePool);
    });

    test('when full the oldest slot is reused', () {
      final pool = SparkPool(kParticlePool);
      for (var i = 0; i < kParticlePool; i++) {
        pool.spawn(x: i.toDouble(), y: 0, vx: 0, vy: 0, life: 10, size: 1, color: 0);
      }
      pool.spawn(x: 999, y: 0, vx: 0, vy: 0, life: 10, size: 1, color: 0);
      expect(pool.x[0], 999, reason: 'oldest (first) slot overwritten');
      expect(pool.x[1], 1, reason: 'others intact');
      expect(pool.liveCount, kParticlePool);
    });

    test('speed falls linearly to zero and the spark dies after its life', () {
      final pool = SparkPool(4)
        ..spawn(x: 0, y: 0, vx: kSparkSpeed, vy: 0, life: kSparkLife, size: 1, color: 0);
      const steps = 100;
      for (var i = 0; i < steps; i++) {
        pool.update(kSparkLife / steps);
      }
      // ∫ v0·(1 − t/T) dt = v0·T/2
      expect(pool.x[0], closeTo(kSparkSpeed * kSparkLife / 2, 0.5));
      expect(pool.isAlive(0), isFalse);
      pool.clear();
      expect(pool.liveCount, 0);
    });
  });

  group('BreakPool (7.2.1 madeni para dönüşü)', () {
    test('formulas', () {
      expect(BreakPool.scaleY(0), closeTo(1, 1e-9));
      expect(BreakPool.scaleY(1 / 3), closeTo(0, 1e-9));
      expect(BreakPool.scaleY(2 / 3), closeTo(1, 1e-9));
      expect(BreakPool.scaleX(0.5), closeTo(1 + kBreakWobbleX, 1e-9));
      expect(BreakPool.rotation(1), closeTo(kBreakRotation, 1e-9));
      expect(BreakPool.opacity(0.25), 1);
      expect(BreakPool.opacity(0.75), closeTo(0.5, 1e-9));
      expect(BreakPool.opacity(1), 0);
      expect(BreakPool.offsetY(0.5), closeTo(kBreakGravity * 0.125, 1e-9));
      expect(BreakPool.offsetX(1, -1), -kBreakDriftSpeed);
      expect(BreakPool.scaleY(0.5), closeTo(math.cos(0.75 * math.pi).abs(), 1e-9));
    });

    test('capacity 56, reuses oldest, expires after 0.7 s', () {
      final pool = BreakPool(kBreakAnimPool);
      expect(kBreakAnimPool, 56);
      for (var i = 0; i < 200; i++) {
        pool.spawn(i.toDouble(), 0, 1, 0);
      }
      expect(pool.liveCount, kBreakAnimPool);
      pool.update(kBreakAnimSec);
      expect(pool.liveCount, 0);
    });
  });

  group('PopPool and FloatTextPool', () {
    test('separate capacities 16 and 8, oldest reused', () {
      final pops = PopPool(kPopAnimPool);
      final texts = FloatTextPool(kFloatTextPool);
      for (var i = 0; i < 100; i++) {
        pops.spawn(0, 0, PopKind.ring);
        texts.spawn(0, 0, i);
      }
      expect(pops.liveCount, kPopAnimPool);
      expect(texts.liveCount, kFloatTextPool);
      expect(texts.value[0], 96, reason: 'slot 0 last written by spawn #96');
    });

    test('durations: pop 0.25 s, shock 0.45 s, text 0.6 s', () {
      final pops = PopPool(2)
        ..spawn(0, 0, PopKind.ring)
        ..spawn(0, 0, PopKind.shock);
      pops.update(kPopSec);
      expect(pops.isAlive(0), isFalse);
      expect(pops.isAlive(1), isTrue);
      expect(pops.kindOf(1), PopKind.shock);
      pops.update(kShockSec);
      expect(pops.liveCount, 0);

      final texts = FloatTextPool(1)..spawn(0, 0, 3);
      texts.update(kFloatTextSec / 2);
      expect(texts.progress(0), closeTo(0.5, 1e-6));
    });
  });
}

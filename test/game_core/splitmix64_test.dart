import 'package:balls_99/game_core/engine/rng.dart';
import 'package:flutter_test/flutter_test.dart';

/// Referans C uygulamasının (Vigna, splitmix64.c) çıktıları (PRD 14.1).
/// Dart int 64-bit işaretli olduğundan üst biti set olanlar negatif görünür;
/// hex literal'ler aynı bit desenini verir.
const Map<int, List<int>> _referenceOutputs = {
  0: [
    0xE220A8397B1DCDAF,
    0x6E789E6AA1B965F4,
    0x06C45D188009454F,
    0xF88BB8A8724C81EC,
    0x1B39896A51A8749B,
    0x53CB9F0C747EA2EA,
    0x2C829ABE1F4532E1,
    0xC584133AC916AB3C,
    0x3EE5789041C98AC3,
    0xF3B8488C368CB0A6,
  ],
  1234567: [
    0x599ED017FB08FC85,
    0x2C73F08458540FA5,
    0x883EBCE5A3F27C77,
    0x3FBEF740E9177B3F,
    0xE3B8346708CB5ECD,
    0x6C4F7DBC989944F6,
    0x9734AED70F5D5E85,
    0x46793DD6F7DF31B1,
    0x70133CC588722B30,
    0xD194599C46D4951C,
  ],
};

void main() {
  group('SplitMix64', () {
    for (final entry in _referenceOutputs.entries) {
      test('first 10 outputs for seed ${entry.key} match reference', () {
        final rng = SplitMix64(entry.key);
        final actual = List.generate(10, (_) => rng.next());
        expect(actual, entry.value);
      });
    }

    test('same seed yields same sequence', () {
      final a = SplitMix64(987654321);
      final b = SplitMix64(987654321);
      for (var i = 0; i < 1000; i++) {
        expect(a.next(), b.next());
      }
    });

    test('nextInt uses the upper 31 bits of next()', () {
      final raw = SplitMix64(42);
      final ints = SplitMix64(42);
      for (final bound in [1, 2, 3, 7, 100, 1 << 20]) {
        expect(ints.nextInt(bound), (raw.next() >>> 33) % bound);
      }
    });

    test('nextInt stays within 0..bound-1', () {
      final rng = SplitMix64(-1);
      for (final bound in [1, 2, 3, 7, 100]) {
        for (var i = 0; i < 2000; i++) {
          final v = rng.nextInt(bound);
          expect(v, inInclusiveRange(0, bound - 1));
        }
      }
    });
  });
}

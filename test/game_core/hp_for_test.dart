import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/rules/hp_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// PRD Bölüm 6.2 doğrulama tablosu: T → [m2=2, m2=3, m2=4].
const Map<int, List<int>> _table = {
  1: [1, 2, 2],
  3: [3, 4, 6],
  7: [7, 10, 14],
  9: [9, 14, 18],
  13: [13, 20, 26],
  15: [15, 22, 30],
  17: [17, 26, 34],
  18: [18, 27, 36],
  21: [21, 32, 42],
};

void main() {
  group('hpFor', () {
    for (final entry in _table.entries) {
      test('T=${entry.key} matches PRD table', () {
        final actual = [for (final m2 in kMultipliersM2) hpFor(entry.key, m2)];
        expect(actual, entry.value);
      });
    }

    test('is round-half-to-even of t*m2/2 for all t in 1..$kMaxBalls', () {
      for (var t = 1; t <= kMaxBalls; t++) {
        for (final m2 in kMultipliersM2) {
          final twice = t * m2; // 2 × gerçek değer
          final hp = hpFor(t, m2);
          // En yakın tamsayı: |2·hp − t·m2| ≤ 1.
          expect((2 * hp - twice).abs(), lessThanOrEqualTo(1),
              reason: 't=$t m2=$m2 hp=$hp');
          // Tam yarımda çift sayı seçilir.
          if (twice.isOdd) {
            expect(hp.isEven, isTrue, reason: 't=$t m2=$m2 hp=$hp');
          }
        }
      }
    });

    test('maximum HP is 2 × kMaxBalls', () {
      expect(hpFor(kMaxBalls, kMultipliersM2.last), 2 * kMaxBalls);
    });
  });
}

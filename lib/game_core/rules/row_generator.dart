import '../constants.dart';
import '../engine/rng.dart';
import '../model/cell.dart';
import '../model/pickup.dart';
import 'hp_rules.dart';

/// Üretilmiş tek bir satır: [kCols] hücre, boş hücre `null`.
class GeneratedRow {
  final List<Cell?> cells;

  GeneratedRow(List<Cell?> cells) : cells = List.unmodifiable(cells);

  @override
  String toString() => 'GeneratedRow($cells)';
}

/// Satır üreticisi (PRD Bölüm 6.1 ve 5.11).
///
/// Çekim sırası sabittir ve değiştirilmez: k → halka → Fisher–Yates →
/// çarpanlar (top sütunları soldan sağa) → yıldız. İlk tahtada halka ve
/// yıldız çekimi yapılmaz. Yıldız çekimi, olasılık 0 olsa bile bir sayı tüketir.
class RowGenerator {
  final SplitMix64 _rng;
  /// Yıldız olasılığı (yüzde). Testlerde 0 verilebilir.
  final int starChancePct;

  RowGenerator(this._rng, {this.starChancePct = kStarChancePct});

  /// Oyunun ilk satırı: T = [kStartBalls], halka ve yıldız yok.
  GeneratedRow initialRow() => _generate(kStartBalls, isInitial: true);

  /// [t] = o andaki top sayısı (bu turun halkaları eklendikten sonra).
  GeneratedRow nextRow(int t) => _generate(t, isInitial: false);

  GeneratedRow _generate(int t, {required bool isInitial}) {
    assert(t >= 1 && t <= kMaxBalls, 't must be in 1..$kMaxBalls, got $t');

    final k = _drawTargetCount();
    final hasRing = !isInitial && _rng.nextInt(kPercentBound) < kRingChancePct;
    final shuffled = _shuffledColumns();

    final cells = List<Cell?>.filled(kCols, null);
    final targetColumns = shuffled.sublist(0, k)..sort();
    for (final col in targetColumns) {
      final m2 = kMultipliersM2[_rng.nextInt(kMultipliersM2.length)];
      cells[col] = TargetCell(hpFor(t, m2));
    }
    if (hasRing) {
      cells[shuffled[k]] = const PickupCell(PickupKind.ring);
    }
    if (!isInitial && _rng.nextInt(kPercentBound) < starChancePct) {
      cells[shuffled[k + (hasRing ? 1 : 0)]] = const PickupCell(PickupKind.star);
    }
    return GeneratedRow(cells);
  }

  /// Ağırlıklı seçim: `nextInt(100)` kümülatif [kBallCountWeights] ile eşlenir.
  int _drawTargetCount() {
    final roll = _rng.nextInt(kPercentBound);
    var cumulative = 0;
    for (var i = 0; i < kBallCountWeights.length; i++) {
      cumulative += kBallCountWeights[i];
      if (roll < cumulative) return kRowTargetCounts[i];
    }
    throw StateError('kBallCountWeights must sum to $kPercentBound');
  }

  /// 0..kCols-1 sütunlarının Fisher–Yates karıştırması (i = kCols-1'den 1'e).
  List<int> _shuffledColumns() {
    final cols = List<int>.generate(kCols, (i) => i);
    for (var i = kCols - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final tmp = cols[i];
      cols[i] = cols[j];
      cols[j] = tmp;
    }
    return cols;
  }
}

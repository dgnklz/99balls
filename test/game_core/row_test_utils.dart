import 'package:balls_99/game_core/model/cell.dart';
import 'package:balls_99/game_core/model/pickup.dart';
import 'package:balls_99/game_core/rules/row_generator.dart';

/// Satırı golden dosyası için metne çevirir: HP sayısı, `R` halka, `S` yıldız,
/// `.` boş; hücreler boşlukla ayrılır. Ör: `". 12 R . 10 S ."`.
String encodeRow(GeneratedRow row) => row.cells.map(encodeCell).join(' ');

String encodeCell(Cell? cell) => switch (cell) {
      null => '.',
      TargetCell(:final hp) => '$hp',
      PickupCell(kind: PickupKind.ring) => 'R',
      PickupCell(kind: PickupKind.star) => 'S',
    };

/// Hücreleri türe göre sayar.
({int targets, int rings, int stars}) countCells(GeneratedRow row) {
  var targets = 0, rings = 0, stars = 0;
  for (final cell in row.cells) {
    switch (cell) {
      case TargetCell():
        targets++;
      case PickupCell(kind: PickupKind.ring):
        rings++;
      case PickupCell(kind: PickupKind.star):
        stars++;
      case null:
        break;
    }
  }
  return (targets: targets, rings: rings, stars: stars);
}

/// Yıldızı boş hücreye çevirerek kopyalar (yıldızsız içerik karşılaştırması için).
List<Cell?> withoutStars(GeneratedRow row) => [
      for (final cell in row.cells)
        cell == const PickupCell(PickupKind.star) ? null : cell,
    ];

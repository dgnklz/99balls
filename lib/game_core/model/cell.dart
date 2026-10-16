import 'pickup.dart';

/// Izgaradaki bir hücrenin içeriği. Boş hücre `null` ile gösterilir.
sealed class Cell {
  const Cell();
}

/// Sayılı top (hedef).
final class TargetCell extends Cell {
  final int hp;

  const TargetCell(this.hp);

  @override
  bool operator ==(Object other) => other is TargetCell && other.hp == hp;

  @override
  int get hashCode => hp.hashCode;

  @override
  String toString() => 'TargetCell($hp)';
}

/// Toplanabilir nesne (halka veya yıldız).
final class PickupCell extends Cell {
  final PickupKind kind;

  const PickupCell(this.kind);

  @override
  bool operator ==(Object other) => other is PickupCell && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'PickupCell(${kind.name})';
}

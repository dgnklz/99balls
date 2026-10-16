import '../model/pickup.dart';

/// Oyun mantığının sunum katmanına (ses, parçacık, titreşim) bildirdiği olaylar
/// (PRD Bölüm 5.3). Oyun mantığı bu olayları yalnızca yazar, okumaz.
sealed class GameEvent {
  /// Olayın gerçekleştiği adım.
  final int step;

  const GameEvent(this.step);
}

final class BallLaunched extends GameEvent {
  final int ballIndex;

  const BallLaunched(super.step, this.ballIndex);
}

enum WallSide { left, right, ceiling }

final class WallHit extends GameEvent {
  final int ballIndex;
  final WallSide side;

  const WallHit(super.step, this.ballIndex, this.side);
}

final class TargetHit extends GameEvent {
  final int ballIndex;
  final int row;
  final int col;
  final int hpLeft;

  const TargetHit(super.step, this.ballIndex, this.row, this.col, this.hpLeft);
}

final class TargetDestroyed extends GameEvent {
  final int ballIndex;
  final int row;
  final int col;

  const TargetDestroyed(super.step, this.ballIndex, this.row, this.col);
}

final class PickupCollected extends GameEvent {
  final int ballIndex;
  final int row;
  final int col;
  final PickupKind kind;

  const PickupCollected(super.step, this.ballIndex, this.row, this.col, this.kind);
}

final class BallLanded extends GameEvent {
  final int ballIndex;
  final double x;

  /// Zaman aşımıyla inmiş sayıldıysa true.
  final bool timedOut;

  const BallLanded(super.step, this.ballIndex, this.x, {this.timedOut = false});
}

final class CollectStarted extends GameEvent {
  const CollectStarted(super.step);
}

final class RowAdvanced extends GameEvent {
  final int round;

  const RowAdvanced(super.step, this.round);
}

/// Toplanmadan oyun bitiş satırına inen halka veya yıldız.
final class PickupExpired extends GameEvent {
  final int col;
  final PickupKind kind;

  const PickupExpired(super.step, this.col, this.kind);
}

final class GameOver extends GameEvent {
  final int score;

  const GameOver(super.step, this.score);
}

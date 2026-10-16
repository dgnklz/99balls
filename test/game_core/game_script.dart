import 'package:balls_99/game_core/engine/aim.dart';
import 'package:balls_99/game_core/engine/events.dart';
import 'package:balls_99/game_core/rules/round_state_machine.dart';

/// Testlerde kullanılan sabit atış dizisi: farklı açılar, duvar ve hedef sekmeleri.
const List<Shot> mixedShots = [
  Shot(-300, -100),
  Shot(250, -400),
  Shot(0, -100),
  Shot(500, -80),
  Shot(-120, -500),
];

/// Oyunu [shots] dizisini döngüyle atarak oynar. Her adımdan sonra o adımın
/// olaylarıyla [onEvents], ardından [onStep] çağrılır. gameOver'a ya da
/// [maxRounds]'a kadar sürer.
GameSession playScripted(
  int seed, {
  GameSession? start,
  List<Shot> shots = mixedShots,
  int maxRounds = 1000,
  void Function(GameSession session)? onStep,
  void Function(List<GameEvent> events, GameSession session)? onEvents,
}) {
  final session = start ?? GameSession(seed);
  var next = 0;
  while (session.phase != GamePhase.gameOver && session.round <= maxRounds) {
    if (session.phase == GamePhase.ready) {
      session.tryShoot(shots[next++ % shots.length]);
    }
    session.step();
    final events = session.drainEvents();
    onEvents?.call(events, session);
    onStep?.call(session);
  }
  return session;
}

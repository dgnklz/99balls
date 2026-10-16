import 'dart:math' show sqrt;

import '../constants.dart';
import '../engine/aim.dart';
import '../engine/events.dart';
import '../engine/rng.dart';
import '../engine/simulation.dart';
import '../engine/state_hash.dart';
import '../model/board.dart';
import '../model/cell.dart';
import '../model/pickup.dart';
import '../replay/shot_log.dart';
import 'row_generator.dart';
import 'scoring.dart';

/// Tur durumları (PRD Bölüm 5.4). Duraklatma bir durum değildir: sunum katmanı
/// [GameSession.step] çağırmayı bırakır.
enum GamePhase { ready, firing, flying, collecting, advancing, gameOver }

/// Tek bir oyunun tüm mantığı. Tohum ve atış dizisi aynıysa her adımda aynı
/// durumu üretir.
///
/// Zaman yalnızca [step] ile ilerler (her çağrı 1/[kStepsPerSec] sn).
/// Toplama ve satır kayma süreleri de adım olarak sayılır, böylece atış
/// kayıtlarındaki adım numarası tek bir saate bağlıdır.
class GameSession {
  final int seed;
  final Board board;
  final RowGenerator _rows;
  final List<GameEvent>? _events;
  late final Simulation _sim = Simulation(board, _events);
  final List<ShotRecord> _shots = [];

  GamePhase _phase = GamePhase.ready;
  int _stepCount = 0;
  int _ballCount;
  int _pendingBalls = 0;
  int _round;
  int _starsCollected = 0;
  double _launchX;

  // Atış (volley) durumu.
  double _dirX = 0;
  double _dirY = 0;
  int _launchTimer = 0;
  int _phaseTimer = 0;

  /// Yeni oyun: tohumdan ilk tahta üretilir (PRD 5.7). [recordEvents] false
  /// ise olay üretilmez (başsız tekrar oynatma).
  GameSession(this.seed, {bool recordEvents = true})
      : board = Board(),
        _rows = RowGenerator(SplitMix64(seed)),
        _events = recordEvents ? <GameEvent>[] : null,
        _ballCount = kStartBalls,
        _round = 1,
        _launchX = kLaunchStartX {
    board.insertRow(_rows.initialRow());
  }

  /// Testler için hazır tahtayla oturum; ilk satır üretilmez.
  GameSession.forTest({
    required this.board,
    this.seed = 0,
    int initialBallCount = kStartBalls,
    int initialRound = 1,
    double initialLaunchX = kLaunchStartX,
    int starChancePct = kStarChancePct,
  })  : _rows = RowGenerator(SplitMix64(seed), starChancePct: starChancePct),
        _events = <GameEvent>[],
        _ballCount = initialBallCount,
        _round = initialRound,
        _launchX = initialLaunchX;

  GamePhase get phase => _phase;

  /// Tamamlanan adım sayısı. Atış kayıtları bu sayıyı kullanır.
  int get stepCount => _stepCount;
  int get ballCount => _ballCount;
  int get pendingBalls => _pendingBalls;
  int get round => _round;
  int get starsCollected => _starsCollected;
  int get score => scoreFor(_round, _starsCollected);
  double get launchX => _launchX;

  /// Topların fiziği (sunum katmanı konumları buradan okur).
  Simulation get simulation => _sim;

  /// Bu oyunda kabul edilen atışlar (adım_no, vx, vy).
  List<ShotRecord> get shots => List.unmodifiable(_shots);

  /// Alt sayaç (PRD 5.5).
  int get counterDisplay => switch (_phase) {
        GamePhase.ready || GamePhase.advancing || GamePhase.gameOver => _ballCount,
        GamePhase.firing => _ballCount - _sim.launchedCount,
        GamePhase.flying || GamePhase.collecting => 0,
      };

  /// Birikmiş olayları döndürür ve kuyruğu boşaltır.
  List<GameEvent> drainEvents() {
    final events = _events;
    if (events == null || events.isEmpty) return const [];
    final drained = List<GameEvent>.of(events);
    events.clear();
    return drained;
  }

  /// Atış yapar. Yalnızca [GamePhase.ready]'de ve geçerli yönde kabul edilir;
  /// aksi halde false döner ve hiçbir şey değişmez (girdi sıraya alınmaz).
  bool tryShoot(Shot shot) {
    if (_phase != GamePhase.ready || !isValidShot(shot)) return false;
    final x = shot.vx.toDouble();
    final y = shot.vy.toDouble();
    final length = sqrt(x * x + y * y);
    _dirX = x / length;
    _dirY = y / length;
    _shots.add(ShotRecord(_stepCount, shot.vx, shot.vy));
    _sim.beginVolley();
    _launchTimer = 0;
    _phase = GamePhase.firing;
    return true;
  }

  /// [ready] durumunda [steps] adım bekler (tekrar oynatmada boş zamanı atlamak için).
  void idle(int steps) {
    if (_phase != GamePhase.ready) {
      throw StateError('idle() is only valid in ready, was $_phase');
    }
    _stepCount += steps;
  }

  /// Bir sabit adım ilerletir.
  void step() {
    if (_phase == GamePhase.gameOver) return;
    _sim.currentStep = _stepCount;
    switch (_phase) {
      case GamePhase.ready:
      case GamePhase.gameOver:
        break;
      case GamePhase.firing:
        if (_launchTimer == 0) {
          final index = _sim.launch(_launchX, kLaunchY, _dirX, _dirY);
          _emit(BallLaunched(_stepCount, index));
          _launchTimer = kLaunchIntervalSteps;
        }
        _launchTimer--;
        _stepPhysics();
        if (_sim.launchedCount == _ballCount) _phase = GamePhase.flying;
      case GamePhase.flying:
        _stepPhysics();
        if (_sim.flyingCount == 0) {
          _launchX = _sim.firstLandingX ?? _launchX;
          _phaseTimer = kCollectSteps;
          _phase = GamePhase.collecting;
          _emit(CollectStarted(_stepCount));
        }
      case GamePhase.collecting:
        if (--_phaseTimer == 0) _startAdvance();
      case GamePhase.advancing:
        if (--_phaseTimer == 0) _finishAdvance();
    }
    _stepCount++;
  }

  void _stepPhysics() {
    _sim.step();
    final collected = _sim.takeCollected();
    _pendingBalls += collected.rings;
    _starsCollected += collected.stars;
  }

  /// advancing başı: top sayısı güncellenir, tahta kayar, yeni satır gelir, tur +1.
  void _startAdvance() {
    _ballCount += _pendingBalls;
    if (_ballCount > kMaxBalls) _ballCount = kMaxBalls;
    _pendingBalls = 0;
    board.shiftDown();
    board.insertRow(_rows.nextRow(_ballCount));
    _round++;
    _phaseTimer = kAdvanceSteps;
    _phase = GamePhase.advancing;
    _emit(RowAdvanced(_stepCount, _round));
  }

  /// advancing sonu: bitiş satırındaki halka/yıldız silinir; hedef varsa oyun biter.
  void _finishAdvance() {
    for (var col = 0; col < kCols; col++) {
      final cell = board.cellAt(kGameOverRow, col);
      if (cell is PickupCell) {
        board.setCell(kGameOverRow, col, null);
        _emit(PickupExpired(_stepCount, col, cell.kind));
      }
    }
    if (board.hasTargetInRow(kGameOverRow)) {
      _phase = GamePhase.gameOver;
      _emit(GameOver(_stepCount, score));
    } else {
      _phase = GamePhase.ready;
    }
  }

  void _emit(GameEvent event) => _events?.add(event);

  /// Tüm mantıksal durumun 64-bit karması (determinism_test).
  int stateHash() {
    final h = StateHasher()
      ..addInt(_stepCount)
      ..addInt(_phase.index)
      ..addInt(_ballCount)
      ..addInt(_pendingBalls)
      ..addInt(_round)
      ..addInt(_starsCollected)
      ..addDouble(_launchX)
      ..addDouble(_dirX)
      ..addDouble(_dirY)
      ..addInt(_launchTimer)
      ..addInt(_phaseTimer);
    for (var row = 0; row < kBoardRows; row++) {
      for (var col = 0; col < kCols; col++) {
        switch (board.cellAt(row, col)) {
          case null:
            h.addInt(0);
          case TargetCell(:final hp):
            h
              ..addInt(1)
              ..addInt(hp);
          case PickupCell(kind: PickupKind.ring):
            h.addInt(2);
          case PickupCell(kind: PickupKind.star):
            h.addInt(3);
        }
      }
    }
    h.addInt(_sim.launchedCount);
    for (var i = 0; i < _sim.launchedCount; i++) {
      final ball = _sim.balls[i];
      h
        ..addInt(ball.state.index)
        ..addInt(ball.flightSteps)
        ..addDouble(ball.x)
        ..addDouble(ball.y)
        ..addDouble(ball.vx)
        ..addDouble(ball.vy);
    }
    return h.value;
  }
}

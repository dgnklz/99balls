import 'dart:math' show sqrt;

import '../constants.dart';
import '../model/ball.dart';
import '../model/board.dart';
import '../model/cell.dart';
import '../model/pickup.dart';
import 'collisions.dart';
import 'events.dart';

enum _Contact { none, target, left, right, ceiling, floor }

/// Topların sabit adımlı fiziği (PRD Bölüm 2.3 ve 5.3).
///
/// Her [step] çağrısı 1/[kStepsPerSec] sn ilerletir. Toplar fırlatılma
/// sırasıyla işlenir; aynı adımda bir halkaya/yıldıza ilk işlenen top sahip olur.
/// Yalnızca +, −, ×, ÷ ve sqrt kullanılır.
class Simulation {
  final Board board;
  final List<GameEvent>? _events;

  /// Top havuzu; bir atışta en fazla [kMaxBalls] top.
  final List<Ball> balls = List<Ball>.generate(kMaxBalls, (_) => Ball(), growable: false);

  int _launched = 0;
  int _flying = 0;

  /// Olaylara yazılan adım numarası; oturum her adımdan önce günceller.
  int currentStep = 0;

  /// Bu atışta zemine ilk inen topun x'i ([kLaunchMinX, kLaunchMaxX] içinde).
  double? firstLandingX;

  /// Son [takeCollected] çağrısından beri toplanan halka ve yıldızlar.
  int _rings = 0;
  int _stars = 0;

  /// [events] null ise olay üretilmez (başsız tekrar oynatma).
  Simulation(this.board, [List<GameEvent>? events]) : _events = events;

  int get launchedCount => _launched;
  int get flyingCount => _flying;

  /// Yeni atış öncesi havuzu sıfırlar.
  void beginVolley() {
    for (var i = 0; i < _launched; i++) {
      balls[i].reset();
    }
    _launched = 0;
    _flying = 0;
    firstLandingX = null;
  }

  /// Bir topu (x, y)'den (dirX, dirY) yönünde sabit hızla fırlatır.
  /// Yön birim olmak zorunda değildir. Topun indeksini döndürür.
  int launch(double x, double y, double dirX, double dirY) {
    final ball = balls[_launched];
    final scale = kBallStepDistance / sqrt(dirX * dirX + dirY * dirY);
    ball
      ..x = x
      ..y = y
      ..vx = dirX * scale
      ..vy = dirY * scale
      ..state = BallState.flying
      ..flightSteps = 0;
    _flying++;
    return _launched++;
  }

  /// Toplanan (halka, yıldız) sayılarını döndürür ve sayaçları sıfırlar.
  ({int rings, int stars}) takeCollected() {
    final result = (rings: _rings, stars: _stars);
    _rings = 0;
    _stars = 0;
    return result;
  }

  /// Havadaki tüm topları bir adım ilerletir.
  void step() {
    for (var i = 0; i < _launched; i++) {
      final ball = balls[i];
      if (ball.state != BallState.flying) continue;
      ball.flightSteps++;
      if (ball.flightSteps > kFlightTimeoutSteps) {
        _land(i, ball, timedOut: true);
        continue;
      }
      _advance(i, ball);
    }
  }

  /// Swept hareket: adım içindeki en erken teması bul, oraya ilerle, yansı,
  /// kalan süreyle devam et (en fazla [kSweepMaxIterations] kez). Yinelemeler
  /// biterse adımın kalan süresi atılır.
  void _advance(int index, Ball ball) {
    var remaining = 1.0;
    for (var iter = 0; iter < kSweepMaxIterations && remaining > 0; iter++) {
      final x = ball.x;
      final y = ball.y;
      final vx = ball.vx;
      final vy = ball.vy;
      final endX = x + vx * remaining;
      final endY = y + vy * remaining;
      final minX = (x < endX ? x : endX) - kHitDistance;
      final maxX = (x < endX ? endX : x) + kHitDistance;
      final minY = (y < endY ? y : endY) - kHitDistance;
      final maxY = (y < endY ? endY : y) + kHitDistance;

      var best = kNoHit;
      var contact = _Contact.none;
      var hitRow = -1;
      var hitCol = -1;

      // Hedefler (satır, sütun) sırasıyla taranır; eşit temas zamanında ilk
      // bulunan (küçük satır, sonra küçük sütun) kalır.
      for (var row = 0; row < kBoardRows; row++) {
        final cy = Board.centerY(row);
        if (cy < minY || cy > maxY) continue;
        for (var col = 0; col < kCols; col++) {
          if (board.cellAt(row, col) is! TargetCell) continue;
          final cx = Board.centerX(col);
          if (cx < minX || cx > maxX) continue;
          final t = circleToi(x, y, vx, vy, cx, cy, kHitDistance);
          if (t < best) {
            best = t;
            contact = _Contact.target;
            hitRow = row;
            hitCol = col;
          }
        }
      }

      // Eşitlikte hedef duvardan, duvarlar zeminden önce gelir.
      var t = lowerBoundToi(x, vx, kBallMinX);
      if (t < best) {
        best = t;
        contact = _Contact.left;
      }
      t = upperBoundToi(x, vx, kBallMaxX);
      if (t < best) {
        best = t;
        contact = _Contact.right;
      }
      t = lowerBoundToi(y, vy, kBallMinY);
      if (t < best) {
        best = t;
        contact = _Contact.ceiling;
      }
      t = upperBoundToi(y, vy, kLaunchY);
      if (t < best) {
        best = t;
        contact = _Contact.floor;
      }

      if (best > remaining) {
        _collectPickups(index, ball, remaining);
        ball.x = endX;
        ball.y = endY;
        return;
      }

      _collectPickups(index, ball, best);
      ball.x = x + vx * best;
      ball.y = y + vy * best;
      remaining -= best;

      switch (contact) {
        case _Contact.target:
          _hitTarget(index, ball, hitRow, hitCol);
        case _Contact.left:
          ball.x = kBallMinX;
          ball.vx = -vx;
          _emit(WallHit(currentStep, index, WallSide.left));
        case _Contact.right:
          ball.x = kBallMaxX;
          ball.vx = -vx;
          _emit(WallHit(currentStep, index, WallSide.right));
        case _Contact.ceiling:
          ball.y = kBallMinY;
          ball.vy = -vy;
          _emit(WallHit(currentStep, index, WallSide.ceiling));
        case _Contact.floor:
          _land(index, ball);
          return;
        case _Contact.none:
          return;
      }
    }
  }

  void _hitTarget(int index, Ball ball, int row, int col) {
    final hpLeft = board.hitTarget(row, col);
    _emit(TargetHit(currentStep, index, row, col, hpLeft));
    if (hpLeft == 0) _emit(TargetDestroyed(currentStep, index, row, col));

    // Yansıma: n = (top − hedef) / |top − hedef|, v' = v − 2(v·n)n;
    // ardından hız sabit büyüklüğe yeniden ölçeklenir.
    var nx = ball.x - Board.centerX(col);
    var ny = ball.y - Board.centerY(row);
    final len = sqrt(nx * nx + ny * ny);
    if (len == 0) {
      ball.vx = -ball.vx;
      ball.vy = -ball.vy;
      return;
    }
    nx /= len;
    ny /= len;
    final dot = ball.vx * nx + ball.vy * ny;
    final rvx = ball.vx - (dot + dot) * nx;
    final rvy = ball.vy - (dot + dot) * ny;
    final scale = kBallStepDistance / sqrt(rvx * rvx + rvy * rvy);
    ball.vx = rvx * scale;
    ball.vy = rvy * scale;
  }

  /// Topun bu alt segmentte (t ∈ [0, tMax]) değdiği halka ve yıldızları toplar.
  void _collectPickups(int index, Ball ball, double tMax) {
    final x = ball.x;
    final y = ball.y;
    final vx = ball.vx;
    final vy = ball.vy;
    final endX = x + vx * tMax;
    final endY = y + vy * tMax;
    final minX = (x < endX ? x : endX) - kPickupDistance;
    final maxX = (x < endX ? endX : x) + kPickupDistance;
    final minY = (y < endY ? y : endY) - kPickupDistance;
    final maxY = (y < endY ? endY : y) + kPickupDistance;
    const limitSq = kPickupDistance * kPickupDistance;

    for (var row = 0; row < kBoardRows; row++) {
      final cy = Board.centerY(row);
      if (cy < minY || cy > maxY) continue;
      for (var col = 0; col < kCols; col++) {
        final cell = board.cellAt(row, col);
        if (cell is! PickupCell) continue;
        final cx = Board.centerX(col);
        if (cx < minX || cx > maxX) continue;
        if (segmentDistanceSq(x, y, vx, vy, tMax, cx, cy) > limitSq) continue;
        board.setCell(row, col, null);
        switch (cell.kind) {
          case PickupKind.ring:
            _rings++;
          case PickupKind.star:
            _stars++;
        }
        _emit(PickupCollected(currentStep, index, row, col, cell.kind));
      }
    }
  }

  void _land(int index, Ball ball, {bool timedOut = false}) {
    ball
      ..y = kLaunchY
      ..vx = 0
      ..vy = 0
      ..state = BallState.landed;
    _flying--;
    final x = ball.x < kLaunchMinX
        ? kLaunchMinX
        : (ball.x > kLaunchMaxX ? kLaunchMaxX : ball.x);
    firstLandingX ??= x;
    _emit(BallLanded(currentStep, index, ball.x, timedOut: timedOut));
  }

  void _emit(GameEvent event) => _events?.add(event);
}

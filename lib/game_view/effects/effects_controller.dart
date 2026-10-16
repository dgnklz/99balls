import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/config/game_config.dart';
import '../../game_core/constants.dart';
import '../../game_core/engine/events.dart';
import '../../game_core/model/board.dart';
import '../../game_core/model/cell.dart';
import '../../game_core/model/pickup.dart';
import '../../themes/game_theme.dart';
import 'anim_pools.dart';
import 'particle_pool.dart';

/// Oyun olaylarını görsel efektlere ve ses anahtarlarına çevirir (yalnızca
/// görünüm). Çekirdek durumunu okumaz-yazmaz; olaylar ve tahta salt okunur.
///
/// Görsel rastgelelik ayrı bir Random ile yapılır, oyun tohumunu tüketmez
/// (PRD 7.2.1). Hızlanmada bir karede çok olay gelir: kare başına yeni
/// kıvılcım [kMaxSparksPerFrame], yeni animasyon [kMaxAnimsPerFrame] ile
/// kısılır; havuzlar zaten sabit kapasitelidir.
class EffectsController {
  final math.Random _random;
  final SparkPool sparks = SparkPool(kParticlePool);
  final BreakPool breaks = BreakPool(kBreakAnimPool);
  final PopPool pops = PopPool(kPopAnimPool);
  final FloatTextPool texts = FloatTextPool(kFloatTextPool);

  /// Hücre başına kalan vuruş nabzı süresi (sn).
  final Float32List _pulse = Float32List(kBoardRows * kCols);

  GameTheme theme;
  int _sparksThisFrame = 0;
  int _animsThisFrame = 0;
  double _sweepAge = double.infinity;
  double _scorePulseAge = double.infinity;
  double _dangerTime = 0;
  bool _danger = false;

  EffectsController({required this.theme, math.Random? random})
      : _random = random ?? math.Random(kVisualRandomSeed);

  int get sparksThisFrame => _sparksThisFrame;
  int get animsThisFrame => _animsThisFrame;

  /// Her karenin başında çağrılır: kare başına üretim sayaçları sıfırlanır.
  void beginFrame() {
    _sparksThisFrame = 0;
    _animsThisFrame = 0;
  }

  /// Olayı efekte çevirir ve çalınacak sesi döndürür (yoksa null).
  SfxKey? onEvent(GameEvent event, Board board) {
    final palette = theme.palette;
    final effects = theme.effects;
    switch (event) {
      case BallLaunched():
        return SfxKey.shoot;
      case WallHit():
        return SfxKey.wall;
      case TargetHit(:final row, :final col, :final hpLeft):
        if (hpLeft == 0) return null; // ses ve efekt TargetDestroyed'da
        _pulse[row * kCols + col] = kHitPulseSec;
        _burst(Board.centerX(col), Board.centerY(row), effects.hitSparks,
            palette.spark.toARGB32());
        return SfxKey.hit;
      case TargetDestroyed(:final row, :final col):
        final x = Board.centerX(col);
        final y = Board.centerY(row);
        // Ölüm anındaki renk: HP 1 → 0 olduğundan HP 1'in rengi.
        final color = theme.hpRamp.forHp(1).toARGB32();
        if (_takeAnim()) breaks.spawn(x, y, _random.nextBool() ? 1 : -1, color);
        _burst(x, y, effects.breakSparks, color);
        return SfxKey.breakTarget;
      case PickupCollected(:final row, :final col, :final kind):
        final x = Board.centerX(col);
        final y = Board.centerY(row);
        if (kind == PickupKind.ring) {
          if (_takeAnim()) pops.spawn(x, y, PopKind.ring);
          _burst(x, y, effects.ringSparks, palette.pickupGlow.toARGB32());
          return SfxKey.pickup;
        }
        if (_takeAnim()) pops.spawn(x, y, PopKind.star);
        if (_takeAnim()) texts.spawn(x, y, kStarScore);
        _burst(x, y, effects.starSparks, palette.star.toARGB32());
        return SfxKey.star;
      case CollectStarted():
        return SfxKey.collect;
      case RowAdvanced():
        _sweepAge = 0;
        _scorePulseAge = 0;
        _pulse.fillRange(0, _pulse.length, 0); // satırlar kaydı
        return SfxKey.advance;
      case GameOver():
        for (var col = 0; col < kCols; col++) {
          if (board.cellAt(kGameOverRow, col) is! TargetCell) continue;
          final x = Board.centerX(col);
          final y = Board.centerY(kGameOverRow);
          if (_takeAnim()) pops.spawn(x, y, PopKind.shock);
          _burst(x, y, effects.gameOverSparksPerTarget, palette.danger.toARGB32());
        }
        return SfxKey.gameOver;
      case BallLanded():
      case PickupExpired():
        return null;
    }
  }

  bool _takeAnim() {
    if (_animsThisFrame >= kMaxAnimsPerFrame) return false;
    _animsThisFrame++;
    return true;
  }

  void _burst(double x, double y, int count, int color) {
    for (var i = 0; i < count; i++) {
      if (_sparksThisFrame >= kMaxSparksPerFrame) return;
      _sparksThisFrame++;
      final angle = _random.nextDouble() * 2 * math.pi;
      sparks.spawn(
        x: x,
        y: y,
        vx: math.cos(angle) * kSparkSpeed,
        vy: math.sin(angle) * kSparkSpeed,
        life: kSparkLife,
        size: kSparkSize,
        color: color,
      );
    }
  }

  /// Gerçek zamanla ilerler. [danger]: 7. satırda hedef var mı (PRD 7.2).
  void update(double dt, {required bool danger}) {
    if (!(dt > 0)) return;
    sparks.update(dt);
    breaks.update(dt);
    pops.update(dt);
    texts.update(dt);
    for (var i = 0; i < _pulse.length; i++) {
      if (_pulse[i] > 0) _pulse[i] = math.max(0, _pulse[i] - dt);
    }
    _sweepAge += dt;
    _scorePulseAge += dt;
    _danger = danger;
    _dangerTime = danger ? _dangerTime + dt : 0;
  }

  /// Vuruş nabzı: 1 → 1.12 → 1 (sinüs tepe).
  double pulseScale(int row, int col) {
    final remaining = _pulse[row * kCols + col];
    if (remaining <= 0) return 1;
    final u = 1 - remaining / kHitPulseSec;
    return 1 + (kHitPulseScale - 1) * math.sin(math.pi * u);
  }

  /// Satır ilerleme süpürmesi ilerlemesi [0, 1]; yoksa −1.
  double get sweep => _sweepAge < kAdvanceSweepSec ? _sweepAge / kAdvanceSweepSec : -1;

  double get scoreScale {
    if (_scorePulseAge >= kScorePulseSec) return 1;
    return 1 + (kScorePulseScale - 1) * math.sin(math.pi * _scorePulseAge / kScorePulseSec);
  }

  /// Tehlike parlaklığı [0, 1], 1.2 sn'lik nefes döngüsü.
  double get dangerGlow =>
      _danger ? (1 - math.cos(2 * math.pi * _dangerTime / kDangerPulseSec)) / 2 : 0;

  void reset() {
    sparks.clear();
    breaks.clear();
    pops.clear();
    texts.clear();
    _pulse.fillRange(0, _pulse.length, 0);
    _sweepAge = double.infinity;
    _scorePulseAge = double.infinity;
    _dangerTime = 0;
    _danger = false;
  }
}

import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/config/game_config.dart';
import '../core/theme/palette.dart';
import '../game_core/constants.dart';
import '../game_core/engine/aim.dart';
import '../game_core/engine/events.dart';
import '../game_core/rules/round_state_machine.dart';
import 'aim_controller.dart';
import 'ball_merge_animator.dart';
import 'game_loop.dart';
import 'guide_path.dart';
import 'painters/background_component.dart';
import 'painters/balls_component.dart';
import 'painters/board_component.dart';
import 'painters/guide_component.dart';
import 'painters/hud_component.dart';

/// Oyun tuvali (PRD 2.2 game_view). [GameSession]'ı sabit adımlı kare
/// döngüsüne bağlar ve çizim bileşenlerine sunar. Oyun durumu kopyalanmaz:
/// bileşenler `session.board` ve `session.simulation.balls`'u doğrudan okur.
///
/// Dünya koordinatları gu'dur; kamera 416×703'lük sabit çözünürlükle tuvali
/// doldurur (widget zaten tuval oranında yerleştirilir, bkz. CanvasFit).
class BallGame extends FlameGame {
  BallGame({required int seed})
      : _session = GameSession(seed),
        super(camera: CameraComponent.withFixedResolution(width: kVirtualW, height: kVirtualH));

  GameSession _session;
  final AimController aim = AimController();
  final GuidePath guide = GuidePath();
  final GameLoop _loop = GameLoop();

  /// İnen topların ilk topa kayması (yalnızca görsel durum).
  final BallMergeAnimator merge = BallMergeAnimator();

  /// Oyun sonu katmanı açılacağı an skor yazılır; yeniden başlatınca null olur.
  /// Sahibi olan ekran dispose eder (dinleyiciler ondan önce sökülür).
  final ValueNotifier<int?> gameOverScore = ValueNotifier<int?>(null);

  int _advanceStartStep = 0;
  bool _gameOver = false;
  double _gameOverElapsed = 0;

  bool _guideVisible = false;
  Shot? _guideShot;
  GameSession? _guideSession;
  int _guideRound = -1;
  double _guideLength = -1;

  GameSession get session => _session;

  /// Son adımdan bu yana geçen süre / adım süresi.
  double get alpha => _loop.alpha;

  bool get guideVisible => _guideVisible;

  /// Girdi yalnızca ready'de ve oyun sonu sürecinde değilken kabul edilir (5.1).
  bool get acceptsInput => _session.phase == GamePhase.ready && !_gameOver;

  /// advancing ilerlemesi [0, 1].
  double get advanceProgress => _progress(_advanceStartStep, kAdvanceSteps);

  /// Oyun sonunda bitiş satırının kırmızı yandığı yarı periyotlar.
  bool get gameOverBlinkOn {
    if (!_gameOver || _gameOverElapsed >= kGameOverHighlightSec) return false;
    const period = kGameOverHighlightSec / kGameOverBlinkCount;
    return (_gameOverElapsed % period) < period / 2;
  }

  @override
  Color backgroundColor() => Palette.bgGradientBottom;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    // Çizim sırası PRD 4.5.1.
    await world.addAll([
      BackgroundComponent(),
      BoardComponent(),
      BallsComponent(),
      GuideComponent(),
      HudComponent(),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameOver) {
      _gameOverElapsed += dt;
      if (_gameOverElapsed >= kGameOverHighlightSec && gameOverScore.value == null) {
        gameOverScore.value = _session.score;
      }
    } else {
      _loop.advance(_session, dt);
      _handleEvents();
    }
    // Birleşme ve kılavuz gerçek zamanla çalışır (hızlanmadan etkilenmez).
    merge.update(dt);
    _updateGuide();
  }

  void _handleEvents() {
    for (final event in _session.drainEvents()) {
      merge.onEvent(event, _session.simulation);
      switch (event) {
        case RowAdvanced(:final step):
          _advanceStartStep = step;
        case GameOver():
          _gameOver = true;
          aim.cancel();
        default:
          // Ses, parçacık ve titreşim olayları M3'te kullanılacak.
          break;
      }
    }
  }

  /// Kılavuz yalnızca atış yönü, boyu, tur veya oturum değişince yeniden
  /// hesaplanır (karede en fazla bir kez). Boy sürükleme uzunluğuyla uzar.
  void _updateGuide() {
    final shot = aim.current;
    _guideVisible = shot != null && acceptsInput;
    if (!_guideVisible) return;
    final length = guideLengthFor(aim.dragDistance);
    if (shot == _guideShot &&
        length == _guideLength &&
        _guideRound == _session.round &&
        identical(_guideSession, _session)) {
      return;
    }
    guide.compute(_session.board, _session.launchX, shot!.vx, shot.vy, maxLength: length);
    _guideShot = shot;
    _guideLength = length;
    _guideRound = _session.round;
    _guideSession = _session;
  }

  /// Fazın başlangıç olayından bu yana geçen adımlar (+ alpha) / süre.
  /// Olay, fazı başlatan adım içinde yazılır; faz bir sonraki adımda sayılır.
  double _progress(int startStep, int durationSteps) {
    final p = (_session.stepCount - startStep - 1 + _loop.alpha) / durationSteps;
    return p < 0 ? 0 : (p > 1 ? 1 : p);
  }

  // --- Girdi (PRD 5.1). Konumlar ekran pikselidir, s = CanvasFit.scale. ---

  void pointerDown(int pointer, Offset position) {
    if (!acceptsInput) return;
    aim.down(pointer, position.dx, position.dy);
  }

  void pointerMove(int pointer, Offset position, double scale) =>
      aim.move(pointer, position.dx, position.dy, scale);

  /// Bırakma: geçerli nişan varsa atış yapılır ve true döner.
  bool pointerUp(int pointer) {
    final shot = aim.up(pointer);
    if (shot == null || !_session.tryShoot(shot)) return false;
    _loop.noteShot();
    return true;
  }

  void pointerCancel() => aim.cancel();

  /// Yeni tohumla yeni oyun.
  void restart(int seed) {
    _session = GameSession(seed);
    _loop.reset();
    aim.cancel();
    _gameOver = false;
    _gameOverElapsed = 0;
    _advanceStartStep = 0;
    merge.reset();
    _guideShot = null;
    _guideSession = null;
    gameOverScore.value = null;
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // Arka planda geçen süre oyuna eklenmez (PRD 10.2).
        _loop.clock.reset();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        aim.cancel();
    }
  }
}

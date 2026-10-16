import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../core/config/game_config.dart';
import '../core/services/audio_service.dart';
import '../game_core/constants.dart';
import '../game_core/engine/aim.dart';
import '../game_core/engine/events.dart';
import '../game_core/rules/round_state_machine.dart';
import '../themes/game_theme.dart';
import '../themes/theme_registry.dart';
import 'aim_controller.dart';
import 'ball_merge_animator.dart';
import 'effects/effects_controller.dart';
import 'fast_forward.dart';
import 'floor_accent_tracker.dart';
import 'game_loop.dart';
import 'guide_path.dart';
import 'painters/background_component.dart';
import 'painters/balls_component.dart';
import 'painters/board_component.dart';
import 'painters/effects_component.dart';
import 'painters/guide_component.dart';
import 'painters/hud_component.dart';

/// Oyun tuvali (PRD 2.2 game_view). [GameSession]'ı sabit adımlı kare
/// döngüsüne bağlar ve çizim bileşenlerine sunar. Oyun durumu kopyalanmaz:
/// bileşenler `session.board` ve `session.simulation.balls`'u doğrudan okur.
///
/// Dünya koordinatları gu'dur; kamera 416×703'lük sabit çözünürlükle tuvali
/// doldurur (widget zaten tuval oranında yerleştirilir, bkz. CanvasFit).
class BallGame extends FlameGame {
  /// [session]: yalnızca testler için hazır oturum (ör. boş tahtada uzun uçuş).
  BallGame({
    required int seed,
    GameTheme? theme,
    this.audio,
    @visibleForTesting GameSession? session,
  })  : _session = session ?? GameSession(seed),
        _theme = theme ?? ThemeRegistry.fallback,
        super(camera: CameraComponent.withFixedResolution(width: kVirtualW, height: kVirtualH)) {
    _renderer = _theme.createRenderer(_theme);
    effects = EffectsController(theme: _theme);
    final audio = this.audio;
    if (audio != null) unawaited(audio.setTheme(_theme.sounds));
  }

  GameSession _session;

  /// Ses servisi; null ise ses yok (testler).
  final AudioService? audio;

  GameTheme _theme;
  late ThemeRenderer _renderer;

  /// Olay → görsel efekt ve ses anahtarı (yalnızca görünüm).
  late final EffectsController effects;

  String Function(int)? _starBonusFormat;
  final Map<int, String> _starBonusLabels = {};
  final AimController aim = AimController();
  final GuidePath guide = GuidePath();
  final GameLoop _loop = GameLoop();

  /// İnen topların ilk topa kayması (yalnızca görsel durum).
  final BallMergeAnimator merge = BallMergeAnimator();

  /// Atış noktasını izleyen zemin neonu (yalnızca görünüm).
  final FloorAccentTracker floorAccent = FloorAccentTracker();

  /// Oyun sonu katmanı açılacağı an skor yazılır; yeniden başlatınca null olur.
  /// Sahibi olan ekran dispose eder (dinleyiciler ondan önce sökülür).
  final ValueNotifier<int?> gameOverScore = ValueNotifier<int?>(null);

  /// Boost butonunun durumu (yalnızca kare saati; kayda yazılmaz). Sahibi
  /// olan ekran dispose eder.
  final ValueNotifier<BoostState> boost = ValueNotifier<BoostState>(BoostState.hidden);

  int _advanceStartStep = 0;
  bool _gameOver = false;
  double _gameOverElapsed = 0;

  bool _guideVisible = false;
  Shot? _guideShot;
  GameSession? _guideSession;
  int _guideRound = -1;
  double _guideLength = -1;

  GameSession get session => _session;

  bool _debugGame = false;

  /// Geliştirici tahtasıyla başlatılan oyun: skoru, en iyi skoru ve öğretici
  /// işaretini kalıcı veriye yazmaz. Normal [restart] ile false olur.
  bool get isDebugGame => _debugGame;

  /// Cihaz pikseli / gu (tuval genişliği × devicePixelRatio / kVirtualW);
  /// çizicinin pişirdiği sprite'ların çözünürlüğü.
  double _pxPerGu = kSpritePxPerGu;

  double get pxPerGu => _pxPerGu;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final dpr = PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 1;
    if (size.x > 0) _pxPerGu = size.x / kVirtualW * dpr;
    _renderer.setPixelRatio(_pxPerGu);
  }

  GameTheme get theme => _theme;

  ThemeRenderer get renderer => _renderer;

  /// Tema değişimi: yalnızca görünüm ve ses (çekirdek etkilenmez).
  set theme(GameTheme value) {
    if (identical(value, _theme)) return;
    _renderer.dispose();
    _theme = value;
    _renderer = value.createRenderer(value)..setPixelRatio(_pxPerGu);
    effects.theme = value;
    final audio = this.audio;
    if (audio != null) unawaited(audio.setTheme(value.sounds));
  }

  /// Yıldız "+n" yazısının yerelleştirilmiş biçimi (ekrandan verilir).
  set starBonusFormat(String Function(int n)? format) {
    _starBonusFormat = format;
    _starBonusLabels.clear();
  }

  /// Önbellekli "+n" etiketi; biçim verilmemişse null.
  String? starBonusLabel(int n) {
    final format = _starBonusFormat;
    if (format == null) return null;
    return _starBonusLabels.putIfAbsent(n, () => format(n));
  }

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
  Color backgroundColor() => _theme.palette.bgBottom;

  @override
  Future<void> onLoad() async {
    camera.viewfinder.anchor = Anchor.topLeft;
    // Çizim sırası PRD 4.5.1: arka plan, halka+hedef, yok olma, atılan toplar,
    // nişan çizgisi, parçacıklar, HUD.
    await world.addAll([
      BackgroundComponent(),
      BoardComponent(),
      BreakEffectsComponent(),
      BallsComponent(),
      GuideComponent(),
      ParticleEffectsComponent(),
      HudComponent(),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    effects.beginFrame();
    if (_gameOver) {
      _gameOverElapsed += dt;
      if (_gameOverElapsed >= kGameOverHighlightSec && gameOverScore.value == null) {
        gameOverScore.value = _session.score;
      }
    } else {
      _loop.advance(_session, dt);
      _handleEvents();
    }
    _publishBoost();
    // Birleşme, efektler, arka plan ve kılavuz gerçek zamanla çalışır
    // (hızlanmadan etkilenmez).
    merge.update(dt);
    floorAccent.update(dt);
    effects.update(dt, danger: _session.board.hasTargetInRow(kPlayableRows - 1));
    _renderer.update(dt);
    _updateGuide();
  }

  void _handleEvents() {
    final audio = this.audio;
    for (final event in _session.drainEvents()) {
      merge.onEvent(event, _session.simulation);
      floorAccent.onEvent(event, _session.simulation);
      final sfx = effects.onEvent(event, _session.board);
      if (sfx != null) audio?.play(sfx);
      switch (event) {
        case RowAdvanced(:final step):
          _advanceStartStep = step;
        case GameOver():
          _gameOver = true;
          aim.cancel();
          _loop.fastForward.reset();
        default:
          // Titreşim M4/M5'te.
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
    _publishBoost();
    return true;
  }

  void pointerCancel() => aim.cancel();

  /// Boost butonuna basış: uçuş [kFastForwardAfter]'ı aştıysa hızlanmayı
  /// açar/kapatır (rampalı). Simülasyonu etkilemez.
  void toggleBoost() {
    _loop.fastForward.toggle();
    _publishBoost();
  }

  void _publishBoost() => boost.value = _loop.fastForward.state;

  /// Yeni tohumla yeni oyun.
  void restart(int seed) => restartWith(GameSession(seed));

  /// Hazır oturumla yeni oyun. [debugGame]: geliştirici tahtası (ör. yüksek HP);
  /// böyle bir oyun kalıcı veriye yazmaz (bkz. [isDebugGame]).
  void restartWith(GameSession session, {bool debugGame = false}) {
    _session = session;
    _debugGame = debugGame;
    _loop.reset();
    aim.cancel();
    _gameOver = false;
    _gameOverElapsed = 0;
    _advanceStartStep = 0;
    merge.reset();
    floorAccent.reset();
    effects.reset();
    _guideShot = null;
    _guideSession = null;
    gameOverScore.value = null;
    _publishBoost();
  }

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    final audio = this.audio;
    switch (state) {
      case AppLifecycleState.resumed:
        // Arka planda geçen süre oyuna eklenmez (PRD 10.2).
        _loop.clock.reset();
        if (audio != null) unawaited(audio.setBackgrounded(false));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        aim.cancel();
        if (audio != null) unawaited(audio.setBackgrounded(true));
    }
  }

  @override
  void onRemove() {
    _renderer.dispose();
    super.onRemove();
  }
}

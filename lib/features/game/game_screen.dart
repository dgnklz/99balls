import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/canvas_fit.dart';
import '../../core/config/game_config.dart';
import '../../core/services/prefs_service.dart';
import '../../core/theme/palette.dart';
import '../../game_core/constants.dart';
import '../../game_view/game_view.dart';
import 'game_seed.dart';
import 'widgets/game_over_overlay.dart';
import 'widgets/letterbox_painter.dart';
import 'widgets/tutorial_overlay.dart';

/// Oyun ekranı (M2 prototipi). Tuval Bölüm 3.1'e göre tek ölçekle ortalanır;
/// dokunma tüm ekranda dinlenir (PRD 3.2, 5.1).
class GameScreen extends ConsumerStatefulWidget {
  /// Testlerde oyun nesnesine erişmek için; null ise yeni tohumla oluşturulur.
  @visibleForTesting
  final BallGame Function()? gameFactory;

  const GameScreen({super.key, this.gameFactory});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final BallGame _game =
      widget.gameFactory?.call() ?? BallGame(seed: newGameSeed());
  late bool _tutorialVisible;
  bool _tutorialFading = false;

  /// İlk geçerli atışta `tutorial_seen = true` yazılacak mı (katman çoktan
  /// solmuş olabilir).
  late bool _tutorialPending;
  CanvasFit? _fit;

  @override
  void initState() {
    super.initState();
    _tutorialPending = !ref.read(prefsRepositoryProvider).tutorialSeen;
    _tutorialVisible = _tutorialPending;
  }

  @override
  void dispose() {
    _game.gameOverScore.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_game.acceptsInput) return;
    if (_tutorialVisible && !_tutorialFading) {
      setState(() => _tutorialFading = true);
    }
    _game.pointerDown(event.pointer, event.position);
  }

  void _onPointerMove(PointerMoveEvent event) {
    final fit = _fit;
    // Sıfır boyutlu yerleşimde ölçek 0 olur; bölme NaN/∞ üretmesin.
    if (fit == null || !(fit.scale > 0) || !fit.scale.isFinite) return;
    _game.pointerMove(event.pointer, event.position, fit.scale);
  }

  void _onPointerUp(PointerUpEvent event) {
    final shotFired = _game.pointerUp(event.pointer);
    if (shotFired && _tutorialPending) {
      _tutorialPending = false;
      ref.read(prefsRepositoryProvider).setTutorialSeen(true);
    }
  }

  void _playAgain() => _game.restart(newGameSeed());

  /// 416×703 gu düzenindeki bir katmanı tuvalin üstüne aynı ölçekle yerleştirir.
  Widget _onCanvas(CanvasFit fit, Widget child) => Positioned.fromRect(
    rect: fit.canvasRect,
    child: FittedBox(
      child: SizedBox(width: kVirtualW, height: kVirtualH, child: child),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = CanvasFit.compute(constraints.biggest, insets);
        _fit = fit;
        // Material atası: katmanlardaki metinler temadan DefaultTextStyle alır
        // (yoksa Flutter'ın sarı çift alt çizgili hata stili görünür).
        return Material(
          type: MaterialType.transparency,
          child: _buildLayers(fit),
        );
      },
    );
  }

  Widget _buildLayers(CanvasFit fit) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) => _game.pointerCancel(),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: LetterboxPainter(fit))),
          Positioned.fromRect(
            rect: fit.canvasRect,
            child: GameWidget(game: _game),
          ),
          if (_tutorialVisible)
            _onCanvas(
              fit,
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _tutorialFading ? 0 : 1,
                  duration: Duration(
                    milliseconds:
                        (kTutorialFadeSec * Duration.millisecondsPerSecond)
                            .round(),
                  ),
                  onEnd: () => setState(() => _tutorialVisible = false),
                  child: const TutorialOverlay(),
                ),
              ),
            ),
          ValueListenableBuilder<int?>(
            valueListenable: _game.gameOverScore,
            builder: (context, score, _) {
              if (score == null) return const SizedBox.shrink();
              return Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(
                    milliseconds:
                        (kGameOverFadeSec * Duration.millisecondsPerSecond)
                            .round(),
                  ),
                  builder: (context, opacity, child) =>
                      Opacity(opacity: opacity, child: child),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                          color: Palette.scrim.withValues(
                            alpha: kOverlayScrimOpacity,
                          ),
                        ),
                      ),
                      _onCanvas(
                        fit,
                        Center(
                          child: GameOverCard(
                            score: score,
                            onPlayAgain: _playAgain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

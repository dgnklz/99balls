import 'package:flutter/material.dart';

import '../../../core/config/game_config.dart';
import '../../../core/theme/palette.dart';
import '../../../game_core/constants.dart';
import '../../../l10n/app_localizations.dart';

/// İlk çalıştırma öğreticisi (PRD 5.8), 416×703 gu düzeninde.
/// El ikonu beyaz noktayı aşağı-sola çeker ve bırakır; döngü 2.4 sn.
/// Geçici sürüm: yalnızca metin ve basit ikon (çizim M3'te).
class TutorialOverlay extends StatefulWidget {
  const TutorialOverlay({super.key});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (kTutorialLoopSec * Duration.millisecondsPerSecond).round()),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: kVirtualW,
      height: kVirtualH,
      child: Stack(
        children: [
          Positioned(
            left: (kVirtualW - kTutorialTextWidth) / 2,
            top: kTutorialTextY,
            width: kTutorialTextWidth,
            child: Text(
              l10n.tutorialAim,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Palette.textPrimary,
                fontSize: kTutorialTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              final t = _loop.value;
              final pulling = t < kTutorialPullFraction;
              final p = pulling ? Curves.easeOut.transform(t / kTutorialPullFraction) : 0.0;
              final x = kTutorialHandX + kTutorialPullX * p;
              final y = kTutorialHandY + kTutorialPullY * p;
              return Stack(
                children: [
                  Positioned(
                    left: x - kTutorialDotRadius,
                    top: y - kTutorialDotRadius,
                    child: Container(
                      width: kTutorialDotRadius * 2,
                      height: kTutorialDotRadius * 2,
                      decoration: const BoxDecoration(
                        color: Palette.textPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: x - kTutorialIconSize / 2,
                    top: y,
                    child: Opacity(
                      opacity: pulling ? 1 : 0,
                      child: const Icon(
                        Icons.touch_app,
                        size: kTutorialIconSize,
                        color: Palette.textPrimary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

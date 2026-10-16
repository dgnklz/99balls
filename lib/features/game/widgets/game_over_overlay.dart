import 'package:flutter/material.dart';

import '../../../core/config/game_config.dart';
import '../../../core/theme/palette.dart';
import '../../../l10n/app_localizations.dart';

/// Geçici oyun sonu kartı (M2): başlık, skor ve "Play Again".
/// Gerçek oyun sonu ekranı (en iyi skor, rekor, ana menü) M4'te gelecek.
class GameOverCard extends StatelessWidget {
  final int score;
  final VoidCallback onPlayAgain;

  const GameOverCard({super.key, required this.score, required this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: kOverlayCardWidth,
      padding: const EdgeInsets.all(kOverlayCardPadding),
      decoration: BoxDecoration(
        color: Palette.popupSurface,
        borderRadius: BorderRadius.circular(kOverlayCardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.gameOverTitle,
            style: const TextStyle(
              color: Palette.textPrimary,
              fontSize: kOverlayTitleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kOverlayGap),
          Text(
            l10n.scoreLabel,
            style: const TextStyle(color: Palette.textSecondary, fontSize: kOverlayLabelSize),
          ),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Palette.textPrimary,
              fontSize: kOverlayScoreSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kOverlayGap),
          SizedBox(
            width: double.infinity,
            height: kOverlayButtonHeight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Palette.buttonPrimary,
                foregroundColor: Palette.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kOverlayCardRadius),
                ),
              ),
              onPressed: onPlayAgain,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  l10n.playAgain,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: kOverlayButtonTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

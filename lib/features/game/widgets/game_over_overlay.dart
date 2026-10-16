import 'package:flutter/material.dart';

import '../../../core/config/game_config.dart';
import '../../../l10n/app_localizations.dart';
import '../../../themes/game_theme.dart';

/// Geçici oyun sonu kartı (M2): başlık, skor ve "Play Again".
/// Gerçek oyun sonu ekranı (en iyi skor, rekor, ana menü) M4'te gelecek.
class GameOverCard extends StatelessWidget {
  final int score;
  final ThemePalette palette;
  final VoidCallback onPlayAgain;

  const GameOverCard({
    super.key,
    required this.score,
    required this.palette,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: kOverlayCardWidth,
      padding: const EdgeInsets.all(kOverlayCardPadding),
      decoration: BoxDecoration(
        color: palette.popupSurface,
        borderRadius: BorderRadius.circular(kOverlayCardRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.gameOverTitle,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: kOverlayTitleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: kOverlayGap),
          Text(
            l10n.scoreLabel,
            style: TextStyle(color: palette.textSecondary, fontSize: kOverlayLabelSize),
          ),
          Text(
            score.toString(),
            style: TextStyle(
              color: palette.textPrimary,
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
                backgroundColor: palette.buttonPrimary,
                foregroundColor: palette.textPrimary,
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

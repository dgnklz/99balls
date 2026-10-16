import '../constants.dart';

/// Skor = tur sayacı + kStarScore × toplanan yıldız (PRD Bölüm 5.6 ve 5.11).
int scoreFor(int round, int starsCollected) => round + kStarScore * starsCollected;

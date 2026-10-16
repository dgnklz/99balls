import 'dart:math';

const int _bits32 = 1 << 32;
const int _shift32 = 32;

/// Tek oyunculu modda her oyunun tohumu (PRD 6.3): cihazın güvenli
/// rastgele kaynağından 64 bit.
int newGameSeed() {
  final random = Random.secure();
  return (random.nextInt(_bits32) << _shift32) | random.nextInt(_bits32);
}

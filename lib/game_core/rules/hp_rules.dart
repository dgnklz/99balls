/// Sayılı topun HP'si (PRD Bölüm 6.2).
///
/// [t]: oyuncunun top sayısı (>= 1). [m2]: 2, 3 veya 4 (çarpan = m2 / 2).
/// Sonuç = round-half-to-even(t * m2 / 2). Dart'ın `.round()` fonksiyonu
/// yarımı yukarı yuvarladığı için kullanılmaz.
int hpFor(int t, int m2) {
  final n = t * m2;
  final q = n ~/ 2;
  final r = n % 2;
  if (r == 0) return q;
  return (q % 2 == 0) ? q : q + 1; // tam yarım: çifte yuvarla
}

/// Oyunun tek tohumlu rastgele sayı üreteci (PRD Bölüm 6.3).
///
/// Yalnızca 64-bit tamsayı işlemleri kullanır; native Dart'ta (mobil) her
/// cihazda aynı diziyi üretir. Web'de int 64-bit olmadığı için desteklenmez.
class SplitMix64 {
  static const int _gamma = 0x9E3779B97F4A7C15;
  static const int _mix1 = 0xBF58476D1CE4E5B9;
  static const int _mix2 = 0x94D049BB133111EB;
  static const int _shift1 = 30;
  static const int _shift2 = 27;
  static const int _shift3 = 31;

  /// [nextInt] için kullanılan üst bitlerin başlangıcı.
  static const int _nextIntShift = 33;

  int _s;

  SplitMix64(this._s);

  /// Sonraki 64-bit değer (Dart int olarak; üst bit set ise negatif görünür).
  int next() {
    _s += _gamma;
    int z = _s;
    z = (z ^ (z >>> _shift1)) * _mix1;
    z = (z ^ (z >>> _shift2)) * _mix2;
    return z ^ (z >>> _shift3);
  }

  /// 0..bound-1 aralığında bir tamsayı.
  int nextInt(int bound) => (next() >>> _nextIntShift) % bound;
}

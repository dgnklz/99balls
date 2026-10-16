import 'dart:ui';

/// HP renk durakları c0…c10 (PRD 7.1). **Geçici değerler**: M3'te tema seçilir.
/// Sıra "kolay → zor": sıcak renkler düşük HP, soğuk orta, mor-pembe yüksek.
abstract final class HpColors {
  static const Color c0 = Color(0xFFD7263D); // kırmızı-pembe
  static const Color c1 = Color(0xFFD9600F); // turuncu
  static const Color c2 = Color(0xFFA88400); // sarı
  static const Color c3 = Color(0xFF2E9A2E); // parlak yeşil
  static const Color c4 = Color(0xFF12907F); // turkuaz
  static const Color c5 = Color(0xFF1789A8); // açık camgöbeği
  static const Color c6 = Color(0xFF2B7BD0); // gök mavisi
  static const Color c7 = Color(0xFF2F55D4); // mavi
  static const Color c8 = Color(0xFF4B3BC4); // indigo
  static const Color c9 = Color(0xFFA53BB8); // eflatun-pembe
  static const Color c10 = Color(0xFFC2187F); // magenta

  static const List<Color> stops = [c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10];

  /// (HP, renk) anahtar kareleri. İki anahtar kare arasında doğrusal sRGB geçiş;
  /// ilkinden küçük HP ilk renk, sonuncusundan büyük HP son renk.
  /// Aynı rengin iki kez geçmesi o aralığı sabit yapar (ör. 7–13 = c2).
  static const List<(int, Color)> keyframes = [
    (3, c0),
    (6, c1),
    (7, c2),
    (13, c2),
    (17, c3),
    (24, c3),
    (26, c4),
    (27, c5),
    (32, c5),
    (34, c6),
    (36, c7),
    (44, c8),
    (48, c9),
    (50, c10),
  ];

  static final List<Color> _cache = [];

  /// HP'ye göre topun rengi. Sonuçlar önbelleğe alınır (çizimde tahsis yok).
  static Color forHp(int hp) {
    final last = keyframes.last.$1;
    final index = hp < 0 ? 0 : (hp > last ? last : hp);
    if (_cache.isEmpty) {
      for (var h = 0; h <= last; h++) {
        _cache.add(_compute(h));
      }
    }
    return _cache[index];
  }

  static Color _compute(int hp) {
    if (hp <= keyframes.first.$1) return keyframes.first.$2;
    for (var i = 1; i < keyframes.length; i++) {
      final (hpB, colorB) = keyframes[i];
      if (hp <= hpB) {
        final (hpA, colorA) = keyframes[i - 1];
        if (colorA == colorB) return colorA; // sabit aralık, birebir aynı renk
        return Color.lerp(colorA, colorB, (hp - hpA) / (hpB - hpA))!;
      }
    }
    return keyframes.last.$2;
  }
}

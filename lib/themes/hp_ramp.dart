import 'dart:ui';

/// HP → renk (PRD 7.1). 11 durak c0…c10 temadan gelir; geçiş kuralı ortaktır.
/// Sıra "kolay → zor": sıcak renkler düşük HP, soğuk orta, mor-pembe yüksek.
class HpRamp {
  static const int stopCount = 11;

  /// Durak indeksleri ve HP anahtar kareleri. İki kare arasında doğrusal sRGB;
  /// ilkinden küçük HP ilk renk, sonuncusundan büyük HP son renk. Aynı durağın
  /// iki kez geçmesi o aralığı sabit yapar (ör. 7–13 = c2).
  static const List<(int, int)> keyframes = [
    (3, 0),
    (6, 1),
    (7, 2),
    (13, 2),
    (17, 3),
    (24, 3),
    (26, 4),
    (27, 5),
    (32, 5),
    (34, 6),
    (36, 7),
    (44, 8),
    (48, 9),
    (50, 10),
  ];

  final List<Color> stops;
  final List<Color> _cache;

  HpRamp(List<Color> stops)
      : assert(stops.length == stopCount, 'HpRamp needs $stopCount stops'),
        stops = List.unmodifiable(stops),
        _cache = _build(stops);

  /// HP'ye göre topun rengi (önbellekten; çizimde tahsis yok).
  Color forHp(int hp) {
    final last = keyframes.last.$1;
    return _cache[hp < 0 ? 0 : (hp > last ? last : hp)];
  }

  static List<Color> _build(List<Color> stops) {
    final last = keyframes.last.$1;
    return List<Color>.unmodifiable([for (var hp = 0; hp <= last; hp++) _compute(stops, hp)]);
  }

  static Color _compute(List<Color> stops, int hp) {
    if (hp <= keyframes.first.$1) return stops[keyframes.first.$2];
    for (var i = 1; i < keyframes.length; i++) {
      final (hpB, stopB) = keyframes[i];
      if (hp <= hpB) {
        final (hpA, stopA) = keyframes[i - 1];
        if (stopA == stopB) return stops[stopA]; // sabit aralık
        return Color.lerp(stops[stopA], stops[stopB], (hp - hpA) / (hpB - hpA))!;
      }
    }
    return stops[keyframes.last.$2];
  }
}

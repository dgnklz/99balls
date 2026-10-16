import 'dart:math' show sqrt;

import '../core/config/game_config.dart';

/// Bir kesik parçası: uç noktalar ve yol başından mesafeler.
typedef DashVisitor = void Function(
  double x0,
  double y0,
  double x1,
  double y1,
  double startDistance,
  double endDistance,
);

/// Noktalardan geçen kırık çizgi boyunca kesikli çizgi parçalarını üretir
/// (PRD 5.2). Desen tüm yol boyunca süreklidir: k. çizgi [k·p, k·p + dash]
/// aralığını kaplar, p = dash + gap; her parça yolun uzunluğuyla kesilir.
///
/// Parçalar mod alma ile değil doğrudan k indeksiyle üretilir ve k her turda
/// artar; segment başına en fazla [maxDashesPerSegment] tur yapılır. Bu yüzden
/// kayan nokta yuvarlaması döngüyü durduramaz (eski sürümdeki ANR hatası).
/// Sıfır uzunluklu segment ve parçalar atlanır. Üretilen parça sayısını döndürür.
int walkDashes({
  required int pointCount,
  required double Function(int index) xAt,
  required double Function(int index) yAt,
  required DashVisitor onDash,
  double dash = kGuideDash,
  double gap = kGuideGap,
  int maxDashesPerSegment = kGuideMaxDashesPerSegment,
}) {
  final period = dash + gap;
  var emitted = 0;
  var segStart = 0.0;

  for (var i = 1; i < pointCount; i++) {
    final ax = xAt(i - 1);
    final ay = yAt(i - 1);
    final segX = xAt(i) - ax;
    final segY = yAt(i) - ay;
    final segLen = sqrt(segX * segX + segY * segY);
    if (!(segLen > 0)) continue;
    final segEnd = segStart + segLen;
    final ux = segX / segLen;
    final uy = segY / segLen;

    var k = (segStart / period).floor();
    for (var n = 0; n < maxDashesPerSegment; n++, k++) {
      final dashStart = k * period;
      if (dashStart >= segEnd) break;
      final from = dashStart > segStart ? dashStart : segStart;
      final dashEnd = dashStart + dash;
      final to = dashEnd < segEnd ? dashEnd : segEnd;
      if (to <= from) continue;
      final t0 = from - segStart;
      final t1 = to - segStart;
      onDash(ax + ux * t0, ay + uy * t0, ax + ux * t1, ay + uy * t1, from, to);
      emitted++;
    }
    segStart = segEnd;
  }
  return emitted;
}

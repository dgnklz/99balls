import 'dart:math' show sqrt;

/// Çarpışma yokluğunu gösteren temas zamanı.
const double kNoHit = double.infinity;

/// p + v·t noktasının (c, radius) dairesine **yaklaşırken** ilk değdiği t ≥ 0.
///
/// Yalnızca (p − c)·v < 0 iken (top daireye yaklaşıyorsa) temas sayılır; bu
/// çifte vuruş korumasıdır (PRD 5.3, v·n < 0). Başlangıçta iç içe ve
/// yaklaşıyorsa 0 döner. Temas yoksa [kNoHit].
double circleToi(
  double px,
  double py,
  double vx,
  double vy,
  double cx,
  double cy,
  double radius,
) {
  final dx = px - cx;
  final dy = py - cy;
  final approach = dx * vx + dy * vy;
  if (approach >= 0) return kNoHit;
  final c = dx * dx + dy * dy - radius * radius;
  if (c <= 0) return 0;
  final a = vx * vx + vy * vy;
  final disc = approach * approach - a * c;
  if (disc < 0) return kNoHit;
  return (-approach - sqrt(disc)) / a;
}

/// Azalan yönde hareket eden koordinatın [limit]'e ulaştığı t ≥ 0.
double lowerBoundToi(double p, double v, double limit) {
  if (v >= 0) return kNoHit;
  if (p <= limit) return 0;
  return (limit - p) / v;
}

/// Artan yönde hareket eden koordinatın [limit]'e ulaştığı t ≥ 0.
double upperBoundToi(double p, double v, double limit) {
  if (v <= 0) return kNoHit;
  if (p >= limit) return 0;
  return (limit - p) / v;
}

/// p'den p + v·tMax'e giden segmentin (cx, cy) noktasına en yakın uzaklığının karesi.
double segmentDistanceSq(
  double px,
  double py,
  double vx,
  double vy,
  double tMax,
  double cx,
  double cy,
) {
  final a = vx * vx + vy * vy;
  var t = a == 0 ? 0.0 : ((cx - px) * vx + (cy - py) * vy) / a;
  if (t < 0) t = 0;
  if (t > tMax) t = tMax;
  final dx = px + vx * t - cx;
  final dy = py + vy * t - cy;
  return dx * dx + dy * dy;
}

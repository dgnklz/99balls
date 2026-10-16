import 'dart:math' as math;

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_view/dash_walker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kesikli çizgi üretimi (PRD 5.2). Bu testlerin hepsinde döngünün bitmesi
/// yapısal olarak garanti (k her turda artar, segment başına üst sınır var);
/// Dart'ta test zaman aşımı senkron sonsuz döngüyü kesemeyeceği için ayrıca
/// parça sayısının sınırlı olduğu doğrulanır.
const double _period = kGuideDash + kGuideGap;

typedef _Dash = ({double x0, double y0, double x1, double y1, double from, double to});

class _Result {
  final List<_Dash> dashes;
  final int returned;

  _Result(this.dashes, this.returned);

  double get total => dashes.fold(0.0, (sum, d) => sum + (d.to - d.from));
}

_Result _walk(List<(double, double)> points, {int max = kGuideMaxDashesPerSegment}) {
  final dashes = <_Dash>[];
  final returned = walkDashes(
    pointCount: points.length,
    xAt: (i) => points[i].$1,
    yAt: (i) => points[i].$2,
    maxDashesPerSegment: max,
    onDash: (x0, y0, x1, y1, from, to) =>
        dashes.add((x0: x0, y0: y0, x1: x1, y1: y1, from: from, to: to)),
  );
  return _Result(dashes, returned);
}

double _pathLength(List<(double, double)> points) {
  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    final dx = points[i].$1 - points[i - 1].$1;
    final dy = points[i].$2 - points[i - 1].$2;
    length += math.sqrt(dx * dx + dy * dy);
  }
  return length;
}

/// Sürekli desenin L uzunluğundaki yolda kapladığı toplam (kapalı form).
double _expectedTotal(double length) {
  final full = (length / _period).floor();
  return full * kGuideDash + math.min(kGuideDash, length - full * _period);
}

/// Her testte geçerli olması gereken değişmezler.
void _expectWellFormed(_Result r) {
  expect(r.returned, r.dashes.length);
  var previousEnd = -1.0;
  for (final d in r.dashes) {
    final len = d.to - d.from;
    expect(len, greaterThan(0), reason: 'no zero/negative pieces');
    expect(len, lessThanOrEqualTo(kGuideDash + 1e-9));
    expect(d.from, greaterThanOrEqualTo(previousEnd - 1e-9), reason: 'increasing distance');
    final drawn = math.sqrt(math.pow(d.x1 - d.x0, 2) + math.pow(d.y1 - d.y0, 2));
    expect(drawn, closeTo(len, 1e-9), reason: 'endpoints match distances');
    previousEnd = d.to;
  }
}

void main() {
  test('vertical path x=208, y 622 → 132 (the ANR case)', () {
    final points = [(208.0, kLaunchY), (208.0, kLaunchY - kGuideLength)];
    final r = _walk(points);
    _expectWellFormed(r);
    expect(r.total, closeTo(240, 1e-9));
    expect(r.total, closeTo(_expectedTotal(kGuideLength), 1e-9));
    expect(r.dashes, hasLength(20));
    for (final d in r.dashes) {
      expect([d.x0, d.x1], [208, 208]);
    }
  });

  test('horizontal path 13 → 403', () {
    final r = _walk([(kBallMinX, 300), (kBallMaxX, 300)]);
    _expectWellFormed(r);
    expect(r.total, closeTo(192, 1e-9));
  });

  test('very short segments, including a 1e-12 one', () {
    final points = [(100.0, 300.0), (100.0, 302.0), (100.0, 302.0 + 1e-12), (100.0, 305.0)];
    final r = _walk(points);
    _expectWellFormed(r);
    expect(r.total, closeTo(_expectedTotal(_pathLength(points)), 1e-9));
    expect(r.total, closeTo(5, 1e-9));
  });

  test('zero-length segments are skipped', () {
    final r = _walk([(50.0, 50.0), (50.0, 50.0), (50.0, 50.0)]);
    expect(r.dashes, isEmpty);
  });

  test('length an exact multiple of the period', () {
    const length = 10 * _period;
    final points = [(208.0, kLaunchY), (208.0, kLaunchY - length)];
    final r = _walk(points);
    _expectWellFormed(r);
    expect(r.total, closeTo(10 * kGuideDash, 1e-9));
    expect(r.dashes, hasLength(10));
  });

  test('64-segment zigzag keeps the pattern continuous', () {
    final points = <(double, double)>[];
    for (var i = 0; i <= kGuideMaxSegments; i++) {
      points.add((i.isEven ? kBallMinX : kBallMaxX, kLaunchY - i * 5.0));
    }
    final r = _walk(points);
    _expectWellFormed(r);
    expect(r.returned, lessThanOrEqualTo(kGuideMaxSegments * kGuideMaxDashesPerSegment));
    expect(r.total, closeTo(_expectedTotal(_pathLength(points)), 1e-6));
    // Bir segmentin içinde başlayan her tam çizgi k·p'de başlar.
    for (final d in r.dashes) {
      final k = (d.from / _period).round();
      final onGrid = (d.from - k * _period).abs() < 1e-6;
      final splitAtCorner = d.to - d.from < kGuideDash - 1e-6;
      expect(onGrid || splitAtCorner, isTrue, reason: 'dash at ${d.from}');
    }
  });

  test('segment starting one ulp-scale step before a period boundary', () {
    final firstLength = 5 * _period - 1e-13;
    final points = [(208.0, 600.0), (208.0, 600.0 - firstLength), (208.0, 600.0 - firstLength - 100)];
    final r = _walk(points);
    _expectWellFormed(r);
    expect(r.total, closeTo(_expectedTotal(_pathLength(points)), 1e-9));
  });

  test('a very long segment is cut at the per-segment limit', () {
    final r = _walk([(0.0, 0.0), (0.0, 1e6)]);
    expect(r.returned, kGuideMaxDashesPerSegment);
    _expectWellFormed(r);
  });
}

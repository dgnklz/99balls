import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/game_core/model/board.dart';
import 'package:balls_99/game_view/guide_path.dart';
import 'package:flutter_test/flutter_test.dart';

/// Nişan çizgisi boyu sürüklemeyle kademeli uzar.
void main() {
  test('length ramps from 60 to 490 over 120 gu past the dead zone', () {
    expect(guideLengthFor(0), kGuideMinLength);
    expect(guideLengthFor(kAimExitDistance), kGuideMinLength);
    expect(guideLengthFor(kAimDeadZone), kGuideMinLength);
    expect(guideLengthFor(kAimDeadZone + kGuideRampDistance / 2), closeTo(275, 1e-9));
    expect(guideLengthFor(kAimDeadZone + kGuideRampDistance), kGuideLength);
    expect(guideLengthFor(500), kGuideLength);
    expect(guideLengthFor(double.nan), kGuideMinLength);
  });

  test('length is monotonic in drag distance', () {
    var previous = 0.0;
    for (var d = 0.0; d <= 200; d += 0.5) {
      final length = guideLengthFor(d);
      expect(length, greaterThanOrEqualTo(previous));
      previous = length;
    }
  });

  test('a short line still bends at the wall and ends at its exact length', () {
    final guide = GuidePath()
      ..compute(Board(), kBallMinX + 10, -100, -100, maxLength: kGuideMinLength);
    expect(guide.pointCount, 3);
    expect(guide.xAt(1), kBallMinX);
    expect(guide.length, closeTo(kGuideMinLength, 1e-9));
  });
}

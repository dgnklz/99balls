import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/candyburst/candyburst_renderer.dart';
import 'package:balls_99/themes/candyburst/candyburst_theme.dart';
import 'package:flutter_test/flutter_test.dart';

/// Candy Burst çizici: tüm çizim çağrıları hatasız; desen katmanları tuval
/// boyunda sarar; desen periyodu tuvali tam böler (ek yeri yok).
void main() {
  test('all paint calls succeed', () {
    final renderer = CandyBurstRenderer(candyBurstTheme);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    renderer
      ..update(1 / 60)
      ..paintBackground(canvas)
      ..paintTarget(canvas, 100, 200, 7)
      ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
      ..paintTarget(canvas, 100, 200, 3, fill: candyBurstPalette.danger)
      ..paintRing(canvas, 50, 50)
      ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
      ..paintStar(canvas, 60, 60, opacity: 0.3)
      ..paintBall(canvas, 208, kLaunchY)
      ..paintSpark(canvas, 80, 80, kSparkSpeed, -kSparkSpeed, kSparkSize, const Color(0xFFFF9AC1))
      ..paintSpark(canvas, 80, 80, 0, 0, kSparkSize, const Color(0xFFFF9AC1))
      ..paintHud(canvas,
          score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: 120)
      ..paintFloatText(canvas, '+3', 100, 100, 0.5);
    canvas
      ..save()
      ..scale(1, 0.3);
    renderer.paintTargetDisc(canvas, candyBurstPalette.danger, 0.5);
    canvas.restore();
    recorder.endRecording().dispose();
    renderer.dispose();
  });

  test('pattern layers drift down and wrap inside the canvas', () {
    final renderer = CandyBurstRenderer(candyBurstTheme);
    renderer.update(1);
    expect(renderer.stripeOffset, closeTo(kCandyStripeSpeed, 1e-9));
    expect(renderer.sprinkleOffset, closeTo(kCandySprinkleSpeed, 1e-9));
    for (var i = 0; i < 10000; i++) {
      renderer.update(1 / 30);
      expect(renderer.stripeOffset, inInclusiveRange(0, kVirtualH));
      expect(renderer.sprinkleOffset, inInclusiveRange(0, kVirtualH));
    }
    renderer
      ..update(0)
      ..update(double.nan); // geçersiz dt yok sayılır
    expect(renderer.sprinkleOffset.isFinite, isTrue);
    final recorder = PictureRecorder();
    renderer.paintBackground(Canvas(recorder));
    recorder.endRecording().dispose();
    renderer.dispose();
    expect(kCandySprinkleSpeed, greaterThan(kCandyStripeSpeed), reason: 'parallax');
  });

  test('ball, ring and gloss stay inside their shapes', () {
    // Sedefli top atılan topun yarıçapında; halka ondan büyük (PRD 7.4).
    expect(kBallRadius - kCandyBallRimStroke / 2, lessThan(kPickupRadius - kPickupStroke / 2));
    // Parlak vurgu ve spiral hedefin içinde kalır.
    expect(kCandySwirlOuterRadius, lessThan(kTargetRadius));
    const glossFar = (-kCandyGlossX + kCandyGlossRadiusX) * (-kCandyGlossX + kCandyGlossRadiusX) +
        (-kCandyGlossY) * (-kCandyGlossY);
    expect(glossFar, lessThan(kTargetRadius * kTargetRadius));
  });
}

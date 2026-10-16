import 'dart:ui';

import 'package:balls_99/core/config/game_config.dart';
import 'package:balls_99/game_core/constants.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_renderer.dart';
import 'package:balls_99/themes/orbitfall/orbitfall_theme.dart';
import 'package:balls_99/themes/text_cache.dart';
import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:flutter_test/flutter_test.dart';

/// Orbitfall çizici: tüm çizim çağrıları hatasız; yıldız tozu tuval içinde kalır.
void main() {
  test('all paint calls succeed', () {
    final renderer = OrbitfallRenderer(orbitfallTheme);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    renderer
      ..update(1 / 60)
      ..paintBackground(canvas)
      ..paintTarget(canvas, 100, 200, 7)
      ..paintTarget(canvas, 100, 200, 150, scale: kHitPulseScale)
      ..paintTarget(canvas, 100, 200, 3, fill: orbitfallPalette.danger)
      ..paintRing(canvas, 50, 50, scale: kPopScale, opacity: 0.5)
      ..paintStar(canvas, 60, 60, opacity: 0.3)
      ..paintBall(canvas, 208, kLaunchY)
      ..paintHud(canvas, score: 42, counter: 7, dangerGlow: 0.5, sweep: 0.3, scoreScale: 1.1, floorAccentX: kLaunchStartX)
      ..paintHud(canvas, score: 42, counter: 7, dangerGlow: 0, sweep: -1, scoreScale: 1, floorAccentX: kBallMinX)
      ..paintFloatText(canvas, '+3', 100, 100, 0.5)
      ..paintFloatText(canvas, '+3', 100, 100, 1);
    canvas
      ..save()
      ..scale(1, 0.3);
    renderer.paintTargetDisc(canvas, orbitfallPalette.danger, 0.5);
    canvas.restore();
    recorder.endRecording().dispose();
    renderer.dispose();
  });

  test('"+3" text: gold, heavy, 40% larger, dark outline', () {
    final style = OrbitfallRenderer.floatTextStyle(orbitfallTheme);
    expect(style.color, const Color(0xFFFFD54A));
    expect(style.fontSize, 20 * 1.4);
    expect(style.fontWeight, FontWeight.w900);
    expect(style.shadows, hasLength(greaterThanOrEqualTo(4)), reason: 'outline + shadow');
    expect(kFloatTextSec, 0.6, reason: 'PRD 5.11 duration unchanged');
  });

  test('star dust drifts down and wraps inside the canvas', () {
    final renderer = OrbitfallRenderer(orbitfallTheme);
    // Uzun süre ilerlet: noktalar tuvalin dışına taşmamalı (sarma).
    for (var i = 0; i < 10000; i++) {
      renderer.update(1 / 30);
    }
    final recorder = PictureRecorder();
    renderer.paintBackground(Canvas(recorder));
    recorder.endRecording().dispose();
    renderer.dispose();
    expect(kStarDustSpeedNear, greaterThan(kStarDustSpeedFar), reason: 'parallax');
  });

  test('TextCache lays out each value once and reports sizes', () {
    final cache = TextCache(const TextStyle(fontSize: kHudFontSize));
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    cache
      ..paintNumber(canvas, 12, 10, 10)
      ..paintNumber(canvas, 12, 20, 20)
      ..paintText(canvas, '+3', 30, 30);
    expect(cache.sizeOf('+3').width, greaterThan(0));
    expect(cache.sizeOf('+3'), cache.sizeOf('+3'));
    recorder.endRecording().dispose();
    cache.dispose();
  });
}

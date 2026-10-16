import 'dart:ui';

import 'package:balls_99/app/canvas_fit.dart';
import 'package:balls_99/app/safe_insets.dart';
import 'package:balls_99/core/config/game_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tam ekranda yalnızca çentik/güvenli alan payı; tuval çentiğin altında kalır.
void main() {
  const screen = Size(393, 852);

  test('Android: inset comes only from the cutout, not from (transient) bars', () {
    const data = MediaQueryData(
      size: screen,
      viewPadding: EdgeInsets.only(top: 24, bottom: 48),
      displayFeatures: [
        DisplayFeature(
          bounds: Rect.fromLTRB(160, 0, 233, 34),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    );
    expect(gameSafeInsets(data, TargetPlatform.android), const EdgeInsets.only(top: 34));
  });

  test('Android without a notch and bars hidden: full screen', () {
    const data = MediaQueryData(size: screen);
    expect(gameSafeInsets(data, TargetPlatform.android), EdgeInsets.zero);
  });

  test('Android: bottom and side cutouts', () {
    const data = MediaQueryData(
      size: screen,
      displayFeatures: [
        DisplayFeature(
          bounds: Rect.fromLTRB(150, 830, 240, 852),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
        DisplayFeature(
          bounds: Rect.fromLTRB(0, 300, 20, 360),
          type: DisplayFeatureType.cutout,
          state: DisplayFeatureState.unknown,
        ),
      ],
    );
    expect(gameSafeInsets(data, TargetPlatform.android),
        const EdgeInsets.only(left: 20, bottom: 22));
  });

  test('iOS: uses viewPadding (notch and home indicator safe area)', () {
    const data = MediaQueryData(
      size: screen,
      viewPadding: EdgeInsets.only(top: 59, bottom: 34),
    );
    expect(gameSafeInsets(data, TargetPlatform.iOS), const EdgeInsets.only(top: 59, bottom: 34));
  });

  test('canvas sits below the notch; the score stays visible under it', () {
    const insets = EdgeInsets.only(top: 34);
    final fit = CanvasFit.compute(screen, insets);
    expect(fit.canvasRect.top, greaterThanOrEqualTo(insets.top));
    final scoreY = fit.canvasRect.top + kHudScoreY * fit.scale;
    expect(scoreY, greaterThan(insets.top));
    // Çubuklar gizli, çentik yoksa tuval tüm ekranı kullanır (tek ölçek).
    final full = CanvasFit.compute(screen, EdgeInsets.zero);
    expect(full.canvasRect.width, screen.width);
  });
}
